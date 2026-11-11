#!/bin/sh
# Builds Chess and runs it on the iOS Simulator: tools/sim.sh ["iPhone 17 Pro"]
set -e
cd "$(dirname "$0")/.."
DEVICE="${1:-iPhone 17 Pro}"
xcodegen generate --quiet
xcodebuild -project Chess.xcodeproj -scheme Chess -configuration Debug \
  -destination "platform=iOS Simulator,name=$DEVICE" -derivedDataPath build -quiet build
xcrun simctl boot "$DEVICE" 2>/dev/null || true
open -a Simulator
xcrun simctl install "$DEVICE" build/Build/Products/Debug-iphonesimulator/Chess.app
xcrun simctl launch "$DEVICE" dev.workgyver.chess
