#!/usr/bin/env bash
set -euo pipefail
file="$1"
: "${ASC_KEY_ID:?}" "${ASC_ISSUER_ID:?}" "${ASC_KEY_PATH:?}"
result="$(xcrun notarytool submit "$file" --key "$ASC_KEY_PATH" --key-id "$ASC_KEY_ID" --issuer "$ASC_ISSUER_ID" --wait --timeout 30m --output-format json)"
echo "$result"
status="$(printf '%s' "$result" | plutil -extract status raw -o - -)"
if [ "$status" != "Accepted" ]; then
  id="$(printf '%s' "$result" | plutil -extract id raw -o - -)"
  xcrun notarytool log "$id" --key "$ASC_KEY_PATH" --key-id "$ASC_KEY_ID" --issuer "$ASC_ISSUER_ID"
  exit 1
fi
