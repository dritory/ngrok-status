#!/usr/bin/env bash
# Tests for reading and writing the config file, including files written by
# versions before 0.4.0. Runs against a throwaway HOME, so it never touches
# your real config:
#   tests/config.sh
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tool="${here}/../ngrok-status"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

export HOME="${work}/home"
export NGROK_STATUS_RAW_BASE="file://${work}/nowhere"  # no update checks over the network
unset NGROK_API_KEY api_key refresh_interval ssh_user ssh_config alias_strip_prefix check_updates
cfg="${HOME}/.config/ngrok-status/config"

pass=0
fail=0
check() {  # check <description> <expected> <actual>
    if [[ "$2" == "$3" ]]; then
        (( pass++ ))
    else
        (( fail++ ))
        printf 'FAIL: %s\n  expected: %s\n  actual:   %s\n' "$1" "$2" "$3"
    fi
}
fresh() {  # fresh [config file contents]
    rm -rf "$HOME"
    mkdir -p "$(dirname "$cfg")"
    if (( $# )); then printf '%s' "$1" > "$cfg"; fi
}
get() { "$tool" config get "$1" 2>/dev/null; }
mode() { stat -c %a "$1" 2>/dev/null || stat -f %Lp "$1"; }

# --- files as old versions wrote them ---

fresh $'api_key=abcd1234efgh5678\nssh_user="chippy"\nalias_strip_prefix="bv-"\n'
chmod 664 "$cfg"
before="$(cat "$cfg")"
check "unquoted value from 0.1.0"        "api_key = abcd***5678"      "$(get api_key)"
check "double-quoted value"              "ssh_user = chippy"          "$(get ssh_user)"
check "prefix with a dash"               "alias_strip_prefix = bv-"   "$(get alias_strip_prefix)"
check "missing key shows its default"    "refresh_interval = 5 (default)" "$(get refresh_interval)"
check "reading tightens the permissions" "600"                        "$(mode "$cfg")"
check "reading does not rewrite the file" "$before"                   "$(cat "$cfg")"

fresh $'# my settings\n\nexport api_key=\'k-single\'\n  refresh_interval = 30  \r\nssh_user=a\nssh_user=b\n'
check "export prefix and single quotes"  "api_key = ***"              "$(get api_key)"
check "spaces around = and a CR"         "refresh_interval = 30"      "$(get refresh_interval)"
check "the last duplicate wins, as in bash" "ssh_user = b"            "$(get ssh_user)"

fresh 'api_key=noeol'
check "file without a final newline"     "api_key = ***"              "$(get api_key)"

# --- nothing in the file is ever executed ---

fresh $'api_key="$(touch '"${work}"$'/pwned1)"\nssh_user=`touch '"${work}"$'/pwned2`\ntouch '"${work}"$'/pwned3\nalias_strip_prefix="ok-"\nrefresh_interval=$((1+1))\n'
out="$("$tool" config get 2>&1)"
check "command substitution is not run"  "no"  "$([[ -e ${work}/pwned1 ]] && echo yes || echo no)"
check "backticks are not run"            "no"  "$([[ -e ${work}/pwned2 ]] && echo yes || echo no)"
check "a bare command is not run"        "no"  "$([[ -e ${work}/pwned3 ]] && echo yes || echo no)"
check "shell code is reported"           "yes" "$([[ $out == *"looks like shell code"* ]] && echo yes || echo no)"
check "a bare command is reported"       "yes" "$([[ $out == *"not a key=value setting"* ]] && echo yes || echo no)"
check "the key with shell code is unset" "api_key = <unset>"          "$(get api_key)"
check "plain lines next to it still load" "alias_strip_prefix = ok-"  "$(get alias_strip_prefix)"
"$tool" version >/dev/null 2>&1
check "other commands do not run it either" "no" "$([[ -e ${work}/pwned1 || -e ${work}/pwned2 || -e ${work}/pwned3 ]] && echo yes || echo no)"

fresh $'refresh_interval=abc\ncheck_updates=maybe\nbogus_key=1\n'
out="$("$tool" config get 2>&1)"
check "a bad interval falls back to 5"   "yes" "$([[ $out == *"refresh_interval = 5"* ]] && echo yes || echo no)"
check "a bad boolean falls back to true" "yes" "$([[ $out == *"check_updates = true"* ]] && echo yes || echo no)"
check "an unknown key is reported"       "yes" "$([[ $out == *"unknown key 'bogus_key'"* ]] && echo yes || echo no)"

# --- writing ---

fresh $'# keep me\napi_key=old\nssh_user="a"\nfuture_key="kept"\nssh_user="b"\n'
"$tool" config set ssh_user pi >/dev/null
check "set replaces the line, drops repeats, keeps the rest" \
    $'# keep me\napi_key=old\nssh_user="pi"\nfuture_key="kept"' "$(cat "$cfg")"
"$tool" config set refresh_interval 10 >/dev/null
check "set appends a new key"            'refresh_interval="10"'      "$(tail -n 1 "$cfg")"
"$tool" config unset ssh_user >/dev/null
check "unset removes the line"           "ssh_user = <unset>"         "$(get ssh_user)"
check "unset keeps the other lines"      $'# keep me\napi_key=old\nfuture_key="kept"\nrefresh_interval="10"' "$(cat "$cfg")"
check "no temp files are left behind"    "config"                     "$(ls -A "$(dirname "$cfg")")"

rm -rf "$HOME"
"$tool" config set api_key 'abcd1234efgh5678' >/dev/null
check "set creates the file"             "api_key = abcd***5678"      "$(get api_key)"
check "a new file is private"            "600"                        "$(mode "$cfg")"

# a 0.4.0 file must still work for an old version, which runs it as bash
check "old versions can still read the file" "abcd1234efgh5678" "$(bash -c 'source "$1"; echo "$api_key"' _ "$cfg")"

fresh 'api_key=keep'
for bad in 'a$b' 'a`b' 'a"b' "a'b" 'a\b' $'a\nb'; do
    "$tool" config set alias_strip_prefix "$bad" >/dev/null 2>&1
    rc=$?
    check "set rejects $(printf '%q' "$bad")" "1" "$rc"
done
"$tool" config set refresh_interval 0 >/dev/null 2>&1;      check "set rejects interval 0"       "1" "$?"
"$tool" config set refresh_interval 5s >/dev/null 2>&1;     check "set rejects interval 5s"      "1" "$?"
"$tool" config set check_updates no >/dev/null 2>&1;        check "set rejects a non-boolean"    "1" "$?"
"$tool" config set api_key 'two words' >/dev/null 2>&1;     check "set rejects a key with spaces" "1" "$?"
"$tool" config set nonsense 1 >/dev/null 2>&1;              check "set rejects an unknown key"   "1" "$?"
"$tool" config set 'x;touch '"${work}"'/pwned4' 1 >/dev/null 2>&1
check "a hostile key name is not run"    "no"  "$([[ -e ${work}/pwned4 ]] && echo yes || echo no)"
check "rejected values leave the file alone" "api_key=keep"           "$(cat "$cfg")"

"$tool" config set ssh_config '/tmp/my ssh/config' >/dev/null
check "a path with a space round-trips"  "ssh_config = /tmp/my ssh/config" "$(get ssh_config)"

# a symlinked config (dotfiles) stays a symlink
fresh
mkdir -p "${work}/dotfiles"
printf 'api_key=linked\n' > "${work}/dotfiles/ngrok"
ln -s "${work}/dotfiles/ngrok" "$cfg"
"$tool" config set ssh_user pi >/dev/null
check "a symlinked config stays a symlink" "yes" "$([[ -L $cfg ]] && echo yes || echo no)"
check "the write lands in the target"    $'api_key=linked\nssh_user="pi"' "$(cat "${work}/dotfiles/ngrok")"

# --- without a key and without a terminal ---

rm -rf "$HOME"
out="$("$tool" watch 2>&1 < /dev/null)"
check "no key and no terminal exits with 1" "1" "$?"
check "and points at setup"              "yes" "$([[ $out == *"ngrok-status setup"* ]] && echo yes || echo no)"

echo "${pass} passed, ${fail} failed"
(( fail == 0 ))
