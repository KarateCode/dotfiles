#!/bin/zsh

ssh_alias=$(ls ~/code/tools-and-infrastructure/scripts/developer/environments | fzf)
tmux set-environment DATABASE_NAME $ssh_alias
tmuxinator mongo-tui --append $ssh_alias
