#!/bin/sh
# Screenshots every main screen on the Simulator into .shots/ (Debug build from tools/sim.sh).
set -e
cd "$(dirname "$0")/.."
D="${1:-iPhone 17 Pro}"
APP=dev.workgyver.chess
mkdir -p .shots
shot() { name=$1; shift; xcrun simctl terminate "$D" $APP 2>/dev/null || true; xcrun simctl launch "$D" $APP "$@" >/dev/null; sleep "${WAIT:-2.5}"; xcrun simctl io "$D" screenshot ".shots/$name.png" >/dev/null 2>&1; echo ".shots/$name.png"; }
shot home -onboarded YES -debugOpen none
shot settings -onboarded YES -debugOpen root
shot app-settings -onboarded YES -debugOpen app
shot difficulty -onboarded YES -debugOpen difficulty
WAIT=4 shot game -onboarded YES -debugOpen game
xcrun simctl ui "$D" appearance dark
shot home-dark -onboarded YES -debugOpen none
WAIT=4 shot game-dark -onboarded YES -debugOpen game
xcrun simctl ui "$D" appearance light
