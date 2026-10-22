#!/bin/bash
# Build the `xterm-ghostty-256' terminfo entry into ~/.terminfo.
#
# WHY THIS EXISTS
# ---------------
# Emacs keeps ONE GLOBAL tty colour table for the whole daemon:
#
#     (defun tty-color-alist (&optional _frame)   ; frame argument IGNORED
#       tty-defined-color-alist)
#     (defun tty-color-clear (&optional _frame)
#       (setq tty-defined-color-alist nil))
#
# Creating any frame runs tty-color-clear and rebuilds that table for the NEW
# frame's colour depth. With frames of MIXED depth in one daemon, every
# already-open frame of the other depth then resolves colours through the
# wrong table. Measured, with a 256-colour tmux frame left untouched:
#
#     tmux frame alone          table=256  #b877db -> ("color-140" 140)   ok
#     after opening a Ghostty
#     (truecolor) frame         table=665  #b877db -> ("orchid3" 13461961) BROKEN
#
# 13461961 is a packed 24-bit value; a 256-colour terminal cannot render it,
# so the text loses its colours. That is the "emacs randomly drops syntax
# highlighting" bug -- the faces were always correct, the INDICES were not.
#
# The daemon runs mixed depths because systemd starts it without COLORTERM, so
# depth falls back to terminfo: xterm-ghostty carries `setrgbf' (-> truecolor)
# while tmux-256color does not (-> 256).
#
# THE FIX: make every frame 256 so the table never thrashes. Rather than
# retyping Ghostty frames as plain `xterm-256color' -- which would also throw
# away Su (synchronised output, i.e. flicker-free redraw), hs/dsl/fsl (title)
# and fullkbd -- this strips ONLY the truecolour capabilities from Ghostty's
# own entry and leaves everything else intact.
#
# Keeping 256 rather than forcing everything to truecolour is deliberate: at
# 256 colours Emacs resolves named colours to ANSI indices (green -> 2), which
# the terminal renders from the palette, so Omarchy's theme still cascades into
# Emacs. At 24-bit they become frozen RGB literals (green -> 52480) and the
# theme no longer reaches them.
#
# THE NAME MATTERS. `tty-run-terminal-initialization' finds a terminal's setup
# file by stripping trailing [-_]segments until something matches:
#     xterm-ghostty-256 -> xterm-ghostty -> xterm   => term/xterm.el   GOOD
# A name like `ghostty-256' matches nothing, xterm--init never runs, and the
# 256-colour cube is never registered -- leaving only 8 basic colours, which
# approximates #fab795 to plain yellow instead of color-216. Verified the hard
# way; do not rename this without re-checking that.
#
# Re-run after a Ghostty upgrade that ships a new terminfo.
set -euo pipefail

SRC=xterm-ghostty
DST=xterm-ghostty-256

if ! infocmp -x "$SRC" >/dev/null 2>&1; then
  echo "error: no terminfo entry for $SRC (is Ghostty installed?)" >&2
  exit 1
fi

tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT

# Drop Tc (truecolour boolean) and the direct-colour setters. Removing setrgbf
# alone is what actually demotes Emacs to 256, but all three go for clarity.
infocmp -x "$SRC" \
  | sed -e 's/\bTc, //' \
        -e 's/setrgbf=[^,]*,[[:space:]]*//g' \
        -e 's/setrgbb=[^,]*,[[:space:]]*//g' \
        -e "2s|^$SRC|ghostty|" \
        -e "2s|^ghostty|$DST|" \
        -e '2s/|ghostty|Ghostty,/|Ghostty 256-color,/' \
  > "$tmp"

if grep -qE "setrgbf|setrgbb|\bTc\b" "$tmp"; then
  echo "error: truecolour capabilities survived the rewrite" >&2
  exit 1
fi

tic -x -o "$HOME/.terminfo" "$tmp"
echo "built $DST into ~/.terminfo"

# Prove it: 256 cells, and `green' back to an ANSI index rather than raw RGB.
if command -v emacs >/dev/null 2>&1; then
  out=$(mktemp); el=$(mktemp --suffix=.el)
  cat > "$el" <<'EOF'
(write-region (format "cells=%s green=%s" (display-color-cells)
                      (nth 1 (tty-color-desc "green")))
              nil (getenv "CHECK_OUT"))
(kill-emacs)
EOF
  CHECK_OUT="$out" env -u COLORTERM TERM="$DST" \
    script -qec "emacs -Q -nw -l $el" /dev/null >/dev/null 2>&1 || true
  echo "check: $(cat "$out" 2>/dev/null || echo '(could not verify)')   # expect cells=256 green=2"
  rm -f "$out" "$el"
fi
