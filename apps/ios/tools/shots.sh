#!/bin/sh
# Screenshots every main screen on the Simulator into .shots/ (Debug build from tools/sim.sh).
set -e
cd "$(dirname "$0")/.."
D="${1:-iPhone 17 Pro}"
APP=com.workgyver.chess
mkdir -p .shots
# A fresh install launches slower: wake it once before the first picture.
xcrun simctl launch "$D" $APP >/dev/null 2>&1; sleep 4
shot() { name=$1; shift; xcrun simctl terminate "$D" $APP 2>/dev/null || true; xcrun simctl launch "$D" $APP "$@" >/dev/null; sleep "${WAIT:-3.5}"; xcrun simctl io "$D" screenshot ".shots/$name.png" >/dev/null 2>&1; echo ".shots/$name.png"; }
shot home -onboarded YES -debugOpen none
shot settings -onboarded YES -debugOpen settings-root
shot app-settings -onboarded YES -debugOpen settings-app
shot game-settings -onboarded YES -debugOpen settings-game
shot difficulty -onboarded YES -debugOpen settings-difficulty
WAIT=4 shot game -onboarded YES -debugOpen game
WAIT=4 shot free-play -onboarded YES -debugOpen friend
shot online -onboarded YES -debugOpen online
xcrun simctl ui "$D" appearance dark
shot home-dark -onboarded YES -debugOpen none
WAIT=4 shot game-dark -onboarded YES -debugOpen game
xcrun simctl ui "$D" appearance light
