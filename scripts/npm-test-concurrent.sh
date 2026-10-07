#!/bin/zsh
#
# npm-test-concurrent.sh -- run the four test suites side by side in a 2x2 tmux
# grid. The shell port of scripts/npm-test-concurrent.nu.
#
# Replaces `tmuxinator npm-test-concurrent --append`, which the `ntc` alias
# used to call. That was dead twice over: tmuxinator is a Ruby gem and is not
# installed, and tmuxinator/npm-test-concurrent.yml was never created either.
#
# NO SLEEPS -- and that is deliberate. The nushell version staggers pane
# creation with `sleep 100ms`, commented "to avoid NuShell session ID
# collisions". That is a real bug, but it is specific to nushell's history
# config in nushell/config.nu:
#       $env.config.history.file_format = "sqlite"
#       $env.config.history.isolation   = true
# isolation makes each session filter history by a session id, so panes born
# in the same instant share an id and up-arrow yanks a sibling pane's command.
# zsh has no session id -- history is a flat file, each shell keeps its own
# in-memory list, and INC_APPEND_HISTORY without SHARE_HISTORY means a running
# pane never absorbs commands from panes started later.
#
# Both halves of that were measured before the sleeps were dropped, 5 runs each
# with zero stagger:
#   - all 4 panes recalled their OWN command on up-arrow, with
#     synchronize-panes on              -> 5/5
#   - all 4 commands actually executed when send-keys fired immediately after
#     pane creation, mid `exec zsh`     -> 5/5
# The second case is safe because keystrokes sit in the pty input buffer and
# survive bash handing off to zsh.

set -u

WINDOW_NAME="Test Suite"

# Status glyph shown in the tmux window name while the suites run. The pass and
# fail glyphs live in ntc-slot.sh, which owns every transition after launch.
# nf-md-timer_sand. Verified present in the Nerd Font actually in use.
GLYPH_PENDING=$'\Uf051b'

# Pane commands, clockwise from the top left. SLOT_* names are the keys
# ntc-slot.sh records results under, and double as the pane titles, so the
# notification body reads in the same order as the grid.
CMD_TOP_LEFT="npm run test:server"
CMD_TOP_RIGHT="npm run test:client"
CMD_BOTTOM_RIGHT="${NTC_LINT_CMD:-${${0:A:h}/#$HOME/~}/ntc-lint.sh}"
CMD_BOTTOM_LEFT="npm run test:shared"

SLOT_TOP_LEFT=server
SLOT_TOP_RIGHT=client
SLOT_BOTTOM_RIGHT=lint
SLOT_BOTTOM_LEFT=shared

if [ -z "${TMUX:-}" ]; then
    print -u2 "ntc: must be run from inside tmux"
    exit 1
fi

# Fail before building four panes that would each just print the same npm
# error. Walking up mirrors what npm itself does, so running from a subdirectory
# of the project is still fine.
dir="$PWD"
while :; do
    [ -f "$dir/package.json" ] && break
    if [ -z "$dir" ]; then
        print -u2 "ntc: no package.json in $PWD or any parent directory"
        exit 1
    fi
    dir="${dir%/*}"
done

# Build the grid. Panes are tracked by id (%12) rather than by leaving the
# newly created one active and sending to it implicitly, which is what the
# nushell version does -- that breaks if anything steals focus mid-build.
#
# The window is born already carrying the pending glyph, so the tab shows
# 󰔛 from the first frame instead of only once a pane gets going.
#
# Naming the window with -n also switches automatic-rename OFF for it (man
# tmux: "automatically disabled for an individual window when a name is
# specified at creation with new-window"). That is what keeps the global
# `automatic-rename on` / `#{b:pane_current_path}` in tmux_omarchy.conf from
# overwriting the status glyph a moment later.
p1=$(tmux new-window   -P -F '#{pane_id}' -n "$GLYPH_PENDING $WINDOW_NAME" -c "$PWD") || exit 1
p2=$(tmux split-window -P -F '#{pane_id}' -h -c "$PWD" -t "$p1")       || exit 1
p3=$(tmux split-window -P -F '#{pane_id}' -v -c "$PWD" -t "$p2")       || exit 1
p4=$(tmux split-window -P -F '#{pane_id}' -v -c "$PWD" -t "$p1")       || exit 1

# A pane id is a valid target for window-level commands too, which sidesteps
# quoting the space in "Test Suite".
tmux select-layout -t "$p1" tiled >/dev/null

# Do NOT assume creation order matches screen position. `select-layout tiled`
# reflows panes in layout-tree order, and the splits above build the tree
#     H[ V[p1,p4], V[p2,p3] ]
# so the panes come out ordered p1 p4 p2 p3 -- putting p4 top-right and p2
# bottom-left, transposed from the obvious reading. (The nushell version
# inherits the same surprise.) Read the grid back by geometry instead, so the
# commands below land where this comment says they do:
#
#   +--------------+--------------+
#   |  test:server |  test:client |
#   +--------------+--------------+
#   |  test:shared |  lint        |
#   +--------------+--------------+
typeset -a grid
grid=( ${(f)"$(tmux list-panes -t "$p1" -F '#{pane_top} #{pane_left} #{pane_id}' \
                | sort -n -k1,1 -k2,2 | awk '{print $3}')"} )
tl=$grid[1]; tr=$grid[2]; bl=$grid[3]; br=$grid[4]

tmux select-pane -t "$tl" -T "$SLOT_TOP_LEFT"
tmux select-pane -t "$tr" -T "$SLOT_TOP_RIGHT"
tmux select-pane -t "$bl" -T "$SLOT_BOTTOM_LEFT"
tmux select-pane -t "$br" -T "$SLOT_BOTTOM_RIGHT"

# --- notification state ---------------------------------------------------
# ntc-slot.sh records each suite's exit code here and the last suite to finish
# reports on the set. See that file for why it is an election and not "ask the
# slowest pane".
#
# Keyed by window id so two concurrent `ntc` runs (different projects, same
# tmux server) cannot read each other's results.
#
# The `slots` manifest is the single definition of "the set is complete";
# ntc-slot.sh records results but stays silent without it, so a half-created
# run directory degrades to no notification rather than a wrong one.
window_id=$(tmux display-message -p -t "$p1" '#{window_id}')
rundir="${XDG_RUNTIME_DIR:-/tmp}/ntc/${window_id#@}"
# Guarded: only ever remove a path we just built from a non-empty window id.
[[ -n "${window_id#@}" ]] && rm -rf "$rundir"
mkdir -p "$rundir"
print -rl -- "$SLOT_TOP_LEFT" "$SLOT_TOP_RIGHT" "$SLOT_BOTTOM_LEFT" "$SLOT_BOTTOM_RIGHT" > "$rundir/slots"
print -r -- "$WINDOW_NAME" > "$rundir/name"

# Absolute path, so a pane whose shell never sourced alias.sh still finds it;
# displayed with ~ so the line recalled by up-arrow stays readable.
slot_script="${0:A:h}/ntc-slot.sh"
slot_disp="${slot_script/#$HOME/~}"

# Commands go out AFTER select-layout, unlike the nushell version. Panes reach
# their final width first, so test output and progress bars wrap correctly
# instead of being laid out for the pre-tiled geometry.
#
# Wrapped in ntc-slot.sh, which passes output and exit status straight through.
# The wrapper is part of the recalled line on purpose: up-arrow + Enter re-runs
# the suite AND re-arms the notification.
tmux send-keys -t "$tl" "$slot_disp $SLOT_TOP_LEFT -- $CMD_TOP_LEFT"         C-m
tmux send-keys -t "$tr" "$slot_disp $SLOT_TOP_RIGHT -- $CMD_TOP_RIGHT"       C-m
tmux send-keys -t "$bl" "$slot_disp $SLOT_BOTTOM_LEFT -- $CMD_BOTTOM_LEFT"   C-m
tmux send-keys -t "$br" "$slot_disp $SLOT_BOTTOM_RIGHT -- $CMD_BOTTOM_RIGHT" C-m

# Synchronize so one up-arrow + Enter re-runs all four suites at once, each
# pane replaying its own last command. This also means ANY typing in this
# window hits every pane -- M-s toggles it (see tmux_omarchy.conf).
tmux set-window-option -t "$p1" synchronize-panes on >/dev/null

print "Started 4 test panes in '$WINDOW_NAME' (synchronize-panes ON, M-s toggles)"
print "Tab shows $GLYPH_PENDING while running; ding + notification when all four finish. Mute with NTC_DING=0"

# Report the resource budget the panes will actually run under. ntc-slot.sh
# owns applying it (so up-arrow re-runs are capped too, see the long comment
# there); this is purely so the numbers in force are visible at a glance
# rather than having to be remembered or read out of a script.
if [[ "${NTC_LIMITS:-1}" == "0" ]]; then
    print "Resource limits: OFF (NTC_LIMITS=0)"
else
    print "Shared budget for all 4 panes: mem ${NTC_MEM_HIGH:-6G} soft / ${NTC_MEM_MAX:-10G} hard, swap ${NTC_SWAP_MAX:-2G}, cpu.weight ${NTC_CPU_WEIGHT:-20}"
    print "  override: NTC_MEM_HIGH/NTC_MEM_MAX/NTC_SWAP_MAX/NTC_CPU_WEIGHT   disable: NTC_LIMITS=0"
fi

# --- stale puppeteer browser warning --------------------------------------
# Puppeteer specs that fail to close their browser leave the whole Chrome
# process tree behind, reparented to systemd, alive indefinitely. Measured
# here: 6 runs' worth accumulated to 77 processes / 715 MB PSS, the oldest 17
# hours old. They are invisible in `ps` unless you know the fingerprint, and
# they quietly eat the headroom the next run needs.
#
# Warn only -- no automatic sweep. The underlying leak is fixed on a branch,
# so this should stop happening once that merges, and a sweep would risk
# killing a browser belonging to a run in progress in another window.
#
# `[p]uppeteer` rather than `puppeteer`: pgrep -f matches against full command
# lines, and the pattern would otherwise match the pgrep (or any shell command
# containing it) as well. The bracket makes the regex match "puppeteer" while
# the literal text on the command line reads "[p]uppeteer", which does not.
#
# PSS, not RSS: these are ~14 processes per leaked browser sharing most of
# their pages, so summing RSS overstates the real cost by roughly 2.5x. One
# awk over every smaps_rollup at once, rather than per-pid, so this stays
# imperceptible at launch.
typeset -a stale_pup
stale_pup=( ${(f)"$(pgrep -f '[p]uppeteer_dev_chrome_profile' 2>/dev/null)"} )
if (( ${#stale_pup} )); then
    typeset -a rollups
    for _p in $stale_pup; do
        [[ -r /proc/$_p/smaps_rollup ]] && rollups+=(/proc/$_p/smaps_rollup)
    done
    stale_mb=0
    (( ${#rollups} )) && stale_mb=$(awk '/^Pss:/{s+=$2} END{printf "%d", s/1024}' $rollups 2>/dev/null)
    msg="${#stale_pup} stale puppeteer Chrome processes (~${stale_mb} MB) from earlier runs"
    print "⚠ $msg"
    print "  kill \$(pgrep -f '[p]uppeteer_dev_chrome_profile')"
    # The launcher's stdout is in the pane you came FROM -- new-window has
    # already moved you to the grid -- so the terminal copy above is easy to
    # miss. Notify as well, but only when there is actually something to act
    # on, so this never becomes noise on a clean machine.
    notify-send -a ntc -u low "ntc: leaked browsers" "$msg" 2>/dev/null || true
fi
