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

    # Pin bare-Ghostty frames to 256 so every frame in the daemon has the same
    # colour depth; Emacs's tty colour table is global and mixed depths corrupt it.
    # Inside tmux TERM is already 256. Rebuilds the terminfo if missing or stale,
    # since ~/.terminfo is not in this repo. Silent on failure: stderr here would
    # garble the editor's first frame.
    if [[ -z "${TMUX:-}" && "$TERM" == "xterm-ghostty" ]]; then
        _ti_src=/usr/share/terminfo/x/xterm-ghostty
        _ti_dst=$HOME/.terminfo/x/xterm-ghostty-256

        if [[ ! -f $_ti_dst || $_ti_src -nt $_ti_dst ]]; then
            "${0:A:h}/make-ghostty-256-terminfo.sh" >/dev/null 2>&1 || true
        fi

        if infocmp xterm-ghostty-256 >/dev/null 2>&1; then
            export TERM=xterm-ghostty-256
        fi
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
