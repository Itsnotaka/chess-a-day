import SwiftUI

/// Owns shared game state and applies app-wide appearance and typography.
@main
struct ChessApp: App {
  @State private var history: History
  @State private var games: Games
  @State private var learning = LearnProgress()
  @AppStorage(Pref.appearance) private var appearance = Appearance.system.rawValue

  init() {
    let history = History()
    _history = State(initialValue: history)
    _games = State(initialValue: Games(history: history))
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(history)
        .environment(games)
        .environment(games.computer)
        .environment(games.online)
        .environment(learning)
        .fontDesign(.rounded)
        .preferredColorScheme(Appearance(rawValue: appearance)?.scheme)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .task {
          Sounds.warmUp()
          games.online.authenticate()
          await ChessEngine.shared.warmUp()
          // `-benchmark YES` times the engine at every level and prints it to the console.
          if UserDefaults.standard.bool(forKey: "benchmark") { await ChessEngine.benchmark() }
        }
    }
  }
}

/// Owns the computer and free-play stores and the Game Center match coordinator.
@MainActor
@Observable
final class Games {
  let computer: GameStore
  let friend: GameStore
  let online: OnlineGames

  init(history: History) {
    computer = GameStore(mode: .computer, history: history)
    friend = GameStore(mode: .friend, history: history)
    online = OnlineGames(history: history)
  }

  /// Lessons fall back to the computer store; online uses the coordinator's current store.
  func store(_ mode: GameMode) -> GameStore {
    switch mode {
    case .computer: computer
    case .friend: friend
    case .online: online.store
    case .lesson: computer
    }
  }
}

/// Switches from onboarding to home when the persisted onboarding flag is set.
struct RootView: View {
  @AppStorage(Pref.onboarded) private var onboarded = false

  var body: some View {
    ZStack {
      if onboarded {
        HomeView().transition(.opacity)
      } else {
        OnboardingView().transition(.opacity)
      }
    }
    .animation(Theme.spring, value: onboarded)
  }
}
