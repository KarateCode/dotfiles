#!/bin/zsh

git ls-files -m | grep -m 1 "" | xargs sh -c 'emacs "$@" < /dev/tty' emacs
