import ChessKit
import SwiftUI

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

  var readingOrder: [Square] {
    Self.all.sorted { (row($0), column($0)) < (row($1), column($1)) }
  }
}

struct BoardView: View {
  @Environment(GameStore.self) private var game
  @AppStorage(Pref.coordinates) private var coordinates = true
  @AppStorage(Pref.legalMoves) private var legalMoves = true
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @State private var dragFrom: Square?
  @State private var dragPoint: CGPoint?
  @GestureState private var touching = false

  private var settle: Animation { reduceMotion ? .easeOut(duration: 0.12) : Theme.pieceSlide }

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
      marks(geometry)
      pieces(geometry).accessibilityHidden(true)
      arrows(geometry)
    }
    .frame(width: geometry.size, height: geometry.size)
    .contentShape(Rectangle())
    .gesture(input(geometry))
    .onChange(of: touching) { _, now in
      // Cancellation skips onEnded; yield so a normal drop can clear its drag first.
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
        .motionTransition(.scale(scale: 0.6).combined(with: .opacity))
        .allowsHitTesting(false)
        .id(reduceMotion ? AnyHashable(item.piece.square) : AnyHashable(item.id))
    }
    .animation(settle, value: game.pieces)
  }

  private func marks(_ geometry: BoardGeometry) -> some View {
    ForEach(game.marks, id: \.self) { mark in
      Circle()
        .strokeBorder(mark.color.board, lineWidth: geometry.cell * 0.08)
        .frame(width: geometry.cell * 0.9, height: geometry.cell * 0.9)
        .position(geometry.center(mark.square))
        .motionTransition(.scale(scale: 0.6).combined(with: .opacity))
    }
    .animation(settle, value: game.marks)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private func arrows(_ geometry: BoardGeometry) -> some View {
    ForEach(game.arrows, id: \.self) { arrow in
      ArrowShape(from: geometry.center(arrow.from), to: geometry.center(arrow.to), width: geometry.cell * 0.17)
        .fill(arrow.color.board)
        .transition(.opacity)
    }
    .animation(.easeOut(duration: 0.25), value: game.arrows)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private func lift(_ point: CGPoint, _ geometry: BoardGeometry) -> CGPoint {
    CGPoint(x: point.x, y: point.y - geometry.cell * 0.45)
  }

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

struct ArrowShape: Shape {
  let from: CGPoint
  let to: CGPoint
  let width: CGFloat

  func path(in rect: CGRect) -> Path {
    let dx = to.x - from.x, dy = to.y - from.y
    let length = max(hypot(dx, dy), 1)
    let ux = dx / length, uy = dy / length
    let head = width * 2.4
    let start = CGPoint(x: from.x + ux * width * 1.2, y: from.y + uy * width * 1.2)
    let neck = CGPoint(x: to.x - ux * head, y: to.y - uy * head)
    let nx = -uy, ny = ux
    var path = Path()
    path.move(to: CGPoint(x: start.x + nx * width / 2, y: start.y + ny * width / 2))
    path.addLine(to: CGPoint(x: neck.x + nx * width / 2, y: neck.y + ny * width / 2))
    path.addLine(to: CGPoint(x: neck.x + nx * head * 0.62, y: neck.y + ny * head * 0.62))
    path.addLine(to: to)
    path.addLine(to: CGPoint(x: neck.x - nx * head * 0.62, y: neck.y - ny * head * 0.62))
    path.addLine(to: CGPoint(x: neck.x - nx * width / 2, y: neck.y - ny * width / 2))
    path.addLine(to: CGPoint(x: start.x - nx * width / 2, y: start.y - ny * width / 2))
    path.addArc(center: start, radius: width / 2, startAngle: .radians(atan2(-ny, -nx)), endAngle: .radians(atan2(ny, nx)), clockwise: false)
    path.closeSubpath()
    return path
  }
}
