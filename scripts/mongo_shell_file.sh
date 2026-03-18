#!/bin/zsh
# Reads a query from a file and runs it in MongoDB
# Usage: mongo_shell_file.sh -f <file> | mongo_shell_file.sh --file <file>
# Default query file: $HOME/working/query.mongodb (e.g., 'Customer.find()')

# Default query file
QUERY_FILE="$HOME/working/query.mongodb"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            QUERY_FILE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Usage: mongo_shell_file.sh [-f|--file <file>]" >&2
            exit 1
            ;;
    esac
done

if [ ! -f "$QUERY_FILE" ]; then
    echo "Query file not found: $QUERY_FILE" >&2
    exit 1
fi

# Read query from file and trim whitespace
QUERY=$(cat "$QUERY_FILE" | tr -d '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Build the eval expression
# If query contains 'find(' or 'aggregate(', it returns a cursor and needs .toArray()
if [[ "$QUERY" == *"find("* || "$QUERY" == *"aggregate("* ]]; then
    EVAL_EXPR="printjson(JSON.stringify(db.${QUERY}.toArray()))"
else
    EVAL_EXPR="printjson(JSON.stringify(db.${QUERY}))"
fi

# Check if SSH tunnel is active on port 27018
if lsof -i :27018 > /dev/null 2>&1; then
    # Parse credentials from cached remote URI
    REMOTE_URI=$(cat "$HOME/.config/.mongo-remote-uri")
    CREDENTIALS=$(echo "$REMOTE_URI" | sed -n 's|mongodb://\([^@]*\)@.*|\1|p')

    # Build local connection string
    LOCAL_URI="mongodb://${CREDENTIALS}@localhost:27018/envoy-web?authSource=admin&directConnection=true"

    mongosh "$LOCAL_URI" --quiet --eval "$EVAL_EXPR"
else
    if [ -z "$NAMING_PREFIX" ]; then
        echo "NAMING_PREFIX not set" >&2
        exit 1
    fi

    mongosh "$NAMING_PREFIX" --quiet --eval "$EVAL_EXPR"
fi
