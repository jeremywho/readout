#!/usr/bin/env bash
set -euo pipefail
version="2.10.0"
cd "$(dirname "$0")/.."
if [ -x build/sparkle/bin/sign_update ]; then exit 0; fi
mkdir -p build/sparkle
curl -fsSL "https://github.com/sparkle-project/Sparkle/releases/download/${version}/Sparkle-${version}.tar.xz" | tar -xJ -C build/sparkle
test -x build/sparkle/bin/sign_update
test -x build/sparkle/bin/generate_keys
