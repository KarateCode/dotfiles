#!/bin/zsh

# 1. We extract the unique keys from ALL objects to ensure the header is complete
# 2. We use // "NA" to fill in gaps for missing fields
ids=$(jq -r '
    (map(with_entries(select(.value | type != "object" and type != "array"))) | add | keys - ["__v"]) as $cols
    | ($cols | @tsv),
      (.[] | [.[$cols[]] | tostring // "NA"] | @tsv)
  ' |
column -t -s $'\t' |
fzf --multi \
        --header-lines=1 \
        --prompt="Select Records (Tab to mark): " \
        --layout=reverse |
awk '{print $1}')

# Exit if no selection made
if [ -z "$ids" ]; then
    exit 0
fi

# Read collection name from temp file
collection_name=$(< /tmp/mongo_collection_name)

if [ -z "$collection_name" ]; then
    echo "Error: Collection name is empty" >&2
    exit 1
fi

if [ -z "$DATABASE_NAME" ]; then
    echo "Error: DATABASE_NAME environment variable is not set" >&2
    exit 1
fi

# Convert newline-separated ids to a JavaScript array of ObjectIds
ids_array=$(echo "$ids" | awk '{printf "ObjectId(\"%s\"),", $0}' | sed 's/,$//')

mongosh --quiet "mongodb://localhost:27017/$DATABASE_NAME" --eval "
    const result = db.getCollection('$collection_name').deleteMany({
        _id: { \$in: [$ids_array] }
    });
    print('\n\x1b[32m  Deleted ' + result.deletedCount + ' document(s)\x1b[0m');
"
