# Chess

A calm, one-game iPhone chess app in SwiftUI. `apps/ios/SPEC.md` is the product, the design tokens and
the internals: read it first, and update it when a decision changes.

## Layout

- `apps/ios/`: Swift sources (`Chess/`), XcodeGen project, tools, art, archive and spec.
- `apps/web/`: public Next.js App Router site (landing, privacy and support).
- Root: pnpm workspace, Turborepo configuration, agent instructions and GPLv3 license.
- iOS local artifacts (`build/`, `.asc/`, `.shots/`, `Chess.xcodeproj`, NNUE networks) stay inside `apps/ios/` and are ignored.
- Swift is not a pnpm package and is not built by Turbo.

## iOS build and run

Run every command below **from `apps/ios/`** (`cd apps/ios` from the repository root).

- `project.yml` is the project; run `xcodegen generate` after adding or moving files. Never edit or commit `Chess.xcodeproj`.
- `tools/fetch-nnue.sh` once, for Stockfish's networks. Without them the app uses the built-in `Fallback` engine.
- `tools/sim.sh ["iPhone 17 Pro"]` builds and launches on the Simulator.
- `tools/device.sh [name or UDID]` builds Release and installs on a connected or Wi-Fi-paired iPhone (team KBPJG8WNLV).
- TestFlight: App Store Connect app "Chess a Day" (6833662358), external group "Friends" with the public link https://testflight.apple.com/join/HEGSJfUE. Bump `CURRENT_PROJECT_VERSION`, then `asc xcode archive`, `asc xcode export --xcodebuild-flag=-allowProvisioningUpdates`, and `asc publish testflight --app 6833662358 --ipa .asc/artifacts/Chess.ipa --group Friends --wait`. Artifacts live in `.asc/` (ignored).
- `tools/shots.sh [device]` screenshots every main screen, light and dark, into `.shots/`. Look at them after any UI change, and once at the largest text size (`xcrun simctl ui <device> content_size accessibility-extra-extra-extra-large`).
- `swift tools/make-icons.swift` re-renders the three app icons.
- Debug builds take `-debugOpen game|friend|online|settings-<page>` (pages: root, difficulty, app, game, notifications, about) and `-onboarded YES` as launch arguments; any `@AppStorage` key works too (`-boardTheme sage`).

## Web build and run

- From the repository root: `pnpm install`, `pnpm --filter web dev`, `pnpm --filter web typecheck`, `pnpm --filter web lint`, `pnpm --filter web format`.
- Tooling: oxlint (`.oxlintrc.json`), oxfmt (`.oxfmtrc.json`, sorts Tailwind classes) and tsrs for type checking. No ESLint or Prettier.
- Root `pnpm build`, `pnpm lint`, `pnpm typecheck`, `pnpm format` and `pnpm format:check` delegate to Turbo; they only operate on web tasks, never Swift.
- `pnpm --filter web build` builds Next.js; `pnpm --filter web start` serves that build.
- Vercel: Root Directory **`apps/web`**, framework **Next.js**, Node.js **26.x** (engines `>=26`, `.node-version`). Enable access to files outside the Root Directory. Set `ENABLE_EXPERIMENTAL_COREPACK=1`, install command `cd ../.. && corepack pnpm install --frozen-lockfile`, build command `pnpm build`, default output directory. The root `packageManager` pins pnpm; no `vercel.json` is needed. Vercel supplies `VERCEL_PROJECT_PRODUCTION_URL` for metadata; local metadata falls back to `http://localhost:3000`.

## Web rules

- TypeScript strict, React Server Components by default, App Router, Tailwind CSS v4. No external font downloads.
- Interactive primitives come from Base UI (`@base-ui/react`), styled with Tailwind. Its Tabs and Accordion render from server components; anything holding state is a small `"use client"` island.
- Colours use semantic CSS variables in `apps/web/src/app/globals.css`, with light and dark schemes. Rounded system type, 36 px cards and pill controls match the app.
- Use semantic HTML, visible keyboard focus, accessible names and at least 44 px control targets. Keep the layout usable at 360 px and with zoomed text.
- Keep motion optional and minimal; respect `prefers-reduced-motion`. No analytics, ads, tracking or invented product claims.
- Verify copy against Swift sources and the spec. Puzzles and awards are not shipped; beta review is pending. Use “Join the beta”, not an invented App Store link.
- Keep privacy and support accurate when storage, networking or contact details change. Contact: `itsnotaka@gmail.com`.

## iOS rules

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
