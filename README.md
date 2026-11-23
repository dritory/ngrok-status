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
sudo cp ngrok-status /usr/local/bin/
```

## Setup

```bash
ngrok-status config set api_key <your-ngrok-api-key>
```

Get your API key from https://dashboard.ngrok.com/api-keys

## Usage

```bash
ngrok-status              # launch the TUI
ngrok-status config get   # show current config
ngrok-status config set refresh_interval 10
ngrok-status config set ssh_user pi
ngrok-status config set alias_strip_prefix bv-   # "bv-krikkand" -> ssh krikkand
```

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
| `q` | Quit |
