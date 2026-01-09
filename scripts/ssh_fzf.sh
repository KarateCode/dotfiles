#!/bin/zsh

selected_file=$(grep "Host " ~/.ssh/config | cut -d " " -f 2 | grep "integration" | fzf)
ssh $selected_file
