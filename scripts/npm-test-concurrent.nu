#!/usr/bin/env nu

# npm-test-concurrent.nu
# Runs 4 test commands in a 2x2 pane grid
# Supports both tmux and herdr environments

# Environment detection helpers
def is-in-herdr [] {
    ($env.HERDR_ENV? | is-not-empty)
}

def is-in-tmux [] {
    ($env.TMUX? | is-not-empty)
}

# tmux implementation with staggered creation to avoid NuShell session ID collisions
def ntc-tmux [] {
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

# herdr implementation
def ntc-herdr [] {
    let cwd = $env.PWD
    let tab_name = "Test Suite"

    # Create new tab and get the initial pane_id
    let pane1 = (herdr tab create --label $tab_name --cwd $cwd --focus | jq -r '.result.root_pane.pane_id')

    # Run first command in top-left pane
    sleep 100ms
    herdr pane run $pane1 "npm run test:server"

    # Split right for top-right pane
    sleep 100ms
    let pane2 = (herdr pane split $pane1 --direction right --cwd $cwd | jq -r '.result.pane.pane_id')
    herdr pane run $pane2 "npm run test:client"

    # Split pane2 down for bottom-right pane
    sleep 100ms
    let pane3 = (herdr pane split $pane2 --direction down --cwd $cwd | jq -r '.result.pane.pane_id')
    herdr pane run $pane3 "npm run lint"

    # Split pane1 down for bottom-left pane
    sleep 100ms
    let pane4 = (herdr pane split $pane1 --direction down --cwd $cwd | jq -r '.result.pane.pane_id')
    herdr pane run $pane4 "npm run test:shared"
}

# Main entry point - detects environment and runs appropriate implementation
def ntc [] {
    if (is-in-herdr) {
        ntc-herdr
    } else if (is-in-tmux) {
        ntc-tmux
    } else {
        error make {msg: "ntc requires either tmux or herdr environment"}
    }
}

# For running as a standalone script
def main [] {
    ntc
}
