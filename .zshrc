
# Set up LS_COLORS for theming
# export LS_COLORS="$(vivid generate catppuccin-latte)"
export LS_COLORS="$(vivid generate dracula)"
# alias ls="gls --color=always"
alias ls='gls --color=auto --group-directories-first'

# More presets can be found at: https://starship.rs/presets/
# To install new presets, use a command similar to following:
# starship preset tokyo-night -o ~/.config/starship.toml
eval "$(starship init zsh)"
# PROMPT="%n@%m %~ %# "

# if zsh-autosuggestions gets wonky, try this:
HISTFILE=~/.zsh_history  # Specifies the history file location
SAVEHIST=1000            # Number of history entries to save
HISTSIZE=999             # Number of history entries to keep in memory
# setopt SHARE_HISTORY     # Shares history across all Zsh sessions
setopt HIST_EXPIRE_DUPS_FIRST # Expires duplicate entries first
setopt HIST_IGNORE_DUPS       # Ignores duplicate commands when adding to history
setopt HIST_IGNORE_SPACE      # Ignores commands starting with a space
setopt HIST_REDUCE_BLANKS     # Removes extra blanks from history entries

# if command -v tmux >/dev/null 2>&1; then
#     [ -z "$TMUX" ] && exec tmux
# fi
