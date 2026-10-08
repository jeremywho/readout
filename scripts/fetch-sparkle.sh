#!/usr/bin/env bash
set -euo pipefail
version="2.10.0"
sha256="c2bf58aa8387266ac179357b1415d6f2635f044da8be41042af32425dae6da0c"
cd "$(dirname "$0")/.."
if [ "$(cat build/sparkle/VERSION 2>/dev/null)" = "$version" ] && [ -x build/sparkle/bin/sign_update ]; then exit 0; fi
rm -rf build/sparkle
mkdir -p build/sparkle
archive="$(mktemp)"
trap 'rm -f "$archive"' EXIT
curl -fsSL "https://github.com/sparkle-project/Sparkle/releases/download/${version}/Sparkle-${version}.tar.xz" -o "$archive"
echo "${sha256}  ${archive}" | shasum -a 256 -c - >/dev/null
tar -xJf "$archive" -C build/sparkle
test -x build/sparkle/bin/sign_update
test -x build/sparkle/bin/generate_keys
echo "$version" > build/sparkle/VERSION
