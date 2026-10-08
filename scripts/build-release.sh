#!/usr/bin/env bash
set -euo pipefail
version="$1"
build="$2"
cd "$(dirname "$0")/.."
rm -rf build/release dist
mkdir -p build/release dist
xcodegen generate
xcodebuild -quiet -project Readout.xcodeproj -scheme Readout -configuration Release \
  -derivedDataPath build/release/DerivedData -archivePath build/release/Readout.xcarchive \
  MARKETING_VERSION="$version" CURRENT_PROJECT_VERSION="$build" ENABLE_HARDENED_RUNTIME=YES \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="Developer ID Application" DEVELOPMENT_TEAM=PCWH4GSLHZ \
  OTHER_CODE_SIGN_FLAGS=--timestamp archive
xcodebuild -quiet -exportArchive -archivePath build/release/Readout.xcarchive \
  -exportOptionsPlist scripts/ExportOptions.plist -exportPath build/release/export
plist=build/release/export/Readout.app/Contents/Info.plist
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist")" = "$version"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$plist")" = "$build"
