#!/usr/bin/env bash
set -euo pipefail
version="$1"
cd "$(dirname "$0")/.."
app=build/release/export/Readout.app
ditto -c -k --keepParent "$app" build/release/Readout-notarize.zip
scripts/notarize.sh build/release/Readout-notarize.zip
xcrun stapler staple "$app"
ditto -c -k --keepParent "$app" "dist/Readout-$version.zip"
staging=build/release/dmg
rm -rf "$staging"
mkdir -p "$staging"
cp -R "$app" "$staging/"
ln -s /Applications "$staging/Applications"
hdiutil create -quiet -volname "Readout $version" -srcfolder "$staging" -ov -format UDZO "dist/Readout-$version.dmg"
codesign --force --timestamp --sign "Developer ID Application: Jeremy Daughhetee (PCWH4GSLHZ)" "dist/Readout-$version.dmg"
scripts/notarize.sh "dist/Readout-$version.dmg"
xcrun stapler staple "dist/Readout-$version.dmg"
