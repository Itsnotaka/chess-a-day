#!/bin/sh
# Downloads Stockfish 17's two networks (~75 MB) into Chess/NNUE, where the build bundles them.
# Without them the app plays its small built-in engine instead.
set -e
cd "$(dirname "$0")/../Chess/NNUE"
for net in nn-1111cefa1111.nnue nn-37f18f62d772.nnue; do
  [ -f "$net" ] || curl -fL --progress-bar "https://tests.stockfishchess.org/api/nn/$net" -o "$net"
done
ls -lh
