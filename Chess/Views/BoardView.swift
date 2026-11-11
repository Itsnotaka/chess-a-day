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
}

/// The playable board: tap a piece then a square, or drag it; legal moves show as dots.
struct BoardView: View {
  @Environment(GameStore.self) private var game
  @AppStorage(Pref.coordinates) private var coordinates = true
  @AppStorage(Pref.legalMoves) private var legalMoves = true
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @State private var dragFrom: Square?
  @State private var dragPoint: CGPoint?

  var body: some View {
    GeometryReader { proxy in
      let geometry = BoardGeometry(size: proxy.size.width, flipped: game.you == .black)
      ZStack(alignment: .topLeading) {
        squares(geometry)
        pieces(geometry)
        ghost(geometry)
      }
      .frame(width: geometry.size, height: geometry.size)
      .contentShape(Rectangle())
      .gesture(input(geometry))
    }
    .aspectRatio(1, contentMode: .fit)
    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.board, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: Theme.Radius.board, style: .continuous)
        .strokeBorder(Theme.Board.edge, lineWidth: 2)
    }
    .overlay { if game.promotion != nil { PromotionPicker() } }
  }

  private func squares(_ geometry: BoardGeometry) -> some View {
    let targets = Set(legalMoves ? game.targets : [])
    return ForEach(BoardGeometry.all, id: \.self) { square in
      let light = (square.file.number + square.rank.value) % 2 == 1
      ZStack(alignment: .topLeading) {
        Rectangle().fill(light ? Theme.Board.light : Theme.Board.dark)
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
        if coordinates { coordinate(square, geometry: geometry) }
      }
      .frame(width: geometry.cell, height: geometry.cell)
      .offset(x: CGFloat(geometry.column(square)) * geometry.cell, y: CGFloat(geometry.row(square)) * geometry.cell)
    }
  }

  @ViewBuilder
  private func coordinate(_ square: Square, geometry: BoardGeometry) -> some View {
    let color = Theme.Board.coordinate
    if geometry.column(square) == 0 {
      Text("\(square.rank.value)").font(.system(size: 10, weight: .bold)).foregroundStyle(color).padding(3)
    }
    if geometry.row(square) == 7 {
      Text(square.file.rawValue).font(.system(size: 10, weight: .bold)).foregroundStyle(color)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing).padding(.trailing, 3).padding(.bottom, 1)
    }
  }

  private func pieces(_ geometry: BoardGeometry) -> some View {
    ForEach(game.pieces) { item in
      Image(item.piece.assetName)
        .resizable()
        .scaledToFit()
        .frame(width: geometry.cell, height: geometry.cell)
        .position(geometry.center(item.piece.square))
        .opacity(dragFrom == item.piece.square && dragPoint != nil ? 0.3 : 1)
        .transition(.scale(scale: 0.6).combined(with: .opacity))
        .allowsHitTesting(false)
    }
    .animation(reduceMotion ? .easeOut(duration: 0.12) : Theme.pieceSlide, value: game.pieces)
  }

  @ViewBuilder
  private func ghost(_ geometry: BoardGeometry) -> some View {
    if let dragFrom, let dragPoint, let piece = game.board.position.piece(at: dragFrom) {
      Image(piece.assetName)
        .resizable()
        .scaledToFit()
        .frame(width: geometry.cell * 1.5, height: geometry.cell * 1.5)
        .position(x: dragPoint.x, y: dragPoint.y - geometry.cell * 0.5)
        .shadow(color: .black.opacity(0.2), radius: 8, y: 6)
        .allowsHitTesting(false)
    }
  }

  /// One gesture for both: a touch that barely moves is a tap, past 6 points it is a drag.
  private func input(_ geometry: BoardGeometry) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        guard let start = geometry.square(at: value.startLocation) else { return }
        let moved = hypot(value.translation.width, value.translation.height) > 6
        let mine = game.board.position.piece(at: start)?.color == game.you
        if moved, game.yourTurn, mine {
          if dragFrom == nil {
            dragFrom = start
            game.selected = start
            Haptics.selection()
          }
          dragPoint = value.location
        }
      }
      .onEnded { value in
        defer {
          dragFrom = nil
          dragPoint = nil
        }
        if let from = dragFrom, dragPoint != nil {
          if let to = geometry.square(at: value.location), to != from {
            game.selected = nil
            game.drop(from: from, to: to)
          }
          return
        }
        if let square = geometry.square(at: value.location) { game.tap(square) }
      }
  }
}

/// The four pieces a pawn can become, over a veil on the board.
struct PromotionPicker: View {
  @Environment(GameStore.self) private var game

  var body: some View {
    ZStack {
      Theme.ground.opacity(0.6)
      HStack(spacing: 8) {
        ForEach([Piece.Kind.queen, .rook, .bishop, .knight], id: \.self) { kind in
          Button { game.promote(to: kind) } label: {
            Image(Piece(kind, color: game.you, square: .a1).assetName)
              .resizable().scaledToFit()
              .frame(width: 54, height: 54)
              .padding(4)
              .background(Theme.raised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
          }
          .buttonStyle(SoftPress())
        }
      }
      .padding(10)
      .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
      .softShadow()
    }
    .onTapGesture { game.promotion = nil }
    .transition(.opacity)
  }
}

/// The home card's board: no input, just the current position.
struct MiniBoard: View {
  let pieces: [BoardPiece]
  let flipped: Bool

  var body: some View {
    GeometryReader { proxy in
      let geometry = BoardGeometry(size: proxy.size.width, flipped: flipped)
      ZStack(alignment: .topLeading) {
        Canvas { context, _ in
          for square in BoardGeometry.all {
            let rect = CGRect(x: CGFloat(geometry.column(square)) * geometry.cell, y: CGFloat(geometry.row(square)) * geometry.cell, width: geometry.cell, height: geometry.cell)
            let light = (square.file.number + square.rank.value) % 2 == 1
            context.fill(Path(rect), with: .color(light ? Theme.Board.light : Theme.Board.dark))
          }
        }
        ForEach(pieces) { item in
          Image(item.piece.assetName)
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
