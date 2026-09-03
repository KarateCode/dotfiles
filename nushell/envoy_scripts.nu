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

def startSecondary [] {
    printf "\e]11;#330b0b\a"
    tmuxinator secondary
}

def startAntiGravity [] {
    printf "\e]11;#0f172a\a"
    tmuxinator antiGravity
}

def ghd [pr: string] {
    gh dash -c (mktemp --suffix .yml | do { let f = $in; $"prSections: [{title: 'PR #($pr)',
    filters: 'is:pr ($pr)'}]" | save -f $f; $f })
}

def --env spawnEnvoyWeb [] {
    let main_worktree = $"($env.HOME)/code/envoy-web1"

    # Ensure main worktree exists
    if not ($main_worktree | path exists) {
        print --stderr "Error: Main worktree not found at ($main_worktree)"
        return
    }

    cd ~/code

    # Find the next available folder name (starting at 2 since envoy-web1 is the main repo)
    let base_name = "envoy-web"
    let suffix = (2.. | each { |n|
        let name = $"($base_name)($n)"
        if not ($name | path exists) { $n } else { null }
    } | first)
    let folder_name = $"($base_name)($suffix)"

    print $"Creating worktree ($folder_name) from develop..."
    git -C $main_worktree worktree add $"($env.HOME)/code/($folder_name)" develop

    cd $folder_name
    fnm use
    npm run install-dev

    # Create symlinks for claude and opencode config directories
    ln -s ~/code/claude .claude
    ln -s ~/code/claude .opencode
}
