#!/bin/zsh

if [[ "$(uname)" == "Linux" ]]; then
    cp ~/.config/tmux/tmux.conf tmux.conf
    cp ~/.config/ghostty/config ghostty_config
else
    cp ~/.config/tmux/tmux.conf tmux.conf
    cp ~/Library/Application\ Support/com.mitchellh.ghostty/config ghostty_config
    cp ~/.config/aerospace/aerospace.toml aerospace.toml
fi
