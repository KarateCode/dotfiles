# Keybindings for the snippets engine
# Add these to your $env.config.keybindings in config.nu

def get-snippet-keybindings [] {
    [
        # Space - expand abbreviation or insert space
        {
            name: snippet_space
            modifier: none
            keycode: space
            mode: [emacs vi_insert]
            event: {
                send: executehostcommand
                cmd: "handle-space"
            }
        }
        # Dot - expand abbreviation or insert dot
        {
            name: snippet_dot
            modifier: none
            keycode: char_.
            mode: [emacs vi_insert]
            event: {
                send: executehostcommand
                cmd: "handle-dot"
            }
        }
        # Slash - expand abbreviation or insert slash
        {
            name: snippet_slash
            modifier: none
            keycode: char_/
            mode: [emacs vi_insert]
            event: {
                send: executehostcommand
                cmd: "handle-slash"
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
