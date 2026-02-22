eval "$(/opt/homebrew/bin/brew shellenv)"

unsetopt share_history
bindkey -e

# eval "$(/opt/homebrew/bin/brew shellenv)"
# export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/bin:$PATH"
export TMUXINATOR_CONFIG=/Users/michaelschneider/code/envoy-tmuxinator-configs/configs
export RIPGREP_CONFIG_PATH=/Users/michaelschneider/.ripgreprc
# alias ls='gls --color=auto --group-directories-first'
# alias ls='ls -G'

## Set up fzf key bindings and fuzzy completion
## Ctrl-R to search history, Ctrl-T to search files ( probably does other things as well )
source <(fzf --zsh)

alias ds='node /Users/michaelschneider/code/tools-and-infrastructure/webdev-tools/menu.js'
source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/dotfiles/alias.sh
source ~/dotfiles/.sensitive.sh

export EDITOR="emacs --init-directory=/Users/michaelschneider/vanilla-emacs"
export VITE_REACT_APP_API_URL=http://localhost:8080
export VITE_REACT_APP_API_WS="ws://localhost:8080"
export VITE_REACT_APP_GOOGLE_CLIENT_ID="85730891639-c4ahs2ldb2i2cmjaom4v02ijc6rjjkt1.apps.googleusercontent.com"

export JIRA_API_TOKEN="nsaJfxujotlQYWyfzxMMCB92"

select_env() {
    local arg="$1"
    eval "$("$HOME/code/tools-and-infrastructure/scripts/developer/select_env_menu.sh" "$arg")"
}

# The ultimate jview: defaults to EP- if input is just numbers
jview() {
    # 1. Check if an argument was provided
    if [[ -z "$1" ]]; then
        echo "Usage: jview <number_or_key>"
        return 1
    fi

    local input="$1"

    # 2. Logic: If the input consists ONLY of digits, prepend 'EP-'
    # ^[0-9]+$ is a regex for "start of string, one or more digits, end of string"
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        input="EP-$input"
    fi

    # 3. Execute the command
    echo "Fetching issue: $input..."
    jira issue view "$input" --comments 50
}

autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select

# source ~/.zshrc

WORDCHARS='~!#$%^&*(){}<>?+;_\|@`-'
