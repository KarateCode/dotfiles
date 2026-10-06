#!/bin/zsh

# Mac only. On Linux both configs are symlinks INTO this repo, so there is
# nothing to copy and doing so would be destructive:
#   ~/.config/tmux/tmux.conf   -> dotfiles/tmux/tmux_omarchy.conf
#   ~/.config/ghostty/config   -> dotfiles/ghostty/config
# The old Linux branch copied those over tmux.conf and ghostty_config, which
# are the MAC files -- overwriting the Mac's config with the Linux one.

if [[ "$(uname)" == "Linux" ]]; then
    echo "Linux: tmux and ghostty configs are symlinked into dotfiles already; nothing to copy."
    exit 0
fi

cp ~/.config/tmux/tmux.conf tmux.conf
cp ~/Library/Application\ Support/com.mitchellh.ghostty/config ghostty_config
cp ~/.config/aerospace/aerospace.toml aerospace.toml
