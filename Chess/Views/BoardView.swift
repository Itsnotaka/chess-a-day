import ChessKit
import SwiftUI

/// Maps squares to points on a board seen from White, or from Black when `flipped`.
struct BoardGeometry {
  let size: CGFloat
  let flipped: Bool
  var cell: CGFloat { size / 8 }

  func column(_ square: Square) -> Int { flipped ? 8 - square.file.number : square.file.number - 1 }
  func row(_ square: Square) -> Int { flipped ? square.rank.value - 1 : 8 - square.rank.value }

  func center(_ square: Square) -> CGPoint {
    CGPoint(x: (CGFloat(column(square)) + 0.5) * cell, y: (CGFloat(row(square)) + 0.5) * cell)
  }

  func square(at point: CGPoint) -> Square? {
    let column = Int(floor(point.x / cell))
    let row = Int(floor(point.y / cell))
    guard (0..<8).contains(column), (0..<8).contains(row) else { return nil }
    let file = flipped ? 8 - column : column + 1
    let rank = flipped ? row + 1 : 8 - row
    return Square("\(Square.File(file).rawValue)\(rank)")
  }

  static let all: [Square] = Square.allCases

  /// Squares as a reader meets them: the top row first, left to right.
  var readingOrder: [Square] {
    Self.all.sorted { (row($0), column($0)) < (row($1), column($1)) }
  }
}

/// The playable board: tap a piece then a square, or drag it; legal moves show as dots.
struct BoardView: View {
  @Environment(GameStore.self) private var game
  @AppStorage(Pref.coordinates) private var coordinates = true
  @AppStorage(Pref.legalMoves) private var legalMoves = true
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @State private var dragFrom: Square?
  @State private var dragPoint: CGPoint?
  @GestureState private var touching = false

  private var settle: Animation { reduceMotion ? .easeOut(duration: 0.12) : Theme.pieceSlide }

  /// Room for the rank and file labels outside the board.
  private var gutter: CGFloat { coordinates ? 18 : 0 }
  @AppStorage(Pref.turnBoard) private var turnBoard = false
  @AppStorage(Pref.boardTheme) private var boardTheme = BoardTheme.stone
  @AppStorage(Pref.pieceSet) private var pieceSet = PieceSet.cburnett

  private var flipped: Bool { game.bottom(turnBoard: turnBoard) == .black }

  var body: some View {
    GeometryReader { proxy in
      let geometry = BoardGeometry(size: proxy.size.width - gutter, flipped: flipped)
      VStack(alignment: .leading, spacing: 0) {
        HStack(spacing: 0) {
          if coordinates { ranks(geometry) }
          board(geometry)
        }
        if coordinates { files(geometry) }
      }
    }
    .aspectRatio(1, contentMode: .fit)
  }

  private func board(_ geometry: BoardGeometry) -> some View {
    ZStack(alignment: .topLeading) {
      squares(geometry)
      pieces(geometry).accessibilityHidden(true)
    }
    .frame(width: geometry.size, height: geometry.size)
    .contentShape(Rectangle())
    .gesture(input(geometry))
    .onChange(of: touching) { _, now in
      // A drag the system cancelled never reaches onEnded: settle the piece back.
      guard !now else { return }
      Task { @MainActor in
        await Task.yield()
        guard dragFrom != nil else { return }
        withAnimation(settle) {
          dragFrom = nil
          dragPoint = nil
        }
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Board")
    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.board, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: Theme.Radius.board, style: .continuous)
        .strokeBorder(Theme.Board.edge, lineWidth: 2)
    }
    .overlay { if game.promotion != nil { PromotionPicker() } }
  }

  private func ranks(_ geometry: BoardGeometry) -> some View {
    VStack(spacing: 0) {
      ForEach(flipped ? Array(1...8) : Array((1...8).reversed()), id: \.self) { rank in
        Text("\(rank)").frame(width: gutter, height: geometry.cell)
      }
    }
    .font(.system(size: 12, weight: .bold))
    .foregroundStyle(Theme.inkMuted)
    .accessibilityHidden(true)
  }

  private func files(_ geometry: BoardGeometry) -> some View {
    HStack(spacing: 0) {
      ForEach(flipped ? Array("hgfedcba") : Array("abcdefgh"), id: \.self) { file in
        Text(String(file)).frame(width: geometry.cell, height: gutter)
      }
    }
    .padding(.leading, gutter)
    .font(.system(size: 12, weight: .bold))
    .foregroundStyle(Theme.inkMuted)
    .accessibilityHidden(true)
  }

  private func squares(_ geometry: BoardGeometry) -> some View {
    let targets = Set(legalMoves ? game.targets : [])
    return ForEach(geometry.readingOrder, id: \.self) { square in
      let light = (square.file.number + square.rank.value) % 2 == 1
      ZStack(alignment: .topLeading) {
        Rectangle().fill(light ? boardTheme.light : boardTheme.dark)
        if square == game.lastMove?.from || square == game.lastMove?.to {
          Rectangle().fill(Theme.Board.last)
        }
        if square == game.selected || square == dragFrom {
          Rectangle().fill(Theme.Board.select)
        }
        if square == game.checkedKing {
          Circle().fill(RadialGradient(colors: [Theme.Board.check, .clear], center: .center, startRadius: 0, endRadius: geometry.cell * 0.55))
        }
        if targets.contains(square) {
          if game.board.position.piece(at: square) == nil {
            Circle().fill(Theme.Board.dot)
              .frame(width: geometry.cell * 0.3, height: geometry.cell * 0.3)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          } else {
            Circle().strokeBorder(Theme.Board.dot, lineWidth: geometry.cell * 0.09).padding(geometry.cell * 0.03)
          }
        }
      }
      .frame(width: geometry.cell, height: geometry.cell)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(label(square))
      .accessibilityValue(value(square, targets: targets))
      .accessibilityAddTraits(.isButton)
      .accessibilityAddTraits(square == game.selected ? .isSelected : [])
      .accessibilityAction { game.tap(square) }
      .offset(x: CGFloat(geometry.column(square)) * geometry.cell, y: CGFloat(geometry.row(square)) * geometry.cell)
    }
  }

  private func label(_ square: Square) -> String {
    guard let piece = game.board.position.piece(at: square) else { return "\(square.notation), empty" }
    return "\(square.notation), \(piece.color == .white ? "white" : "black") \(piece.kind.name)"
  }

  private func value(_ square: Square, targets: Set<Square>) -> String {
    [
      square == game.selected ? "selected" : nil,
      targets.contains(square) ? (game.board.position.piece(at: square) == nil ? "legal move" : "capture") : nil,
      square == game.checkedKing ? "in check" : nil,
      square == game.lastMove?.to ? "last move" : nil,
    ]
    .compactMap { $0 }
    .joined(separator: ", ")
  }

  /// One view per piece, also while it is dragged: lifted under the finger, then settling into
  /// its new square, or back to its own when the drop is not legal.
  private func pieces(_ geometry: BoardGeometry) -> some View {
    ForEach(game.pieces) { item in
      let lifted = dragPoint != nil && dragFrom == item.piece.square
      pieceSet.image(item.piece)
        .resizable()
        .scaledToFit()
        .frame(width: geometry.cell, height: geometry.cell)
        .scaleEffect(lifted ? 1.35 : 1)
        .shadow(color: .black.opacity(lifted ? 0.22 : 0), radius: 8, y: 6)
        .position(lifted ? lift(dragPoint ?? .zero, geometry) : geometry.center(item.piece.square))
        .zIndex(lifted ? 1 : 0)
        .transition(.scale(scale: 0.6).combined(with: .opacity))
        .allowsHitTesting(false)
    }
    .animation(settle, value: game.pieces)
  }

  /// The piece rides a little above the fingertip, so the finger doesn't hide it.
  private func lift(_ point: CGPoint, _ geometry: BoardGeometry) -> CGPoint {
    CGPoint(x: point.x, y: point.y - geometry.cell * 0.45)
  }

  /// One gesture for both: a touch that barely moves is a tap, past 6 points it is a drag.
  private func input(_ geometry: BoardGeometry) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .updating($touching) { _, state, _ in state = true }
      .onChanged { value in
        guard let start = geometry.square(at: value.startLocation) else { return }
        let moved = hypot(value.translation.width, value.translation.height) > 6
        let mine = game.board.position.piece(at: start).map { game.controls($0.color) } ?? false
        guard moved, mine else { return }
        if dragFrom == nil {
          dragFrom = start
          game.selected = start
          Haptics.selection()
          Haptics.prepareDrop()
        }
        dragPoint = value.location
      }
      .onEnded { value in
        guard let from = dragFrom, dragPoint != nil else {
          dragFrom = nil
          if let square = geometry.square(at: value.location) { game.tap(square) }
          return
        }
        let target = geometry.square(at: value.location)
        withAnimation(settle) {
          dragFrom = nil
          dragPoint = nil
          if let target, target != from {
            game.selected = nil
            game.drop(from: from, to: target)
          }
        }
      }
  }
}

/// The four pieces a pawn can become, over a veil on the board.
struct PromotionPicker: View {
  @Environment(GameStore.self) private var game
  @AppStorage(Pref.pieceSet) private var pieceSet = PieceSet.cburnett

  var body: some View {
    ZStack {
      Theme.ground.opacity(0.6)
      HStack(spacing: 8) {
        ForEach([Piece.Kind.queen, .rook, .bishop, .knight], id: \.self) { kind in
          Button { game.promote(to: kind) } label: {
            pieceSet.image(Piece(kind, color: game.sideToMove, square: .a1))
              .resizable().scaledToFit()
              .frame(width: 54, height: 54)
              .padding(4)
              .background(Theme.raised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
          }
          .buttonStyle(SoftPress())
          .accessibilityLabel("Promote to \(kind.name)")
        }
      }
      .padding(10)
      .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
      .softShadow()
    }
    .onTapGesture { game.promotion = nil }
    .accessibilityAction(.escape) { game.promotion = nil }
    .transition(.opacity)
  }
}

/// The home card's board: no input, just the current position.
struct MiniBoard: View {
  let pieces: [BoardPiece]
  let flipped: Bool
  @AppStorage(Pref.boardTheme) private var boardTheme = BoardTheme.stone
  @AppStorage(Pref.pieceSet) private var pieceSet = PieceSet.cburnett

  var body: some View {
    GeometryReader { proxy in
      let geometry = BoardGeometry(size: proxy.size.width, flipped: flipped)
      ZStack(alignment: .topLeading) {
        Canvas { context, _ in
          for square in BoardGeometry.all {
            let rect = CGRect(x: CGFloat(geometry.column(square)) * geometry.cell, y: CGFloat(geometry.row(square)) * geometry.cell, width: geometry.cell, height: geometry.cell)
            let light = (square.file.number + square.rank.value) % 2 == 1
            context.fill(Path(rect), with: .color(light ? boardTheme.light : boardTheme.dark))
          }
        }
        ForEach(pieces) { item in
          pieceSet.image(item.piece)
            .resizable().scaledToFit()
            .frame(width: geometry.cell, height: geometry.cell)
            .position(geometry.center(item.piece.square))
        }
      }
    }
    .aspectRatio(1, contentMode: .fit)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.Board.edge, lineWidth: 2)
    }
  }
}
