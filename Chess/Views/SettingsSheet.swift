import SwiftUI

enum SettingsPage: String, Identifiable, Hashable {
  case root, difficulty, app, game, notifications, about
  var id: Self { self }
}

/// The settings sheet: a level banner, then rows that push pages with a round Back button.
struct SettingsSheet: View {
  let start: SettingsPage
  @State private var path: [SettingsPage] = []

  var body: some View {
    NavigationStack(path: $path) {
      SettingsRoot(path: $path)
        .navigationDestination(for: SettingsPage.self) { page in
          SettingsPageView(page: page, path: $path)
        }
    }
    .onAppear { if start != .root, path.isEmpty { path = [start] } }
  }
}

private struct SettingsRoot: View {
  @Binding var path: [SettingsPage]
  @Environment(History.self) private var history
  @AppStorage(Pref.level) private var level = Level.medium

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        banner.padding(.bottom, 14)
        row(.difficulty, symbol: "star.fill", title: "Difficulty")
        row(.app, symbol: "circle.lefthalf.filled", title: "App Settings")
        row(.game, symbol: "checkerboard.rectangle", title: "Game Settings")
        row(.notifications, symbol: "bell.badge.fill", title: "Notifications")
        row(.about, symbol: "bubble.left.fill", title: "Feedback and more")
      }
      .padding(.horizontal, 20)
      .padding(.top, 30)
    }
    .background(Theme.card)
    .toolbar(.hidden, for: .navigationBar)
  }

  private var banner: some View {
    let streak = history.streak()
    return VStack(spacing: 6) {
      HStack(spacing: 8) {
        Image(systemName: level.symbol).font(.system(size: 18, weight: .bold))
        Text(level.name).font(.system(size: 24, weight: .heavy))
      }
      Text(streak == 0 ? "No streak yet" : "\(streak)-day streak")
        .font(.system(size: 16, weight: .semibold)).opacity(0.9)
      Button { path.append(.difficulty) } label: {
        HStack(spacing: 8) {
          Image(systemName: level.symbol).font(.system(size: 15, weight: .bold))
          Text("Change level").font(.system(size: 18, weight: .bold))
        }
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 26)
        .frame(height: 52)
        .background(Theme.card, in: Capsule())
      }
      .buttonStyle(SoftPress())
      .padding(.top, 10)
    }
    .foregroundStyle(.white)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 22)
    .background(level.tint, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    .shadow(color: level.tint.opacity(0.3), radius: 18, y: 10)
  }

  private func row(_ page: SettingsPage, symbol: String, title: String) -> some View {
    Button { path.append(page) } label: { SettingsRowLabel(symbol: symbol, title: title) }
      .buttonStyle(SoftPress())
  }
}

private struct SettingsPageView: View {
  let page: SettingsPage
  @Binding var path: [SettingsPage]

  var body: some View {
    VStack(spacing: 0) {
      SheetHeader(title: title) { _ = path.popLast() }
      ScrollView {
        Group {
          switch page {
          case .root: EmptyView()
          case .difficulty: DifficultyPage()
          case .app: AppSettingsPage()
          case .game: GameSettingsPage()
          case .notifications: NotificationsPage()
          case .about: AboutPage()
          }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 32)
      }
    }
    .background(Theme.card)
    .toolbar(.hidden, for: .navigationBar)
  }

  private var title: String {
    switch page {
    case .root: "Settings"
    case .difficulty: "Difficulty"
    case .app: "App Settings"
    case .game: "Game Settings"
    case .notifications: "Notifications"
    case .about: "Feedback and more"
    }
  }
}

private struct DifficultyPage: View {
  @AppStorage(Pref.level) private var level = Level.medium

  var body: some View {
    VStack(spacing: 10) {
      ForEach(Level.allCases) { option in
        LevelRow(level: option, selected: option == level) {
          withAnimation(Theme.spring) { level = option }
          Haptics.selection()
        }
      }
      Text("Sets the computer's strength and the daily puzzle from your next game.")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(Theme.inkMuted)
        .multilineTextAlignment(.center)
        .padding(.top, 8)
    }
  }
}

private struct AppSettingsPage: View {
  @AppStorage(Pref.appearance) private var appearance = Appearance.system
  @AppStorage(Pref.haptics) private var haptics = true
  @AppStorage(Pref.sounds) private var sounds = true
  @AppStorage(Pref.appIcon) private var appIcon = "classic"
  @Namespace private var thumb

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 4) {
        ForEach(Appearance.allCases) { option in
          let chosen = appearance == option
          Button {
            withAnimation(Theme.spring) { appearance = option }
            Haptics.selection()
          } label: {
            HStack(spacing: 8) {
              Image(systemName: option.symbol).font(.system(size: 17, weight: .bold))
              if chosen { Text(option.name).font(.system(size: 17, weight: .bold)) }
            }
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: chosen ? .infinity : 64)
            .frame(height: 50)
            .background {
              if chosen {
                Capsule().fill(Theme.card).softShadow(radius: 8, y: 3).matchedGeometryEffect(id: "thumb", in: thumb)
              }
            }
          }
          .buttonStyle(.plain)
        }
      }
      .padding(5)
      .background(Theme.raised, in: Capsule())

      Hairline().padding(.vertical, 22)

      SectionLabel(title: "App Icon").padding(.bottom, 14)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 14) {
          ForEach(["classic", "night", "mono"], id: \.self) { icon in
            Button {
              withAnimation(Theme.spring) { appIcon = icon }
              Haptics.selection()
            } label: {
              IconTile(style: icon, selected: appIcon == icon)
            }
            .buttonStyle(SoftPress())
          }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 2)
      }

      Hairline().padding(.top, 14).padding(.bottom, 6)
      ToggleRow(symbol: "iphone.radiowaves.left.and.right", title: "Haptic Feedback", isOn: $haptics)
      ToggleRow(symbol: "speaker.wave.2.fill", title: "Sounds", isOn: $sounds)
    }
  }
}

/// An app icon choice: a knight on a tile, ringed in ink with a check when chosen.
private struct IconTile: View {
  let style: String
  let selected: Bool

  var body: some View {
    PieceSet.cburnett.image(style == "night" ? "bN" : "wN")
      .resizable().scaledToFit()
      .padding(18)
      .opacity(style == "mono" ? 0.45 : 1)
      .frame(width: 96, height: 96)
      .background(style == "night" ? Color(white: 0.15) : .white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .strokeBorder(selected ? Theme.ink : Theme.hairline, lineWidth: selected ? 3.5 : 1.5)
      }
      .overlay(alignment: .topTrailing) {
        if selected {
          Image(systemName: "checkmark")
            .font(.system(size: 12, weight: .heavy))
            .foregroundStyle(Theme.onInk)
            .frame(width: 30, height: 30)
            .background(Theme.ink, in: Circle())
            .overlay(Circle().strokeBorder(Theme.card, lineWidth: 2.5))
            .offset(x: 8, y: -8)
            .transition(.scale.combined(with: .opacity))
        }
      }
  }
}

private struct GameSettingsPage: View {
  @AppStorage(Pref.timeControl) private var timeControl = TimeControl.none
  @AppStorage(Pref.coordinates) private var coordinates = true
  @AppStorage(Pref.legalMoves) private var legalMoves = true
  @AppStorage(Pref.autoQueen) private var autoQueen = false
  @AppStorage(Pref.turnBoard) private var turnBoard = false
  @AppStorage(Pref.boardTheme) private var boardTheme = BoardTheme.stone
  @AppStorage(Pref.pieceSet) private var pieceSet = PieceSet.cburnett

  var body: some View {
    VStack(spacing: 0) {
      SectionLabel(title: "Board").padding(.bottom, 12)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(BoardTheme.allCases) { theme in
            ThemeChoice(name: theme.name, selected: boardTheme == theme) {
              withAnimation(Theme.spring) { boardTheme = theme }
            } tile: {
              Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                GridRow { theme.light; theme.dark }
                GridRow { theme.dark; theme.light }
              }
            }
          }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 2)
      }

      SectionLabel(title: "Pieces").padding(.top, 14).padding(.bottom, 12)
      HStack(spacing: 12) {
        ForEach(PieceSet.allCases) { set in
          ThemeChoice(name: set.name, selected: pieceSet == set) {
            withAnimation(Theme.spring) { pieceSet = set }
          } tile: {
            ZStack {
              boardTheme.light
              HStack(spacing: -6) {
                set.image("wN").resizable().scaledToFit()
                set.image("bN").resizable().scaledToFit()
              }
              .padding(8)
            }
          }
        }
        Spacer(minLength: 0)
      }
      .padding(.vertical, 10)
      .padding(.horizontal, 2)

      Hairline().padding(.top, 14).padding(.bottom, 22)
      SectionLabel(title: "Clock").padding(.bottom, 12)
      FlowLayout(spacing: 8) {
        ForEach(TimeControl.allCases) { option in
          Chip(title: option.name, selected: timeControl == option) {
            withAnimation(Theme.spring) { timeControl = option }
            Haptics.selection()
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      Hairline().padding(.top, 22).padding(.bottom, 6)
      ToggleRow(symbol: "textformat.abc", title: "Coordinates", isOn: $coordinates)
      ToggleRow(symbol: "smallcircle.filled.circle", title: "Show Legal Moves", isOn: $legalMoves)
      ToggleRow(symbol: "crown.fill", title: "Always Promote to Queen", isOn: $autoQueen)
      ToggleRow(symbol: "arrow.trianglehead.2.clockwise.rotate.90", title: "Turn Board in Free Play", isOn: $turnBoard)
    }
  }
}

/// A choosable look: a rounded tile ringed in ink with a check when chosen, its name below.
private struct ThemeChoice<Tile: View>: View {
  let name: String
  let selected: Bool
  let action: () -> Void
  @ViewBuilder let tile: () -> Tile

  var body: some View {
    Button {
      action()
      Haptics.selection()
    } label: {
      VStack(spacing: 8) {
        tile()
          .frame(width: 76, height: 76)
          .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
          .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
              .strokeBorder(selected ? Theme.ink : Theme.hairline, lineWidth: selected ? 3.5 : 1.5)
          }
          .overlay(alignment: .topTrailing) {
            if selected {
              Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(Theme.onInk)
                .frame(width: 26, height: 26)
                .background(Theme.ink, in: Circle())
                .overlay(Circle().strokeBorder(Theme.card, lineWidth: 2.5))
                .offset(x: 7, y: -7)
                .transition(.scale.combined(with: .opacity))
            }
          }
        Text(name)
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(selected ? Theme.ink : Theme.inkMuted)
      }
    }
    .buttonStyle(SoftPress())
    .accessibilityLabel(name)
    .accessibilityAddTraits(selected ? .isSelected : [])
  }
}

private struct NotificationsPage: View {
  @AppStorage(Pref.reminder) private var reminder = false
  @AppStorage(Pref.reminderHour) private var reminderHour = 9

  var body: some View {
    VStack(spacing: 10) {
      ToggleRow(symbol: "bell.badge.fill", title: "Daily Reminder", isOn: $reminder)
      if reminder {
        ReminderHours(hour: $reminderHour).transition(.opacity)
      }
    }
    .animation(Theme.spring, value: reminder)
    .onChange(of: reminder) { _, on in on ? Reminders.schedule(hour: reminderHour) : Reminders.cancel() }
    .onChange(of: reminderHour) { _, hour in if reminder { Reminders.schedule(hour: hour) } }
  }
}

private struct AboutPage: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Chess is free software under the GPLv3.").font(.system(size: 17, weight: .semibold))
      Text("Engine: Stockfish 17 (GPLv3) via ChessKitEngine (MIT). Rules: ChessKit (MIT). Pieces: cburnett (GPLv2+). Puzzles: the lichess.org database (CC0).")
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(Theme.inkMuted)
    }
    .foregroundStyle(Theme.ink)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
