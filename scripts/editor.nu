#!/usr/bin/env nu
# Edit a MongoDB document in $EDITOR and save changes back to the database
# Usage: ms 'Client.findOne()' | editor

# Pipeable function for use in nushell
def editor [] {
    # $in is already structured data from ms (which does | from json)
    let input_data = $in

    # Read collection name from hardcoded temp file
    let collection_name = if ("/tmp/mongo_collection_name" | path exists) {
        open /tmp/mongo_collection_name | str trim
    } else {
        ""
    }

    if ($collection_name | is-empty) {
        print --stderr "Error: Collection name is empty"
        exit 1
    }

    # Check if DATABASE_NAME is set
    let db_name = $env.DATABASE_NAME? | default $env.NAMING_PREFIX?
    if ($db_name | is-empty) {
        print --stderr "Error: DATABASE_NAME or NAMING_PREFIX environment variable is not set"
        exit 1
    }

    # Extract _id from input data
    # Input could be a record (single doc) or a list (array of docs)
    let raw_id = if ($input_data | describe | str starts-with "list") {
        # It's a list, get first element's _id
        $input_data | get 0._id?
    } else {
        # It's a single record
        $input_data | get _id?
    }

    # If still no _id, error out
    if ($raw_id | is-empty) {
        print --stderr "Error: Could not find '_id' in input"
        exit 1
    }

    # Extract the actual hex string from _id
    # It could be a plain string, or a record like {"$oid": "..."}
    let id = if ($raw_id | describe | str starts-with "record") {
        # BSON extended JSON format: {"$oid": "..."}
        $raw_id | get "$oid"? | default ($raw_id | values | first)
    } else {
        $raw_id | into string
    }

    print $"_id: ($id)"

    # Query MongoDB and save to temp file
    let temp_file = (mktemp --suffix .json | str trim)

    let mongosh_eval = "const doc = db.getCollection('" + $collection_name + "').findOne({ _id: ObjectId('" + $id + "') }); if (doc) { printjson(doc); }"
    let result = (mongosh --quiet $"mongodb://localhost:27017/($db_name)" --eval $mongosh_eval | str trim)

    if ($result | is-not-empty) {
        $result | save --force $temp_file

        # Open editor - need to use raw terminal
        let editor = $env.EDITOR? | default "vim"
        ^$editor $temp_file

        # Read the updated file and update MongoDB
        let updated_doc = (open $temp_file --raw | str trim)

        let update_eval = "const updatedDoc = " + $updated_doc + "; db.getCollection('" + $collection_name + "').replaceOne({ _id: ObjectId('" + $id + "') }, updatedDoc); print('\\n\\x1b[32m  Document updated successfully\\x1b[0m');"
        mongosh --quiet $"mongodb://localhost:27017/($db_name)" --eval $update_eval

        # Clean up temp file
        rm -f $temp_file
    } else {
        print $"No document found with _id: ($id)"
    }
}

# For running as a standalone script
def main [] {
    $in | editor
}

null
