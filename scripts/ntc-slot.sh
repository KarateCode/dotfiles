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

# ---------------------------------------------------------------------------
# RESOURCE CONFINEMENT
# ---------------------------------------------------------------------------
# Measured on this machine (15.5G RAM, 15.5G zram at priority 100 plus a 15.5G
# disk swapfile at priority 0): a full run drove available memory from 5.5G
# down to 575M and pushed swap from 6.5G to 14.5G -- 91% of zram. The disk
# swapfile then started taking pages. Once swap lands on the NVMe instead of
# compressed RAM the whole desktop stalls, because the compositor and the
# browser have to fault their own pages back in.
#
# Chromium alone had 2.4G reclaimed out from under it during that run, which
# is why the desktop stays unusable for a while even after the suites finish.
#
# So the four suites run inside ONE shared slice with an aggregate budget,
# not four independent caps -- what hurts the desktop is the total, and four
# separate limits would just multiply by four.
#
# Why these four properties:
#   MemoryHigh     soft brake. Above it the kernel throttles THIS cgroup and
#                  reclaims from it. Nothing is killed; the suites just slow
#                  down instead of the desktop doing so.
#   MemoryMax      hard stop, deliberately well above the 7.3G measured peak
#                  so a normal run never trips it. This is the runaway catch
#                  (the old puppeteer leak), not the everyday limit.
#   MemorySwapMax  the load-bearing one. MemoryMax caps RAM only -- a cgroup
#                  with memory.swap.max unlimited happily spills gigabytes
#                  into swap and thrashes the machine anyway. Verified: a
#                  runaway under MemoryMax alone wedged this box for minutes,
#                  and the same runaway under MemoryMax+MemorySwapMax died in
#                  12 seconds with no visible impact.
#   CPUWeight      relative share, only consulted under contention. Costs
#                  nothing when the machine is otherwise idle, and yields to
#                  the compositor when it is not.
#
# Tune without editing this file:
#   NTC_MEM_HIGH=4G NTC_MEM_MAX=8G NTC_SWAP_MAX=1G NTC_CPU_WEIGHT=10 ntc
# Opt out entirely:
#   NTC_LIMITS=0 ntc
NTC_SLICE="${NTC_SLICE:-ntc.slice}"
NTC_MEM_HIGH="${NTC_MEM_HIGH:-6G}"
NTC_MEM_MAX="${NTC_MEM_MAX:-10G}"
NTC_SWAP_MAX="${NTC_SWAP_MAX:-2G}"
NTC_CPU_WEIGHT="${NTC_CPU_WEIGHT:-20}"

# Run the real command, confined when we can be and unconfined when we cannot.
#
# The limits are (re)applied here rather than in npm-test-concurrent.sh
# because the normal way to re-run is up-arrow + Enter inside an existing
# pane, which calls this script directly and never touches the launcher. If
# the budget lived only in the launcher, every re-run after the first would
# be uncapped -- the exact situation this is meant to prevent.
#
# --runtime keeps the drop-in in /run, so it evaporates on logout rather than
# accumulating in ~/.config/systemd. set-property is idempotent, so the four
# panes all racing to set the same values is harmless.
ntc_run() {
    if [[ "${NTC_LIMITS:-1}" == "0" ]] || ! whence systemd-run >/dev/null; then
        "$@"
        return $?
    fi

    if ntc_apply_limits; then
        # --scope (not --unit): runs synchronously in this pane, keeps the tty
        # so progress bars and colour still work, and propagates the real exit
        # status. Both verified.
        systemd-run --user --slice="$NTC_SLICE" --scope --quiet -- "$@"
        return $?
    fi

    # ----------------------------------------------------------------------
    # Applying the limits failed. There are two very different reasons for
    # that and they must NOT be handled the same way.
    #
    # This distinction is not hypothetical. An earlier version of this
    # function fell straight through to an unconfined run whenever
    # set-property failed. A single bad value (`MemoryHigh=max`, which systemd
    # rejects -- the keyword is `infinity`) was therefore enough to silently
    # disable the limits, and the very next command, a runaway allocator, took
    # the machine down hard enough for the kernel OOM killer to close the
    # terminal. A safety net whose failure mode is removing the safety is
    # worse than no safety net, because it is trusted.
    #
    # So: probe whether confinement works AT ALL with a value systemd cannot
    # object to. If it does, the environment is fine and the supplied numbers
    # are the problem -- refuse to run, because running the suite unconfined
    # is exactly the outcome this wrapper exists to prevent. Only when even
    # the probe fails (no cgroup delegation, non-systemd box) is falling back
    # to an unconfined run the right call.
    # ----------------------------------------------------------------------
    if systemctl --user set-property --runtime "$NTC_SLICE" CPUWeight=100 >/dev/null 2>&1; then
        systemctl --user revert "$NTC_SLICE" >/dev/null 2>&1
        print -u2 "ntc-slot: refusing to run unconfined -- one or more resource limits were rejected."
        # Pinpoint the offender rather than making the reader bisect four
        # values by hand. Only on the error path, so the extra calls cost
        # nothing in the normal case.
        local kv probe="ntc-validate.slice"
        for kv in "MemoryHigh=$NTC_MEM_HIGH" "MemoryMax=$NTC_MEM_MAX" \
                  "MemorySwapMax=$NTC_SWAP_MAX" "CPUWeight=$NTC_CPU_WEIGHT"; do
            systemctl --user set-property --runtime "$probe" "$kv" >/dev/null 2>&1 \
                || print -u2 "    rejected: $kv"
        done
        systemctl --user revert "$probe" >/dev/null 2>&1
        print -u2 "  sizes are systemd syntax: 6G, 512M, infinity  (there is no 'max')"
        print -u2 "  fix the value, or opt out deliberately with NTC_LIMITS=0"
        return 78   # EX_CONFIG
    fi

    print -u2 "ntc-slot: cgroup limits unavailable here (no delegation?); running unconfined"
    "$@"
}

# Returns non-zero if systemd rejects any of the requested values.
ntc_apply_limits() {
    systemctl --user set-property --runtime "$NTC_SLICE" \
        MemoryHigh="$NTC_MEM_HIGH" \
        MemoryMax="$NTC_MEM_MAX" \
        MemorySwapMax="$NTC_SWAP_MAX" \
        CPUWeight="$NTC_CPU_WEIGHT" >/dev/null 2>&1
}

# Outside tmux, or if tmux cannot tell us where we are, degrade to a plain
# run. Better to run the suite with no notification than to not run it.
# Still confined: the memory budget matters more than the ding does.
if [[ -z "${TMUX_PANE:-}" ]] || ! whence tmux >/dev/null; then
    ntc_run "$@"
    exit $?
fi
window=$(tmux display-message -p -t "$TMUX_PANE" '#{window_id}' 2>/dev/null) || window=""
if [[ -z "$window" ]]; then
    ntc_run "$@"
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
ntc_run "$@"
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
