#!/usr/bin/env bash
set -euo pipefail
version="$1"
build="$2"
cd "$(dirname "$0")/.."
: "${ASC_KEY_ID:?}" "${ASC_ISSUER_ID:?}" "${ASC_KEY_PATH:?}"
security unlock-keychain -p "$(cat ~/.claude-keychain-pw)" ~/Library/Keychains/login.keychain-db
scripts/fetch-sparkle.sh
key_dir="$(mktemp -d)"
trap 'rm -P -f "$key_dir/sparkle-ed-key"; rmdir "$key_dir"' EXIT
build/sparkle/bin/generate_keys --account readout -x "$key_dir/sparkle-ed-key" >/dev/null
export SPARKLE_ED_KEY_FILE="$key_dir/sparkle-ed-key"
scripts/build-release.sh "$version" "$build"
scripts/package.sh "$version"
scripts/verify.sh "$version"
scripts/appcast.sh "$version" "$build"
ls -l dist
