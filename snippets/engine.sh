ABBR_ACTIVE=0

source ~/dotfiles/snippets/snippets.sh

_expand_abbr() {
    local word=${LBUFFER##*[^a-zA-Z0-9_]}
    local expansion=${ABBR[$word]}

    [[ -z $expansion ]] && return 1

    LBUFFER=${LBUFFER%$word}
    LBUFFER+=$expansion

    # Jump to first % if present
    local buf="$LBUFFER$RBUFFER"
    local pos=${buf[(i)%]}
    if (( pos <= ${#buf} )); then
        LBUFFER=${buf:0:$((pos-1))}
        RBUFFER=${buf:$pos}
        ABBR_ACTIVE=1
    fi

    return 0
}

_jump_abbr() {
    if [[ $ABBR_ACTIVE -eq 1 ]]; then
        local buf="$LBUFFER$RBUFFER"
        local pos=${buf[(i)%]}
        if (( pos <= ${#buf} )); then
            LBUFFER=${buf:0:$((pos-1))}
            RBUFFER=${buf:$pos}
            return
        fi
        ABBR_ACTIVE=0
    fi
    zle expand-or-complete
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
