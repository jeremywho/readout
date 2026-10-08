#!/usr/bin/env bash
set -euo pipefail
: "${DEVELOPER_ID_P12_BASE64:?}" "${DEVELOPER_ID_P12_PASSWORD:?}" "${RUNNER_TEMP:?}"
keychain="$RUNNER_TEMP/release.keychain-db"
password="$(uuidgen)"
security create-keychain -p "$password" "$keychain"
security set-keychain-settings -lut 21600 "$keychain"
security unlock-keychain -p "$password" "$keychain"
printf '%s' "$DEVELOPER_ID_P12_BASE64" | base64 --decode > "$RUNNER_TEMP/developer-id.p12"
security import "$RUNNER_TEMP/developer-id.p12" -k "$keychain" -P "$DEVELOPER_ID_P12_PASSWORD" -T /usr/bin/codesign -T /usr/bin/security
rm -f "$RUNNER_TEMP/developer-id.p12"
security set-key-partition-list -S apple-tool:,apple: -s -k "$password" "$keychain" >/dev/null
security list-keychains -d user -s "$keychain" $(security list-keychains -d user | tr -d '"')
security find-identity -v -p codesigning "$keychain" | grep -q "Developer ID Application: Jeremy Daughhetee (PCWH4GSLHZ)"
