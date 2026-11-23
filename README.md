# ngrok-status

Watch-style TUI for monitoring ngrok TCP addresses.

## Dependencies

`curl`, `jq`, `tput` (ncurses) — all standard on most Linux/macOS systems.

For clipboard support (`c` / `s` shortcuts): `xclip`, `xsel`, or `wl-copy` on Linux; `pbcopy` on macOS.

```bash
# Ubuntu/Debian
sudo apt install curl jq xclip
```

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/dritory/ngrok-status/main/install.sh | bash
```

This puts the script in `~/.local/bin`, which needs no sudo. If `ngrok-status` is already installed somewhere else on your PATH, that copy is replaced where it is (with sudo if the directory needs it). The installer also tells you which dependencies are missing and how to install them. Set `NGROK_STATUS_INSTALL_DIR` to choose the directory yourself.

## Update

```bash
ngrok-status update
```

While the TUI runs, it checks now and then whether a newer version has been published, and shows a line under the header when there is one. `ngrok-status version` does the same check. To turn it off, run `ngrok-status config set check_updates false`.

If you work on the tool itself, symlink your checkout instead (`ln -s "$PWD/ngrok-status" ~/.local/bin/ngrok-status`). The installer leaves a symlink alone.

## Setup

```bash
ngrok-status
```

The first time you run it, the tool asks for your ngrok API key, checks it with ngrok, and saves it. You create the key at https://dashboard.ngrok.com/api-keys. Note that it is not the authtoken that the ngrok agent uses. The setup then offers two optional ssh settings. Run `ngrok-status setup` to go through it again.

On a machine without a terminal, use `ngrok-status config set api_key <your-ngrok-api-key>`, or set the `NGROK_API_KEY` environment variable.

## Usage

```bash
ngrok-status              # launch the TUI
ngrok-status config get   # show current config
ngrok-status config set refresh_interval 10
ngrok-status config set ssh_user pi
ngrok-status config set alias_strip_prefix bv-   # "bv-krikkand" -> ssh krikkand
ngrok-status config unset ssh_user               # back to the default
```

### Settings

Press `e` in the TUI to see all settings with their current values. Enter changes the selected one, and the change takes effect right away. Clearing a value puts its default back.

| Key | Default | Meaning |
|-----|---------|---------|
| `api_key` | | Your ngrok API key |
| `refresh_interval` | `5` | Seconds between two fetches of the address list |
| `ssh_user` | | User name for the copied ssh command and for new ssh config entries |
| `ssh_config` | `~/.ssh/config` | The ssh config file that `a` edits |
| `alias_strip_prefix` | | Prefix dropped from a description to suggest a Host alias |
| `check_updates` | `true` | Whether to look for newer versions |

The settings live in `~/.config/ngrok-status/config`, as `key="value"` lines that only you can read. The file is read as data and never run as a script, so a value cannot contain `$`, backticks, quotes or backslashes.

### Upgrading from a version before 0.4.0

There is nothing to do. Your existing config file is read as it is and is not rewritten. The first time 0.4.0 sees the file, it makes it readable by you only, since it holds your API key and older versions left it readable by other users on the machine.

Older versions ran the config file as a bash script. If you had put shell code in it by hand (for example `api_key=$(pass show ngrok)`), that line is now ignored and the tool tells you which line it was, also on the setup screen that appears when the key is the line in question. Use the `NGROK_API_KEY` environment variable for that case.

### ssh config

Press `a` on a row to point a `Host` entry in `~/.ssh/config` at that address, so that you can run `ssh krikkand`. You are asked for the alias, with a suggestion made from the description (lowercased, minus `alias_strip_prefix`). If a `Host` block with that alias already exists, only its `HostName` and `Port` are rewritten; otherwise a new block is appended, with `ssh_user` as `User`. The previous file is kept as `~/.ssh/config.ngrok-status.bak`.

The SSH column shows the alias that currently points at each address, and marks it `(stale)` when the alias exists but points somewhere else. Set `ssh_config` to edit a different file.

### Keyboard shortcuts

| Key | Action |
|-----|--------|
| `↑`/`↓` or `j`/`k` | Navigate rows |
| `PgUp`/`PgDn`, `g`/`G` | Page up/down, jump to first/last row |
| `c` | Copy selected address to clipboard |
| `s` | Copy SSH command to clipboard |
| `a` | Add or update the selected address in the ssh config |
| `e` | Open the settings |
| `q` | Quit |
