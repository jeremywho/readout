#!/usr/bin/env bash
set -euo pipefail
version="$1"
cd "$(dirname "$0")/.."
app=build/release/export/Readout.app
dmg="dist/Readout-$version.dmg"
codesign --verify --deep --strict --verbose=2 "$app"
spctl -a -t exec -vv "$app"
spctl -a -t open --context context:primary-signature -vv "$dmg"
xcrun stapler validate "$app"
xcrun stapler validate "$dmg"
signature="$(codesign -dv --verbose=4 "$app" 2>&1)"
grep -q "TeamIdentifier=PCWH4GSLHZ" <<<"$signature"
grep -Eq "flags=0x[0-9a-f]+\(runtime\)" <<<"$signature"
"$app/Contents/MacOS/Readout" --self-test
