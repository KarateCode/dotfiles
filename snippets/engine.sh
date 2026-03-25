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

# Popup fzf menu to select MongoDB field names and insert at cursor
_fzf_mongo_fields() {
    local tmp_file="/tmp/fzf_popup_selection"
    local tmp_collection="/tmp/fzf_popup_collection"
    rm -f "$tmp_file"

    # Get full command line and parse collection name
    # Matches patterns like: Client.find(), Product.aggregate(), etc.
    local full_line="$LBUFFER$RBUFFER"
    local collection_name=$(echo "$full_line" | sed -E -n 's/.*([A-Z][a-zA-Z]*).(find|findOne|aggregate|count|distinct).*/\1/p')

    if [[ -z "$collection_name" ]]; then
        zle -M "Could not parse collection name from command line"
        return
    fi
    # echo "collection_name: $collection_name"

    # Write collection name to temp file for the popup script to read
    echo "$collection_name" > "$tmp_collection"

    # Run fzf in a tmux popup with mongosh providing field names
    popup_script="
        select_env=$DATABASE_NAME
        collection=\$(< $tmp_collection)
        echo 'key' > $tmp_file
        mongosh \"$DATABASE_NAME\" --quiet --eval \"JSON.stringify(db.getCollection('\$collection').findOne())\" |
        jq -r '. | (with_entries(select(.value | type != \"object\" and type != \"array\"))) | keys - [\"_id\"] | .[]' |
        fzf --multi --prompt='Select fields: ' >> $tmp_file
    "
    tmux display-popup -E -w 80% -h 60% $popup_script

    # Read selection and insert at cursor
    if [[ -f "$tmp_file" ]]; then
        local selection=$(< "$tmp_file" | yq -p=csv '.[] |= .key + ": 1" | join(", ")') # actual mongo (not mongoose) syntax
        # local selection=$(< "$tmp_file" | yq -p=csv ".[] |= \"'\" + .key + \"'\" | join(\", \")") # wrapped in single quotes
        # local selection=$(< "$tmp_file" | yq -p=csv '.[] |= "\"" + .key + "\"" | join(", ")') # wrapped in double quotes
        if [[ -n "$selection" ]]; then
            LBUFFER+="$selection"
        fi
        rm -f "$tmp_file"
    fi
    rm -f "$tmp_collection"

    zle redisplay
}

_fzf_mongo_table_names() {
    ms "getCollectionNames()" | jq -r ".[]" | sort | fzf | tr -d '[:space:]'
}
zle -N _fzf_mongo_fields
bindkey '^[,' _fzf_mongo_fields
zle -N _fzf_mongo_table_names
bindkey '^[t' _fzf_mongo_table_names
