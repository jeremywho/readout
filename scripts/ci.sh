#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift format lint --strict --recursive ReadoutKit/Sources ReadoutKit/Tests App
swift test --package-path ReadoutKit
xcodegen generate
xcodebuild -quiet -project Readout.xcodeproj -scheme Readout -configuration Release -derivedDataPath build/ci -destination 'platform=macOS' CODE_SIGN_IDENTITY=- build
build/ci/Build/Products/Release/Readout.app/Contents/MacOS/Readout --self-test
