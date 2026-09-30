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

# Pane commands, clockwise from the top left.
CMD_TOP_LEFT="npm run test:server"
CMD_TOP_RIGHT="npm run test:client"
CMD_BOTTOM_RIGHT="npm run lint"
CMD_BOTTOM_LEFT="npm run test:shared"

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
p1=$(tmux new-window   -P -F '#{pane_id}' -n "$WINDOW_NAME" -c "$PWD") || exit 1
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

tmux select-pane -t "$tl" -T server
tmux select-pane -t "$tr" -T client
tmux select-pane -t "$bl" -T shared
tmux select-pane -t "$br" -T lint

# Commands go out AFTER select-layout, unlike the nushell version. Panes reach
# their final width first, so test output and progress bars wrap correctly
# instead of being laid out for the pre-tiled geometry.
tmux send-keys -t "$tl" "$CMD_TOP_LEFT"     C-m
tmux send-keys -t "$tr" "$CMD_TOP_RIGHT"    C-m
tmux send-keys -t "$bl" "$CMD_BOTTOM_LEFT"  C-m
tmux send-keys -t "$br" "$CMD_BOTTOM_RIGHT" C-m

# Synchronize so one up-arrow + Enter re-runs all four suites at once, each
# pane replaying its own last command. This also means ANY typing in this
# window hits every pane -- M-s toggles it (see tmux_omarchy.conf).
tmux set-window-option -t "$p1" synchronize-panes on >/dev/null

print "Started 4 test panes in '$WINDOW_NAME' (synchronize-panes ON, M-s toggles)"
