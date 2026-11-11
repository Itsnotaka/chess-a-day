#!/bin/sh
# Downloads the lichess studies the Learn courses are made of into Chess/Learn/Courses.
# lichess rate-limits bursts, so requests are spaced out. Each is a public study whose author allows export; they're credited in the app.
set -e
cd "$(dirname "$0")/../Chess/Learn/Courses"
fetch() { sleep 2; curl -fsSL "https://lichess.org/api/study/$2.pgn?comments=true&variations=true&clocks=false&orientation=true" -o "$1.pgn"; echo "$1.pgn  $(grep -c '^\[Event ' "$1.pgn") chapters"; }
fetch london  vIEKP8t3   # ⭐ The London System ⭐ — LeninPerez
fetch italian vJsZScnC   # 🇮🇹 Italian Opening 🇮🇹 — LeninPerez
fetch dragon  pCsPvGUQ   # THE SICILIAN DRAGON — Sidattack243
fetch carokann jtlLwUvh  # 🏰 Caro-Kann Defense🔥 — LeninPerez
