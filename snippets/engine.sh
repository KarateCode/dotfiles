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

# Popup fzf menu that inserts selection at cursor
_fzf_popup_insert() {
    local tmp_file="/tmp/fzf_popup_selection"
    rm -f "$tmp_file"

    # Run fzf in a tmux popup - customize the input source as needed
    tmux display-popup -E -w 80% -h 60% "echo -e 'option1\noption2\noption3\nfoo\nbar\nbaz' | fzf --prompt='Select: ' > $tmp_file"

    # Read selection and insert at cursor
    if [[ -f "$tmp_file" ]]; then
        local selection=$(<"$tmp_file")
        if [[ -n "$selection" ]]; then
            LBUFFER+="$selection"
        fi
        rm -f "$tmp_file"
    fi

    zle redisplay
}

zle -N _fzf_popup_insert
bindkey '^[,' _fzf_popup_insert
