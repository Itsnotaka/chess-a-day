import Foundation
import Observation

/// What each day counted: a finished game and the solved puzzle.
struct DayMark: Codable, Equatable, Sendable {
  var game = false
  var puzzle = false
  var count: Int { (game ? 1 : 0) + (puzzle ? 1 : 0) }
}

/// One finished game against the computer, for Stats.
struct GameRecord: Codable, Equatable, Sendable {
  enum Outcome: String, Codable, Sendable { case win, draw, loss }
  var date: Date
  var level: Level
  var result: Outcome
  var moves: Int
}

/// Days played and games finished, kept as JSON in Application Support. A day counts toward
/// the streak when it has a finished game or the day's puzzle solved; doing both fills its ring.
@MainActor
@Observable
final class History {
  private(set) var days: [String: DayMark] = [:]
  private(set) var games: [GameRecord] = []

  private struct File: Codable {
    var days: [String: DayMark]
    var games: [GameRecord]
  }

  private let url = Storage.file("history.json")

  init() {
    let file = Storage.read(File.self, from: url)
    days = file?.days ?? [:]
    games = file?.games ?? []
  }

  func record(_ game: GameRecord) {
    games.append(game)
    mark(DayKey.of(game.date), game: true)
  }

  func mark(_ day: String, game: Bool = false, puzzle: Bool = false) {
    var mark = days[day] ?? DayMark()
    mark.game = mark.game || game
    mark.puzzle = mark.puzzle || puzzle
    days[day] = mark
    Storage.write(File(days: days, games: games), to: url)
  }

  func streak(today: Date = .now) -> Int {
    let calendar = Calendar.current
    let counted = { (date: Date) in (self.days[DayKey.of(date)]?.count ?? 0) > 0 }
    let start = counted(today) ? today : calendar.date(byAdding: .day, value: -1, to: today) ?? today
    return sequence(first: start) { calendar.date(byAdding: .day, value: -1, to: $0) }
      .prefix { counted($0) }
      .reduce(0) { count, _ in count + 1 }
  }

  /// The longest run of counted days ever.
  var bestStreak: Int {
    let calendar = Calendar.current
    let dates = days.filter { $0.value.count > 0 }.keys.compactMap(DayKey.date).sorted()
    return dates.indices.reduce(into: (best: 0, run: 0)) { state, index in
      let follows = index > 0 && calendar.date(byAdding: .day, value: 1, to: dates[index - 1]) == dates[index]
      state.run = follows ? state.run + 1 : 1
      state.best = max(state.best, state.run)
    }.best
  }
}

/// A day's key in the person's own calendar: "2026-11-11".
enum DayKey {
  static func of(_ date: Date) -> String {
    let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
  }

  static func date(_ key: String) -> Date? {
    let parts = key.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3 else { return nil }
    return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
  }
}

/// JSON files under Application Support.
enum Storage {
  static func file(_ name: String) -> URL {
    let folder = URL.applicationSupportDirectory
    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    return folder.appending(path: name)
  }

  static func read<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    return try? JSONDecoder().decode(type, from: data)
  }

  static func write<T: Encodable>(_ value: T, to url: URL) {
    guard let data = try? JSONEncoder().encode(value) else { return }
    try? data.write(to: url, options: .atomic)
  }

  static func remove(_ url: URL) {
    try? FileManager.default.removeItem(at: url)
  }
}
