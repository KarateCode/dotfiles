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

    # Pin this frame to 256 colours so EVERY frame in the daemon has the same
    # colour depth.
    #
    # Emacs keeps ONE GLOBAL tty colour table (`tty-color-alist' ignores its
    # frame argument). Creating a frame clears and rebuilds it for that frame's
    # depth, so mixed depths make already-open frames resolve colours through
    # the wrong table -- a 256-colour tmux frame starts emitting packed 24-bit
    # indices its terminal cannot render, and the buffer goes grey/black. That
    # is the "emacs randomly loses syntax highlighting" bug; the faces are fine,
    # the colour INDICES are not. See scripts/make-ghostty-256-terminfo.sh for
    # the measurements.
    #
    # Inside tmux TERM is already tmux-256color (256), so only bare-Ghostty
    # frames need demoting. xterm-ghostty-256 is Ghostty's own terminfo with
    # just the truecolour caps removed, so Su/hs/fullkbd survive -- unlike
    # retyping to plain xterm-256color.
    #
    # Guarded three ways: only outside tmux, only when the terminal really is
    # Ghostty (alacritty etc. would need their own entry), and only if the
    # terminfo was actually built. Missing entry just means no override --
    # degrades to the old mixed-depth behaviour rather than an unusable TERM.
    if [[ -z "${TMUX:-}" && "$TERM" == "xterm-ghostty" ]]; then
        _ti_src=/usr/share/terminfo/x/xterm-ghostty
        _ti_dst=$HOME/.terminfo/x/xterm-ghostty-256

        # Self-healing, because ~/.terminfo is NOT in this repo: cloning the
        # dotfiles onto a new box gets the script but not its output. Without
        # this the guard below would simply find no entry and skip, silently
        # restoring the very bug it exists to prevent.
        #
        # Rebuild when the entry is missing, or when Ghostty has shipped a
        # NEWER terminfo than the one we derived from (package upgrade).
        # `tic` costs ~8ms and only runs when one of those is true, so the
        # common path is a single stat.
        if [[ ! -f $_ti_dst || $_ti_src -nt $_ti_dst ]]; then
            "${0:A:h}/make-ghostty-256-terminfo.sh" >/dev/null 2>&1 || true
        fi

        # Deliberately silent on failure: this runs immediately before an
        # editor takes over the terminal, so writing to stderr here would
        # garble the first frame. Run the script by hand to see why it failed.
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
