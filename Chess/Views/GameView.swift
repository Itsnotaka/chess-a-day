import ChessKit
import SwiftUI

/// A game against the computer, full screen: header, the two players around the board, and
/// the result card when it ends.
struct GameView: View {
  @Environment(GameStore.self) private var game
  @Environment(\.dismiss) private var dismiss
  @AppStorage(Pref.level) private var level = Level.medium
  @AppStorage(Pref.side) private var side = SidePreference.white.rawValue
  @AppStorage(Pref.timeControl) private var timeControl = TimeControl.none
  @State private var confirmResign = false

  var body: some View {
    TimelineView(.periodic(from: .now, by: 0.25)) { timeline in
      VStack(spacing: 14) {
        header(now: timeline.date)
        Spacer(minLength: 8)
        PlayerRow(name: "Computer", symbol: game.level.symbol, tint: game.level.tint,
                  taken: game.takenByThem, clock: game.timeLeft(game.you.opposite, at: timeline.date),
                  running: game.active && !game.yourTurn, thinking: game.thinking)
        BoardView()
        PlayerRow(name: "You", symbol: "person.fill", tint: Theme.ink,
                  taken: game.takenByYou, clock: game.timeLeft(game.you, at: timeline.date),
                  running: game.yourTurn, thinking: false)
        Spacer(minLength: 8)
        footer
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 8)
      .onChange(of: timeline.date) { _, now in game.checkFlag(at: now) }
    }
    .background(Theme.card.ignoresSafeArea())
    .animation(Theme.spring, value: game.isOver)
    .confirmationDialog("Resign this game?", isPresented: $confirmResign, titleVisibility: .visible) {
      Button("Resign", role: .destructive) { game.resign() }
      Button("Keep playing", role: .cancel) {}
    }
  }

  private func header(now: Date) -> some View {
    HStack {
      RaisedCircleButton(symbol: "chevron.down", label: "Close") { dismiss() }
      Spacer()
      VStack(spacing: 2) {
        Text("\(game.level.name) · \(game.you == .white ? "White" : "Black")")
          .font(.system(size: 17, weight: .bold)).foregroundStyle(Theme.ink)
        HStack(spacing: 5) {
          Image(systemName: "circle").font(.system(size: 12, weight: .bold))
          Text(Self.clock(now.timeIntervalSince(game.saved?.startedAt ?? now)))
            .font(.system(size: 15, weight: .semibold)).monospacedDigit()
        }
        .foregroundStyle(Theme.inkMuted)
      }
      Spacer()
      RaisedCircleButton(symbol: "flag.fill", label: "Resign") { confirmResign = true }
        .disabled(!game.active)
        .opacity(game.active ? 1 : 0.35)
    }
  }

  @ViewBuilder
  private var footer: some View {
    if let result = game.result {
      VStack(spacing: 14) {
        VStack(spacing: 4) {
          Text(result.title).font(.system(size: 30, weight: .heavy))
          Text("\(game.reason) · \(game.moveCount) \(game.moveCount == 1 ? "move" : "moves")")
            .font(.system(size: 15, weight: .medium)).foregroundStyle(Theme.inkMuted)
        }
        .foregroundStyle(Theme.ink)
        HStack(spacing: 10) {
          SoftPill(title: "Done") { dismiss() }
          InkPill(title: "Play again", symbol: "arrow.clockwise") {
            game.newGame(side: SidePreference(rawValue: side) ?? .white, level: level, timeControl: timeControl)
          }
        }
      }
      .padding(.vertical, 18)
      .frame(maxWidth: .infinity)
      .background(Theme.raised, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
      .transition(.move(edge: .bottom).combined(with: .opacity))
    } else {
      Text(game.thinking ? "Computer's move" : game.checkedKing != nil ? "Check · your move" : "Your move")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(Theme.inkMuted)
        .contentTransition(.opacity)
        .frame(height: 56)
    }
  }

  static func clock(_ seconds: TimeInterval) -> String {
    let total = max(Int(seconds.rounded(.down)), 0)
    return String(format: "%d:%02d", total / 60, total % 60)
  }
}

/// A player above or below the board: who, what they have taken, their clock.
struct PlayerRow: View {
  let name: String
  let symbol: String
  let tint: Color
  let taken: [Piece]
  let clock: TimeInterval?
  let running: Bool
  let thinking: Bool

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: symbol)
        .font(.system(size: 16, weight: .bold))
        .foregroundStyle(tint)
        .frame(width: 40, height: 40)
        .background(Theme.raised, in: Circle())
      VStack(alignment: .leading, spacing: 2) {
        Text(name).font(.system(size: 16, weight: .bold)).foregroundStyle(Theme.ink)
        if thinking {
          Text("Thinking…").font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.inkMuted)
            .phaseAnimator([0.4, 1]) { text, phase in text.opacity(phase) } animation: { _ in .easeInOut(duration: 0.7) }
        } else {
          HStack(spacing: -5) {
            ForEach(Array(taken.enumerated()), id: \.offset) { _, piece in
              Image(piece.assetName).resizable().scaledToFit().frame(width: 18, height: 18)
            }
          }
          .frame(height: 16)
        }
      }
      Spacer()
      if let clock {
        Text(GameView.clock(clock))
          .font(.system(size: 20, weight: .bold)).monospacedDigit()
          .foregroundStyle(running ? Theme.onInk : Theme.ink)
          .padding(.horizontal, 12)
          .frame(height: 38)
          .background(running ? Theme.ink : Theme.raised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
      }
    }
    .animation(Theme.spring, value: running)
  }
}
