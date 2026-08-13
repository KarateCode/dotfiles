alias van = ~/bin/my-emacs.sh
alias e = cd ~/code/envoy-web
alias ds = node /Users/michaelschneider/code/tools-and-infrastructure/webdev-tools/menu.js
alias la = ls -la

# Environment detection helpers
def is-in-herdr [] {
    ($env.HERDR_ENV? | is-not-empty)
}

def is-in-tmux [] {
    ($env.TMUX? | is-not-empty)
}

alias cod = git checkout develop
alias pd = git pull origin develop
# def select_env [] {
#     local arg="$1"
#     eval "$("$HOME/code/tools-and-infrastructure/scripts/developer/select_env_menu.sh" "$arg")"
# }

def ns [] {
    cd ~/code/envoy-web/server
    ./bin/run-dev-server
}
alias sl = pmset sleepnow
alias hss = bash ~/dotfiles/scripts/ssh_fzf.sh
alias preview = fzf --preview 'bat --style=numbers --color=always {}'
alias ptq = npm run task process-tasks-queue
alias ccont = git cherry-pick --continue
def rcont [] { git rebase --continue; git status }
alias b = cd -

alias o = ~/dotfiles/scripts/next_rebase_file.sh
alias gd = ~/dotfiles/scripts/next_git_diff_file.sh
alias fa = ~/dotfiles/scripts/next_git_add_file.sh
alias fr = ~/dotfiles/scripts/next_git_checkout_file.sh
alias fo = ~/dotfiles/scripts/next_git_ours_file.sh
alias ft = ~/dotfiles/scripts/next_git_theirs_file.sh
alias cf = ~/dotfiles/scripts/next_vs_code_file.sh
alias ef = ~/dotfiles/scripts/next_emacs_file.sh
alias lastc = git log -p -1
alias lastcfiles = git diff-tree --no-commit-id --name-only -r HEAD
alias reseed = npm run db:seed -- --email michael.schneider@envoyplatform.com

# ntc is sourced from ~/dotfiles/scripts/npm-test-concurrent.nu
alias jdev = mb-jira-cli --toggleview="column" --filter="Dev Review"
alias jme = mb-jira-cli --toggleview="table" --filter="Me"

alias nr = npm run
alias nt = npm run test:concurrent
alias nrt = npm run test-one
alias nrs = npm run test:server
alias nru = npm run test:utilities
alias nrc = npm run test:client

alias gits = git status
alias co = git checkout
alias cob = git checkout -b
alias gitc = git commit -m
alias gitb = git branch
alias gitd = git diff
def gita [] {
      git add -A .
      git status
}
alias gitl = git log
def gpull [] {
    git pull origin (git symbolic-ref --short HEAD) --rebase
}
def gpush [--force (-f)] {
    if $force {
        git push origin (git symbolic-ref --short HEAD) --force
    } else {
        git push origin (git symbolic-ref --short HEAD)
    }
}
alias cof = bash ~/dotfiles/scripts/checkout_feature.sh
def stash [] {
    git add -A .
    git stash
    git status
}
def pop [] {
    git stash pop
    git reset HEAD .
    git status
}
alias gl = bash ~/dotfiles/scripts/grep-git-log.sh

alias job = env AWS_PROFILE=appropos APPROPOS_ENV=local ./server/bin/run-node server/bin/task-runner.js background-job-runner --integrationARN="arn:aws:sns:us-east-1:506597054164:appropos-integration-local-error" --ignoreJobInterval=true

def rmautodump [] {
    try { rm -rf auto_dump_* }
    try { rm auto_dump_*.tar.gz }
    git status
}
# alias fcode='fzf | cut -d ":" -f 1 | xargs code'

alias onering = /Users/michaelschneider/code/tools-and-infrastructure/scripts/developer/one-ring/onering.sh

def --env select_env [filename?: string] {
    print $filename
    # let output = (^$env.HOME/code/tools-and-infrastructure/scripts/developer/select_env_menu.sh $arg)
    # $output | nu-highlight | print
    # $output | nu
    let env_dir = "~/code/tools-and-infrastructure/scripts/developer/environments" | path expand
    let filename = if ($filename | str ends-with ".sh") { $filename } else { $"($filename).sh" }
    load-sh-exports ($env_dir | path join $filename)
}

# Select environment - sources .sh export files via fzf
def --env se [] {
    let env_dir = "~/code/tools-and-infrastructure/scripts/developer/environments" | path expand
    let filename = (ls $env_dir | get name | each { path basename } | to text | fzf | str trim)
    load-sh-exports ($env_dir | path join $filename)
}

# Switch the ~/code/envoy-web symlink to point to a different envoy-web folder
def --env symEnvoyWeb [] {
    let code_dir = "~/code" | path expand
    let symlink_path = $code_dir | path join "envoy-web"

    # Find all envoy-web folders with numeric suffix (e.g., envoy-web1, envoy-web2)
    let envoy_folders = (ls $code_dir
        | where type == "dir"
        | get name
        | each { path basename }
        | where { $in =~ '^envoy-web\d+$' }
        | sort)

    if ($envoy_folders | is-empty) {
        print $"(ansi red)No envoy-web folders found(ansi reset) (looking for envoy-web1, envoy-web2, etc.)"
        return
    }

    # Present fzf menu
    let selected = ($envoy_folders | to text | fzf | str trim)

    if ($selected | is-empty) {
        print $"(ansi yellow)No folder selected(ansi reset)"
        return
    }

    let target_path = $code_dir | path join $selected

    # Remove old symlink if it exists (but not if it's a real directory)
    if ($symlink_path | path exists) {
        let link_type = (ls -l $code_dir | where name == $symlink_path | get type | first)
        if ($link_type == "symlink") {
            rm $symlink_path
            print $"(ansi yellow)Removed old symlink:(ansi reset) ($symlink_path)"
        } else {
            print $"(ansi red_bold)Error:(ansi reset) ($symlink_path) exists but is not a symlink. Aborting."
            return
        }
    } else {
        print $"(ansi cyan)No existing symlink at ($symlink_path), creating new one...(ansi reset)"
    }

    # Create new symlink
    ln -s $target_path $symlink_path
    print $"(ansi green_bold)Created symlink:(ansi reset) ($symlink_path) -> (ansi cyan_bold)($target_path)(ansi reset)"

    # cd into the new symlink location
    cd $symlink_path
}

# Start backend with fzf environment selection - tmux implementation
def startBackEnd-tmux [env_name: string] {
    tmux rename-session dev-environment
    print $"Starting backend with environment: ($env_name)"
    tmuxinator backend --append $env_name
}

# Start backend with fzf environment selection - herdr implementation
def startBackEnd-herdr [env_name: string] {
    let cwd = "~/code/envoy-web" | path expand

    print $"Starting backend with environment: ($env_name)"

    # Create new tab labeled "BE" and get the initial pane_id (server pane)
    let server_pane = (herdr tab create --label "BE" --cwd $cwd --focus | jq -r '.result.root_pane.pane_id')
    print "server pane:"
    print $server_pane
    sleep 100ms
    herdr pane rename $server_pane "server"

    # Split right 50/50 for frontend pane
    let frontend_pane = (herdr pane split $server_pane --direction right --cwd $cwd | jq -r '.result.pane.pane_id')
    print "frontend_pane:"
    print $frontend_pane
    sleep 100ms
    herdr pane rename $frontend_pane "frontend"

    # Split frontend pane down 50/50 for shell pane
    let shell_pane = (herdr pane split $frontend_pane --direction down --cwd $cwd | jq -r '.result.pane.pane_id')
    print "shell pane:"
    print $shell_pane
    sleep 100ms
    herdr pane rename $shell_pane "shell"

    # Run startup commands in each pane
    herdr pane run $server_pane $"select_env ($env_name); ./server/bin/run-dev-server"
    herdr pane run $frontend_pane $"select_env ($env_name); npm run gulp -- --live-reload"
    herdr pane run $shell_pane $"select_env ($env_name)"

    herdr pane focus --direction right
    herdr pane focus --direction down
}

# Start backend with fzf environment selection - detects environment
def startBackEnd [] {
    let env_dir = "~/code/tools-and-infrastructure/scripts/developer/environments" | path expand
    let env_name = (ls $env_dir
        | get name
        | each { path basename | str replace '.sh' '' }
        | to text
        | fzf
        | str trim)

    if ($env_name | is-empty) {
        print "No environment selected"
        return
    }

    if (is-in-herdr) {
        startBackEnd-herdr $env_name
    } else if (is-in-tmux) {
        startBackEnd-tmux $env_name
    } else {
        error make {msg: "startBackEnd requires either tmux or herdr environment"}
    }
}

# Bounce the backend environment - tmux implementation
def bounceEnv-tmux [selected_env: string] {
    print $"Switching to: ($selected_env)"

    # Restart dev server in pane 1 (with symlink-aware cd)
    tmux send-keys -t dev-environment:BE.1 C-c
    tmux send-keys -t dev-environment:BE.1 "cd ~/code/envoy-web" C-m
    tmux send-keys -t dev-environment:BE.1 $"select_env ($selected_env)" C-m
    sleep 1sec
    tmux send-keys -t dev-environment:BE.1 './server/bin/run-dev-server' C-m

    # Restart gulp in pane 2 (with symlink-aware cd)
    tmux send-keys -t dev-environment:BE.2 C-c
    tmux send-keys -t dev-environment:BE.2 "cd ~/code/envoy-web" C-m
    tmux send-keys -t dev-environment:BE.2 $"select_env ($selected_env)" C-m
    sleep 1sec
    tmux send-keys -t dev-environment:BE.2 'npm run gulp -- --live-reload' C-m

    # Update env in pane 3 (with symlink-aware cd)
    tmux send-keys -t dev-environment:BE.3 "cd ~/code/envoy-web" C-m
    tmux send-keys -t dev-environment:BE.3 $"select_env ($selected_env)" C-m
}

# Bounce the backend environment - herdr implementation
def bounceEnv-herdr [selected_env: string] {
    print $"Switching to: ($selected_env)"

    # Find the BE tab in the current workspace
    let current_workspace = $env.HERDR_WORKSPACE_ID
    let be_tab = (herdr tab list | jq -r --arg ws $current_workspace '.result.tabs[] | select(.workspace_id == $ws and .label == "BE") | .tab_id')

    if ($be_tab | is-empty) {
        print "Error: Could not find 'BE' tab in current workspace."
        print "Run 'startBackEnd' first to create the backend panes."
        return
    }

    # Get all panes in the BE tab
    let panes = (herdr pane list | jq -r --arg tab $be_tab '[.result.panes[] | select(.tab_id == $tab)]')

    # Find panes by label
    let server_pane = ($panes | jq -r '.[] | select(.label == "server") | .pane_id')
    let frontend_pane = ($panes | jq -r '.[] | select(.label == "frontend") | .pane_id')
    let shell_pane = ($panes | jq -r '.[] | select(.label == "shell") | .pane_id')

    if ($server_pane | is-empty) or ($frontend_pane | is-empty) or ($shell_pane | is-empty) {
        print "Error: Could not find labeled panes (server, frontend, shell) in BE tab."
        print "Run 'startBackEnd' first to create properly labeled backend panes."
        return
    }

    # Restart server pane (Ctrl+C, cd, select_env, run server)
    herdr pane send-keys $server_pane ctrl+c
    sleep 100ms
    herdr pane run $server_pane $"cd ~/code/envoy-web; select_env ($selected_env); ./server/bin/run-dev-server"

    # Restart frontend pane (Ctrl+C, cd, select_env, run gulp)
    herdr pane send-keys $frontend_pane ctrl+c
    sleep 100ms
    herdr pane run $frontend_pane $"cd ~/code/envoy-web; select_env ($selected_env); npm run gulp -- --live-reload"

    # Update shell pane (cd, select_env)
    herdr pane run $shell_pane $"cd ~/code/envoy-web; select_env ($selected_env)"
}

# Bounce the backend environment to a new env selection - detects environment
def bounceEnv [env_name?: string] {
    let env_dir = "~/code/tools-and-infrastructure/scripts/developer/environments" | path expand
    let available_envs = (ls $env_dir
        | get name
        | each { path basename | str replace '.sh' '' })

    let selected_env = if ($env_name | is-empty) {
        # No argument provided, show fzf menu
        $available_envs | to text | fzf | str trim
    } else {
        # Argument provided, validate it exists
        if ($env_name not-in $available_envs) {
            print $"Error: '($env_name)' is not a valid environment"
            print "Available environments:"
            $available_envs | each { print $"  ($in)" }
            return
        }
        $env_name
    }

    if ($selected_env | is-empty) {
        print "No environment selected"
        return
    }

    if (is-in-herdr) {
        bounceEnv-herdr $selected_env
    } else if (is-in-tmux) {
        bounceEnv-tmux $selected_env
    } else {
        error make {msg: "bounceEnv requires either tmux or herdr environment"}
    }
}

# Dump remote DB to local, bounce environment, and check indexes
def dumpToLocalBounceEnv [] {
    let env_dir = "~/code/tools-and-infrastructure/scripts/developer/environments" | path expand
    let env_name = (ls $env_dir
        | get name
        | each { path basename | str replace '.sh' '' }
        | to text
        | fzf
        | str trim)

    if ($env_name | is-empty) {
        print "No environment selected"
        return
    }

    print $"Dumping to local: ($env_name)"
    ds dump-to-local $env_name

    bounceEnv $env_name

    sleep 1sec
    print "Checking DB indexes..."
    npm run task check-db-indexes
}

def --env clientPatchJobRunner [] {
    if ($env.NAMING_PREFIX? | is-empty) {
        error make {msg: "$env.NAMING_PREFIX not set"}
    }

    print ""
    print $"(ansi yellow)Patching client record for local runs of background-job-runner...(ansi reset)"
    mongosh $env.NAMING_PREFIX --quiet --eval "db.Client.updateMany({}, {$set: {'config.integrationMoveFiles': false}})"
    mongosh $env.NAMING_PREFIX --quiet --eval "db.Client.updateMany({}, {$set: {'config.integrationSrcPath': '/Users/michaelschneider/code/envoy-web'}})"
    print $"(ansi green_bold)Done!(ansi reset)"
    print ""
}
