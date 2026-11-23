# Changelog

## 0.4.0 — 2026-11-23

### Added

- A first-run setup. Without an API key, the tool now asks for one, checks it with ngrok before saving it, and offers the ssh user and alias prefix. It suggests a prefix when most of your addresses share one. `ngrok-status setup` runs it again.
- A settings screen in the TUI, opened with `e`. It lists every setting with its value and an explanation, and a change takes effect without a restart. A new API key is checked with ngrok before it is saved.
- `ngrok-status config unset <key>`.
- `tests/config.sh`, which covers reading and writing the config file, including files written by older versions.

### Security

- The config file is no longer run as a bash script. It is read as plain `key="value"` lines, so nothing in it can be executed.
- The config file is only readable by you. Older versions created it readable by every user on the machine, although it holds the API key. An existing file is tightened the first time 0.4.0 reads it.
- The API key is no longer passed on curl's command line, where other users on the machine could see it in the process list.
- `config set` checks its input. It used to paste the key and the value into a sed command and into the file unescaped, so some characters corrupted the file.

### Changed

- `config set` rejects unknown keys and invalid values, such as a refresh interval that is not a number. Values cannot contain `$`, backticks, quotes or backslashes.
- `config get` lists every setting, including the ones that are at their default.
- The config file is written to a temporary file and renamed into place, so an interrupted write cannot leave half a file. Lines that the tool does not understand, such as comments, are kept.

### Upgrading

- An existing config file needs no changes and is not rewritten. Lines are read the way bash read them, so a comment after a value still works. A file edited by 0.4.0 can still be read by older versions.
- Shell code in the config file (for example `api_key=$(pass show ngrok)`) is no longer run. The tool reports such a line and ignores it, and the setup screen says so before it asks for a key. Use the `NGROK_API_KEY` environment variable for that.
- A path that starts with `~` is stored as the full path, because older versions do not expand it.

### Fixed

- The bar at the top of the screen was a few columns short of the terminal width.

## 0.3.1 — 2026-11-23

### Fixed

- The header said "refreshed never" for a moment at startup, before the first fetch had finished. It now leaves the refresh time out until there is one.

This is also the first release published after the update check went in, so it is the first one that a running 0.3.0 will announce.

## 0.3.0 — 2026-11-23

### Added

- A one-line installer: `curl -fsSL https://raw.githubusercontent.com/dritory/ngrok-status/main/install.sh | bash`. It installs to `~/.local/bin` without sudo, or replaces an existing copy where it is, and reports missing dependencies.
- `ngrok-status update`, which runs the installer over the current copy.
- The TUI checks for a newer version at startup and every 6 hours after that, and shows a notice under the header that says how to update. `ngrok-status version` reports it as well.
- Config key `check_updates`, to turn the check off.

## 0.2.0 — 2026-11-23

### Added

- `a` adds the selected address to the ssh config, or updates it, so that you can run `ssh <alias>`. An existing `Host` block keeps everything except `HostName` and `Port`, and the previous file is kept as `~/.ssh/config.ngrok-status.bak`.
- An SSH column that shows which alias points at each address, and marks an alias as `(stale)` when it points somewhere else.
- Config keys `alias_strip_prefix` and `ssh_config`.
- `PgUp`/`PgDn`, `Home`/`End` and `g`/`G` for moving through long lists.
- `ngrok-status version`.

### Fixed

- The list no longer breaks when there are more addresses than the terminal has rows. It now scrolls to follow the selection, and rows are cut to the terminal width.
- The TUI no longer freezes during a refresh, because the API requests run in the background.
- Scrolling keeps up with a held key, because a redraw no longer starts any subprocesses.
- A keypress could get lost when it arrived just as a read timed out.
- Status messages printed their colour codes literally.
- A missing config file made the tool exit silently instead of explaining how to set the API key.

### Changed

- The "refreshed" time in the header is the time of the last fetch, not of the last redraw.
- The refresh interval counts from the end of a fetch.

## 0.1.0 — 2026-03-26

- First version: a watch-style TUI that lists reserved ngrok TCP addresses and whether they are connected, with shortcuts to copy the address or an ssh command.
