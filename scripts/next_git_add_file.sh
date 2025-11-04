#!/bin/zsh

git ls-files -m | grep -m 1 "" | xargs git add
git status
