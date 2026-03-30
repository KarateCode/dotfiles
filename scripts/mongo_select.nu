#!/usr/bin/env nu
# Shared MongoDB document selection via fzf
# Used by deleteMany, updateMany, and other mongo tools
#
# Returns a record with: { ids: list<string>, collection_name: string, db_name: string }
# Or null if selection was cancelled or invalid

def mongo-select [] {
    # $in is already structured data from ms
    let input_data = $in

    # Ensure we have a flat list of records
    let input_type = ($input_data | describe)
    let docs = if ($input_type | str starts-with "list") {
        # Already a list, use as-is
        $input_data
    } else if ($input_type | str starts-with "record") {
        # Single record, wrap in list
        [$input_data]
    } else {
        # Unexpected type, try to work with it
        [$input_data] | flatten
    }

    if ($docs | is-empty) {
        print "No documents to display"
        return null
    }

    # Read collection name from temp file
    let collection_name = if ("/tmp/mongo_collection_name" | path exists) {
        open /tmp/mongo_collection_name | str trim
    } else {
        ""
    }

    if ($collection_name | is-empty) {
        print --stderr "Error: Collection name is empty"
        return null
    }

    # Check if DATABASE_NAME is set
    let db_name = $env.DATABASE_NAME? | default $env.NAMING_PREFIX?
    if ($db_name | is-empty) {
        print --stderr "Error: DATABASE_NAME or NAMING_PREFIX environment variable is not set"
        return null
    }

    # Extract _id as string (handling both plain string and {$oid: ...} format)
    let extract_id = {|doc|
        let raw_id = ($doc | get _id?)
        if ($raw_id | describe | str starts-with "record") {
            $raw_id | get "$oid"? | default ($raw_id | values | first)
        } else {
            $raw_id | into string
        }
    }

    # Filter to only scalar fields (no nested objects/arrays) for display
    let display_docs = $docs | each {|doc|
        # Skip if not a record
        let doc_type = ($doc | describe)
        if not ($doc_type | str starts-with "record") {
            return null
        }

        # Get clean _id string
        let id = (do $extract_id $doc)

        # Remove __v if it exists
        let filtered_doc = if ("__v" in ($doc | columns)) {
            $doc | reject __v
        } else {
            $doc
        }

        # Filter to scalar fields only and convert to strings
        $filtered_doc
        | items {|key, val|
            let type = ($val | describe)
            if $key == "_id" {
                # Use the clean extracted id
                {key: "_id", val: $id}
            } else if ($type | str starts-with "record") or ($type | str starts-with "list") or ($type | str starts-with "table") {
                null
            } else {
                {key: $key, val: ($val | into string)}
            }
        }
        | where { $in != null }
        | reduce --fold {} {|it, acc| $acc | insert $it.key $it.val}
    } | where { $in != null }

    # Use nushell's table command to format, then pipe to fzf
    # Save to temp file to avoid pipe issues with external commands
    let tmp_table = "/tmp/nu_mongo_select_table.txt"
    $display_docs | table | save --force $tmp_table

    let selected = (open $tmp_table --raw | fzf --ansi --multi --header-lines=2 --prompt="Select Records (Tab to mark): " --layout=reverse | str trim)

    if ($selected | is-empty) {
        rm -f $tmp_table
        return null
    }

    # Extract _ids from selected lines - find the _id column value
    # nushell table format: │ # │ _id │ ... so _id is in column index 2
    let ids = $selected | lines | each {|line|
        # Split by │ and get the _id column (index 2, after # column)
        $line | split row "│" | get 2? | default "" | str trim
    } | where {$in | is-not-empty}

    rm -f $tmp_table

    if ($ids | is-empty) {
        return null
    }

    # Return the selection result
    {
        ids: $ids
        collection_name: $collection_name
        db_name: $db_name
    }
}

null
