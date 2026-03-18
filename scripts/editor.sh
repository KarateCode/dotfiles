#!/bin/zsh

# Read JSON from stdin
json_input=$(cat)

# Read collection name from hardcoded temp file
collection_name=$(< /tmp/mongo_collection_name)

if [ -z "$collection_name" ]; then
    echo "Error: Collection name is empty" >&2
    exit 1
fi

# Check if DATABASE_NAME is set
if [ -z "$DATABASE_NAME" ]; then
    echo "Error: DATABASE_NAME environment variable is not set" >&2
    exit 1
fi

# Extract _id from JSON
# First try to get _id directly (if input is an object)
_id=$(echo "$json_input" | jq -r '._id // empty' 2>/dev/null)

# If that fails or is empty, try to get first element's _id (if input is an array)
if [ -z "$_id" ]; then
    _id=$(echo "$json_input" | jq -r '.[0]._id // empty' 2>/dev/null)
fi

# If still no _id, error out
if [ -z "$_id" ]; then
    echo "Error: Could not find '_id' in JSON input" >&2
    exit 1
fi

# Query MongoDB and output the record
mongosh --quiet "mongodb://localhost:27017/$DATABASE_NAME" --eval "
    const doc = db.getCollection('$collection_name').findOne({ _id: ObjectId('$_id') });
    if (doc) {
        printjson(doc);
    } else {
        print('No document found with _id: $_id');
    }
"

