export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

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
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

bindkey -r "^H"

nvm use default

typeset -A ABBR
typeset -a ABBR_JUMPS

ABBR[um]='updateMany({%}, {%})'
ABBR[fn]='function %(%) { % }'

_expand_abbr() {
    local word=${LBUFFER##*[^a-zA-Z0-9_]}
    local expansion=${ABBR[$word]}

    [[ -z $expansion ]] && return 1

    LBUFFER=${LBUFFER%$word}

    ABBR_JUMPS=()

    while [[ $expansion == *%* ]]; do
        local before=${expansion%%\%*}
        local pos=$(( ${#LBUFFER} + ${#before} ))

        ABBR_JUMPS+=($pos)
        expansion=${expansion/\%/}
    done

    LBUFFER+=$expansion

    if (( ${#ABBR_JUMPS} > 0 )); then
        CURSOR=${ABBR_JUMPS[1]}
        ABBR_JUMPS=("${ABBR_JUMPS[@]:1}")
    fi

    return 0
}

_jump_abbr() {
    if (( ${#ABBR_JUMPS} > 0 )); then
        CURSOR=${ABBR_JUMPS[1]}
        ABBR_JUMPS=("${ABBR_JUMPS[@]:1}")
    else
        zle expand-or-complete
    fi
}

_delim_expand() {
    _expand_abbr || zle self-insert
}

zle -N _delim_expand
zle -N _jump_abbr

bindkey ' ' _delim_expand
bindkey '.' _delim_expand
bindkey '/' _delim_expand

bindkey '^I' _jump_abbr
