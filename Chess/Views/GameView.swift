import ChessKit
import SwiftUI

/// A game against the computer, full screen. Top to bottom: header, the computer, the board,
/// you, the moves so far, and the bar with Resign and Flip (the result card when it ends).
struct GameView: View {
  @Environment(GameStore.self) private var game
  @Environment(\.dismiss) private var dismiss
  @AppStorage(Pref.level) private var level = Level.medium
  @AppStorage(Pref.side) private var side = SidePreference.white.rawValue
  @AppStorage(Pref.timeControl) private var timeControl = TimeControl.none
  @AppStorage(Pref.turnBoard) private var turnBoard = false
  @State private var confirmResign = false
  @State private var settings = false

  var body: some View {
    @Bindable var game = game
    TimelineView(.periodic(from: .now, by: 0.25)) { timeline in
      VStack(spacing: 0) {
        header(now: timeline.date)
        Spacer(minLength: 12)
        VStack(spacing: 12) {
          player(game.bottom(turnBoard: turnBoard).opposite, now: timeline.date)
          BoardView()
          player(game.bottom(turnBoard: turnBoard), now: timeline.date)
        }
        Spacer(minLength: 12)
        MoveList(moves: game.san)
        Spacer(minLength: 12)
        footer
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 4)
      .onChange(of: timeline.date) { _, now in game.checkFlag(at: now) }
    }
    .background(Theme.card.ignoresSafeArea())
    .animation(Theme.spring, value: game.isOver)
    .confirmationDialog(resignQuestion, isPresented: $confirmResign, titleVisibility: .visible) {
      Button("Resign", role: .destructive) { game.resign() }
      Button("Keep playing", role: .cancel) {}
    }
    .sheet(isPresented: $settings) {
      SettingsSheet(start: .game)
        .presentationDetents([.fraction(0.6), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Theme.Radius.card)
        .presentationBackground(Theme.card)
    }
  }

  /// One side's row: the computer or you against the computer, White or Black in free play.
  private func player(_ color: Piece.Color, now: Date) -> some View {
    let colorName = color == .white ? "White" : "Black"
    let toMove = game.active && game.sideToMove == color
    let isComputer = game.mode == .computer && color != game.you
    let status: String? = if isComputer {
      game.thinking ? "Thinking…" : nil
    } else if toMove && !game.thinking {
      game.checkedKing != nil ? "Check" : game.mode == .friend ? "To move" : "Your move"
    } else {
      nil
    }
    return PlayerRow(
      name: game.mode == .friend ? colorName : isComputer ? "Computer" : "You",
      detail: game.mode == .friend ? "" : isComputer ? game.level.name : colorName,
      symbol: game.mode == .friend ? (color == .white ? "circle" : "circle.fill") : isComputer ? game.level.symbol : "person.fill",
      tint: isComputer ? game.level.tint : Theme.ink,
      taken: game.taken(by: color),
      clock: game.timeLeft(color, at: now),
      status: status,
      active: toMove)
  }

  private func header(now: Date) -> some View {
    HStack {
      RaisedCircleButton(symbol: "chevron.down", label: "Close") { dismiss() }
      Spacer()
      VStack(spacing: 2) {
        Text(game.mode == .friend ? "Free play" : game.level.name)
          .font(.system(size: 17, weight: .bold))
          .foregroundStyle(Theme.ink)
        HStack(spacing: 5) {
          Image(systemName: "clock").font(.system(size: 12, weight: .bold))
          Text(Self.clock(now.timeIntervalSince(game.saved?.startedAt ?? now)))
            .font(.system(size: 15, weight: .semibold)).monospacedDigit()
        }
        .foregroundStyle(Theme.inkMuted)
      }
      Spacer()
      RaisedCircleButton(symbol: "gearshape.fill", label: "Game Settings") { settings = true }
    }
    .padding(.top, 4)
  }

  private var resignQuestion: String {
    game.mode == .friend ? "Resign for \(game.sideToMove == .white ? "White" : "Black")?" : "Resign this game?"
  }

  @ViewBuilder
  private var footer: some View {
    if let result = game.result {
      VStack(spacing: 14) {
        VStack(spacing: 4) {
          Text(result.title).font(.system(size: 30, weight: .heavy))
          Text("\(game.reason) · \(game.moveCount) \(game.moveCount == 1 ? "move" : "moves")")
            .font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.inkMuted)
        }
        .foregroundStyle(Theme.ink)
        HStack(spacing: 10) {
          SoftPill(title: "Done") { dismiss() }
          InkPill(title: "Play again", symbol: "arrow.clockwise") {
            game.newGame(side: game.mode == .friend ? .white : SidePreference(rawValue: side) ?? .white, level: level, timeControl: timeControl)
          }
        }
      }
      .padding(.vertical, 18)
      .frame(maxWidth: .infinity)
      .background(Theme.raised, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
      .transition(.move(edge: .bottom).combined(with: .opacity))
    } else {
      HStack(spacing: 12) {
        RaisedCircleButton(symbol: "flag.fill", label: "Resign", size: 56) { confirmResign = true }
          .disabled(!game.active)
        Spacer()
        Button {
          withAnimation(Theme.spring) { game.flipped.toggle() }
          Haptics.selection()
        } label: {
          HStack(spacing: 8) {
            Image(systemName: "arrow.up.arrow.down").font(.system(size: 15, weight: .bold))
            Text("Flip board").font(.system(size: 17, weight: .bold))
          }
          .foregroundStyle(Theme.ink)
          .padding(.horizontal, 22)
          .frame(height: 56)
          .background(Theme.raised, in: Capsule())
        }
        .buttonStyle(SoftPress())
      }
    }
  }

  static func clock(_ seconds: TimeInterval) -> String {
    let total = max(Int(seconds.rounded(.down)), 0)
    return String(format: "%d:%02d", total / 60, total % 60)
  }
}

/// A player above or below the board: who, what they have taken, and either their clock or
/// a badge saying whose move it is.
struct PlayerRow: View {
  @AppStorage(Pref.pieceSet) private var pieceSet = PieceSet.cburnett
  let name: String
  let detail: String
  let symbol: String
  let tint: Color
  let taken: [Piece]
  let clock: TimeInterval?
  let status: String?
  let active: Bool

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: symbol)
        .font(.system(size: 17, weight: .bold))
        .foregroundStyle(tint)
        .frame(width: 44, height: 44)
        .background(Theme.raised, in: Circle())
      VStack(alignment: .leading, spacing: 3) {
        HStack(spacing: 6) {
          Text(name).font(.system(size: 17, weight: .bold)).foregroundStyle(Theme.ink)
          Text(detail).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.inkMuted)
        }
        if !taken.isEmpty {
          HStack(spacing: -5) {
            ForEach(Array(taken.enumerated()), id: \.offset) { _, piece in
              pieceSet.image(piece).resizable().scaledToFit().frame(width: 18, height: 18)
            }
          }
          .frame(height: 18)
          .transition(.opacity)
        }
      }
      Spacer(minLength: 8)
      if let clock {
        Text(GameView.clock(clock))
          .font(.system(size: 20, weight: .bold)).monospacedDigit()
          .foregroundStyle(active ? Theme.onInk : Theme.ink)
          .padding(.horizontal, 14)
          .frame(height: 40)
          .background(active ? Theme.ink : Theme.raised, in: Capsule())
      } else if let status {
        Text(status)
          .font(.system(size: 15, weight: .bold))
          .foregroundStyle(Theme.onInk)
          .padding(.horizontal, 14)
          .frame(height: 34)
          .background(Theme.ink, in: Capsule())
          .phaseAnimator(status == "Thinking…" ? [1, 0.55] : [1]) { view, phase in view.opacity(phase) } animation: { _ in .easeInOut(duration: 0.8) }
          .transition(.scale(scale: 0.8).combined(with: .opacity))
      }
    }
    .frame(minHeight: 44)
    .animation(Theme.spring, value: status)
    .animation(Theme.spring, value: taken.count)
    .animation(Theme.spring, value: active)
  }
}

/// The moves so far as numbered pairs, scrolled to the latest.
struct MoveList: View {
  let moves: [String]

  var body: some View {
    ScrollViewReader { reader in
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 6) {
          if moves.isEmpty {
            Text("Moves appear here")
              .font(.system(size: 15, weight: .semibold))
              .foregroundStyle(Theme.inkMuted)
              .padding(.horizontal, 12)
          }
          ForEach(Array(stride(from: 0, to: moves.count, by: 2)), id: \.self) { index in
            HStack(spacing: 6) {
              Text("\(index / 2 + 1).").foregroundStyle(Theme.inkMuted)
              move(index)
              if index + 1 < moves.count { move(index + 1) }
            }
            .id(index)
          }
        }
        .font(.system(size: 15, weight: .bold))
        .padding(.horizontal, 10)
      }
      .frame(height: 44)
      .background(Theme.raised, in: Capsule())
      .onChange(of: moves.count) { _, count in
        withAnimation(Theme.spring) { reader.scrollTo(max(count - 1, 0) / 2 * 2, anchor: .trailing) }
      }
    }
  }

  private func move(_ index: Int) -> some View {
    let latest = index == moves.count - 1
    return Text(moves[index])
      .foregroundStyle(latest ? Theme.onInk : Theme.ink)
      .padding(.horizontal, 8)
      .frame(height: 30)
      .background(latest ? Theme.ink : .clear, in: Capsule())
  }
}
