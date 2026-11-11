#!/bin/sh
# Launches the installed app on the iPhone with -benchmark YES and prints the engine timings.
# The phone must be unlocked. tools/bench-device.sh [device name or UDID]  (install with tools/device.sh)
cd "$(dirname "$0")/.."
DEVICE="${1:-O2}"
UDID=$(xcrun devicectl list devices 2>/dev/null | awk -v d="$DEVICE" '$0 ~ d { for (i = 1; i <= NF; i++) if ($i ~ /^[0-9A-F]{8}-/) { print $i; exit } }')
LOG=$(mktemp)
timeout "${SECONDS_TO_RUN:-45}" xcrun devicectl device process launch --device "$UDID" --terminate-existing --console com.workgyver.chess -benchmark YES >"$LOG" 2>&1
if grep -q "Locked" "$LOG"; then echo "$DEVICE is locked: unlock it and run this again."; exit 1; fi
grep -E "\[bench\]|ERROR" "$LOG" || tail -20 "$LOG"
rm -f "$LOG"
