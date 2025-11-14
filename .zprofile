eval "$(/opt/homebrew/bin/brew shellenv)"

unsetopt share_history
bindkey -e

# eval "$(/opt/homebrew/bin/brew shellenv)"
# export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/bin:$PATH"
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
export VITE_REACT_APP_API_URL=http://localhost:8080
export VITE_REACT_APP_API_WS="ws://localhost:8080"
export VITE_REACT_APP_GOOGLE_CLIENT_ID="85730891639-c4ahs2ldb2i2cmjaom4v02ijc6rjjkt1.apps.googleusercontent.com"

select_env() {
    local arg="$1"
    eval "$("$HOME/code/tools-and-infrastructure/scripts/developer/select_env_menu.sh" "$arg")"
}

# source ~/.zshrc

WORDCHARS='~!#$%^&*(){}<>?+;_\|@`'
