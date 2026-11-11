import SwiftUI

/// The five levels. One choice sets the computer's strength and the daily puzzle's band.
enum Level: String, CaseIterable, Codable, Identifiable, Sendable {
  case easy, medium, hard, expert, master

  var id: Self { self }

  var name: String {
    switch self {
    case .easy: "Easy"
    case .medium: "Medium"
    case .hard: "Hard"
    case .expert: "Expert"
    case .master: "Master"
    }
  }

  var symbol: String {
    switch self {
    case .easy: "square.fill"
    case .medium: "circle.fill"
    case .hard: "seal.fill"
    case .expert: "star.fill"
    case .master: "crown.fill"
    }
  }

  var detail: String {
    switch self {
    case .easy: "Learning the moves. The computer misses a lot."
    case .medium: "You know the rules and a few tricks."
    case .hard: "You play regularly and see tactics coming."
    case .expert: "Club strength. Few free pieces here."
    case .master: "No mercy."
    }
  }

  /// Each level's colour, as Sudoku a Day colours its difficulties.
  var tint: Color {
    switch self {
    case .easy: Theme.teal
    case .medium: Theme.purple
    case .hard: Theme.red
    case .expert: Theme.brown
    case .master: Theme.ink
    }
  }

  /// Stockfish's strength: a Skill Level for the lower levels, an Elo limit above.
  var engineOptions: [(String, String)] {
    switch self {
    case .easy: [("UCI_LimitStrength", "false"), ("Skill Level", "0")]
    case .medium: [("UCI_LimitStrength", "false"), ("Skill Level", "4")]
    case .hard: [("UCI_LimitStrength", "false"), ("Skill Level", "9")]
    case .expert: [("UCI_LimitStrength", "true"), ("UCI_Elo", "1800")]
    case .master: [("UCI_LimitStrength", "true"), ("UCI_Elo", "2400")]
    }
  }

  /// How long the engine may think, in milliseconds.
  var moveTime: Int {
    switch self {
    case .easy: 60
    case .medium: 150
    case .hard: 300
    case .expert: 500
    case .master: 900
    }
  }

  /// The shortest visible "thinking" pause, so instant replies don't feel robotic.
  var minimumThink: Duration {
    switch self {
    case .easy, .medium: .milliseconds(650)
    case .hard, .expert: .milliseconds(500)
    case .master: .milliseconds(400)
    }
  }
}

enum TimeControl: String, CaseIterable, Codable, Identifiable, Sendable {
  case none, rapid10 = "10+0", blitz5 = "5+3", blitz3 = "3+2"

  var id: Self { self }

  var name: String { self == .none ? "No clock" : rawValue }

  var base: Duration? {
    switch self {
    case .none: nil
    case .rapid10: .seconds(600)
    case .blitz5: .seconds(300)
    case .blitz3: .seconds(180)
    }
  }

  var increment: Duration {
    switch self {
    case .none, .rapid10: .zero
    case .blitz5: .seconds(3)
    case .blitz3: .seconds(2)
    }
  }
}

enum SidePreference: String, CaseIterable, Identifiable, Sendable {
  case white, random, black
  var id: Self { self }
  var name: String { rawValue.capitalized }
}

enum Appearance: String, CaseIterable, Identifiable, Sendable {
  case light, system, dark
  var id: Self { self }

  var name: String {
    switch self {
    case .light: "Light"
    case .system: "Auto"
    case .dark: "Dark"
    }
  }

  var symbol: String {
    switch self {
    case .light: "sun.max.fill"
    case .system: "circle.lefthalf.filled"
    case .dark: "moon.stars.fill"
    }
  }

  var scheme: ColorScheme? {
    switch self {
    case .light: .light
    case .system: nil
    case .dark: .dark
    }
  }
}

/// The `@AppStorage` keys, in one place.
enum Pref {
  static let onboarded = "onboarded"
  static let level = "level"
  static let side = "side"
  static let appearance = "appearance"
  static let haptics = "haptics"
  static let sounds = "sounds"
  static let timeControl = "timeControl"
  static let coordinates = "coordinates"
  static let legalMoves = "legalMoves"
  static let autoQueen = "autoQueen"
  static let turnBoard = "turnBoard"
  static let boardTheme = "boardTheme"
  static let pieceSet = "pieceSet"
  static let reminder = "reminder"
  static let reminderHour = "reminderHour"
  static let appIcon = "appIcon"
}
