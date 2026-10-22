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
- `aerospace.toml` → `~/.aerospace.toml` (macOS) - window manager and global hotkeys
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
- **Always runs in terminal** (never GUI) - connects via Ghostty
- Runs as daemon via `van` alias
- Uses `--init-directory` flag on macOS (on Linux `~/.config/emacs` is already
  the default, so the flag is unnecessary there)
- **After modifying any emacs config**, bounce the daemon so changes take
  effect — use the `eb` alias, which picks the right mechanism per platform:

  | platform | mechanism |
  |---|---|
  | Linux (omarchy) | `systemctl --user restart emacs` |
  | macOS | `pkill -9 emacs; emacs --init-directory="$HOME/.config/emacs" --daemon` |

  Do **not** use the macOS command on omarchy. systemd owns the daemon there
  (`/usr/lib/systemd/user/emacs.service`, `ExecStart=/usr/bin/emacs
  --fg-daemon`) with `Restart=on-failure`, so `pkill -9` is treated as a
  failure and systemd revives it instantly — the manual `emacs --daemon` then
  races a second daemon onto the same socket. It also bypasses the drop-in at
  `~/.config/systemd/user/emacs.service.d/wayland-env.conf`.

- `emacsclient -e '(load "...")'` is NOT a substitute for bouncing. It picks up
  most edits, but never exercises the startup path (`init.el` →
  `after-init-hook` → `init_omarchy.el`), so it can mask an init that is
  broken for every real restart.

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

## Git

**Git is the user's job. Do not run it, and do not offer to.**

- Never `git add`, `commit`, `push`, `checkout`, `stash`, `reset`, `rebase`, or
  `merge` — not even when a change is obviously finished, and not even when
  asked "are we done?". Leave the working tree dirty and say so.
- Do not end a turn by offering to stage or commit, and do not close with a
  summary of which files were changed or added. `git status` already shows the
  user that; repeating it is noise.
- Read-only inspection (`git status`, `git log`, `git diff`) is fine and often
  useful — e.g. confirming an edit landed, or checking whether a file is
  tracked before treating it as disposable. Use it to inform your own work, not
  to narrate back.

## Scripts (additional notes)

- `make-ghostty-256-terminfo.sh` builds the `xterm-ghostty-256` terminfo into
  `~/.terminfo`, which is OUTSIDE this repo. `emacs-editor.sh` calls it
  automatically when the entry is missing or stale, so a fresh clone heals
  itself. Read that script's header before touching Emacs terminal colours.

## Style

- No trailing spaces in code or shell scripts
- Match surrounding code style and patterns
- Comments only where behavior isn't obvious from code
