#!/bin/zsh

if [[ "$(uname)" == "Linux" ]]; then
    # Omarchy (Linux) - use emacsclient with auto-start daemon
    if [[ -n "${INSIDE_EMACS:-}" ]]; then
        # Called from a shell running inside Emacs (M-x shell, vterm, ...). Asking
        # for -nw there would try to build a terminal frame inside the frame we are
        # already in. Hand the file to the surrounding Emacs instead; emacsclient
        # still blocks until you finish the buffer, which is what $EDITOR requires.
        exec emacsclient -a '' "$@"
    fi

    exec emacsclient -nw -a '' "$@"
else
    # macOS - use custom init directory
    EMACS_INIT_DIR="$HOME/.config/emacs"

    # Start daemon with correct init directory if not running
    if ! emacsclient -e '(+ 1 1)' &>/dev/null; then
        emacs --init-directory="$EMACS_INIT_DIR" --daemon
    fi

    if [[ -n "${INSIDE_EMACS:-}" ]]; then
        exec emacsclient "$@"
    fi

    exec emacsclient -nw "$@"
fi
