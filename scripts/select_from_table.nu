#!/usr/bin/env nu
# Select and delete MongoDB documents using fzf
# Usage: ms 'Client.find({})' | deleteMany
#
# Presents documents in a table with fzf multi-select.
# Selected documents will be deleted from the collection.

def deleteMany [] {
    let selection = ($in | mongo-select)

    if ($selection | is-empty) {
        return
    }

    let ids = $selection.ids
    let collection_name = $selection.collection_name
    let db_name = $selection.db_name

    # Build the ObjectId array for MongoDB
    let ids_array = $ids | each {|id| $"ObjectId\(\"($id)\"\)"} | str join ","

    let delete_eval = "db.getCollection('" + $collection_name + "').deleteMany({ _id: { $in: [" + $ids_array + "] } }).deletedCount"

    let result = (mongosh --quiet $"mongodb://localhost:27017/($db_name)" --eval $delete_eval | str trim)

    print $"\n  (ansi green)Deleted ($result) document\(s\)(ansi reset)"
}

# For running as a standalone script
def main [] {
    $in | deleteMany
}

null
