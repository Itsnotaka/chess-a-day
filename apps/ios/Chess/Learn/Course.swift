import ChessKit
import Foundation

struct Course: Identifiable, Sendable {
  let id: String
  let title: String
  let summary: String
  let symbol: String
  let side: Piece.Color
  let author: String
  let source: URL
  let lessons: [Lesson]
}

struct Lesson: Identifiable, Sendable {
  enum Style: Sendable { case play, watch }

  let id: String
  let title: String
  let you: Piece.Color
  let fen: String?
  let style: Style
  let steps: [LessonStep]
}

enum GuideColor: String, Sendable { case green = "G", red = "R", blue = "B", yellow = "Y" }

struct Shapes: Sendable, Equatable {
  var arrows: [BoardArrow] = []
  var marks: [BoardMark] = []
  var isEmpty: Bool { arrows.isEmpty && marks.isEmpty }
}

struct LessonStep: Sendable {
  enum Kind: Sendable { case say, you, them, watch }

  var kind: Kind
  var san: String?
  var prompt: String = ""
  var promptShapes = Shapes()
  var why: String = ""
  var whyShapes = Shapes()
  var wrong: [String: String] = [:]
}


enum Courses {
  static let all: [Course] = catalogue.compactMap { $0.load() }

  static func course(_ id: String) -> Course? { all.first { $0.id == id } }

  private struct Source {
    let file: String
    let title: String
    let summary: String
    let symbol: String
    let side: Piece.Color
    let author: String
    let study: String
    var skip: Set<String> = []

    func load() -> Course? {
      guard let url = Bundle.main.url(forResource: file, withExtension: "pgn"),
            let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
      let lessons = Study.chapters(in: text)
        .filter { chapter in !skip.contains { chapter.headers["ChapterURL"]?.hasSuffix("/\($0)") == true } }
        .compactMap { $0.lesson(course: file) }
        .filter { $0.you == side }
      guard !lessons.isEmpty else { return nil }
      return Course(id: file, title: title, summary: summary, symbol: symbol, side: side, author: author,
                    source: URL(string: "https://lichess.org/study/\(study)")!, lessons: lessons)
    }
  }

  private static let catalogue = [
    Source(file: "london", title: "London System", summary: "One calm setup for White against almost anything.",
           symbol: "building.columns.fill", side: .white, author: "LeninPerez", study: "vIEKP8t3"),
    // The two later Closed Sicilian chapters are opening-explorer trees: transpositions and game references, no teaching.
    Source(file: "sicilian", title: "Sicilian Defence", summary: "Black's fighting answer to 1.e4: the Dragon, the Najdorf and more.",
           symbol: "flame.fill", side: .black, author: "francesco_super", study: "8c8bmUfy", skip: ["tFH530Ea", "k5gWu5u7"]),
    Source(file: "carokann", title: "Caro-Kann Defence", summary: "A rock-solid answer to 1.e4.",
           symbol: "shield.fill", side: .black, author: "LeninPerez", study: "jtlLwUvh"),
  ]
}


enum Study {
  struct Node {
    var san: String
    var comments: [String] = []
    var variations: [[Node]] = []
  }

  struct Chapter {
    var headers: [String: String]
    var intro: [String]
    var line: [Node]
  }

  static func chapters(in text: String) -> [Chapter] {
    text.replacingOccurrences(of: "\r\n", with: "\n")
      .components(separatedBy: "\n\n\n")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .map(chapter)
  }

  private static func chapter(_ text: String) -> Chapter {
    var headers: [String: String] = [:]
    var body: [Substring] = []
    for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
      if line.hasPrefix("["), line.hasSuffix("\"]"), let space = line.firstIndex(of: " ") {
        let key = String(line[line.index(after: line.startIndex)..<space])
        let value = line[line.index(space, offsetBy: 2)..<line.index(line.endIndex, offsetBy: -2)]
        headers[key] = String(value)
      } else {
        body.append(line)
      }
    }
    var intro: [String] = []
    var index = 0
    let tokens = tokenize(body.joined(separator: "\n"))
    let line = parse(tokens, at: &index, intro: &intro)
    return Chapter(headers: headers, intro: intro, line: line)
  }

  private static func tokenize(_ text: String) -> [String] {
    var tokens: [String] = []
    var i = text.startIndex
    while i < text.endIndex {
      let c = text[i]
      if c == "{" {
        let end = text[i...].firstIndex(of: "}") ?? text.index(before: text.endIndex)
        tokens.append(String(text[i...end]))
        i = text.index(after: end)
      } else if c == "(" || c == ")" {
        tokens.append(String(c))
        i = text.index(after: i)
      } else if c.isWhitespace {
        i = text.index(after: i)
      } else {
        var j = i
        while j < text.endIndex, !text[j].isWhitespace, !"(){".contains(text[j]) { j = text.index(after: j) }
        tokens.append(String(text[i..<j]))
        i = j
      }
    }
    return tokens
  }

  private static func parse(_ tokens: [String], at index: inout Int, intro: inout [String]) -> [Node] {
    var nodes: [Node] = []
    while index < tokens.count {
      let token = tokens[index]
      index += 1
      if token == ")" { return nodes }
      if token == "(" {
        var unused: [String] = []
        let variation = parse(tokens, at: &index, intro: &unused)
        if !nodes.isEmpty { nodes[nodes.count - 1].variations.append(variation) }
        continue
      }
      if token.hasPrefix("{") {
        let comment = String(token.dropFirst().dropLast())
        if nodes.isEmpty { intro.append(comment) } else { nodes[nodes.count - 1].comments.append(comment) }
        continue
      }
      if token.hasPrefix("$") || ["1-0", "0-1", "1/2-1/2", "*"].contains(token) { continue }
      let san = token
        .replacing(/^\d+\.+/, with: "")
        .trimmingCharacters(in: CharacterSet(charactersIn: "!?"))
      if !san.isEmpty, !(san.allSatisfy(\.isNumber)) { nodes.append(Node(san: san)) }
    }
    return nodes
  }

  static func read(_ comments: [String]) -> (text: String, shapes: Shapes) {
    var shapes = Shapes()
    var words: [String] = []
    for comment in comments {
      for match in comment.matches(of: /\[%cal ([^\]]*)\]/) {
        for item in match.1.split(separator: ",") where item.count == 5 {
          let color = GuideColor(rawValue: String(item.prefix(1))) ?? .green
          let from = Square(String(item.dropFirst().prefix(2))), to = Square(String(item.suffix(2)))
          shapes.arrows.append(BoardArrow(from: from, to: to, color: color))
        }
      }
      for match in comment.matches(of: /\[%csl ([^\]]*)\]/) {
        for item in match.1.split(separator: ",") where item.count == 3 {
          shapes.marks.append(BoardMark(square: Square(String(item.suffix(2))), color: GuideColor(rawValue: String(item.prefix(1))) ?? .green))
        }
      }
      let text = comment.replacing(/\[%[^\]]*\]/, with: "")
        .split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }.joined(separator: "\n")
        .replacing(/[ \t]+/, with: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)
      if !text.isEmpty { words.append(text) }
    }
    return (words.joined(separator: "\n\n"), shapes)
  }
}

extension Study.Chapter {
  func lesson(course: String) -> Lesson? {
    let fen = headers["FEN"]
    let start = fen.flatMap(Position.init(fen:)) ?? .standard
    guard start.pieces.filter({ $0.kind == .king }).count == 2 else { return nil }
    let you: Piece.Color = headers["Orientation"] == "black" ? .black : .white
    let style: Lesson.Style = headers["ChapterMode"] == "gamebook" ? .play : .watch
    if style == .watch, line.count > 30 { return nil }

    var steps: [LessonStep] = []
    var pending = Study.read(intro)
    var mover = start.sideToMove
    var ply = (start.clock.fullmoves - 1) * 2 + (mover == .black ? 1 : 0)
    for node in line {
      let after = Study.read(node.comments)
      if style == .watch {
        if !pending.text.isEmpty || !pending.shapes.isEmpty {
          steps.append(LessonStep(kind: .say, prompt: pending.text, promptShapes: pending.shapes))
        }
        steps += node.variations.filter { $0.count > 1 || $0.first.map { !Study.read($0.comments).text.isEmpty } == true }
          .map { LessonStep(kind: .say, prompt: Self.sideline($0, ply: ply, you: mover == you)) }
        steps.append(LessonStep(kind: .watch, san: node.san, why: after.text, whyShapes: after.shapes))
        pending = ("", Shapes())
      } else if mover == you {
        let wrong = Dictionary(node.variations.compactMap { line -> (String, String)? in
          guard let first = line.first else { return nil }
          return (first.san, Study.read(first.comments).text)
        }, uniquingKeysWith: { first, _ in first })
        steps.append(LessonStep(kind: .you, san: node.san, prompt: pending.text, promptShapes: pending.shapes,
                                why: after.text, whyShapes: after.shapes, wrong: wrong))
        pending = ("", Shapes())
      } else {
        if !pending.text.isEmpty || !pending.shapes.isEmpty { steps.append(LessonStep(kind: .say, prompt: pending.text, promptShapes: pending.shapes)) }
        steps.append(LessonStep(kind: .them, san: node.san))
        pending = after
      }
      mover = mover.opposite
      ply += 1
    }
    if !pending.text.isEmpty || !pending.shapes.isEmpty {
      steps.append(LessonStep(kind: .say, prompt: pending.text, promptShapes: pending.shapes))
    }
    guard !steps.isEmpty else { return nil }
    if style == .watch, !steps.contains(where: { !$0.prompt.isEmpty || !$0.why.isEmpty }) { return nil }

    let name = headers["ChapterName"] ?? "Lesson"
    let chapterID = headers["ChapterURL"].flatMap { URL(string: $0)?.lastPathComponent } ?? name
    return Lesson(id: "\(course)/\(chapterID)", title: Self.tidy(name), you: you, fen: fen, style: style, steps: steps)
  }

  /// A study's alternative to the move about to be shown, written out with its notes:
  /// "If you play 6...Ng4 instead: Big blunder" and the rest of the line under it.
  private static func sideline(_ line: [Study.Node], ply: Int, you: Bool) -> String {
    let player = you ? "you play" : ply.isMultiple(of: 2) ? "White plays" : "Black plays"
    var text = ""
    var numbered = true
    for (offset, node) in line.prefix(12).enumerated() {
      let at = ply + offset
      let number = at.isMultiple(of: 2) ? "\(at / 2 + 1)." : numbered ? "\(at / 2 + 1)..." : ""
      let note = Study.read(node.comments).text
      if offset == 0 {
        text = "If \(player) \(number)\(node.san) instead:" + (note.isEmpty ? "" : " \(note)") + "\n"
      } else {
        text += (text.hasSuffix("\n") ? "" : " ") + number + node.san + (note.isEmpty ? "" : ": \(note)\n")
      }
      numbered = offset == 0 || !note.isEmpty
    }
    text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    return line.count > 12 ? "\(text) …" : text
  }

  private static func tidy(_ name: String) -> String {
    guard name == name.uppercased(), name.contains(where: \.isLetter) else { return name }
    return name.prefix(1) + name.dropFirst().lowercased()
  }
}
