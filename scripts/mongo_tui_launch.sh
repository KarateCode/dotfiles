#!/bin/zsh

ssh_alias=$(ls ~/code/tools-and-infrastructure/scripts/developer/environments | fzf)

tmuxinator mongo-tui --append $ssh_alias
