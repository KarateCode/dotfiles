#!/usr/bin/env nu
# Select and update MongoDB documents using fzf
# Usage: ms 'Client.find({})' | updateMany
#
# Presents documents in a table with fzf multi-select.
# Selected documents will be updated with user-provided $set values.

def updateMany [] {
    let selection = ($in | mongo-select)

    if ($selection | is-empty) {
        return
    }

    let ids = $selection.ids
    let collection_name = $selection.collection_name
    let db_name = $selection.db_name

    # Build the ObjectId array for MongoDB
    let ids_array = $ids | each {|id| $"ObjectId\(\"($id)\"\)"} | str join ","

    # Prompt user for the $set clause with instructions
    print $"\n(ansi cyan){(ansi yellow)$set(ansi cyan): { (ansi green)your_update_clause(ansi cyan) }}(ansi reset)"
    print $"(ansi dark_gray)Where (ansi green)your_update_clause(ansi reset)(ansi dark_gray) is what you type at the prompt(ansi reset)\n"

    let prompt = $"(ansi purple)your_update_clause(ansi green):(ansi reset) "
    let user_input = (input $prompt | str trim)

    if ($user_input | is-empty) {
        print "No update provided, aborting."
        return
    }

    let update_eval = "db.getCollection('" + $collection_name + "').updateMany({ _id: { $in: [" + $ids_array + "] } }, { $set: { " + $user_input + " } }).modifiedCount"

    let result = (mongosh --quiet $"mongodb://localhost:27017/($db_name)" --eval $update_eval | str trim)

    print $"\n  (ansi green)Updated ($result) document\(s\)(ansi reset)"
}

# For running as a standalone script
def main [] {
    $in | updateMany
}

null
