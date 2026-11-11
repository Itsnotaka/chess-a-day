#!/bin/sh
# Builds Chess (Release, so Stockfish runs at full speed) and installs it on your iPhone
# over USB or Wi-Fi. No TestFlight: signed with your development team, valid for a year.
# tools/device.sh [device name or UDID]   (list with: xcrun devicectl list devices)
set -e
cd "$(dirname "$0")/.."
DEVICE="${1:-O2}"
UDID=$(xcrun devicectl list devices 2>/dev/null | awk -v d="$DEVICE" '$0 ~ d { for (i = 1; i <= NF; i++) if ($i ~ /^[0-9A-F]{8}-/) { print $i; exit } }')
[ -n "$UDID" ] || { echo "No device matching '$DEVICE'"; exit 1; }
xcodegen generate --quiet
xcodebuild -project Chess.xcodeproj -scheme Chess -configuration Release \
  -destination "id=$UDID" -derivedDataPath build -allowProvisioningUpdates -quiet build
xcrun devicectl device install app --device "$UDID" build/Build/Products/Release-iphoneos/Chess.app
xcrun devicectl device process launch --device "$UDID" dev.workgyver.chess
