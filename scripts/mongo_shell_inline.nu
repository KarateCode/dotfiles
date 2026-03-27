#!/usr/bin/env nu
# an alias sets this script to `ms1` in alias.sh
# Usage: ms1 'Product.findOne({})'

def main [query: string] {
    # Parse collection name from query (e.g., 'Customer.find({...})' -> 'Customer')
    let collection_name = $query | split row '.' | first

    # Write collection name to a hardcoded temp file (overwrites each time)
    $collection_name | save --force /tmp/mongo_collection_name

    # Build the eval expression
    # If query contains 'find(' or 'aggregate(', it returns a cursor and needs .toArray()
    let eval_expr = if ($query | str contains 'find(') or ($query | str contains 'aggregate(') {
        $"JSON.stringify\(db.($query).toArray\(\)\)"
    } else {
        $"JSON.stringify\(db.($query)\)"
    }

    # Check if SSH tunnel is active on port 27018
    let tunnel_active = (do { lsof -i :27018 } | complete | get exit_code) == 0

    if $tunnel_active {
        # Parse credentials from cached remote URI
        let remote_uri = open $"($env.HOME)/.config/.mongo-remote-uri" | str trim
        let credentials = $remote_uri | parse "mongodb://{creds}@{rest}" | get creds.0

        # Build local connection string
        let local_uri = $"mongodb://($credentials)@localhost:27018/envoy-web?authSource=admin&directConnection=true"

        mongosh $local_uri --quiet --eval $eval_expr
    } else {
        if ($env.NAMING_PREFIX? | is-empty) {
            print --stderr "$env.NAMING_PREFIX not set"
            exit 1
        }

        mongosh $env.NAMING_PREFIX --quiet --eval $eval_expr | from json
    }
}
