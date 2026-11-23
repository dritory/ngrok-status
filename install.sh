#!/usr/bin/env bash
# Installs or updates ngrok-status:
#   curl -fsSL https://raw.githubusercontent.com/dritory/ngrok-status/main/install.sh | bash
#
# NGROK_STATUS_INSTALL_DIR overrides where the script goes.
set -euo pipefail

RAW_BASE="${NGROK_STATUS_RAW_BASE:-https://raw.githubusercontent.com/dritory/ngrok-status/main}"

say() { printf '%s\n' "$*"; }
fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }

# Prints the command that installs the given packages on this system, if we know it.
install_hint() {
    if command -v apt-get &>/dev/null; then echo "sudo apt install $*"
    elif command -v dnf &>/dev/null; then echo "sudo dnf install $*"
    elif command -v pacman &>/dev/null; then echo "sudo pacman -S $*"
    elif command -v zypper &>/dev/null; then echo "sudo zypper install $*"
    elif command -v apk &>/dev/null; then echo "sudo apk add $*"
    elif command -v brew &>/dev/null; then echo "brew install $*"
    fi
}

# Everything runs from main, which is only called on the last line, so that a
# download that was cut off halfway does nothing instead of half of the work.
main() {
    command -v curl &>/dev/null || fail "curl is required."

    # An existing install is replaced where it is, so that there is never a
    # second copy further down the PATH that shadows the new one, or is shadowed by it.
    local dir="${NGROK_STATUS_INSTALL_DIR:-}"
    local existing
    existing="$(command -v ngrok-status 2>/dev/null || true)"
    if [[ -z "$dir" && -n "$existing" ]]; then
        if [[ -L "$existing" ]]; then
            local target
            target="$(readlink -f "$existing" 2>/dev/null || readlink "$existing")"
            say "ngrok-status at ${existing} is a symlink to ${target}."
            say "It is not replaced. Update that copy instead (for a git checkout: git pull)."
            exit 0
        fi
        dir="$(dirname "$existing")"
    fi
    dir="${dir:-${HOME}/.local/bin}"
    local dest="${dir}/ngrok-status"

    local tmp
    tmp="$(mktemp)"
    trap 'rm -f "${tmp:-}"' EXIT
    curl -fsSL --max-time 30 "${RAW_BASE}/ngrok-status" -o "$tmp" \
        || fail "could not download ${RAW_BASE}/ngrok-status"
    [[ "$(head -c 2 "$tmp")" == "#!" ]] && bash -n "$tmp" 2>/dev/null \
        || fail "the download does not look like the ngrok-status script."

    local old="" new
    if [[ -x "$dest" ]]; then
        # 0.1.0 had no version line
        old="$(sed -n 's/^VERSION="\(.*\)"$/\1/p' "$dest" | head -n 1)"
        old="${old:-0.1.0}"
    fi
    new="$(sed -n 's/^VERSION="\(.*\)"$/\1/p' "$tmp" | head -n 1)"

    # install replaces the file instead of writing into it, which matters when
    # the old script is the one running this update
    if mkdir -p "$dir" 2>/dev/null && [[ -w "$dir" ]]; then
        install -m 755 "$tmp" "$dest"
    else
        say "${dir} is not writable, so this step needs sudo."
        sudo mkdir -p "$dir"
        sudo install -m 755 "$tmp" "$dest"
    fi

    if [[ -n "$old" && "$old" != "$new" ]]; then
        say "Updated ngrok-status ${old} -> ${new} at ${dest}"
    elif [[ -n "$old" ]]; then
        say "ngrok-status ${new} is already the latest version (${dest})"
    else
        say "Installed ngrok-status ${new:-} at ${dest}"
    fi

    case ":${PATH}:" in
        *":${dir}:"*) ;;
        *)
            say ""
            say "${dir} is not on your PATH. Add this line to your shell profile:"
            say "  export PATH=\"${dir}:\$PATH\""
            ;;
    esac

    local missing=() cmd
    for cmd in jq tput; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if (( ${#missing[@]} )); then
        local pkgs="${missing[*]}"
        pkgs="${pkgs/tput/ncurses-bin}"
        say ""
        say "Missing: ${missing[*]}. Install with:"
        say "  $(install_hint "$pkgs" || true)"
    fi
    if ! command -v wl-copy &>/dev/null && ! command -v xclip &>/dev/null \
        && ! command -v xsel &>/dev/null && ! command -v pbcopy &>/dev/null; then
        say ""
        say "Optional: the copy shortcuts need a clipboard tool, for example:"
        say "  $(install_hint xclip || true)"
    fi

    if [[ ! -f "${HOME}/.config/ngrok-status/config" && -z "${NGROK_API_KEY:-}" ]]; then
        say ""
        say "Next, set your API key (from https://dashboard.ngrok.com/api-keys):"
        say "  ngrok-status config set api_key <your-ngrok-api-key>"
    fi
}

main "$@"
