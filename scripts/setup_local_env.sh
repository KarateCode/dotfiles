#!/bin/zsh

envName=$(ls ~/code/tools-and-infrastructure/scripts/developer/environments | fzf | sed 's/\.sh$//')
# ssh $envName
echo $envName


tmux send-keys -t dev-environment:main.3 C-c
tmux send-keys -t dev-environment:main.3 "select_env $envName" C-m
tmux send-keys -t dev-environment:main.3 'npm run gulp -- --live-reload' C-m

tmux send-keys -t dev-environment:main.2 "select_env $envName" C-m
# select_env $envName

tmux send-keys -t dev-environment:main.1 C-c
sleep 0.2
tmux send-keys -t dev-environment:main.1 "select_env $envName" C-m
tmux send-keys -t dev-environment:main.1 './bin/run-dev-server' C-m


