import ChessKit
import SwiftUI

/// Home: the round buttons, today's card with Play, the daily puzzle row and the day strip.
struct HomeView: View {
  @Environment(GameStore.self) private var game
  @Environment(Games.self) private var games
  @Environment(History.self) private var history
  @AppStorage(Pref.level) private var level = Level.medium
  @AppStorage(Pref.side) private var side = SidePreference.white.rawValue
  @AppStorage(Pref.timeControl) private var timeControl = TimeControl.none

  @State private var day = Date.now
  @State private var settings: SettingsPage?
  @State private var playing: GameMode?

  var body: some View {
    VStack(spacing: 18) {
      topBar
      card
      HStack(spacing: 12) {
        HomeTile(symbol: "puzzlepiece.fill", tint: level.tint, title: "Daily puzzle", detail: "\(level.name) · one a day") { settings = .root }
        HomeTile(symbol: "person.2.fill", tint: Theme.ink, title: "Free play",
                 detail: games.friend.active ? "Continue game" : "Two players") { playFriend() }
      }
      DayStrip(selected: $day)
    }
    .padding(.horizontal, 20)
    .padding(.top, 8)
    .background(Theme.ground.ignoresSafeArea())
    .sheet(item: $settings) { page in
      SettingsSheet(start: page)
        .presentationDetents([.fraction(0.74), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Theme.Radius.card)
        .presentationBackground(Theme.card)
    }
    .fullScreenCover(item: $playing) { mode in
      GameView().environment(games.store(mode))
    }
    #if DEBUG
    // `simctl launch … -debugOpen game|friend|settings-<page>` opens a screen for screenshots.
    .onAppear {
      switch UserDefaults.standard.string(forKey: "debugOpen") {
      case "game"?: play()
      case "friend"?: playFriend()
      case let page?: settings = SettingsPage(rawValue: page.replacingOccurrences(of: "settings-", with: ""))
      case nil: break
      }
    }
    #endif
  }

  private var topBar: some View {
    HStack(spacing: 10) {
      CircleIconButton(symbol: level.symbol, label: "Level: \(level.name)", tint: level.tint) { settings = .difficulty }
      // Streak, Awards and Stats get their own screens next; until then they only answer the press.
      CircleIconButton(symbol: "laurel.leading", label: "\(history.streak())-day streak") { Haptics.selection() }
      CircleIconButton(symbol: "trophy.fill", label: "Awards") { Haptics.selection() }
      Spacer()
      CircleIconButton(symbol: "chart.bar.fill", label: "Stats") { Haptics.selection() }
      CircleIconButton(symbol: "gearshape.fill", label: "Settings") { settings = .root }
    }
  }

  private var card: some View {
    VStack(spacing: 0) {
      VStack(spacing: -2) {
        Text(day.formatted(.dateTime.weekday(.wide)))
          .foregroundStyle(LinearGradient(colors: [Theme.inkFaint, Theme.inkFaint.opacity(0)], startPoint: .top, endPoint: .bottom))
        Text(day.formatted(.dateTime.month(.wide).day()))
          .foregroundStyle(Theme.ink)
      }
      .font(.system(size: 46, weight: .heavy))
      .tracking(-1.8)
      .lineLimit(1)
      .minimumScaleFactor(0.7)
      .contentTransition(.numericText())

      HStack(spacing: 8) {
        Circle().fill(game.active ? Theme.live : Theme.inkFaint).frame(width: 9, height: 9)
        Text(status).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.inkMuted)
      }
      .padding(.top, 12)

      Spacer(minLength: 16)

      ZStack {
        MiniBoard(pieces: game.pieces, flipped: game.you == .black)
          .rotationEffect(.degrees(-2))
          .frame(maxWidth: 290)
        InkPill(title: game.active ? "Continue" : "Play", symbol: "play.fill") { play() }
      }

      Spacer(minLength: 16)

      if game.active {
        Text("Playing as \(game.you == .white ? "White" : "Black") · \(game.level.name)")
          .font(.system(size: 15, weight: .bold))
          .foregroundStyle(Theme.ink)
          .frame(height: 48)
      } else {
        SidePicker(side: $side)
      }
    }
    .padding(.horizontal, 24)
    .padding(.top, 30)
    .padding(.bottom, 22)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    .softShadow(radius: 30, y: 14)
  }

  private var status: String {
    if game.active { return game.yourTurn ? "Game in progress · your move" : "Game in progress" }
    if history.days[DayKey.of(day)]?.game == true { return "Played today · \(level.name)" }
    return "\(level.name) · \(timeControl.name)"
  }

  private func play() {
    Haptics.tap()
    if !game.active {
      game.newGame(side: SidePreference(rawValue: side) ?? .white, level: level, timeControl: timeControl)
    }
    playing = .computer
  }

  private func playFriend() {
    Haptics.tap()
    if !games.friend.active {
      games.friend.newGame(side: .white, level: level, timeControl: timeControl)
    }
    playing = .friend
  }
}

/// A half-width tile under the card: a round symbol, a title and one line.
struct HomeTile: View {
  let symbol: String
  let tint: Color
  let title: String
  let detail: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 10) {
        Image(systemName: symbol)
          .font(.system(size: 17, weight: .bold))
          .foregroundStyle(tint)
          .frame(width: 40, height: 40)
          .background(Theme.raised, in: Circle())
        VStack(alignment: .leading, spacing: 2) {
          Text(title).font(.system(size: 17, weight: .bold)).foregroundStyle(Theme.ink)
          Text(detail).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.inkMuted).lineLimit(1)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(14)
      .background(Theme.card, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
      .softShadow(radius: 16, y: 6)
    }
    .buttonStyle(SoftPress())
  }
}

/// White · Random · Black, a segmented pill.
struct SidePicker: View {
  @Binding var side: String
  @Namespace private var thumb

  var body: some View {
    HStack(spacing: 4) {
      ForEach(SidePreference.allCases) { option in
        Button {
          withAnimation(Theme.spring) { side = option.rawValue }
          Haptics.selection()
        } label: {
          HStack(spacing: 6) {
            Circle()
              .fill(option == .white ? Color.white : option == .black ? Theme.ink : Theme.inkFaint)
              .overlay(Circle().strokeBorder(Theme.ink, lineWidth: 1.5))
              .frame(width: 12, height: 12)
            Text(option.name).font(.system(size: 15, weight: .bold))
          }
          .foregroundStyle(Theme.ink)
          .padding(.horizontal, 14)
          .frame(height: 40)
          .background {
            if side == option.rawValue {
              Capsule().fill(Theme.card).softShadow(radius: 6, y: 2).matchedGeometryEffect(id: "thumb", in: thumb)
            }
          }
        }
        .buttonStyle(.plain)
      }
    }
    .padding(4)
    .background(Theme.raised, in: Capsule())
  }
}

/// Five days around the chosen one; each ring fills as its game and puzzle are done.
struct DayStrip: View {
  @Binding var selected: Date
  @Environment(History.self) private var history

  private var days: [Date] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)
    return (-3...1).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
  }

  var body: some View {
    HStack(spacing: 0) {
      ForEach(days, id: \.self) { day in
        let isSelected = Calendar.current.isDate(day, inSameDayAs: selected)
        let future = day > .now
        Button {
          withAnimation(Theme.spring) { selected = day }
          Haptics.selection()
        } label: {
          VStack(spacing: 4) {
            Text(day.formatted(.dateTime.weekday(.abbreviated)))
              .font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.inkMuted)
            Text(day.formatted(.dateTime.day()))
              .font(.system(size: 26, weight: .bold)).monospacedDigit().foregroundStyle(Theme.ink)
            DayRing(count: history.days[DayKey.of(day)]?.count ?? 0)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background {
            if isSelected { RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.pressed) }
          }
          .opacity(future ? 0.35 : 1)
        }
        .buttonStyle(.plain)
        .disabled(future)
      }
    }
  }
}

/// Dashed when nothing is done, half when one of the two is, filled with a check for both.
struct DayRing: View {
  let count: Int

  var body: some View {
    ZStack {
      Circle()
        .strokeBorder(Theme.inkFaint, style: StrokeStyle(lineWidth: 1.5, dash: [2.5, 3]))
        .opacity(count == 0 ? 1 : 0)
      Circle()
        .trim(from: 0, to: count == 0 ? 0 : count == 1 ? 0.5 : 1)
        .stroke(Theme.ink, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .padding(1.25)
      if count == 2 {
        Circle().fill(Theme.ink)
        Image(systemName: "checkmark").font(.system(size: 10, weight: .heavy)).foregroundStyle(Theme.onInk)
      }
    }
    .frame(width: 24, height: 24)
    .padding(.top, 2)
  }
}
