# Dotfiles Project

Cross-platform dotfiles for **macOS** and **Linux (omarchy)**. When editing configs or scripts, maintain compatibility with both platforms unless the file is explicitly platform-specific.

## Platform Detection

Scripts should detect the platform and branch accordingly:
```bash
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Linux/omarchy
fi
```

## Config Locations

Use `~/.config/` convention where possible. Many configs are symlinked from this repo into `~/.config/`.

### Symlinked to ~/.config/
- `bat/`
- `gh-dash/config.yml`
- `ghostty/` → `~/Library/Application Support/com.mitchellh.ghostty/config` (macOS)
- `nushell/`
- `sketchybar/`
- `starship/`
- `television/`
- `tmux/tmux.conf`
- `tmuxinator/`
- `workmux/config.yaml`

### Symlinked elsewhere
- `emacs/init.el` → `~/.config/emacs/init.el`
- `aerospace/aerospace.toml` → `~/.aerospace.toml` (macOS)
- `spotify-player/` → `~/.config/spotify-player/`

## Key Tools

### Ghostty Terminal
- macOS config: `ghostty/config_macos`
- Uses `\x1b[N;9z` escape sequences for keybindings (not F-keys)
- Escape sequences pass through tmux user-keys to emacs

### Tmux
- Config: `tmux/tmux.conf`
- Uses user-keys to pass escape sequences to emacs
- Omarchy theme ported from Linux

### Emacs
- Vanilla emacs (not Spacemacs) at `~/.config/emacs/`
- Runs as daemon via `van` alias
- Uses `--init-directory` flag on macOS
- Restart: `pkill -9 emacs; emacs --init-directory="$HOME/.config/emacs" --daemon`

### Workmux
- Manages git worktrees + tmux windows for parallel agent workflows
- `wms` alias: Toggle sidebar (width flag workaround)
- `wmrm` alias: Remove worktree but keep local branch
- `oc` function: Wrapper for `opencode` that auto-registers with workmux sidebar

### OpenCode
- V2 plugin at `.opencode/plugins/workmux-status/` for sidebar status tracking
- Plugin uses `Bun.spawn` for shell commands (not `ctx.$` which is V1 API)
- Full path to binaries required in plugins (PATH not available)

## Scripts

Located in `scripts/`. Should be cross-platform where possible.

- `emacs-editor.sh` - Cross-platform emacs launcher (`van` alias)
- `ding.sh` - Sound notification (afplay on macOS, pw-play on Linux)
- `editor.sh` - MongoDB document editor

## Style

- No trailing spaces in code or shell scripts
- Match surrounding code style and patterns
- Comments only where behavior isn't obvious from code
