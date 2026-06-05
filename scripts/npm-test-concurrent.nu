#!/usr/bin/env nu

# npm-test-concurrent.nu
# Runs 4 test commands in a 2x2 tmux pane grid with staggered creation
# to avoid NuShell session ID collisions

def main [] {
    let cwd = $env.PWD
    let window_name = "Test Suite"

    # Create new window with first command
    tmux new-window -n $window_name -c $cwd
    tmux send-keys "npm run test:server" Enter

    sleep 100ms
    tmux split-window -h -c $cwd
    tmux send-keys "npm run test:client" Enter

    sleep 100ms
    tmux split-window -v -c $cwd
    tmux send-keys "npm run lint" Enter

    sleep 100ms
    tmux select-pane -t '{top-left}'
    tmux split-window -v -c $cwd
    tmux send-keys "npm run test:shared" Enter

    # Apply tiled layout for even 2x2 grid
    tmux select-layout tiled

    # Enable synchronized panes (after commands are sent)
    tmux set-window-option synchronize-panes on
}
