import ChessKit
import ChessKitEngine
import Foundation

/// The computer opponent. Stockfish 17 (ChessKitEngine) when its two NNUE files are bundled,
/// else a small built-in search so the app always has an opponent.
actor ChessEngine {
  static let shared = ChessEngine()

  /// Stockfish 17 refuses to search without both networks; `tools/fetch-nnue.sh` downloads them.
  static let hasNetworks =
    Bundle.main.url(forResource: "nn-1111cefa1111", withExtension: "nnue") != nil
      && Bundle.main.url(forResource: "nn-37f18f62d772", withExtension: "nnue") != nil

  private let engine = Engine(type: .stockfish)
  private var listener: Task<Void, Never>?
  private var ready: CheckedContinuation<Void, Never>?
  private var pending: CheckedContinuation<String?, Never>?
  private var started = false

  /// The first call starts Stockfish and waits for `readyok`; later calls return immediately.
  func warmUp() async {
    guard Self.hasNetworks, !started else { return }
    started = true
    await engine.start(coreCount: 2)
    guard let stream = await engine.responseStream else { return }
    listener = Task { [weak self] in
      for await response in stream { await self?.handle(response) }
    }
    await withCheckedContinuation { continuation in
      ready = continuation
      Task { await engine.send(command: .isready) }
    }
  }

  /// Returns a UCI move ("e7e5", "a7a8q"), or nil if no move is available.
  /// Callers must not overlap searches: there is only one pending continuation.
  func bestMove(fen: String, level: Level) async -> String? {
    guard Self.hasNetworks else { return Fallback.bestMove(fen: fen, level: level) }
    await warmUp()
    for (id, value) in level.engineOptions {
      await engine.send(command: .setoption(id: id, value: value))
    }
    return await withCheckedContinuation { continuation in
      pending = continuation
      Task {
        await engine.send(command: .position(.fen(fen)))
        await engine.send(command: .go(movetime: level.moveTime))
      }
    }
  }

  /// Times a reply at every level on a few positions, for `devicectl … --console`.
  static func benchmark() async {
    let positions = [
      "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1",
      "r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4",
      "r2q1rk1/pp2bppp/2np1n2/2p1p3/4P3/2PP1N1P/PPB2PP1/RNBQR1K1 b - - 0 10",
    ]
    print("[bench] networks bundled: \(hasNetworks)")
    let warm = ContinuousClock.now
    await shared.warmUp()
    print("[bench] warm-up: \(ContinuousClock.now - warm)")
    for level in Level.allCases {
      for fen in positions {
        let start = ContinuousClock.now
        let move = await shared.bestMove(fen: fen, level: level)
        print("[bench] \(level.name) budget \(level.moveTime) ms: \(move ?? "nil") in \(ContinuousClock.now - start)")
      }
    }
    print("[bench] done")
  }

  /// Clears Stockfish's game state if startup has begun; does not stop a search.
  func newGame() async {
    guard started else { return }
    await engine.send(command: .ucinewgame)
  }

  private func handle(_ response: EngineResponse) {
    switch response {
    case .readyok:
      ready?.resume()
      ready = nil
    case let .bestmove(move, _):
      pending?.resume(returning: move)
      pending = nil
    default:
      break
    }
  }
}

/// Scores each legal move by material, centralization and the largest threatened piece.
/// A position-derived roll occasionally chooses a weaker move, more often at lower levels.
enum Fallback {
  static func bestMove(fen: String, level: Level) -> String? {
    guard let position = Position(fen: fen) else { return nil }
    let board = Board(position: position)
    let side = position.sideToMove
    let scored = moves(on: board, for: side).map { move in
      var next = board
      next.move(pieceAt: move.from, to: move.to)
      if case .promotion(let pending) = next.state { next.completePromotion(of: pending, to: .queen) }
      return (uci: move.uci, score: score(after: next, for: side))
    }
    let ranked = scored.sorted { $0.score > $1.score }
    guard let best = ranked.first else { return nil }
    let roll = fen.utf8.reduce(7) { ($0 &* 31 &+ Int($1)) & 0x7FFF_FFFF }
    let sloppiness = [Level.easy: 3, .medium: 6, .hard: 14, .expert: 40, .master: 100_000][level] ?? 100_000
    return roll % sloppiness == 0 ? ranked[roll % ranked.count].uci : best.uci
  }

  /// Material values in centipawns.
  private static let value: [Piece.Kind: Int] = [.pawn: 100, .knight: 320, .bishop: 330, .rook: 500, .queen: 900, .king: 0]

  private static func moves(on board: Board, for side: Piece.Color) -> [(from: Square, to: Square, uci: String)] {
    board.position.pieces
      .filter { $0.color == side }
      .flatMap { piece in
        board.legalMoves(forPieceAt: piece.square).map { target in
          let promotes = piece.kind == .pawn && (target.rank.value == 8 || target.rank.value == 1)
          return (piece.square, target, piece.square.notation + target.notation + (promotes ? "q" : ""))
        }
      }
  }

  private static func score(after board: Board, for side: Piece.Color) -> Int {
    if case .checkmate = board.state { return 100_000 }
    if case .draw = board.state { return 0 }
    let material = board.position.pieces.reduce(0) { total, piece in
      let worth = (value[piece.kind] ?? 0) + centre(piece)
      return piece.color == side ? total + worth : total - worth
    }
    let threat = board.position.pieces
      .filter { $0.color == side.opposite }
      .flatMap { board.legalMoves(forPieceAt: $0.square) }
      .compactMap { board.position.piece(at: $0) }
      .map { value[$0.kind] ?? 0 }
      .max() ?? 0
    return material - threat
  }

  private static func centre(_ piece: Piece) -> Int {
    guard [.pawn, .knight, .bishop].contains(piece.kind) else { return 0 }
    let file = min(piece.square.file.number - 1, 8 - piece.square.file.number)
    let rank = min(piece.square.rank.value - 1, 8 - piece.square.rank.value)
    return (file + rank) * 4
  }
}
