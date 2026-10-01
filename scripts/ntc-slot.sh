#!/bin/zsh
#
# ntc-slot.sh -- run one test suite, record its exit code, and let the LAST
# suite to finish report on the whole set.
#
#   ntc-slot.sh <slot> -- <command...>
#
# Wrapped around each pane command by npm-test-concurrent.sh. Output of the
# real command passes through untouched and the real exit status is preserved,
# so this is invisible except for the notification at the end.
#
# ---------------------------------------------------------------------------
# WHY A "LAST ONE FINISHES" ELECTION AND NOT "ASK THE SLOWEST PANE"
# ---------------------------------------------------------------------------
# tmux has no way to read another pane's last exit code. #{pane_dead_status}
# only exists for panes that have EXITED, and these panes stay alive at a
# prompt. So each suite has to report its own result and something has to
# aggregate them.
#
# The obvious move is to let test:server do it, since it is almost always the
# slowest. "Almost" is the bug: on a warm cache lint sometimes trails, and
# then server aggregates a set that is not finished yet -- reading a missing
# file, or worse, last run's stale one. A notifier that is silently wrong is
# worse than no notifier.
#
# Instead every pane, after writing its own result, checks whether the set is
# complete and if so races to `mkdir .reported`. mkdir is atomic: it either
# creates the directory or fails, never both, even if two panes finish in the
# same millisecond. Exactly one winner, and it is whichever pane actually
# finished last. No polling, no daemon, no assumption about which suite is
# slowest.
#
# ---------------------------------------------------------------------------
# SEMANTICS: "LATEST KNOWN RESULT OF EACH SUITE"
# ---------------------------------------------------------------------------
# Resetting clears only THIS slot's result, not all four. So re-running a
# single pane (sync off) updates that one suite and re-evaluates the whole
# picture against the other three's most recent results. That is deliberate
# and useful: fix the one red suite, re-run just it, get the green ding
# without sitting through the other three again.
#
# The normal path -- up-arrow + Enter with synchronize-panes on -- restarts
# all four within milliseconds of each other, so every slot resets long before
# any of them can finish.
#
# ---------------------------------------------------------------------------
# State lives in $XDG_RUNTIME_DIR/ntc/<window_id>/ (tmpfs, cleared at logout):
#   slots          one slot name per line, written by npm-test-concurrent.sh.
#                  The manifest is what defines "the set is complete"; without
#                  it this script records results but never reports, which is
#                  the safe direction to fail.
#   name           base window name, so the glyph can be re-prefixed cleanly
#   <slot>.exit    exit code, written when that suite finishes
#   .reported      election marker; existence means someone already notified

set -u

GLYPH_PENDING=$'\Uf051b'   # nf-md-timer_sand
GLYPH_PASS=$'\Uf0c3'       # nf-fa-flask
GLYPH_FAIL=$'\Uf188'       # nf-fa-bug

slot="${1:-}"
if [[ -z "$slot" ]]; then
    print -u2 "ntc-slot: usage: ntc-slot.sh <slot> -- <command...>"
    exit 2
fi
shift
[[ "${1:-}" == "--" ]] && shift
if (( $# == 0 )); then
    print -u2 "ntc-slot: no command given"
    exit 2
fi

# Outside tmux, or if tmux cannot tell us where we are, degrade to a plain
# exec. Better to run the suite with no notification than to not run it.
if [[ -z "${TMUX_PANE:-}" ]] || ! whence tmux >/dev/null; then
    "$@"
    exit $?
fi
window=$(tmux display-message -p -t "$TMUX_PANE" '#{window_id}' 2>/dev/null) || window=""
if [[ -z "$window" ]]; then
    "$@"
    exit $?
fi

rundir="${XDG_RUNTIME_DIR:-/tmp}/ntc/${window#@}"
mkdir -p "$rundir" 2>/dev/null

# Base name: written by the parent. Fall back to the live window name with any
# status glyph we may have added previously stripped back off, so a manual
# rename-window is respected instead of being clobbered back to "Test Suite".
if [[ -r "$rundir/name" ]]; then
    base=$(<"$rundir/name")
else
    base=$(tmux display-message -p -t "$window" '#{window_name}' 2>/dev/null)
    base="${base#[$GLYPH_PENDING$GLYPH_PASS$GLYPH_FAIL] }"
    [[ -n "$base" ]] || base="Test Suite"
fi

rename_window() {
    tmux rename-window -t "$window" "$1 $base" 2>/dev/null || true
}

# --- round reset ----------------------------------------------------------
# Clearing .reported is what lets a re-run notify again. Clearing only our own
# .exit is the "latest known result" semantic described above.
rm -f  "$rundir/$slot.exit"  2>/dev/null
rmdir  "$rundir/.reported"   2>/dev/null
rename_window "$GLYPH_PENDING"

# --- run the real thing ---------------------------------------------------
# NOT `status=$?`. In zsh `status` is a read-only special variable, an alias
# for `?`, so assigning to it aborts the script with
#     ntc-slot.sh: read-only variable: status
# right after the suite finishes -- no .exit file, no notification, and the
# error buried under whatever the test runner just printed. `zsh -n` does not
# catch it; only running it does.
"$@"
rc=$?

print -r -- "$rc" > "$rundir/$slot.exit"

# --- is the set complete, and am I the one to say so? ---------------------
[[ -r "$rundir/slots" ]] || exit $rc
typeset -a slots
slots=( ${(f)"$(<"$rundir/slots")"} )
(( ${#slots} )) || exit $rc

for s in $slots; do
    [[ -f "$rundir/$s.exit" ]] || exit $rc
done

# Atomic. Exactly one pane gets past this line per round.
mkdir "$rundir/.reported" 2>/dev/null || exit $rc

# --- report ---------------------------------------------------------------
typeset -a failed parts
failed=()
parts=()
for s in $slots; do
    code=$(<"$rundir/$s.exit")
    if [[ "$code" == "0" ]]; then
        parts+=("$s ✓")
    else
        parts+=("$s ✗")
        failed+=("$s")
    fi
done
# Joined rather than accumulated-with-trailing-separator: trimming the tail
# would need ${x%%[[:space:]]##}, and `##` is EXTENDED_GLOB, which is off by
# default in scripts. It would have silently left the trailing spaces in.
detail="${(j:   :)parts}"

ding="${0:A:h}/ding.sh"

if (( ${#failed} == 0 )); then
    rename_window "$GLYPH_PASS"
    [[ -x "$ding" ]] && "$ding" pass
    # Normal urgency, no -t: Omarchy's quickshell notification service
    # (plugins/notifications/Service.qml) clamps a normal popup to a minimum
    # of 8s and a maximum of 30s, so the default is already 8 seconds.
    # --urgency=critical is deliberately NOT used anywhere here: durationFor()
    # returns 0 for Critical, which means the popup never expires and has to
    # be dismissed by hand.
    notify-send -a ntc -u normal "Test suite passed" "$detail" 2>/dev/null || true
else
    rename_window "$GLYPH_FAIL"
    [[ -x "$ding" ]] && "$ding" fail
    # 20s rather than the 8s default, so a red result is still on screen if
    # you look up a few seconds late. Still auto-dismisses; still under the
    # 30s ceiling, above which quickshell would clamp it back down anyway.
    notify-send -a ntc -u normal -t 20000 "Test suite failed" "$detail" 2>/dev/null || true
fi

exit $rc
