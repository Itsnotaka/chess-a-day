import Foundation
import Observation

/// What each day counted: one finished game and one solved puzzle.
struct DayMark: Codable, Equatable, Sendable {
  var game = false
  var puzzle = false
  var count: Int { (game ? 1 : 0) + (puzzle ? 1 : 0) }
}

/// Days played, kept as JSON in Application Support. A day counts toward the streak
/// when it has both a finished game and the day's puzzle solved.
@MainActor
@Observable
final class History {
  private(set) var days: [String: DayMark] = [:]

  private let url = Storage.file("history.json")

  init() {
    days = Storage.read([String: DayMark].self, from: url) ?? [:]
  }

  func mark(_ day: String, game: Bool = false, puzzle: Bool = false) {
    var mark = days[day] ?? DayMark()
    mark.game = mark.game || game
    mark.puzzle = mark.puzzle || puzzle
    days[day] = mark
    Storage.write(days, to: url)
  }

  func streak(today: Date = .now) -> Int {
    let calendar = Calendar.current
    let counted = { (date: Date) in self.days[DayKey.of(date)].map { $0.game && $0.puzzle } ?? false }
    let start = counted(today) ? today : calendar.date(byAdding: .day, value: -1, to: today) ?? today
    return sequence(first: start) { calendar.date(byAdding: .day, value: -1, to: $0) }
      .prefix { counted($0) }
      .reduce(0) { count, _ in count + 1 }
  }
}

/// A day's key in the person's own calendar: "2026-11-11".
enum DayKey {
  static func of(_ date: Date) -> String {
    let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
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
