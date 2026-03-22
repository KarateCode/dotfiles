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
_id=$(echo $json_input | jq -r '._id // empty' 2>/dev/null)
echo "_id: $_id"
# If that fails or is empty, try to get first element's _id (if input is an array)
if [ -z "$_id" ]; then
    _id=$(echo "$json_input" | jq -r '.[0]._id // empty' 2>/dev/null)
fi

# If still no _id, error out
if [ -z "$_id" ]; then
    echo "Error: Could not find '_id' in JSON input" >&2
    exit 1
fi

# Query MongoDB and save to temp file
temp_file=$(mktemp).json
result=$(mongosh --quiet "mongodb://localhost:27017/$DATABASE_NAME" --eval "
    const doc = db.getCollection('$collection_name').findOne({ _id: ObjectId('$_id') });
    if (doc) {
        printjson(doc);
    }
")

if [ -n "$result" ]; then
    echo "$result" > "$temp_file"
    $EDITOR "$temp_file" < /dev/tty

    # Read the updated file and update MongoDB
    updated_doc=$(< "$temp_file")

    mongosh --quiet "mongodb://localhost:27017/$DATABASE_NAME" --eval "
        const updatedDoc = $updated_doc;
        db.getCollection('$collection_name').replaceOne(
            { _id: ObjectId('$_id') },
            updatedDoc
        );
        print('\n\\x1b[32m  Document updated successfully\\x1b[0m');
    "

    # Clean up temp file
    rm -f "$temp_file"
else
    echo "No document found with _id: $_id"
fi

