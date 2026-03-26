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
```

### Keyboard shortcuts

| Key | Action |
|-----|--------|
| `↑`/`↓` or `j`/`k` | Navigate rows |
| `c` | Copy selected address to clipboard |
| `s` | Copy SSH command to clipboard |
| `q` | Quit |
