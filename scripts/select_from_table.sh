#!/bin/zsh

# 1. We extract the unique keys from ALL objects to ensure the header is complete
# 2. We use // "NA" to fill in gaps for missing fields
jq -r '
    (map(with_entries(select(.value | type != "object" and type != "array"))) | add | keys - ["__v"]) as $cols
    | ($cols | @tsv),
      (.[] | [.[$cols[]] | tostring // "NA"] | @tsv)
  ' |
column -t -s $'\t' |
fzf --multi \
        --header-lines=1 \
        --prompt="Select Records (Tab to mark): " \
        --layout=reverse |
awk '{print $1}'
