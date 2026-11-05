#!/bin/zsh

# Read JSON from stdin and sanitize control characters that break jq
# tr removes ASCII 0x00-0x08, 0x0B, 0x0C, 0x0E-0x1F (preserving tab, newline, carriage return)
json_input=$(cat | tr -d '\000-\010\013\014\016-\037')

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
# MongoDB extended JSON format has _id as {"$oid": "..."}, plain format has _id as string
# Use printf to avoid echo adding newlines that break jq parsing
# First try to get _id directly (if input is an object)
_id=$(printf '%s' "$json_input" | jq -r '._id | if type == "object" then .["$oid"] // . else . end // empty' 2>/dev/null)
echo "_id: $_id"
# If that fails or is empty, try to get first element's _id (if input is an array)
if [ -z "$_id" ]; then
    _id=$(printf '%s' "$json_input" | jq -r '.[0]._id | if type == "object" then .["$oid"] // . else . end // empty' 2>/dev/null)
fi

# If still no _id, error out
if [ -z "$_id" ]; then
    echo "Error: Could not find '_id' in JSON input" >&2
    exit 1
fi

# Query MongoDB and save to temp file
temp_file=$(mktemp --suffix=.json)
result=$(mongosh --quiet "mongodb://localhost:27017/$DATABASE_NAME" --eval "
    const doc = db.getCollection('$collection_name').findOne({ _id: ObjectId('$_id') });
    if (doc) {
        printjson(doc);
    }
")

if [ -n "$result" ]; then
    # printf, not echo: zsh's echo expands \n and \t, which corrupts string
    # literals in the document (printjson emits them escaped inside quotes)
    printf '%s\n' "$result" > "$temp_file"
    $EDITOR "$temp_file" < /dev/tty

    # Read the updated file and update MongoDB
    updated_doc=$(< "$temp_file")

    # Pass the update script as a file rather than --eval: Linux caps a single
    # argv entry at 128 KiB (MAX_ARG_STRLEN), which large documents exceed.
    script_file=$(mktemp --suffix=.js)
    cat > "$script_file" <<EOF
const updatedDoc = $updated_doc;
try {
    const res = db.getCollection('$collection_name').replaceOne(
        { _id: ObjectId('$_id') },
        updatedDoc
    );
    if (res.matchedCount === 0) {
        print('\n\x1b[31m  No document matched _id $_id\x1b[0m');
        quit(1);
    }
    print('\n\x1b[32m  Document updated successfully\x1b[0m');
} catch (err) {
    print('\n\x1b[31m  Update failed: ' + err.message + '\x1b[0m');
    quit(1);
}
EOF

    mongosh --quiet "mongodb://localhost:27017/$DATABASE_NAME" "$script_file"
    rc=$?
    rm -f "$script_file"

    # Keep the edited document around if the write failed
    if [ $rc -ne 0 ]; then
        echo "Edits preserved at: $temp_file" >&2
        exit $rc
    fi

    rm -f "$temp_file"
else
    echo "No document found with _id: $_id"
fi

