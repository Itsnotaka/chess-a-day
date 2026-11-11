import ChessKit
import Foundation
import Observation

/// Lessons learned and practised, kept as JSON in Application Support.
@MainActor
@Observable
final class LearnProgress {
  struct Result: Codable, Equatable {
    var learned = false
    var stars = 0
  }

  private(set) var results: [String: Result] = [:]
  private let url = Storage.file("learn.json")

  init() {
    results = Storage.read([String: Result].self, from: url) ?? [:]
  }

  func result(_ lesson: Lesson) -> Result { results[lesson.id] ?? Result() }

  func learned(in course: Course) -> Int { course.lessons.filter { result($0).learned }.count }

  /// The first lesson not yet learned, else the one with the fewest stars.
  func next(in course: Course) -> Lesson? {
    course.lessons.first { !result($0).learned } ?? course.lessons.min { result($0).stars < result($1).stars }
  }

  func record(_ lesson: Lesson, practice: Bool, stars: Int) {
    var result = result(lesson)
    result.learned = true
    if practice { result.stars = max(result.stars, stars) }
    results[lesson.id] = result
    Storage.write(results, to: url)
  }
}

/// Plays one lesson on a GameStore of its own: says the coach's words, plays the opponent's
/// replies, accepts only the move being taught, and answers wrong moves.
/// In practice the words and shapes are gone: you play the line from memory, and every wrong
/// move or hint costs a star.
@MainActor
@Observable
final class LessonPlayer {
  enum Mood { case calm, good, wrong }

  let course: Course
  let lesson: Lesson
  let practice: Bool
  let store: GameStore

  private(set) var index = 0
  private(set) var message = ""
  /// A muted line above the message: what the opponent just played.
  private(set) var detail: String?
  private(set) var mood = Mood.calm
  /// The coach waits for Continue.
  private(set) var waiting = false
  private(set) var canHint = false
  private(set) var finished = false
  private(set) var mistakes = 0
  /// Bumped on every wrong move, to shake the coach's card.
  private(set) var shake = 0

  private var misses = 0
  private var expected: (uci: String, san: String)?
  private let progress: LearnProgress

  init(course: Course, lesson: Lesson, practice: Bool, history: History, progress: LearnProgress) {
    self.course = course
    self.lesson = lesson
    self.practice = practice
    self.progress = progress
    store = GameStore(mode: .lesson, history: history)
  }

  var fraction: Double { finished ? 1 : Double(index) / Double(max(lesson.steps.count, 1)) }
  var stars: Int { mistakes == 0 ? 3 : mistakes <= 2 ? 2 : 1 }

  func start() {
    index = 0
    mistakes = 0
    finished = false
    detail = nil
    store.startLesson(you: lesson.you, fen: lesson.fen)
    store.onLessonMove = { [weak self] answer in self?.answer(answer) }
    run()
  }

  /// Continue: the next step.
  func next() {
    waiting = false
    detail = nil
    index += 1
    run()
  }

  /// Shows the move being asked for. In practice it counts as a mistake.
  func hint() {
    guard expected != nil else { return }
    if practice { mistakes += 1 }
    reveal()
  }

  // MARK: Steps

  private func run() {
    guard index < lesson.steps.count else { return finish() }
    let step = lesson.steps[index]
    mood = .calm
    canHint = false
    expected = nil
    store.lessonExpected = nil
    switch step.kind {
    case .say:
      guard !practice else { return next() }
      say(step.prompt, step.promptShapes)
      waiting = true

    case .them:
      store.guide(arrows: [], marks: [])
      Task {
        try? await Task.sleep(for: .milliseconds(practice ? 350 : 600))
        guard let san = step.san, let uci = store.uci(forSAN: san) else { return finish() }
        let side = store.sideToMove == .white ? "White" : "Black"
        store.playScripted(uci)
        index += 1
        run()
        detail = "\(side) played \(san)."
      }

    case .watch:
      Task {
        try? await Task.sleep(for: .milliseconds(350))
        guard let san = step.san, let uci = store.uci(forSAN: san) else { return finish() }
        store.playScripted(uci)
        say(step.why.isEmpty ? "\(san)." : step.why, step.whyShapes)
        waiting = true
      }

    case .you:
      guard let san = step.san, let uci = store.uci(forSAN: san) else { return finish() }
      expected = (uci, san)
      misses = 0
      store.lessonExpected = uci
      canHint = true
      if practice {
        say("Your move.", Shapes())
      } else {
        say(step.prompt.isEmpty ? "Your move." : step.prompt, step.promptShapes)
      }
    }
  }

  private func answer(_ answer: LessonAnswer) {
    guard index < lesson.steps.count else { return }
    let step = lesson.steps[index]
    switch answer {
    case .correct:
      mood = .good
      canHint = false
      expected = nil
      detail = nil
      if practice || step.why.isEmpty {
        store.guide(arrows: [], marks: [])
        Task {
          try? await Task.sleep(for: .milliseconds(300))
          next()
        }
      } else {
        say(step.why, step.whyShapes)
        waiting = true
      }

    case let .wrong(san):
      misses += 1
      mistakes += 1
      shake += 1
      mood = .wrong
      if misses >= 2 {
        reveal()
      } else if !practice, let note = step.wrong[san], !note.isEmpty {
        message = "\(note)\n\nTry again."
      } else if practice || step.prompt.isEmpty {
        message = "Not that one. Try again."
      } else {
        // Keep the author's question in view under the nudge.
        message = "Not quite. \(step.prompt)"
      }
    }
  }

  /// Draws the expected move as an arrow and names it.
  private func reveal() {
    guard let expected else { return }
    let from = Square(String(expected.uci.prefix(2))), to = Square(String(expected.uci.dropFirst(2).prefix(2)))
    store.guide(arrows: [BoardArrow(from: from, to: to, color: .green)], marks: [])
    message = "The move is \(expected.san)."
  }

  private func say(_ text: String, _ shapes: Shapes) {
    message = text
    store.guide(arrows: practice ? [] : shapes.arrows, marks: practice ? [] : shapes.marks)
  }

  private func finish() {
    finished = true
    waiting = false
    canHint = false
    store.lessonExpected = nil
    store.guide(arrows: [], marks: [])
    progress.record(lesson, practice: practice, stars: stars)
    Haptics.finish(won: true)
    Sounds.play(.end)
  }
}
