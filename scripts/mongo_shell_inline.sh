#!/bin/zsh
# an alias sets this script to `ms1` in alias.sh
# Usage: ms1 'Product.findOne({})'

if [ -z "$NAMING_PREFIX" ]; then
    echo "NAMING_PREFIX not set" >&2
    exit 1
fi

QUERY=$1

# Build the eval expression
# If query contains 'find(' or 'aggregate(', it returns a cursor and needs .toArray()
if [[ "$QUERY" == *"find("* || "$QUERY" == *"aggregate("* ]]; then
    EVAL_EXPR="JSON.stringify(db.${QUERY}.toArray())"
else
    EVAL_EXPR="JSON.stringify(db.${QUERY})"
fi

# Check if SSH tunnel is active on port 27018
if lsof -i :27018 > /dev/null 2>&1; then
    # echo "Active SSH tunnel detected on port 27018"

    # Parse credentials from cached remote URI
    REMOTE_URI=$(cat "$HOME/.config/.mongo-remote-uri")
    CREDENTIALS=$(echo "$REMOTE_URI" | sed -n 's|mongodb://\([^@]*\)@.*|\1|p')

    # Build local connection string
    # echo "credentials discovered: $CREDENTIALS"
    LOCAL_URI="mongodb://${CREDENTIALS}@localhost:27018/envoy-web?authSource=admin&directConnection=true"

    mongosh "$LOCAL_URI" --quiet --eval "$EVAL_EXPR"
else
    mongosh "$NAMING_PREFIX" --quiet --eval "$EVAL_EXPR"
fi
