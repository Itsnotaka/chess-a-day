#!/bin/sh
# Launches the installed app on the iPhone with -benchmark YES and prints the engine timings.
# tools/bench-device.sh [device name or UDID]   (install first with tools/device.sh)
cd "$(dirname "$0")/.."
DEVICE="${1:-O2}"
UDID=$(xcrun devicectl list devices 2>/dev/null | awk -v d="$DEVICE" '$0 ~ d { for (i = 1; i <= NF; i++) if ($i ~ /^[0-9A-F]{8}-/) { print $i; exit } }')
xcrun devicectl device process launch --device "$UDID" --terminate-existing --console com.workgyver.chess -benchmark YES 2>&1 &
PID=$!
sleep "${SECONDS_TO_RUN:-40}"
kill $PID 2>/dev/null
