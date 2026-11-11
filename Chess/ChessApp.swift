import SwiftUI

@main
struct ChessApp: App {
  @State private var history: History
  @State private var games: Games
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
        .fontDesign(.rounded)
        .preferredColorScheme(Appearance(rawValue: appearance)?.scheme)
        .task { await ChessEngine.shared.warmUp() }
    }
  }
}

/// The two saved games: one against the computer, one of free play.
@MainActor
@Observable
final class Games {
  let computer: GameStore
  let friend: GameStore

  init(history: History) {
    computer = GameStore(mode: .computer, history: history)
    friend = GameStore(mode: .friend, history: history)
  }

  func store(_ mode: GameMode) -> GameStore { mode == .computer ? computer : friend }
}

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
