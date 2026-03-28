# Nushell snippets engine
# Provides abbreviation expansion with placeholder jumping
#
# Usage: Source this file in config.nu, then use:
#   - Space/dot/slash after an abbreviation to expand it
#   - Tab to jump to the next % placeholder
#   - Alt+, for MongoDB field picker (requires tmux)
#   - Alt+t for MongoDB table names

source ~/dotfiles/nushell/snippets/snippets.nu

# Expand abbreviation at cursor position
def expand-abbr [] {
    let line = (commandline)
    let cursor = (commandline get-cursor)
    let before_cursor = ($line | str substring 0..<$cursor)

    # Extract the last word before cursor
    let word = ($before_cursor | split row ' ' | last | split row '.' | last | split row '/' | last)

    let snippets = (get-snippets)

    if ($word in $snippets) {
        let expansion = ($snippets | get $word)
        let word_len = ($word | str length)
        let prefix = ($before_cursor | str substring 0..<($cursor - $word_len))
        let after_cursor = ($line | str substring $cursor..)

        let new_line = $"($prefix)($expansion)($after_cursor)"
        commandline edit --replace $new_line

        # Find first placeholder and position cursor there
        let placeholder_pos = ($new_line | str index-of '%')
        if $placeholder_pos >= 0 {
            commandline set-cursor $placeholder_pos
        }
        true
    } else {
        false
    }
}

# Jump to next placeholder or perform default tab action
def jump-to-placeholder [] {
    let line = (commandline)
    let cursor = (commandline get-cursor)

    # Look for % after current cursor position
    let after_cursor = ($line | str substring $cursor..)
    let placeholder_pos = ($after_cursor | str index-of '%')

    if $placeholder_pos >= 0 {
        # Remove the % and position cursor there
        let before = ($line | str substring 0..($cursor + $placeholder_pos))
        let after = ($line | str substring ($cursor + $placeholder_pos + 1)..)
        commandline edit --replace $"($before)($after)"
        commandline set-cursor ($cursor + $placeholder_pos)
    }
}

# Handler for space key - expand or insert space
def handle-space [] {
    if (expand-abbr) {
        # Expansion happened - don't insert space if we landed on a placeholder
        let line = (commandline)
        let cursor = (commandline get-cursor)
        let char_at_cursor = ($line | str substring $cursor..($cursor + 1))
        # Don't insert space if cursor is at a placeholder
        if $char_at_cursor != '%' {
            commandline edit --insert ' '
        }
    } else {
        commandline edit --insert ' '
    }
}

# Handler for dot key
def handle-dot [] {
    if (expand-abbr) {
        # Expansion happened - don't insert dot if we landed on a placeholder
        let line = (commandline)
        let cursor = (commandline get-cursor)
        let char_at_cursor = ($line | str substring $cursor..($cursor + 1))
        if $char_at_cursor != '%' {
            commandline edit --insert '.'
        }
    } else {
        commandline edit --insert '.'
    }
}

# Handler for slash key
def handle-slash [] {
    if (expand-abbr) {
        # Expansion happened - don't insert slash if we landed on a placeholder
        let line = (commandline)
        let cursor = (commandline get-cursor)
        let char_at_cursor = ($line | str substring $cursor..($cursor + 1))
        if $char_at_cursor != '%' {
            commandline edit --insert '/'
        }
    } else {
        commandline edit --insert '/'
    }
}

# MongoDB field picker using fzf in tmux popup
def mongo-field-picker [] {
    let line = (commandline)

    # Parse collection name from command line (e.g., Client.find(), Product.aggregate())
    let parsed = ($line | parse --regex '([A-Z][a-zA-Z]*)\.(find|findOne|aggregate|count|distinct)')
    if ($parsed | is-empty) {
        print "Could not parse collection name from command line"
        return
    }
    let collection = ($parsed | get capture0 | first)

    let tmp_file = "/tmp/fzf_nu_popup_selection"
    let tmp_collection = "/tmp/fzf_nu_popup_collection"
    let tmp_script = "/tmp/fzf_nu_popup_script.sh"

    $collection | save --force $tmp_collection

    # Build the popup script
    let db_name = $env.DATABASE_NAME? | default $env.NAMING_PREFIX?
    if ($db_name | is-empty) {
        print "DATABASE_NAME or NAMING_PREFIX not set"
        return
    }

    # Write the bash script to a file to avoid escaping hell
    # Build mongosh line by concatenating parts
    let mongosh_line = "mongosh \"" + $db_name + "\" --quiet --eval \"JSON.stringify(db.getCollection('$collection').findOne())\" |"
    let jq_line = "jq -r '. | (with_entries(select(.value | type != \"object\" and type != \"array\"))) | keys - [\"_id\"] | .[]' |"
    let fzf_line = "fzf --multi --prompt='Select fields: ' > /tmp/fzf_nu_popup_selection"

    let script_lines = [
        "#!/bin/bash"
        "collection=$(< /tmp/fzf_nu_popup_collection)"
        $mongosh_line
        $jq_line
        $fzf_line
    ]
    $script_lines | str join "\n" | save --force $tmp_script
    ^chmod +x $tmp_script

    ^tmux display-popup -E -w 80% -h 60% $tmp_script

    # Read selection and insert at cursor
    if ($tmp_file | path exists) {
        let selection = (open $tmp_file | lines | where { $in | str trim | is-not-empty } | str join " ")
        if ($selection | is-not-empty) {
            commandline edit --insert $selection
        }
        rm -f $tmp_file
    }
    rm -f $tmp_collection
    rm -f $tmp_script
}

# MongoDB table names picker
def mongo-table-picker [] {
    let db_name = $env.DATABASE_NAME? | default $env.NAMING_PREFIX?
    if ($db_name | is-empty) {
        print "DATABASE_NAME or NAMING_PREFIX not set"
        return
    }

    let selection = (ms "getCollectionNames()" | get 0? | to text | fzf | str trim)
    if ($selection | is-not-empty) {
        commandline edit --insert $selection
    }
}

null
