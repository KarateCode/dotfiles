export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

eval "$(/opt/homebrew/bin/brew shellenv)"

unsetopt share_history

# eval "$(/opt/homebrew/bin/brew shellenv)"
# export PATH="/opt/homebrew/bin:$PATH"
export TMUXINATOR_CONFIG=/Users/michaelschneider/code/envoy-tmuxinator-configs/configs
# alias ls='gls --color=auto --group-directories-first'
# alias ls='ls -G'

## Set up fzf key bindings and fuzzy completion
## Ctrl-R to search history, Ctrl-T to search files ( probably does other things as well )
source <(fzf --zsh)

alias ds='node /Users/michaelschneider/code/tools-and-infrastructure/webdev-tools/menu.js'
source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/dotfiles/alias.sh
export EDITOR=emacs

# source ~/.zshrc

# WORDCHARS='~!#$%^&*(){}[]<>?.+;-_/\|=@`'
