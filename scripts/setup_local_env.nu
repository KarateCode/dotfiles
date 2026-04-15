# Bounce the local dev environment to a new env selection
def bounceenv [] {
    let env_name = (ls ~/code/tools-and-infrastructure/scripts/developer/environments
        | get name
        | each { path basename | str replace '.sh' '' }
        | to text
        | fzf
        | str trim)

    if ($env_name | is-empty) {
        print "No environment selected"
        return
    }

    print $"Switching to: ($env_name)"

    # Restart gulp in pane 3
    tmux send-keys -t dev-environment:main.3 C-c
    tmux send-keys -t dev-environment:main.3 $"select_env ($env_name)" C-m
    sleep 1sec
    tmux send-keys -t dev-environment:main.3 'npm run gulp -- --live-reload' C-m

    # Update env in pane 2
    tmux send-keys -t dev-environment:main.2 $"select_env ($env_name)" C-m

    # Restart dev server in pane 1
    tmux send-keys -t dev-environment:main.1 C-c
    tmux send-keys -t dev-environment:main.1 $"select_env ($env_name)" C-m
    sleep 1sec
    tmux send-keys -t dev-environment:main.1 './bin/run-dev-server' C-m
}
