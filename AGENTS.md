# Chess

A calm, one-game iPhone chess app in SwiftUI. `SPEC.md` is the product, the design tokens and
the internals: read it first, and update it when a decision changes.

## Build and run

- `project.yml` is the project; run `xcodegen generate` after adding or moving files. Never edit or commit `Chess.xcodeproj`.
- `tools/fetch-nnue.sh` once, for Stockfish's networks. Without them the app uses the built-in `Fallback` engine.
- `tools/sim.sh ["iPhone 17 Pro"]` builds and launches on the Simulator.
- `tools/device.sh [name or UDID]` builds Release and installs on a connected or Wi-Fi-paired iPhone (team KBPJG8WNLV). No TestFlight.
- `tools/shots.sh [device]` screenshots every main screen, light and dark, into `.shots/`. Look at them after any UI change.
- Debug builds take `-debugOpen game|friend|settings-<page>` (pages: root, difficulty, app, game, notifications, about) and `-onboarded YES` as launch arguments; any `@AppStorage` key works too (`-boardTheme sage`).

## Rules

- iPhone only. SwiftUI first; UIKit only where SwiftUI has no API.
- Colours come from `Theme` (Sudoku a Day's tokens), never a literal in a view. Levels colour themselves through `Level.tint`.
- Controls come from `Design/Components.swift`: round 52 pt buttons, ink pills, rounded rows, `SoftPress` for every press.
- Motion uses `Theme.spring` or `Theme.pieceSlide`, and respects Reduce Motion.
- The board is rebuilt from the saved UCI moves; never mutate it any other way.
- The engine is the `ChessEngine` actor; nothing else talks to Stockfish.
- Swift 6 strict concurrency stays on.
