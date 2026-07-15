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

def --env startMongoSession [] {
    printf "\e]11;#0b2912\a"

    # Enable autopairs for mongo work (cursor ends up between the pairs)
    # Note: some keycodes and values need quoting to avoid parser issues
    let curly_pair = (char --unicode "007b") + (char --unicode "007d")

    $env.config.keybindings = ($env.config.keybindings | append [
        # Parentheses () - bind directly to the ( character
        {
            name: autopair_paren
            modifier: none
            keycode: "char_("
            mode: [emacs, vi_insert]
            event: [
                { edit: InsertString, value: '()' }
                { edit: MoveLeft }
            ]
        }
        # Curly braces {} - bind directly to the { character
        {
            name: autopair_brace
            modifier: none
            keycode: "char_{"
            mode: [emacs, vi_insert]
            event: [
                { edit: InsertString, value: $curly_pair }
                { edit: MoveLeft }
            ]
        }
        # Square brackets []
        {
            name: autopair_bracket
            modifier: none
            keycode: "char_["
            mode: [emacs, vi_insert]
            event: [
                { edit: InsertString, value: '[]' }
                { edit: MoveLeft }
            ]
        }
        # Single quotes ''
        {
            name: autopair_single_quote
            modifier: none
            keycode: "char_'"
            mode: [emacs, vi_insert]
            event: [
                { edit: InsertString, value: "''" }
                { edit: MoveLeft }
            ]
        }
        # Double quotes "" - bind directly to the " character
        {
            name: autopair_double_quote
            modifier: none
            keycode: 'char_"'
            mode: [emacs, vi_insert]
            event: [
                { edit: InsertString, value: '""' }
                { edit: MoveLeft }
            ]
        }
    ])

    tmuxinator mongo
}

def startSecondary [] {
    printf "\e]11;#330b0b\a"
    tmuxinator secondary
}
