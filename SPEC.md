# Chess: spec

A calm, one-game iPhone app: play the computer, plus one daily puzzle. Modelled on the
minimalist daily Sudoku app: grey ground, one big white card, round icon buttons, sheets
with a grabber, a day strip, big pill buttons. No glass, no account, no network, no Pro.

Status: **SwiftUI app, UI polish phase.** Runs on the Simulator; next is your iPhone.

## Decisions

| Area | Decision |
|---|---|
| Platform | iPhone only, iOS 18+. SwiftUI, with UIKit only where SwiftUI has no API (haptics, dynamic colours). No Mac app. |
| Project | XcodeGen (`project.yml`); `Chess.xcodeproj` is generated and not committed. |
| Rules | ChessKit (`chesskit-swift`, MIT): legal moves, check, mate, draws, promotion. |
| Engine | Stockfish 17 through ChessKitEngine (MIT wrapper, GPL engine). Its two NNUE networks (~75 MB) come from `tools/fetch-nnue.sh`; without them the app plays its small built-in engine (`Fallback`). |
| License | GPLv3 for the whole repo, since it ships Stockfish. |
| Pieces | cburnett SVGs (lichess, GPLv2+), as vector assets. |
| Look | Sudoku a Day's own tokens (below), SF Pro Rounded everywhere via `.fontDesign(.rounded)`. |
| Network | None. Puzzles ship in the app. |
| Data | Settings in `@AppStorage`; the current game and the day history as JSON in Application Support. |
| Testing | Simulator and your own iPhone straight from the command line (`tools/sim.sh`, `tools/device.sh`); no TestFlight. |

The Exact prototype (Contract + TypeScript) is kept in `archive/exact-prototype` as a visual reference.

### The engine spike: passed on the Simulator

Stockfish 17 answers through ChessKitEngine in about the level's move time and plays a real move (1.e4 Nf6 on Medium). Still to prove on a phone: drag feel at 120 Hz and engine speed in a Release build.

## Levels

Five levels, picked in onboarding and changed in Settings → Difficulty. One choice sets
both the computer's strength and the puzzle band.

| Level | Description (shown on the card) | Stockfish 17 | Puzzle rating |
|---|---|---|---|
| Easy | Learning the moves. The computer misses a lot. | Skill Level 0, depth 1 | 600–1000 |
| Medium | You know the rules and a few tricks. | Skill Level 4, 100 ms | 1000–1400 |
| Hard | You play regularly and see tactics coming. | Skill Level 9, 250 ms | 1400–1800 |
| Expert | Club strength. Few free pieces here. | UCI_LimitStrength, UCI_Elo 1800, 500 ms | 1800–2200 |
| Master | No mercy. | UCI_LimitStrength, UCI_Elo 2400, 900 ms | 2200+ |

Strengths are first guesses; tune them by playing.

## Onboarding

On first launch, until `onboarded` (persisted) is true. It's one floating white card over the
grey ground, like Sudoku's "Select your level", whose content changes step by step, with a
round Back button and a black Continue pill at the bottom.

1. **Welcome.** App mark, "Chess", "One calm game a day. Play the computer, solve a puzzle." Continue.
2. **Level.** "Pick your level". Five rounded rows (Easy…Master), each with a symbol and its name. The selected row turns black with a white check and shows its description. Continue.
3. **Reminder.** "A daily nudge?" A time (default 9:00), "Remind me" (asks for notification permission, schedules) and "Not now". Either one finishes.
4. Home.

No placement test. The level can be changed at any time.

## Home

- **Top bar**, round 52 pt buttons: **Level** (filled accent, the level's symbol, opens Difficulty) · **Streak** (laurel, opens the streak sheet) · **Awards** (trophy) | **Stats** (bars) · **Settings** (gear).
- **The card** (white, 36 pt radius, soft shadow): the weekday in faded heavy type over the date in bold heavy type ("Thursday / May 15"), a status line ("● Your move" for a game in progress, "Today's game: won" and so on), a slightly tilted board preview (the game in progress, else the start position) with a black **Play** pill over it, and a three-way **White · Random · Black** picker under it.
- **Daily puzzle row** under the card: a smaller rounded row, "Daily puzzle", the level, and Solve / Solved.
- **Day strip** at the bottom: five days centred on the selected one, each with its weekday, its number and a ring. Dashed ring: nothing counted. Half ring: a game *or* the puzzle. Full ring: both. Past days open their puzzle; the computer is always today.

## Games against the computer

- Unlimited games. Before Play: White, Black or Random. The board flips when you're Black.
- **No hints and no undo.** Resign is the only way out of a game, besides finishing it.
- **Time control** (Game Settings): None (default; an elapsed timer like Sudoku's "○ 1:23") or 10+0, 5+3, 3+2. With a clock, both clocks show, and a flag loses.
- Input: tap-tap and drag, legal-move dots and capture rings, last-move tint, check tint on the king, a slide animation, a haptic on drop, promotion picker (Q R B N).
- A game in progress is kept across launches.
- End: a sheet shows the result (Win / Draw / Loss and the reason), the moves count, and buttons for Play again and Done.

## Daily puzzle

- One puzzle per date per level: a stable pick from that level's band, indexed by the date.
- Strict, as on lichess: one wrong move fails it. Retry is allowed but doesn't count. No hints.
- The puzzle's first move is the opponent's: play it with an animation, then it's your turn.
- Past days on the strip can be solved; they fill their ring but don't revive a streak.

## Streaks

- Unlimited play, but **one game and one puzzle per day count**.
- A day **counts** when it has one finished computer game (any result) and the day's puzzle solved.
- The streak is the run of counted days ending today or yesterday.
- Open question: should a day with just one of the two still keep the streak alive?

## Settings (a sheet with a grabber over home, at 70% and large)

Rows with a leading symbol and a trailing chevron, each pushing a page that has a round
Back button and a centred title:

- **Difficulty**: the five level rows from onboarding.
- **App Settings**: Light / Auto / Dark segmented pill · App Icon picker (`setAlternateIconName`) · Haptic Feedback switch · Sounds switch.
- **Game Settings**: time control · coordinates on/off · show legal moves on/off · auto-queen on/off · board theme (Stone, Sand, Mint, Graphite).
- **Notifications**: daily reminder on/off and its hour.
- **Feedback and more**: send feedback (mail), licenses (Stockfish GPLv3, ChessKit and ChessKitEngine MIT, cburnett, lichess puzzles CC0), version.

## Stats and awards (after v1's core loop)

- Stats: games, W/D/L by level, puzzles solved, best streak.
- Awards: first win per level, 7/30/100-day streaks, a win in under 20 moves, a win with fewer pieces.

## Puzzle data

- Source: lichess puzzle CSV (CC0). Filter: Popularity ≥ 80, NbPlays ≥ 100, RatingDeviation ≤ 100, and 2–4 solution moves for the lower levels.
- 400 per level (2,000 total, about 250 KB) in a generated `puzzles.json` bundled with the app: `{id, fen, moves, rating, themes}`. A `tools/` script builds it; it's never fetched at runtime.
- Apply `moves[0]` before showing the position; the solution starts at `moves[1]`. In a mate-in-one, any mating move counts.

## Look

Taken from sudokuaday.com's CSS custom properties, so the app matches the reference exactly:

| Token | Light | Dark |
|---|---|---|
| ground | #E6E6E6 | #1A1A1A |
| card | #FEFFFF | #262626 |
| raised | #F2F2F2 | #333333 |
| ink | #262626 | #D9D9D9 |
| ink muted | #666666 | #8C8C8C |
| ink faint | #BFBFBF | #404040 |

- One colour per level, as Sudoku a Day colours its difficulties: Easy teal #2FAFC8, Medium purple #AF51DD, Hard red #FC3E30, Expert brown #A1835D, Master ink. The level button, the settings banner and the computer's badge take it.
- The weekday is a heavy title in a #BFBFBF-to-clear gradient above the date in ink, tracked tight (-0.04 em).
- The board is soft greys (#FAFAFA / #DCDCDC) inside a 2 pt ink outline, as Sudoku's grid is.
- Every button is round (52 pt) or a pill (50–56 pt). Cards have 36 pt continuous corners and soft, wide shadows.
- Motion: one short spring that overshoots a touch (`Theme.spring`), pieces slide on a firmer one, presses sink to 95%. Reduce Motion turns slides into fades.

## Internals

```
project.yml                 XcodeGen: targets, packages (ChessKit, ChessKitEngine), signing team
Chess/ChessApp.swift        the app, RootView (onboarding or home), scheme, rounded font
Chess/Design/               Theme (tokens), Components (buttons, rows, chips), FlowLayout
Chess/Model/                Level/TimeControl/Pref, GameStore, ChessEngine (+ Fallback), History, Haptics, Reminders
Chess/Views/                OnboardingView, HomeView (+ SidePicker, DayStrip), BoardView (+ MiniBoard), GameView, SettingsSheet
Chess/Assets.xcassets       pieces (SVG), AccentColor, LaunchBackground, AppIcon
Chess/NNUE/                 Stockfish networks (git-ignored; tools/fetch-nnue.sh)
tools/                      fetch-nnue.sh, sim.sh, device.sh, shots.sh
```

- **The saved game is the moves.** `game.json` holds the UCI moves, side, level, clock and ending; the board is always rebuilt by replaying them, so it can't disagree with the file.
- **Pieces keep ids.** Each piece's id is the square it started on, carried through captures, castling and promotion, so SwiftUI slides it instead of redrawing.
- **The engine is an actor.** `ChessEngine.bestMove(fen:level:)` sets the level's options and `go movetime`, and waits for `bestmove`. The game shows "Thinking…" for at least the level's minimum pause.
- **Clocks** are stored at each move and counted down from `lastMoveAt` by a `TimelineView`; a flag ends the game.
- **Reminders** use a repeating `UNCalendarNotificationTrigger`; iOS repeats it.

## Not in v1

Online play, accounts, lichess API, opening explorer, Maia/human-like nets, post-game
review/accuracy, hints, undo, iPad, Mac, widgets, Live Activities.
