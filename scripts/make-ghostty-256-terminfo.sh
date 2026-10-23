#!/bin/bash
# Builds `xterm-ghostty-256': Ghostty's terminfo without the truecolour caps.
#
# Emacs keeps ONE global tty colour table for the whole daemon, so frames of
# mixed colour depth corrupt each other's colours. Pinning Ghostty frames to 256
# matches tmux-256color and keeps named colours on ANSI indices, so the Omarchy
# theme still reaches Emacs.
#
# The name must start with `xterm-' or Emacs never loads term/xterm.el and
# registers only 8 colours. Re-run after a Ghostty upgrade ships new terminfo.
set -euo pipefail

SRC=xterm-ghostty
DST=xterm-ghostty-256

if ! infocmp -x "$SRC" >/dev/null 2>&1; then
  echo "error: no terminfo entry for $SRC (is Ghostty installed?)" >&2
  exit 1
fi

tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT

# setrgbf alone is what demotes Emacs to 256; the rest go for consistency.
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
