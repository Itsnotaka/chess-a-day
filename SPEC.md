# Chess: spec

A calm, one-game iPhone app: play the computer, plus one daily puzzle. Modelled on the
minimalist daily Sudoku app: grey ground, one big white card, round icon buttons, sheets
with a grabber, a day strip, big pill buttons. Liquid Glass is reserved for the app icon; the interface uses quiet opaque surfaces. No account, no network, no Pro.

Status: **SwiftUI app, UI polish phase.** Runs on the Simulator; next is your iPhone.

## Decisions

| Area | Decision |
|---|---|
| Platform | iPhone only, iOS 18+. SwiftUI, with UIKit only where SwiftUI has no API (haptics, dynamic colours). No Mac app. |
| Project | XcodeGen (`project.yml`); `Chess.xcodeproj` is generated and not committed. |
| Rules | ChessKit (`chesskit-swift`, MIT): legal moves, check, mate, draws, promotion. |
| Engine | Stockfish 17 through ChessKitEngine (MIT wrapper, GPL engine). Its two NNUE networks (~75 MB) come from `tools/fetch-nnue.sh`; without them the app plays its small built-in engine (`Fallback`). |
| License | GPLv3 for the whole repo, since it ships Stockfish. |
| Pieces | Three lichess sets as vector assets, namespaced in the catalog: cburnett (GPLv2+), Merida (GPLv2+), Chessnut (Apache 2.0). |
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

- **Top bar**, round 52 pt buttons: **Level** (filled with the level's colour, opens Difficulty) · **Streak** (laurel: the current run, the best, this week's rings) | **Stats** (bars: played, won, drawn, lost, and a Swift Charts bar chart by level) · **Settings** (gear). Awards come back when they exist; nothing on home opens a placeholder.
- **The card** (white, 36 pt radius, soft shadow): the weekday in faded heavy type over the date in bold heavy type ("Thursday / May 15"), a status line ("● Your move" for a game in progress, "Today's game: won" and so on), a slightly tilted board preview (the game in progress, else the start position) with a black **Play** pill over it, and a three-way **White · Random · Black** picker under it ("Playing as White · Medium" while a game is in progress).
- **Three tiles** under the card: **Learn**, **Free play** (one phone) and **Online** (with a count of games waiting on you). The **Daily puzzle** joins them once puzzles ship.
- Choosing a past day on the strip shows what was played that day; the card's pill becomes **Back to today**, so the heading never disagrees with the game Play opens.
- **Day strip** at the bottom: five days centred on the selected one, each with its weekday, its number and a ring. Dashed ring: nothing counted. Half ring: a game *or* the puzzle. Full ring: both. Past days open their puzzle; the computer is always today.

## Games against the computer

- Unlimited games. Before Play: White, Black or Random. The board flips when you're Black.
- **No hints and no undo.** Resign is the only way out of a game, besides finishing it.
- Layout, top to bottom: header (close, level and elapsed time, Game Settings), the computer's row, the board, your row, the move list, then Resign and Flip board. Whose move it is shows as an ink badge on that player's row.
- **Time control** (Game Settings): None (default; an elapsed timer like Sudoku's "○ 1:23") or 10+0, 5+3, 3+2. With a clock, both clocks show, and a flag loses.
- Input: tap-tap and drag, legal-move dots and capture rings, last-move tint, check tint on the king, a slide animation, a haptic on drop, promotion picker (Q R B N).
- A game in progress is kept across launches.
- End: a sheet shows the result (Win / Draw / Loss and the reason), the moves count, and buttons for Play again and Done.

## Online with friends

- Game Center turn-based matches (`GKTurnBasedMatch`), so there is no server and no account of ours. Signed in quietly at launch.
- **Invite** opens Apple's invite-only picker: Messages to any contact, Game Center friends, recent players. Whoever invites plays White.
- Each move ends your turn with a **one-day timeout**; your friend gets Game Center's turn notification. A turn left too long loses on time.
- The match stores `{moves, whiteID}`; the board replays the moves through the same `GameStore` (mode `.online`), so rules, drag, sounds and VoiceOver are shared.
- Checkmate, a draw or a resignation ends the match for both with won, lost or tied; a friend who resigns out of turn hands you the win. **Rematch** starts a new match with the same friend.
- Home's **Online** tile opens Apple's invite sheet straight away. With games going it opens a small menu instead: Invite a friend, then the games, your move first. Its badge counts games waiting on you. Signed out, it explains how to sign in.
- Online games don't count toward the streak or Stats.
- Needs the App Store Connect app record with Game Center (bundle `com.workgyver.chess`, Game Center capability enabled through asc). Testing needs two Game Center accounts.

## Learn

- Four courses, each a public lichess study bundled as PGN (`Chess/Learn/Courses`, refreshed by `tools/fetch-courses.sh`): as White, **London System** and **Italian Game** (LeninPerez); as Black, **Sicilian Dragon** (Sidattack243) and **Caro-Kann Defence** (LeninPerez). Authors are credited in the course page and About.
- A lichess **gamebook** chapter becomes a played lesson: the comment after the opponent's move is the question for your move, the comment after your move says why, a sideline to your move is the answer to that particular wrong move, and `[%cal]` arrows and `[%csl]` circles are drawn in the author's colours. Other chapters (up to 30 plies) become watched lessons; diagrams without kings and long example games are left out.
- The board accepts only the taught move; a wrong one settles back, the coach card shakes, and a second miss shows the move. Hint shows it at once.
- **Practice** replays a learned lesson with no words or arrows; wrong moves and hints cost stars (3, 2 or 1). Progress is kept per lesson.
- Every line was checked move by move, sidelines included, before bundling.
- Licence note: lichess studies belong to their authors. Ask them before a public release.

## Free play

- Two people, one phone. Either side moves in turn; there is no engine and no level.
- Opened from the **Free play** tile on home; it keeps its own saved game (`free-play.json`), so a computer game in progress is never lost.
- White plays from the bottom. **Turn Board in Free Play** (Game Settings) turns it to the side to move after each move; Flip turns it by hand.
- The rows read White and Black; "To move" marks whose turn it is. Resign resigns for the side to move. The result reads "White wins", "Black wins" or "Draw".
- The clock works as in a computer game. Free play doesn't count toward the streak.

## Daily puzzle

- One puzzle per date per level: a stable pick from that level's band, indexed by the date.
- Strict, as on lichess: one wrong move fails it. Retry is allowed but doesn't count. No hints.
- The puzzle's first move is the opponent's: play it with an animation, then it's your turn.
- Past days on the strip can be solved; they fill their ring but don't revive a streak.

## Streaks

- Unlimited play, but **one game and one puzzle per day count**.
- A day **counts** when it has a finished computer game (any result) **or** the day's puzzle solved. Doing both fills the day's ring; one fills half.
- The streak is the run of counted days ending today or yesterday.

## Settings (a tray over home)

Rows with a leading symbol and a trailing chevron, each pushing a page that has a round
Back button and a centred title:

- **Difficulty**: the five level rows from onboarding.
- **App Settings**: Light / Auto / Dark segmented pill · App Icon picker (`setAlternateIconName`) · Haptic Feedback switch · Sounds switch.
- **Game Settings**: board (Stone, Sand, Sage, Sky, Lilac) · pieces (Classic cburnett, Merida, Chessnut) · clock · coordinates · show legal moves · always promote to queen · turn board in free play. The board and pieces apply everywhere a board is drawn.
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
- The board sits inside a 2 pt ink outline, as Sudoku's grid does. Its squares come from the chosen `BoardTheme`; Stone (#FAFAFA / #DCDCDC) is the default. Coordinates sit outside the board in ink muted.
- Every button is round (52 pt) or a pill (50–56 pt). Cards have 36 pt continuous corners and soft, wide shadows.
- Motion: one short spring that overshoots a touch (`Theme.spring`), pieces slide on a firmer one, presses sink to 95%. Reduce Motion turns slides into fades.

## Internals

```
project.yml                 XcodeGen: targets, packages (ChessKit, ChessKitEngine, Vortex), signing team, alternate icons
Chess/ChessApp.swift        the app, RootView (onboarding or home), scheme, rounded font
Chess/Design/               Theme (tokens), Components (buttons, rows, chips), FlowLayout
Chess/Model/                Level/TimeControl/Pref, GameStore, ChessEngine (+ Fallback), History, Haptics, Sounds, Reminders
Chess/Design/               Theme, BoardStyle (board themes, piece sets), Components, ScaledFont, FlowLayout
Chess/Views/                OnboardingView, HomeView (+ HomeRow, SidePicker, DayStrip), BoardView (+ MiniBoard), GameView, SettingsSheet, StatsViews (Streak, Stats)
Chess/Assets.xcassets       pieces (SVG), AccentColor, LaunchBackground, AppIcon
Chess/NNUE/                 Stockfish networks (git-ignored; tools/fetch-nnue.sh)
Chess/Sounds/               move.wav, capture.wav, end.wav (synthesised)
tools/                      fetch-nnue.sh, sim.sh, device.sh, shots.sh, make-icons.swift
```

- **The saved game is the moves.** `game.json` holds the UCI moves, side, level, clock and ending; the board is always rebuilt by replaying them, so it can't disagree with the file.
- **Pieces keep ids.** Each piece's id is the square it started on, carried through captures, castling and promotion, so SwiftUI slides it instead of redrawing.
- **The engine is an actor.** `ChessEngine.bestMove(fen:level:)` sets the level's options and `go movetime`, and waits for `bestmove`. The game shows "Thinking…" for at least the level's minimum pause.
- **Clocks** are stored at each move and counted down from `lastMoveAt` by a `TimelineView`. The model adjudicates: a move made after the flag fell loses on time and earns no increment, whether or not the view noticed first.
- **A relaunch resumes the computer's turn** when the saved game is waiting for its reply.
- **History** keeps day marks (for the strip and streak) and one `GameRecord` per finished computer game (for Stats).
- **Reminders** use a repeating `UNCalendarNotificationTrigger`; iOS repeats it.

## Feel and accessibility

- **Sounds** (AVFoundation): a soft knock for a move, a deeper double knock for a capture, a two-note chime when a game ends. Synthesised by a script, so they carry no licence. Ambient session, respects the silent switch, played on a serial queue so audio never touches the main thread.
- **Haptics** (UIKit): one generator per kind, made once and reused; the drop's generator is prepared when a drag starts.
- **Confetti** (Vortex) in the level colours when you win; none under Reduce Motion.
- **Segmented pills** (White/Random/Black, Light/Auto/Dark) are masked like a good tab bar: the labels are drawn twice, muted and active, and the active copy shows only through the sliding thumb, so a label changes colour exactly where the thumb covers it. The thumb follows a dragging finger and snaps on lift; a tap lands on lift; the choice is stored by the control itself, so a tap redraws only it.
- **Morphing pill** for async actions (Remind me): label, then a spinner as the pill draws in to a circle, then a check with "Reminder set".
- **Trays, not sheets** (after rit3zh/expo-dynamic-tray): every bottom panel is a `Tray` card floating 16 pt in from the edges over a dimmed backdrop. One spring lifts it in and scales it from 94%; it springs to its content's height and scrolls only past the screen; a page change scales the new page up from 96% as the old one fades. Drag down past 110 pt or flick at 1000 pt/s, tap the backdrop, or use the VoiceOver escape gesture to close. Under Reduce Motion it fades in and out and pages crossfade.
- **Reminder time** is a slider in quarter hours, 5 AM to 11 PM, with a large readout; it ticks each step and reschedules on lift.
- **Drag**: the dragged piece itself rides above the finger (1.35x, with a shadow) and settles into its new square or back to its own; a cancelled touch settles it back too.
- **VoiceOver**: every square is a button labelled with its square and piece ("e4, white pawn") and valued with its state (selected, legal move, capture, in check, last move); activating it is a tap. Promotion choices are named. Clocks read as "You's clock, 4:32".
- **Dynamic Type**: every size goes through `scaledFont`, which follows the reader's text size. Home and the game are one screen without scrolling, so they stop at the largest standard size; trays scroll and go to Accessibility 2.
- **Reduce Motion**: presses only dim, onboarding steps fade instead of slide, pieces fade instead of slide, no pulse, no confetti.
- **Contrast**: the level colours are a step deeper than Sudoku a Day's in light mode, so white on them and them on a light fill keep 3:1; in dark mode the symbol on a level colour is near-black. Dark-mode boards are mid-toned so black pieces never sink into them.
- **Reminders** stay off when iOS won't deliver them: a blocked permission shows as such, with Open Settings.
- **App icons**: the full-bleed B3 checkerboard with a purple knight, coral rook and yellow pawn. `Chess/AppIcon.icon` is the editable Liquid Glass source and the primary Home Screen icon. `tools/make-icons.swift` renders it for the onboarding mark and Classic, Night and Mono picker previews, and generates the Night and Mono alternate icons. The check moves only after `setAlternateIconName` succeeds.

## Later

- **Daily puzzle** (the lichess CC0 set, bundled) and **Awards**.
- **Widgets** (WidgetKit): today's ring and streak on the Home Screen.
- **Game Center leaderboards** (GameKit): streak and wins.

## Not in v1

Online play, accounts, lichess API, opening explorer, Maia/human-like nets, post-game
review/accuracy, hints, undo, iPad, Mac, widgets, Live Activities.
