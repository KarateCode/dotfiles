#!/bin/zsh

if [[ -n "${INSIDE_EMACS:-}" ]]; then
    # Called from a shell running inside Emacs (M-x shell, vterm, ...). Asking
    # for -nw there would try to build a terminal frame inside the frame we are
    # already in. Hand the file to the surrounding Emacs instead; emacsclient
    # still blocks until you finish the buffer, which is what $EDITOR requires.
    exec emacsclient -a '' "$@"
fi

exec emacsclient -nw -a '' "$@"
