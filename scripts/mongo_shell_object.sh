#!/bin/zsh
# an alias sets this script to `ms1` in alias.sh
# Usage: ms1 'Product.findOne({})'

if [ -z "$NAMING_PREFIX" ]; then
    echo "NAMING_PREFIX not set" >&2
    exit 1
fi

QUERY=$1

mongosh "$NAMING_PREFIX" --quiet --eval "JSON.stringify(db.$QUERY)"
