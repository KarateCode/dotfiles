# Keybindings for the snippets engine
# Add these to your $env.config.keybindings in config.nu

def get-snippet-keybindings [] {
    [
        # Ctrl+Space - expand abbreviation (doesn't interfere with pasting)
        {
            name: snippet_expand
            modifier: control
            keycode: space
            mode: [emacs vi_insert]
            event: {
                send: executehostcommand
                cmd: "handle-expand"
            }
        }
        # Tab - jump to next placeholder
        {
            name: snippet_tab_jump
            modifier: none
            keycode: tab
            mode: [emacs vi_insert]
            event: {
                send: executehostcommand
                cmd: "jump-to-placeholder"
            }
        }
        # Alt+, - MongoDB field picker
        {
            name: mongo_field_picker
            modifier: alt
            keycode: char_y
            # keycode: char_,
            mode: [emacs vi_insert]
            event: {
                send: executehostcommand
                cmd: "mongo-field-picker"
            }
        }
        # Alt+t - MongoDB table picker
        {
            name: mongo_table_picker
            modifier: alt
            keycode: char_t
            mode: [emacs vi_insert]
            event: {
                send: executehostcommand
                cmd: "mongo-table-picker"
            }
        }
    ]
}

null
