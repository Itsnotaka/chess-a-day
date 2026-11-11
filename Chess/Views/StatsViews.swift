import Charts
import SwiftUI

struct StreakSheet: View {
  @Environment(History.self) private var history

  private var week: [Date] {
    let today = Calendar.current.startOfDay(for: .now)
    return (-6...0).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: today) }
  }

  var body: some View {
    let streak = history.streak()
    VStack(spacing: 18) {
      HStack(spacing: 4) {
        Image(systemName: "laurel.leading")
        Text("\(streak)").monospacedDigit().contentTransition(.numericText())
        Image(systemName: "laurel.trailing")
      }
      .scaledFont(56, .heavy)
      .foregroundStyle(Theme.ink)
      VStack(spacing: 4) {
        Text(streak == 1 ? "day in a row" : "days in a row").scaledFont(18, .bold).foregroundStyle(Theme.ink)
        Text("A finished game or the daily puzzle keeps it going. Best: \(history.bestStreak).")
          .scaledFont(15, .medium)
          .foregroundStyle(Theme.inkMuted)
          .multilineTextAlignment(.center)
      }
      HStack(spacing: 0) {
        ForEach(week, id: \.self) { day in
          VStack(spacing: 6) {
            Text(day.formatted(.dateTime.weekday(.narrow))).scaledFont(14, .semibold).foregroundStyle(Theme.inkMuted)
            DayRing(count: history.days[DayKey.of(day)]?.count ?? 0)
          }
          .frame(maxWidth: .infinity)
          .accessibilityElement(children: .ignore)
          .accessibilityLabel("\(day.formatted(.dateTime.weekday(.wide))), \(Self.describe(history.days[DayKey.of(day)]))")
        }
      }
      .padding(.vertical, 14)
      .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
    .padding(.horizontal, 24)
    .padding(.top, 32)
    .padding(.bottom, 16)
  }

  static func describe(_ mark: DayMark?) -> String {
    switch (mark?.game ?? false, mark?.puzzle ?? false) {
    case (true, true): "game and puzzle done"
    case (true, false): "game played"
    case (false, true): "puzzle solved"
    case (false, false): "nothing played"
    }
  }
}

struct StatsSheet: View {
  @Environment(History.self) private var history

  private struct Bar: Identifiable {
    let level: Level
    let outcome: GameRecord.Outcome
    let count: Int
    var id: String { "\(level.rawValue)-\(outcome.rawValue)" }
  }

  private var bars: [Bar] {
    Level.allCases.flatMap { level in
      [GameRecord.Outcome.win, .draw, .loss].map { outcome in
        Bar(level: level, outcome: outcome, count: history.games.filter { $0.level == level && $0.result == outcome }.count)
      }
    }
    .filter { $0.count > 0 }
  }

  var body: some View {
    let games = history.games
    let wins = games.filter { $0.result == .win }.count
    let draws = games.filter { $0.result == .draw }.count
    VStack(alignment: .leading, spacing: 20) {
        Text("Stats").scaledFont(28, .heavy).foregroundStyle(Theme.ink).frame(maxWidth: .infinity)
        HStack(spacing: 10) {
          tile("\(games.count)", "Played")
          tile("\(wins)", "Won")
          tile("\(draws)", "Drawn")
          tile("\(games.count - wins - draws)", "Lost")
        }
        if games.isEmpty {
          Text("Finish a game against the computer and your results show up here, level by level.")
            .scaledFont(16, .medium)
            .foregroundStyle(Theme.inkMuted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
        } else {
          SectionLabel(title: "By level")
          Chart(bars) { bar in
            BarMark(x: .value("Level", bar.level.name), y: .value("Games", bar.count))
              .foregroundStyle(by: .value("Result", bar.outcome.rawValue.capitalized))
              .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
          }
          .chartForegroundStyleScale(["Win": Theme.ink, "Draw": Theme.inkMuted, "Loss": Theme.inkFaint])
          .chartYAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
          .frame(height: 220)
          Text("Best streak: \(history.bestStreak) \(history.bestStreak == 1 ? "day" : "days")")
            .scaledFont(15, .semibold)
            .foregroundStyle(Theme.inkMuted)
        }
      }
    .padding(.horizontal, 20)
    .padding(.top, 30)
    .padding(.bottom, 24)
  }

  private func tile(_ value: String, _ label: String) -> some View {
    VStack(spacing: 2) {
      Text(value).scaledFont(26, .heavy).monospacedDigit().foregroundStyle(Theme.ink)
      Text(label).scaledFont(14, .semibold).foregroundStyle(Theme.inkMuted)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 14)
    .background(Theme.raised, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    .accessibilityElement(children: .combine)
  }
}
