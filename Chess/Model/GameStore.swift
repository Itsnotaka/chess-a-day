import ChessKit
import Foundation
import Observation

/// A game against the computer, as saved: the moves in UCI form plus the clocks.
/// The board is always rebuilt by replaying `moves`, so the file can never disagree with it.
struct SavedGame: Codable, Sendable {
  var moves: [String] = []
  var you: Piece.Color
  var level: Level
  var timeControl: TimeControl
  var startedAt: Date
  var lastMoveAt: Date
  var whiteLeft: TimeInterval
  var blackLeft: TimeInterval
  var ending: Ending?
  var recorded = false

  enum Ending: Codable, Sendable {
    case resigned(Piece.Color)
    case flagged(Piece.Color)
  }
}

/// A piece as the board draws it: `id` follows the piece from square to square, so it slides.
struct BoardPiece: Identifiable, Equatable {
  let id: String
  let piece: Piece
}

enum GameResult: Equatable {
  case win, loss, draw

  var title: String {
    switch self {
    case .win: "You won"
    case .loss: "You lost"
    case .draw: "Draw"
    }
  }
}

@MainActor
@Observable
final class GameStore {
  private(set) var saved: SavedGame?
  private(set) var board = Board()
  private(set) var pieces: [BoardPiece] = []
  private(set) var lastMove: (from: Square, to: Square)?
  private(set) var takenByYou: [Piece] = []
  private(set) var takenByThem: [Piece] = []
  private(set) var thinking = false

  var selected: Square?
  var promotion: (from: Square, to: Square)?

  private let url = Storage.file("game.json")
  private let history: History

  init(history: History) {
    self.history = history
    saved = Storage.read(SavedGame.self, from: url)
    rebuild()
  }

  // MARK: State the views read

  var active: Bool { saved != nil && !isOver }
  var you: Piece.Color { saved?.you ?? .white }
  var level: Level { saved?.level ?? .medium }
  var yourTurn: Bool { active && board.position.sideToMove == you && !thinking }

  var isOver: Bool { saved?.ending != nil || boardEnded }

  private var boardEnded: Bool {
    switch board.state {
    case .checkmate, .draw: true
    default: false
    }
  }

  var result: GameResult? {
    guard let saved, isOver else { return nil }
    switch saved.ending {
    case let .resigned(loser), let .flagged(loser): return loser == you ? .loss : .win
    case nil: break
    }
    if case let .checkmate(color) = board.state { return color == you ? .loss : .win }
    return .draw
  }

  var reason: String {
    switch saved?.ending {
    case .resigned: return "Resigned"
    case .flagged: return "Out of time"
    case nil: break
    }
    switch board.state {
    case .checkmate: return "Checkmate"
    case .draw(.stalemate): return "Stalemate"
    case .draw(.repetition): return "Threefold repetition"
    case .draw(.fiftyMoves): return "Fifty-move rule"
    case .draw(.insufficientMaterial): return "Insufficient material"
    default: return ""
    }
  }

  var checkedKing: Square? {
    guard case let .check(color) = board.state else {
      if case let .checkmate(color) = board.state { return king(of: color) }
      return nil
    }
    return king(of: color)
  }

  var targets: [Square] {
    guard let selected else { return [] }
    return board.legalMoves(forPieceAt: selected)
  }

  var moveCount: Int { ((saved?.moves.count ?? 0) + 1) / 2 }

  /// Time left on a side's clock at `now`, counting the running side down.
  func timeLeft(_ color: Piece.Color, at now: Date) -> TimeInterval? {
    guard let saved, saved.timeControl.base != nil else { return nil }
    let stored = color == .white ? saved.whiteLeft : saved.blackLeft
    let running = active && board.position.sideToMove == color && !saved.moves.isEmpty
    return running ? stored - now.timeIntervalSince(saved.lastMoveAt) : stored
  }

  // MARK: Actions

  func newGame(side: SidePreference, level: Level, timeControl: TimeControl) {
    let now = Date.now
    let you: Piece.Color = switch side {
    case .white: .white
    case .black: .black
    case .random: Bool.random() ? .white : .black
    }
    let base = timeControl.base.map { Double($0.components.seconds) } ?? 0
    saved = SavedGame(you: you, level: level, timeControl: timeControl, startedAt: now, lastMoveAt: now, whiteLeft: base, blackLeft: base)
    selected = nil
    promotion = nil
    persist()
    rebuild()
    Task { await ChessEngine.shared.newGame() }
    replyIfNeeded()
  }

  /// A tap on a square: select your piece, move the selected one, or clear the selection.
  func tap(_ square: Square) {
    if let selected, targets.contains(square) {
      attempt(from: selected, to: square)
      return
    }
    if yourTurn, let piece = board.position.piece(at: square), piece.color == you, selected != square {
      selected = square
      Haptics.selection()
      return
    }
    selected = nil
  }

  /// A finished drag; the piece goes back when the drop is not legal.
  func drop(from: Square, to: Square) {
    guard yourTurn, board.canMove(pieceAt: from, to: to) else { return }
    attempt(from: from, to: to)
  }

  func promote(to kind: Piece.Kind) {
    guard let promotion else { return }
    self.promotion = nil
    play(promotion.from.notation + promotion.to.notation + kind.uciLetter)
  }

  func resign() {
    guard active, var saved else { return }
    saved.ending = .resigned(you)
    self.saved = saved
    finishIfOver()
  }

  /// Called by the clock; ends the game when a running side reaches zero.
  func checkFlag(at now: Date) {
    guard active, var saved else { return }
    let side = board.position.sideToMove
    guard let left = timeLeft(side, at: now), left <= 0 else { return }
    saved.ending = .flagged(side)
    self.saved = saved
    finishIfOver()
  }

  // MARK: Internals

  private func attempt(from: Square, to: Square) {
    selected = nil
    let piece = board.position.piece(at: from)
    let promotes = piece?.kind == .pawn && (to.rank.value == 8 || to.rank.value == 1)
    if promotes && !UserDefaults.standard.bool(forKey: Pref.autoQueen) {
      promotion = (from, to)
      return
    }
    play(from.notation + to.notation + (promotes ? "q" : ""))
  }

  private func play(_ uci: String) {
    guard var saved, !isOver else { return }
    let now = Date.now
    let mover = board.position.sideToMove
    var trial = board
    guard Self.apply(uci, to: &trial) != nil else { return }
    if saved.timeControl.base != nil, !saved.moves.isEmpty {
      let spent = now.timeIntervalSince(saved.lastMoveAt) - Double(saved.timeControl.increment.components.seconds)
      if mover == .white { saved.whiteLeft -= spent } else { saved.blackLeft -= spent }
    }
    saved.moves.append(uci)
    saved.lastMoveAt = now
    self.saved = saved
    rebuild()
    Haptics.move(capture: lastCapture)
    finishIfOver()
    replyIfNeeded()
  }

  private func replyIfNeeded() {
    guard active, let saved, board.position.sideToMove != saved.you else { return }
    thinking = true
    let fen = board.position.fen
    let level = saved.level
    Task {
      let started = ContinuousClock.now
      let move = await ChessEngine.shared.bestMove(fen: fen, level: level)
      let elapsed = ContinuousClock.now - started
      if elapsed < level.minimumThink { try? await Task.sleep(for: level.minimumThink - elapsed) }
      thinking = false
      guard let move, self.board.position.fen == fen else { return }
      play(move)
    }
  }

  private func finishIfOver() {
    persist()
    guard isOver, var saved, !saved.recorded else { return }
    saved.recorded = true
    self.saved = saved
    persist()
    history.mark(DayKey.of(.now), game: true)
    Haptics.finish(won: result == .win)
  }

  private func persist() {
    if let saved { Storage.write(saved, to: url) } else { Storage.remove(url) }
  }

  private var lastCapture = false

  /// Replays the saved moves, keeping each piece's id from the square it started on.
  private func rebuild() {
    var board = Board()
    var ids = Dictionary(uniqueKeysWithValues: board.position.pieces.map { ($0.square, "\($0.color.rawValue)\($0.kind.rawValue)-\($0.square.notation)") })
    var mine: [Piece] = []
    var theirs: [Piece] = []
    var last: (Square, Square)?
    var captured = false
    for uci in saved?.moves ?? [] {
      guard let move = Self.apply(uci, to: &board) else { break }
      let id = ids.removeValue(forKey: move.start)
      captured = false
      switch move.result {
      case let .capture(taken):
        ids.removeValue(forKey: taken.square)
        if move.piece.color == you { mine.append(taken) } else { theirs.append(taken) }
        captured = true
      case let .castle(castling):
        if let rook = ids.removeValue(forKey: castling.rookStart) { ids[castling.rookEnd] = rook }
      case .move:
        break
      }
      ids[move.end] = id
      last = (move.start, move.end)
    }
    self.board = board
    lastMove = last
    lastCapture = captured
    takenByYou = mine.sorted { $0.kind.worth > $1.kind.worth }
    takenByThem = theirs.sorted { $0.kind.worth > $1.kind.worth }
    pieces = board.position.pieces.map { BoardPiece(id: ids[$0.square] ?? $0.square.notation, piece: $0) }
  }

  /// Plays one UCI move on `board`, completing a promotion; nil when it is not legal.
  private static func apply(_ uci: String, to board: inout Board) -> Move? {
    guard uci.count >= 4 else { return nil }
    let from = Square(String(uci.prefix(2)))
    let to = Square(String(uci.dropFirst(2).prefix(2)))
    guard var move = board.move(pieceAt: from, to: to) else { return nil }
    if case let .promotion(pending) = board.state {
      let kind = Piece.Kind(uciLetter: uci.count > 4 ? String(uci.suffix(1)) : "q")
      move = board.completePromotion(of: pending, to: kind)
    }
    return move
  }

  private func king(of color: Piece.Color) -> Square? {
    board.position.pieces.first { $0.kind == .king && $0.color == color }?.square
  }
}

extension Piece.Kind {
  var uciLetter: String {
    switch self {
    case .queen: "q"
    case .rook: "r"
    case .bishop: "b"
    case .knight: "n"
    case .pawn, .king: "q"
    }
  }

  init(uciLetter: String) {
    self = switch uciLetter {
    case "r": .rook
    case "b": .bishop
    case "n": .knight
    default: .queen
    }
  }

  var worth: Int {
    switch self {
    case .queen: 9
    case .rook: 5
    case .bishop, .knight: 3
    case .pawn: 1
    case .king: 0
    }
  }

  /// The asset name's letter: "wN", "bP".
  var assetLetter: String { self == .pawn ? "P" : rawValue }
}

extension Piece {
  var assetName: String { "\(color.rawValue)\(kind.assetLetter)" }
}
