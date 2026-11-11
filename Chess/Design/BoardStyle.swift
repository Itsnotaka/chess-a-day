import ChessKit
import SwiftUI

/// The board's colours. Each theme has a light square and a dark square, in light and dark mode.
enum BoardTheme: String, CaseIterable, Identifiable, Sendable {
  case stone, sand, sage, sky, lilac

  var id: Self { self }
  var name: String { rawValue.capitalized }

  var light: Color {
    switch self {
    case .stone: Color(light: 0xFAFAFA, dark: 0x4A4A4A)
    case .sand: Color(light: 0xF7F1E6, dark: 0x5A5246)
    case .sage: Color(light: 0xF1F4EC, dark: 0x4D5547)
    case .sky: Color(light: 0xEEF3F8, dark: 0x47505B)
    case .lilac: Color(light: 0xF6F1FA, dark: 0x534A5C)
    }
  }

  var dark: Color {
    switch self {
    case .stone: Color(light: 0xDCDCDC, dark: 0x363636)
    case .sand: Color(light: 0xE3D3B6, dark: 0x403A31)
    case .sage: Color(light: 0xC9D6BB, dark: 0x383F33)
    case .sky: Color(light: 0xC6D5E7, dark: 0x333B45)
    case .lilac: Color(light: 0xDCCBEA, dark: 0x3D3545)
    }
  }
}

/// The piece artwork, each a namespaced folder in the asset catalog.
enum PieceSet: String, CaseIterable, Identifiable, Sendable {
  case cburnett, merida, chessnut

  var id: Self { self }

  var name: String {
    switch self {
    case .cburnett: "Classic"
    case .merida: "Merida"
    case .chessnut: "Chessnut"
    }
  }

  func image(_ piece: Piece) -> Image { Image("\(rawValue)/\(piece.assetName)") }
  func image(_ name: String) -> Image { Image("\(rawValue)/\(name)") }
}
