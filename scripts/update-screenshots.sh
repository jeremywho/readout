#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
xcodegen generate
xcodebuild -quiet -project Readout.xcodeproj -scheme Readout -configuration Release -derivedDataPath build/dd-shots CODE_SIGN_IDENTITY=- build
build/dd-shots/Build/Products/Release/Readout.app/Contents/MacOS/Readout --export-screenshots docs/images
ls -1 docs/images
