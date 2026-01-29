#!/bin/zsh

# git ls-files -m | grep -m 1 "" | xargs code
result=$(git ls-files -m | grep -m 1 "")
# env -S $EDITOR result
env -S $EDITOR "$result"
