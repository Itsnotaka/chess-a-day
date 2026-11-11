import ChessKit
import SwiftUI

struct HomeView: View {
  @Environment(GameStore.self) private var game
  @Environment(Games.self) private var games
  @Environment(OnlineGames.self) private var online
  @Environment(LearnProgress.self) private var learning
  @Environment(History.self) private var history
  @AppStorage(Pref.level) private var level = Level.medium
  @AppStorage(Pref.timeControl) private var timeControl = TimeControl.none

  @State private var day = Date.now
  @State private var settings: SettingsPage?
  @State private var playing: GameMode?
  @State private var showingStreak = false
  @State private var showingLearn = false
  @State private var lesson: LessonRequest?
  @State private var afterLearn: LessonRequest?

  @State private var showingStats = false

  private var isToday: Bool { Calendar.current.isDateInToday(day) }

  var body: some View {
    VStack(spacing: 18) {
      topBar
      card
      HStack(spacing: 10) {
        Button { showingLearn = true } label: {
          TileLabel(symbol: "graduationcap.fill", title: "Learn", detail: learnDetail, badge: nil)
        }
        .buttonStyle(SoftPress())
        Button { playFriend() } label: {
          TileLabel(symbol: "iphone", title: "Free play",
                    detail: games.friend.active ? "In progress" : "One phone", badge: nil)
        }
        .buttonStyle(SoftPress())
        onlineTile
      }
      DayStrip(selected: $day)
    }
    .padding(.horizontal, 20)
    .padding(.top, 8)
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    .background(Theme.ground.ignoresSafeArea())
    .sheet(item: $settings) { page in
      SettingsSheet(start: page)
    }
    .onChange(of: online.presentRequest) {
      settings = nil
      playing = .online
    }
    .alert("Online play", isPresented: Binding(get: { online.problem != nil }, set: { if !$0 { online.problem = nil } })) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(online.problem ?? "")
    }
    .sheet(isPresented: $showingLearn, onDismiss: {
      lesson = afterLearn
      afterLearn = nil
    }) {
      LearnSheet { request in
        afterLearn = request
        showingLearn = false
      }
    }
    .fullScreenCover(item: $lesson) { request in
      LessonScreen(request: request)
    }
    .sheet(isPresented: $showingStreak) {
      FittedSheet { StreakSheet() }
    }
    .sheet(isPresented: $showingStats) {
      FittedSheet { StatsSheet() }
    }
    .fullScreenCover(item: $playing) { mode in
      GameView().environment(games.store(mode))
    }
    #if DEBUG
    .onAppear {
      switch UserDefaults.standard.string(forKey: "debugOpen") {
      case "game"?: play()
      case "friend"?: playFriend()
      case "online"?: online.startInvite()
      case "learn"?: showingLearn = true
      case let page? where page.hasPrefix("lesson-"):
        lesson = LessonRequest(course: String(page.dropFirst(7)), lesson: 1, practice: false)
      case let page?: settings = SettingsPage(rawValue: page.replacingOccurrences(of: "settings-", with: ""))
      case nil: break
      }
    }
    #endif
  }

  private var topBar: some View {
    HStack(spacing: 10) {
      CircleIconButton(symbol: level.symbol, label: "Level: \(level.name)", tint: level.tint) { settings = .difficulty }
      CircleIconButton(symbol: "laurel.leading", label: "Streak, \(history.streak()) days") { showingStreak = true }
      Spacer()
      CircleIconButton(symbol: "chart.bar.fill", label: "Stats") { showingStats = true }
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
      .scaledFont(46, .heavy)
      .tracking(-1.8)
      .lineLimit(1)
      .minimumScaleFactor(0.7)
      .contentTransition(.numericText())

      HStack(spacing: 8) {
        Circle().fill(game.active ? Theme.live : Theme.inkFaint).frame(width: 9, height: 9)
        Text(status).scaledFont(15, .semibold).foregroundStyle(Theme.inkMuted)
      }
      .padding(.top, 12)

      Spacer(minLength: 16)

      ZStack {
        MiniBoard(pieces: game.pieces, flipped: game.you == .black)
          .rotationEffect(.degrees(-2))
          .frame(maxWidth: 290)
        if isToday {
          InkPill(title: game.active ? "Continue" : "Play", symbol: "play.fill") { play() }
        } else {
          InkPill(title: "Back to today", symbol: "arrow.uturn.backward") {
            withAnimation(Theme.spring) { day = .now }
          }
        }
      }

      Spacer(minLength: 16)

      if !isToday {
        Color.clear.frame(height: 48)
      } else if game.active {
        Text("Playing as \(game.you == .white ? "White" : "Black") · \(game.level.name)")
          .scaledFont(15, .bold)
          .foregroundStyle(Theme.ink)
          .frame(height: 48)
      } else {
        SidePicker()
      }
    }
    .padding(.horizontal, 24)
    .padding(.top, 30)
    .padding(.bottom, 22)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    .softShadow(radius: 30, y: 14)
  }

  @ViewBuilder
  private var onlineTile: some View {
    let games = online.summaries.filter { !$0.finished }
    let label = TileLabel(symbol: "paperplane.fill", title: "Online", detail: onlineDetail,
                          badge: online.yourMoveCount > 0 ? "\(online.yourMoveCount)" : nil)
    if games.isEmpty {
      Button { online.startInvite() } label: { label }
        .buttonStyle(SoftPress())
    } else {
      Menu {
        Button("Invite a friend", systemImage: "paperplane") { online.startInvite() }
        Section("Your games") {
          ForEach(games) { game in
            Button("\(game.opponent) · \(game.label)", systemImage: game.state == .yourMove ? "circle.fill" : "circle") {
              Task {
                if await online.open(game.id) { playing = .online }
              }
            }
          }
        }
      } label: { label }
        .buttonStyle(SoftPress())
    }
  }

  private var onlineDetail: String {
    let count = online.yourMoveCount
    if count > 0 { return count == 1 ? "Your move" : "\(count) waiting" }
    return online.summaries.contains { !$0.finished } ? "In progress" : "Invite"
  }

  private var learnDetail: String {
    let started = Courses.all.first { learning.learned(in: $0) > 0 && learning.learned(in: $0) < $0.lessons.count }
    return started?.title ?? "\(Courses.all.count) courses"
  }

  private var status: String {
    if !isToday {
      let played = history.games.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
      guard !played.isEmpty else { return history.days[DayKey.of(day)]?.puzzle == true ? "Puzzle solved" : "Nothing played" }
      let wins = played.filter { $0.result == .win }.count
      return "\(played.count) \(played.count == 1 ? "game" : "games") · \(wins) won"
    }
    if game.active { return game.yourTurn ? "Game in progress · your move" : "Game in progress" }
    if history.days[DayKey.of(day)]?.game == true { return "Played today · \(level.name)" }
    return "\(level.name) · \(timeControl.name)"
  }

  private func play() {
    Haptics.tap()
    if !game.active {
      let side = SidePreference(rawValue: UserDefaults.standard.string(forKey: Pref.side) ?? "") ?? .white
      game.newGame(side: side, level: level, timeControl: timeControl)
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

struct TileLabel: View {
  let symbol: String
  let title: String
  let detail: String
  let badge: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .top) {
        Image(systemName: symbol)
          .font(.system(size: 17, weight: .bold))
          .foregroundStyle(Theme.ink)
          .frame(width: 42, height: 42)
          .background(Theme.raised, in: Circle())
        Spacer(minLength: 0)
        if let badge {
          Text(badge)
            .scaledFont(14, .heavy)
            .foregroundStyle(Theme.onInk)
            .frame(minWidth: 26, minHeight: 26)
            .background(Theme.ink, in: Capsule())
            .motionTransition(.scale.combined(with: .opacity))
        }
      }
      VStack(alignment: .leading, spacing: 2) {
        Text(title).scaledFont(17, .bold).foregroundStyle(Theme.ink)
        Text(detail).scaledFont(14, .semibold).foregroundStyle(Theme.inkMuted).lineLimit(1)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(Theme.card, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    .softShadow(radius: 16, y: 6)
    .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    .accessibilityElement(children: .combine)
    .accessibilityHint(badge.map { "\($0) waiting on your move" } ?? "")
  }
}

struct SidePicker: View {
  @AppStorage(Pref.side) private var side = SidePreference.white

  var body: some View {
    PillSegments(options: SidePreference.allCases, selection: $side, name: \.name) { option, active in
      HStack(spacing: 6) {
        Circle()
          .fill(option == .white ? Color.white : option == .black ? Theme.ink : Theme.inkFaint)
          .overlay(Circle().strokeBorder(active ? Theme.ink : Theme.inkMuted, lineWidth: 1.5))
          .frame(width: 12, height: 12)
        Text(option.name).scaledFont(15, .bold)
      }
      .foregroundStyle(active ? Theme.ink : Theme.inkMuted)
    }
    .frame(maxWidth: 330)
  }
}

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
              .scaledFont(15, .semibold).foregroundStyle(Theme.inkMuted)
            Text(day.formatted(.dateTime.day()))
              .scaledFont(26, .bold).monospacedDigit().foregroundStyle(Theme.ink)
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
        .accessibilityLabel("\(day.formatted(.dateTime.weekday(.wide).month(.wide).day())), \(StreakSheet.describe(history.days[DayKey.of(day)]))")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
      }
    }
  }
}

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
