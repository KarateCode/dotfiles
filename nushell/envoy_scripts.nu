#!/usr/bin/env nu

def adminLogin [] {
    # Check if DATABASE_NAME is set
    let db_name = $env.DATABASE_NAME? | default $env.NAMING_PREFIX?
    if ($db_name | is-empty) {
        print --stderr "Error: DATABASE_NAME or NAMING_PREFIX environment variable is not set"
        return
    }

    let mongosh_eval = "const doc = db.Login.findOne({email: 'triage@envoyplatform.com'}); if (doc) { printjson(doc); }"
    mongosh --quiet $"mongodb://localhost:27017/($db_name)" --eval $mongosh_eval | from json
}

def adminUser [] {
    # Check if DATABASE_NAME is set
    let db_name = $env.DATABASE_NAME? | default $env.NAMING_PREFIX?
    if ($db_name | is-empty) {
        print --stderr "Error: DATABASE_NAME or NAMING_PREFIX environment variable is not set"
        return
    }

    let mongosh_eval = "const doc = db.Login.findOne({email: 'triage@envoyplatform.com'}); if (doc) { printjson(doc); }"
    let loginId = (mongosh --quiet $"mongodb://localhost:27017/($db_name)" --eval $mongosh_eval) | from json | get _id | str replace -r ',$' ''

    let mongosh_user_eval = "const doc = db.User.findOne({login: " + $loginId + ", name: 'Administrator'}); if (doc) { printjson(doc); }"
    mongosh --quiet $"mongodb://localhost:27017/($db_name)" --eval $mongosh_user_eval | from json
}

def startMongoSession [] {
    printf "\e]11;#0b2912\a"
    tmuxinator mongo
}
