# Chess

A calm, one-game iPhone chess app in SwiftUI. `SPEC.md` is the product, the design tokens and
the internals: read it first, and update it when a decision changes.

## Build and run

- `project.yml` is the project; run `xcodegen generate` after adding or moving files. Never edit or commit `Chess.xcodeproj`.
- `tools/fetch-nnue.sh` once, for Stockfish's networks. Without them the app uses the built-in `Fallback` engine.
- `tools/sim.sh ["iPhone 17 Pro"]` builds and launches on the Simulator.
- `tools/device.sh [name or UDID]` builds Release and installs on a connected or Wi-Fi-paired iPhone (team KBPJG8WNLV). No TestFlight.
- `tools/shots.sh [device]` screenshots every main screen, light and dark, into `.shots/`. Look at them after any UI change, and once at the largest text size (`xcrun simctl ui <device> content_size accessibility-extra-extra-extra-large`).
- `swift tools/make-icons.swift` re-renders the three app icons.
- Debug builds take `-debugOpen game|friend|online|settings-<page>` (pages: root, difficulty, app, game, notifications, about) and `-onboarded YES` as launch arguments; any `@AppStorage` key works too (`-boardTheme sage`).

## Rules

- iPhone only. SwiftUI first; UIKit only where SwiftUI has no API.
- Colours come from `Theme` (Sudoku a Day's tokens), never a literal in a view. Levels colour themselves through `Level.tint`.
- Controls come from `Design/Components.swift`: round 52 pt buttons, ink pills, rounded rows, `SoftPress` for every press.
- Motion uses `Theme.spring` or `Theme.pieceSlide`, and respects Reduce Motion.
- The board is rebuilt from the saved UCI moves; never mutate it any other way.
- The engine is the `ChessEngine` actor; nothing else talks to Stockfish.
- Swift 6 strict concurrency stays on.
- Type goes through `scaledFont`, except glyphs inside fixed shapes (round buttons, board coordinates).
- Every motion has a Reduce Motion version; every control and square has a VoiceOver label.
- No audio or other blocking work on the main thread; `Sounds` owns its queue.
- Nothing on screen opens a placeholder: hide a feature until it works.
