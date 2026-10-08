#!/usr/bin/env bash
set -euo pipefail
version="$1"
build="$2"
cd "$(dirname "$0")/.."
scripts/fetch-sparkle.sh
zip="dist/Readout-$version.zip"
if [ -n "${SPARKLE_ED_KEY_FILE:-}" ]; then
  signature="$(build/sparkle/bin/sign_update --ed-key-file "$SPARKLE_ED_KEY_FILE" "$zip")"
else
  signature="$(build/sparkle/bin/sign_update --account readout "$zip")"
fi
case "$signature" in *'sparkle:edSignature="'*'length="'*) ;; *) echo "unexpected sign_update output: $signature"; exit 1 ;; esac
cat > dist/appcast.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Readout</title>
    <item>
      <title>Version $version</title>
      <pubDate>$(LC_ALL=C date -u "+%a, %d %b %Y %H:%M:%S +0000")</pubDate>
      <sparkle:version>$build</sparkle:version>
      <sparkle:shortVersionString>$version</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>26.0</sparkle:minimumSystemVersion>
      <sparkle:releaseNotesLink>https://github.com/jeremywho/readout/releases/tag/v$version</sparkle:releaseNotesLink>
      <enclosure url="https://github.com/jeremywho/readout/releases/download/v$version/Readout-$version.zip" type="application/octet-stream" $signature />
    </item>
  </channel>
</rss>
EOF
xmllint --noout dist/appcast.xml
