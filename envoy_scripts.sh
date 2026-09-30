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
    if [ ! -d "$ENVOY_CODE/envoy-web-base" ]; then
        printf '%sError:%s %s not found\n' "$red" "$reset" "$ENVOY_CODE/envoy-web-base" >&2
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
        target="$ENVOY_CODE/envoy-web-base"
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
