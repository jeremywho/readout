#!/usr/bin/env bash
set -euo pipefail
host="${1:?usage: mac-install.sh <host> <version>}"
version="${2:?usage: mac-install.sh <host> <version>}"
ssh "$host" bash -s -- "$version" <<'REMOTE'
set -euo pipefail
version="$1"
fail() {
    echo "$(hostname): $*" >&2
    exit 1
}
work="$(mktemp -d)"
curl -fsSL "https://github.com/jeremywho/readout/releases/download/v$version/Readout-$version.zip" \
    -o "$work/Readout.zip" || fail "could not download Readout $version"
ditto -x -k "$work/Readout.zip" "$work/unpacked"
app="$work/unpacked/Readout.app"
found="$(defaults read "$app/Contents/Info.plist" CFBundleShortVersionString)"
[ "$found" = "$version" ] || fail "archive holds version $found, not $version"
codesign --verify --deep --strict "$app" || fail "signature does not verify"
assessment="$(spctl -a -t exec -vv "$app" 2>&1)" || fail "Gatekeeper rejects the build: $assessment"
grep -q "source=Notarized Developer ID" <<<"$assessment" || fail "not a notarized Developer ID build: $assessment"
signature="$(codesign -dv --verbose=4 "$app" 2>&1)"
grep -q "TeamIdentifier=PCWH4GSLHZ" <<<"$signature" || fail "unexpected signing team: $signature"
pkill -x Readout || true
sleep 1
if [ -d /Applications/Readout.app ]; then
    mv /Applications/Readout.app "$work/Readout-previous.app"
fi
ditto "$app" /Applications/Readout.app
tmux=/opt/homebrew/bin/tmux
session="$("$tmux" ls -F '#S' 2>/dev/null | grep -E '^(hil|gui)$' | head -1 || true)"
if [ -n "$session" ]; then
    "$tmux" new-window -d -t "$session" "open /Applications/Readout.app"
else
    open /Applications/Readout.app
fi
for _ in $(seq 1 20); do
    pgrep -f /Applications/Readout.app/Contents/MacOS/Readout >/dev/null && break
    sleep 0.5
done
pgrep -f /Applications/Readout.app/Contents/MacOS/Readout >/dev/null || fail "Readout did not start"
installed="$(defaults read /Applications/Readout.app/Contents/Info.plist CFBundleShortVersionString)"
[ "$installed" = "$version" ] || fail "installed version is $installed, not $version"
echo "$(hostname): Readout $installed running; previous copy in $work/Readout-previous.app"
REMOTE
