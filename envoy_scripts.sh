# envoy_scripts.sh -- Envoy work functions for bash/zsh.
#
# The shell-side counterpart to nushell/envoy_scripts.nu. This is a separate
# file from alias.sh on purpose: alias.sh is 122 lines of pure one-line
# aliases, and these are multi-line functions with error handling.
#
# Sourced from zsh/zshrc_omarchy. Everything here is written to run under
# BOTH bash and zsh, so bash/bashrc_omarchy can source it too if you ever want
# to retire its private copy of select_env (see the note on select_env below).
#
# Directory listings go through `find` rather than a `*/` glob. That is not
# style: zsh's default `nomatch` makes an unmatched glob a fatal error that
# ABORTS THE WHOLE FUNCTION, where bash would just pass the pattern through
# literally. An empty envoy-web__worktrees/ would kill symEnvoyWeb outright.
#     zsh -c 'f(){ for d in /empty/*/; do :; done; echo reached; }; f'
#     -> f: no matches found: /empty/*/     ("reached" never prints)

ENVOY_CODE="${ENVOY_CODE:-$HOME/code}"
ENVOY_WEB="${ENVOY_WEB:-$ENVOY_CODE/envoy-web}"
ENVOY_WEB_BASE="${ENVOY_WEB_BASE:-$ENVOY_CODE/envoy-web-base}"
ENVOY_WORKTREES="${ENVOY_WORKTREES:-$ENVOY_CODE/envoy-web__worktrees}"
ENVOY_TOOLS="${ENVOY_TOOLS:-$ENVOY_CODE/tools-and-infrastructure}"
ENVOY_ENV_DIR="${ENVOY_ENV_DIR:-$ENVOY_TOOLS/scripts/developer/environments}"

# Where the backend lives. startBackEnd creates it, bounceEnv reattaches to it,
# so both read these rather than hardcoding the names in two places.
ENVOY_BE_SESSION="${ENVOY_BE_SESSION:-dev-environment}"
ENVOY_BE_WINDOW="${ENVOY_BE_WINDOW:-BE}"

# --- select_env ----------------------------------------------------------
# This HAS to live somewhere zsh can see it. bash/bashrc_omarchy defines its
# own copy, but that never reaches zsh: ~/.bashrc ends with `exec zsh`, and
# functions are shell state rather than environment, so they are dropped by
# the handoff (the same reason zshrc_omarchy re-sources Omarchy's alias and
# function files). Before this file existed, `select_env` was undefined in
# zsh -- which also silently broke the `se` alias in alias.sh, since it calls
# select_env after the fzf pick.
#
# select_env_menu.sh prints `export ...` lines on stdout; eval is what
# actually applies them to the CURRENT shell, so this must be a function and
# can never be a script.
select_env() {
    eval "$("$ENVOY_TOOLS/scripts/developer/select_env_menu.sh" "$1")"
}

# --- shared helpers ------------------------------------------------------

# Complain about anything missing before we start creating panes. Doing this
# up front avoids the worst failure mode: a window gets built, then the
# commands inside it die and you are left cleaning up half a layout.
_envoy_check() {
    local missing=0 cmd
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            printf 'envoy: required command not found: %s\n' "$cmd" >&2
            missing=1
        fi
    done

    # ~/code/envoy-web is a SYMLINK that symEnvoyWeb repoints at either
    # envoy-web-base or a worktree under envoy-web__worktrees. It is
    # legitimately absent until you have pointed it somewhere.
    if [ ! -d "$ENVOY_WEB" ]; then
        printf 'envoy: %s does not exist.\n' "$ENVOY_WEB" >&2
        printf '  It is a symlink managed by symEnvoyWeb -- run that first.\n' >&2
        missing=1
    fi
    return $missing
}

# Bare environment names, one per line, with the .sh stripped for display.
# Stripping is safe: no env filename is a substring of another (checked across
# all 39), so select_env_menu.sh's partial matching resolves each uniquely and
# never hits its "Multiple matches" error.
_envoy_env_list() {
    find "$ENVOY_ENV_DIR" -mindepth 1 -maxdepth 1 -name '*.sh' -type f 2>/dev/null \
        | sed -e 's|.*/||' -e 's|\.sh$||' \
        | sort
}

_envoy_pick_env() {
    local env_name
    env_name=$(_envoy_env_list | fzf --prompt='env> ' --height=40% --reverse)
    if [ -z "$env_name" ]; then
        printf 'No environment selected\n' >&2
        return 1
    fi
    printf '%s\n' "$env_name"
}

# --- startBackEnd --------------------------------------------------------
# Pick an environment with fzf, then build the backend window:
#
#     +---------------+---------------+
#     |               |   frontend    |
#     |    server     +---------------+
#     |               |    shell      |
#     +---------------+---------------+
#
# The nushell version shells out to `tmuxinator backend --append <env>`, but
# tmuxinator is a Ruby gem and is NOT installed on this box, so that path
# would just fail. The three panes below are built directly with tmux instead,
# reproducing tmuxinator/backend.yml (including its roughly 36/64 vertical
# split) with no Ruby dependency.
#
# Panes are addressed by tmux PANE ID (%12) rather than by index. Index-based
# targets like BE.1 depend on `pane-base-index 1` from tmux_omarchy.conf and
# silently target the wrong pane if that ever changes. Creation order still
# lines up with what bounceEnv expects -- server=.1, frontend=.2, shell=.3 --
# because tmux numbers panes left-to-right, top-to-bottom.
startBackEnd() {
    local env_name server frontend shell

    if [ -z "${TMUX:-}" ]; then
        printf 'startBackEnd must be run from inside tmux\n' >&2
        return 1
    fi
    _envoy_check tmux fzf || return 1
    env_name=$(_envoy_pick_env) || return 1

    printf 'Starting backend with environment: %s\n' "$env_name"
    tmux rename-session "$ENVOY_BE_SESSION" 2>/dev/null

    server=$(tmux new-window -P -F '#{pane_id}' -n "$ENVOY_BE_WINDOW" -c "$ENVOY_WEB") || return 1
    frontend=$(tmux split-window -P -F '#{pane_id}' -h -c "$ENVOY_WEB" -t "$server") || return 1
    shell=$(tmux split-window -P -F '#{pane_id}' -v -l '64%' -c "$ENVOY_WEB" -t "$frontend") || return 1

    tmux select-pane -t "$server"   -T server
    tmux select-pane -t "$frontend" -T frontend
    tmux select-pane -t "$shell"    -T shell

    tmux send-keys -t "$server"   "select_env $env_name; ./server/bin/run-dev-server" C-m
    tmux send-keys -t "$frontend" "select_env $env_name; npm run gulp -- --live-reload" C-m
    tmux send-keys -t "$shell"    "select_env $env_name" C-m

    tmux select-pane -t "$shell"
}

# --- bounceEnv -----------------------------------------------------------
# Repoint an already-running backend at a different environment: interrupt the
# dev server and gulp, re-source the env in all three panes, relaunch.
#
# Resolve one backend pane. Prefers the pane TITLE that startBackEnd sets,
# which survives the panes being reordered or resized, and falls back to the
# positional index for windows built before titles existed (or by tmuxinator).
# Both a pane id (%12) and an index target (dev-environment:BE.1) are valid
# `tmux -t` arguments, so callers do not care which came back.
_envoy_be_pane() {
    local id
    id=$(tmux list-panes -t "$ENVOY_BE_SESSION:$ENVOY_BE_WINDOW" \
            -f "#{==:#{pane_title},$1}" -F '#{pane_id}' 2>/dev/null | head -1)
    if [ -n "$id" ]; then
        printf '%s\n' "$id"
    else
        printf '%s:%s.%s\n' "$ENVOY_BE_SESSION" "$ENVOY_BE_WINDOW" "$2"
    fi
}

bounceEnv() {
    local selected="$1" server frontend shell

    if [ -z "${TMUX:-}" ]; then
        printf 'bounceEnv must be run from inside tmux\n' >&2
        return 1
    fi
    _envoy_check tmux fzf || return 1

    if [ -n "$selected" ]; then
        # Validate an explicitly passed name up front. Without this a typo is
        # sent straight into three panes as `select_env <typo>`, where it fails
        # three times over and leaves the backend half-bounced.
        if ! _envoy_env_list | grep -qxF -- "$selected"; then
            printf "Error: '%s' is not a valid environment\n" "$selected" >&2
            printf 'Available environments:\n' >&2
            _envoy_env_list | sed 's/^/  /' >&2
            return 1
        fi
    else
        selected=$(_envoy_pick_env) || return 1
    fi

    # The nushell tmux path sends keys blind; only its herdr path checks first.
    # Without this you get three opaque "can't find window" errors from tmux.
    if ! tmux list-windows -t "$ENVOY_BE_SESSION" -F '#{window_name}' 2>/dev/null \
         | grep -qx -- "$ENVOY_BE_WINDOW"; then
        printf "Error: no '%s' window in session '%s'.\n" \
            "$ENVOY_BE_WINDOW" "$ENVOY_BE_SESSION" >&2
        printf "  Run 'startBackEnd' first to create the backend panes.\n" >&2
        return 1
    fi

    server=$(_envoy_be_pane server 1)
    frontend=$(_envoy_be_pane frontend 2)
    shell=$(_envoy_be_pane shell 3)

    printf 'Switching to: %s\n' "$selected"

    # Interrupt the two long-running processes and reset all three panes. The
    # cd matters because the panes may be sitting in a checkout that
    # symEnvoyWeb has since repointed the symlink away from.
    tmux send-keys -t "$server"   C-c
    tmux send-keys -t "$frontend" C-c

    tmux send-keys -t "$server"   "cd $ENVOY_WEB" C-m
    tmux send-keys -t "$frontend" "cd $ENVOY_WEB" C-m
    tmux send-keys -t "$shell"    "cd $ENVOY_WEB" C-m

    tmux send-keys -t "$server"   "select_env $selected" C-m
    tmux send-keys -t "$frontend" "select_env $selected" C-m
    tmux send-keys -t "$shell"    "select_env $selected" C-m

    # One shared pause instead of the nushell version's per-pane `sleep 1sec`,
    # which cost 2s for the same effect: give select_env time to finish
    # exporting before the servers read the environment.
    sleep 1

    tmux send-keys -t "$server"   './server/bin/run-dev-server' C-m
    tmux send-keys -t "$frontend" 'npm run gulp -- --live-reload' C-m
}

# --- symEnvoyWeb ---------------------------------------------------------
# Repoint the ~/code/envoy-web symlink at either the main checkout
# (envoy-web-base) or one of the worktrees under envoy-web__worktrees/, then
# cd there. Everything else -- the `e` alias, startBackEnd, bounceEnv -- goes
# through that symlink, so this is what decides which checkout they all act on.
symEnvoyWeb() {
    local selected target
    local yellow="" red="" green="" cyan="" reset=""
    if [ -t 1 ]; then
        yellow=$'\033[33m'; red=$'\033[31m'; green=$'\033[32m'
        cyan=$'\033[36m';   reset=$'\033[0m'
    fi

    if ! command -v fzf >/dev/null 2>&1; then
        printf '%ssymEnvoyWeb: fzf not found%s\n' "$red" "$reset" >&2
        return 1
    fi
    if [ ! -d "$ENVOY_WEB_BASE" ]; then
        printf '%sError:%s %s not found\n' "$red" "$reset" "$ENVOY_WEB_BASE" >&2
        return 1
    fi

    # Candidates: the main repo first, then every worktree directory.
    # -type d (not -L) intentionally skips symlinks, matching the nushell
    # version's `where type == "dir"`.
    selected=$(
        {
            printf 'envoy-web-base\n'
            find "$ENVOY_WORKTREES" -mindepth 1 -maxdepth 1 -type d 2>/dev/null \
                | sed 's|.*/||' | sort
        } | fzf --prompt='envoy-web> ' --height=40% --reverse
    )

    if [ -z "$selected" ]; then
        printf '%sNo folder selected%s\n' "$yellow" "$reset" >&2
        return 1
    fi

    if [ "$selected" = "envoy-web-base" ]; then
        target="$ENVOY_WEB_BASE"
    else
        target="$ENVOY_WORKTREES/$selected"
    fi

    if [ ! -d "$target" ]; then
        printf '%sError:%s target is not a directory: %s\n' "$red" "$reset" "$target" >&2
        return 1
    fi

    # -L is tested BEFORE -e, and that ordering is the whole point. -e (and
    # nushell's `path exists`) follow the link, so both report FALSE for a
    # symlink whose target is gone -- exactly what you get after deleting a
    # worktree that envoy-web still points at. The nushell version therefore
    # falls into its "creating new one" branch and then dies on
    #   ln: failed to create symbolic link: File exists
    # because the link itself is very much still there. -L asks about the link
    # rather than the target, so a dangling link is cleaned up correctly.
    if [ -L "$ENVOY_WEB" ]; then
        rm "$ENVOY_WEB" || return 1
        printf '%sRemoved old symlink:%s %s\n' "$yellow" "$reset" "$ENVOY_WEB"
    elif [ -e "$ENVOY_WEB" ]; then
        printf '%sError:%s %s exists but is not a symlink. Aborting.\n' \
            "$red" "$reset" "$ENVOY_WEB" >&2
        return 1
    else
        printf '%sNo existing symlink at %s, creating new one...%s\n' \
            "$cyan" "$ENVOY_WEB" "$reset"
    fi

    ln -s "$target" "$ENVOY_WEB" || return 1
    printf '%sCreated symlink:%s %s -> %s%s%s\n' \
        "$green" "$reset" "$ENVOY_WEB" "$cyan" "$target" "$reset"

    # Plain cd, not cd -P: staying on the logical ~/code/envoy-web path is the
    # point of the symlink, and bounceEnv's `cd ~/code/envoy-web` relies on it.
    cd "$ENVOY_WEB" || return 1
}

# --- startFeatureBranch --------------------------------------------------
# The whole "start a ticket" routine in one command: refresh develop in the
# main checkout, run `ds start-feature-branch` to pick a Jira ticket and cut
# the branch, then hand that branch to workmux for its own worktree and tmux
# session. Optionally takes an EP number (`startFeatureBranch EP-1234`), which
# menu.js uses to skip the ticket picker when exactly one ticket matches.
#
# Three things here are not obvious.
#
# `ds` is an ALIAS (alias.sh), and aliases are NOT expanded inside function
# bodies, so this has to invoke menu.js through node itself.
#
# The new branch name is read back with `git rev-parse` instead of from the
# script's output. ds start-feature-branch is interactive -- an fzf ticket
# picker plus inquirer prompts -- so capturing its stdout would starve those
# prompts of the terminal they need. Capturing is also unnecessary: its last
# git action is `git checkout -b <branch>`, roughly 80 lines before it exits
# (webdev-tools/scripts/start-feature-branch.js), so once it returns, HEAD in
# this repo IS the branch name.
#
# Returning to develop afterwards is a hard requirement, not tidiness. git
# refuses to check a branch out in two places at once, so `workmux add` would
# die with "fatal: '<branch>' is already checked out" if the main repo were
# still sitting on the branch the worktree is being created for.
startFeatureBranch() {
    local base_branch="${ENVOY_BASE_BRANCH:-develop}"
    local menu="$ENVOY_TOOLS/webdev-tools/menu.js"
    local branch cmd
    local yellow="" red="" green="" cyan="" reset=""
    if [ -t 1 ]; then
        yellow=$'\033[33m'; red=$'\033[31m'; green=$'\033[32m'
        cyan=$'\033[36m';   reset=$'\033[0m'
    fi

    # Same reasoning as _envoy_check: fail before anything has been created.
    # fzf and gh are in here even though menu.js checks for them too, so a
    # missing one costs nothing instead of a checkout and a pull.
    for cmd in node git fzf gh workmux; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            printf '%sstartFeatureBranch:%s required command not found: %s\n' \
                "$red" "$reset" "$cmd" >&2
            return 1
        fi
    done

    # The main checkout, deliberately NOT $ENVOY_WEB: that symlink may well be
    # pointing at a worktree, and worktrees cannot be the base for new ones.
    if [ ! -d "$ENVOY_WEB_BASE" ]; then
        printf '%sError:%s %s not found\n' "$red" "$reset" "$ENVOY_WEB_BASE" >&2
        return 1
    fi
    if [ ! -f "$menu" ]; then
        printf '%sError:%s webdev-tools menu not found at %s\n' "$red" "$reset" "$menu" >&2
        return 1
    fi

    cd "$ENVOY_WEB_BASE" || return 1

    printf '%sRefreshing %s in %s...%s\n' "$cyan" "$base_branch" "$ENVOY_WEB_BASE" "$reset"
    git checkout "$base_branch" || return 1
    git pull || return 1
    printf '\n'

    # No `cd` wrapper and no subshell: menu.js inherits this terminal so fzf
    # and inquirer can drive it.
    if ! node "$menu" start-feature-branch "$@"; then
        printf '\n%sstartFeatureBranch:%s start-feature-branch did not complete -- skipping workmux.\n' \
            "$red" "$reset" >&2
        printf '  %s is left on branch: %s\n' \
            "$ENVOY_WEB_BASE" "$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" >&2
        return 1
    fi

    branch=$(git rev-parse --abbrev-ref HEAD) || return 1

    # Belt and braces for the case where the script somehow exits 0 without
    # cutting a branch. Everything it creates is feature/EP-xxxxx-..., so
    # anything else means there is nothing worth building a worktree for.
    case "$branch" in
        feature/*) ;;
        *)
            printf '\n%sstartFeatureBranch:%s expected a feature/* branch, but HEAD is "%s".\n' \
                "$red" "$reset" "$branch" >&2
            printf '  No new branch to hand to workmux.\n' >&2
            return 1
            ;;
    esac

    printf '\n%sNew branch:%s %s%s%s\n' "$green" "$reset" "$cyan" "$branch" "$reset"

    printf '%sReturning %s to %s so the worktree can claim the branch...%s\n' \
        "$yellow" "$ENVOY_WEB_BASE" "$base_branch" "$reset"
    git checkout "$base_branch" || return 1

    printf '%sHanding %s to workmux...%s\n' "$cyan" "$branch" "$reset"
    workmux add "$branch"
}
