
use std "path add"
path add "~/.cargo/bin"

# fnm auto-switching: automatically switch Node version when entering a directory
# with .node-version or .nvmrc file
# $env.config.hooks.env_change.PWD = (
#     $env.config.hooks.env_change.PWD | default [] | append {||
#         if ([.node-version .nvmrc] | any { |f| ($f | path exists) }) {
#             ^fnm use --silent-if-unchanged
#         }
#     }
# )

$env.config.show_banner = false
$env.config.history.file_format = "sqlite"
$env.config.history.isolation = true

# source_sh_exports must come before alias.nu (alias.nu uses load-sh-exports)
source ~/dotfiles/scripts/source_sh_exports.nu
load-sh-exports ~/dotfiles/.sensitive.sh
source ~/dotfiles/scripts/mongo_shell_inline.nu
source ~/dotfiles/scripts/editor.nu
source ~/dotfiles/scripts/mongo_select.nu
source ~/dotfiles/scripts/delete_many.nu
source ~/dotfiles/scripts/update_many.nu
source ~/dotfiles/scripts/rebase_on_develop.nu
source ~/dotfiles/scripts/download_latest.nu
source ~/dotfiles/scripts/npm-test-concurrent.nu
source ~/dotfiles/scripts/gitbd.nu
source ~/dotfiles/scripts/netsuite.nu
source ~/dotfiles/nushell/alias.nu
source ~/dotfiles/nushell/envoy_scripts.nu

# Snippets engine - abbreviation expansion with placeholder jumping
source ~/dotfiles/nushell/snippets/engine.nu
source ~/dotfiles/nushell/snippets/keybindings.nu
$env.config.keybindings = ($env.config.keybindings | append (get-snippet-keybindings))

# fzf keybindings
$env.config.keybindings = ($env.config.keybindings | append [
    {
        name: fzf_history
        modifier: control
        keycode: char_r
        mode: [emacs, vi_normal, vi_insert]
        event: {
            send: executehostcommand
            cmd: "commandline edit --replace (history | get command | reverse | uniq | to text | fzf --height=40% | str trim)"
        }
    }
    {
        name: fzf_files
        modifier: control
        keycode: char_t
        mode: [emacs, vi_normal, vi_insert]
        event: {
            send: executehostcommand
            cmd: "commandline edit --insert (fzf --height=40%)"
        }
    }
])

# Autopairs - enabled when NUSHELL_AUTOPAIRS env var is set (e.g., via tmuxinator pre_window)
if ($env.NUSHELL_AUTOPAIRS? | is-not-empty) {
    let curly_pair = (char --unicode "007b") + (char --unicode "007d")

    $env.config.keybindings = ($env.config.keybindings | append [
        # Parentheses ()
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
        # Curly braces {}
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
        # Double quotes ""
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
}

# Initialize starship prompt
source ~/.cache/starship/init.nu
