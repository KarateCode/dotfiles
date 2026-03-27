#!/usr/bin/env nu
# Source environment variables from a .sh file containing 'export VAR=value' lines
# Usage: source source_sh_exports.nu /path/to/env.sh
#    or: use source_sh_exports.nu *; load-sh-exports /path/to/env.sh

# Load exports from a shell file into the current environment
def --env load-sh-exports [file: path] {
    open $file
    | lines
    | where { $in | str trim | str starts-with 'export ' }
    | each { |line|
        # Remove 'export ' prefix
        let assignment = $line | str trim | str replace 'export ' ''

        # Split on first '=' only (value might contain '=')
        let eq_index = $assignment | str index-of '='
        let name = $assignment | str substring 0..<$eq_index
        let value = $assignment | str substring ($eq_index + 1)..

        # Strip surrounding quotes (single or double)
        let clean_value = $value | str replace -r "^[\"']" ''
            | str replace -r "[\"']$" ''

        { name: $name, value: $clean_value }
    }
    | reduce --fold {} { |it, acc| $acc | insert $it.name $it.value }
    | load-env

    print $"Loaded environment from ($file)"
}

# "sanity check"
# When run directly with an argument
# def --env main [file: path] {
#     load-sh-exports $file
# }
