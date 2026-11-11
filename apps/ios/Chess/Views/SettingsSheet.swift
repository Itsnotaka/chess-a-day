import SwiftUI
import UIKit

enum SettingsPage: String, Identifiable, Hashable {
  case root, difficulty, app, game, notifications, about
  var id: Self { self }
}

struct SettingsSheet: View {
  let start: SettingsPage
  @State private var page: SettingsPage = .root

  var body: some View {
    ZStack(alignment: .top) {
      Group {
        if page == .root {
          SettingsRoot(open: open)
        } else {
          SettingsPageView(page: page, back: back)
        }
      }
      .id(page)
      .motionTransition(.asymmetric(
        insertion: .scale(scale: 0.96).combined(with: .opacity),
        removal: .opacity))
    }
    .clipped()
    .onAppear { page = start }
  }

  private func open(_ next: SettingsPage) {
    withAnimation(Theme.Tray.page) { page = next }
    Haptics.selection()
  }

  private func back() {
    withAnimation(Theme.Tray.page) { page = .root }
  }
}

private struct SettingsRoot: View {
  let open: (SettingsPage) -> Void
  @Environment(History.self) private var history
  @AppStorage(Pref.level) private var level = Level.medium

  var body: some View {
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
    .padding(.bottom, 12)
  }

  private var banner: some View {
    let streak = history.streak()
    return VStack(spacing: 6) {
      HStack(spacing: 8) {
        Image(systemName: level.symbol).scaledFont(18, .bold)
        Text(level.name).scaledFont(24, .heavy)
      }
      Text(streak == 0 ? "No streak yet" : "\(streak)-day streak")
        .scaledFont(16, .semibold).opacity(0.9)
      Button { open(.difficulty) } label: {
        Text("Change level")
          .scaledFont(18, .bold)
          .multilineTextAlignment(.center)
          .foregroundStyle(Theme.ink)
          .padding(.horizontal, 26)
          .padding(.vertical, 12)
          .frame(minHeight: 52)
          .background(Theme.card, in: Capsule())
      }
      .buttonStyle(SoftPress())
      .padding(.top, 10)
    }
    .foregroundStyle(Theme.onTint)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 22)
    .background(level.tint, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    .shadow(color: level.tint.opacity(0.3), radius: 18, y: 10)
  }

  private func row(_ page: SettingsPage, symbol: String, title: String) -> some View {
    Button { open(page) } label: { SettingsRowLabel(symbol: symbol, title: title) }
      .buttonStyle(SoftPress())
  }
}

private struct SettingsPageView: View {
  let page: SettingsPage
  let back: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      SheetHeader(title: title, back: back)
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
      .padding(.bottom, 24)
    }
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
      Text("Sets the computer's strength from your next game.")
        .scaledFont(14, .medium)
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
  @State private var current = AppIcon.current

  private func choose(_ icon: AppIcon) {
    guard icon != current, UIApplication.shared.supportsAlternateIcons else { return }
    Haptics.selection()
    UIApplication.shared.setAlternateIconName(icon.alternateName) { error in
      guard error == nil else { return }
      Task { @MainActor in withAnimation(Theme.spring) { current = icon } }
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      PillSegments(options: Appearance.allCases, selection: $appearance, height: 50, name: \.name) { option, active in
        HStack(spacing: 8) {
          Image(systemName: option.symbol).font(.system(size: 17, weight: .bold))
          Text(option.name).scaledFont(17, .bold).lineLimit(1)
        }
        .foregroundStyle(active ? Theme.ink : Theme.inkMuted)
      }

      Hairline().padding(.vertical, 22)

      SectionLabel(title: "App Icon").padding(.bottom, 14)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 14) {
          ForEach(AppIcon.allCases) { icon in
            Button { choose(icon) } label: {
              IconTile(icon: icon, selected: current == icon)
            }
            .buttonStyle(SoftPress())
            .accessibilityLabel("\(icon.name) icon")
            .accessibilityAddTraits(current == icon ? .isSelected : [])
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

enum AppIcon: String, CaseIterable, Identifiable {
  case classic, night, mono

  var id: Self { self }
  var name: String { rawValue.capitalized }

  var preview: String { "Icon\(rawValue.capitalized)" }

  var alternateName: String? {
    switch self {
    case .classic: nil
    case .night: "AppIcon-Night"
    case .mono: "AppIcon-Mono"
    }
  }

  @MainActor static var current: AppIcon {
    allCases.first { $0.alternateName == UIApplication.shared.alternateIconName } ?? .classic
  }
}

private struct IconTile: View {
  let icon: AppIcon
  let selected: Bool

  var body: some View {
    Image(icon.preview)
      .resizable()
      .interpolation(.high)
      .frame(width: 96, height: 96)
      .clipShape(RoundedRectangle(cornerRadius: 96 * 0.2237, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 96 * 0.2237, style: .continuous)
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
            .motionTransition(.scale.combined(with: .opacity))
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
      SectionLabel(title: "Clock").padding(.bottom, 4)
      Text("Applies from your next game.")
        .scaledFont(14, .medium)
        .foregroundStyle(Theme.inkMuted)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 12)
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
                .motionTransition(.scale.combined(with: .opacity))
            }
          }
        Text(name)
          .scaledFont(14, .bold)
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
  @AppStorage(Pref.reminderMinute) private var reminderMinute = ReminderTime.defaultMinute
  @Environment(\.scenePhase) private var scenePhase
  @State private var permission = Reminders.Permission.unknown

  var body: some View {
    VStack(spacing: 10) {
      if permission == .blocked {
        VStack(alignment: .leading, spacing: 10) {
          Label("Notifications are off for Chess", systemImage: "bell.slash.fill")
            .scaledFont(17, .bold)
            .foregroundStyle(Theme.ink)
          Text("Turn them on in iOS Settings to get a daily reminder.")
            .scaledFont(15, .medium)
            .foregroundStyle(Theme.inkMuted)
          InkPill(title: "Open Settings", symbol: "gearshape.fill") {
            if let url = URL(string: UIApplication.openNotificationSettingsURLString) { UIApplication.shared.open(url) }
          }
          .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
      }
      ToggleRow(symbol: "bell.badge.fill", title: "Daily Reminder", isOn: Binding(get: { reminder }, set: turn))
        .disabled(permission == .blocked)
      if reminder {
        ReminderTime(minute: $reminderMinute) { minute in
          Task { _ = await Reminders.enable(minute: minute) }
        }
        .padding(.top, 6)
        .motionTransition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .animation(Theme.spring, value: reminder)
    .animation(Theme.spring, value: permission)
    .task { await refresh() }
    .onChange(of: scenePhase) { _, phase in if phase == .active { Task { await refresh() } } }
  }

  private func turn(_ on: Bool) {
    guard on else {
      reminder = false
      Reminders.cancel()
      return
    }
    Task {
      reminder = await Reminders.enable(minute: reminderMinute)
      await refresh()
    }
  }

  private func refresh() async {
    permission = await Reminders.permission()
    if permission == .blocked { reminder = false }
  }
}

private struct AboutPage: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Chess is free software under the GPLv3.").scaledFont(17, .semibold)
      Text("Engine: Stockfish 17 (GPLv3) via ChessKitEngine (MIT). Rules: ChessKit (MIT). Pieces: cburnett, Merida (GPLv2+), Chessnut (Apache 2.0). Effects: Vortex (MIT).")
        .scaledFont(15, .medium)
        .foregroundStyle(Theme.inkMuted)
      Text("Learn courses are lichess studies: The London System and Caro-Kann Defense by LeninPerez, and All about the Sicilian Defense by francesco_super. Thank you!")
        .scaledFont(15, .medium)
        .foregroundStyle(Theme.inkMuted)
    }
    .foregroundStyle(Theme.ink)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
