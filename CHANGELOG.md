# Changelog

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
