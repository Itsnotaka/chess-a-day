import SwiftUI

@main
struct ChessApp: App {
  @State private var history: History
  @State private var game: GameStore
  @AppStorage(Pref.appearance) private var appearance = Appearance.system.rawValue

  init() {
    let history = History()
    _history = State(initialValue: history)
    _game = State(initialValue: GameStore(history: history))
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(history)
        .environment(game)
        .fontDesign(.rounded)
        .preferredColorScheme(Appearance(rawValue: appearance)?.scheme)
        .task { await ChessEngine.shared.warmUp() }
    }
  }
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
