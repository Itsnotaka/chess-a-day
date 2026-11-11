import ChessKit
import SwiftUI

/// The board's colours. Each theme has a light square and a dark square, in light and dark mode.
/// Dark mode keeps the squares mid-toned, so black pieces never sink into them.
enum BoardTheme: String, CaseIterable, Identifiable, Sendable {
  case stone, sand, sage, sky, lilac

  var id: Self { self }
  var name: String { rawValue.capitalized }

  var light: Color {
    switch self {
    case .stone: Color(light: 0xFAFAFA, dark: 0xA3A3A3)
    case .sand: Color(light: 0xF7F1E6, dark: 0xBDAF97)
    case .sage: Color(light: 0xF1F4EC, dark: 0xA5B297)
    case .sky: Color(light: 0xEEF3F8, dark: 0x9FB0C4)
    case .lilac: Color(light: 0xF6F1FA, dark: 0xB2A4C2)
    }
  }

  var dark: Color {
    switch self {
    case .stone: Color(light: 0xDCDCDC, dark: 0x787878)
    case .sand: Color(light: 0xE3D3B6, dark: 0x8F7F64)
    case .sage: Color(light: 0xC9D6BB, dark: 0x76856A)
    case .sky: Color(light: 0xC6D5E7, dark: 0x6F8299)
    case .lilac: Color(light: 0xDCCBEA, dark: 0x85759A)
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
