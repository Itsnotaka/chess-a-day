import SwiftUI
import UIKit

/// The palette, taken from Sudoku a Day's own tokens: soft neutral greys, ink that is
/// never pure black, and one colour per difficulty. Nothing else in the app writes a colour.
enum Theme {
  static let ground = Color(light: 0xE6E6E6, dark: 0x1A1A1A)
  static let card = Color(light: 0xFEFFFF, dark: 0x262626)
  static let raised = Color(light: 0xF2F2F2, dark: 0x333333)
  static let pressed = Color(light: 0xE9E9E9, dark: 0x3B3B3B)

  static let ink = Color(light: 0x262626, dark: 0xD9D9D9)
  static let inkMuted = Color(light: 0x666666, dark: 0x8C8C8C)
  static let inkFaint = Color(light: 0xBFBFBF, dark: 0x404040)
  static let onInk = Color(light: 0xFEFFFF, dark: 0x1A1A1A)

  static let blue = Color(light: 0x007AFF, dark: 0x0A84FF)
  static let live = Color(light: 0x8AB800, dark: 0xBBF91E)

  // Sudoku a Day's difficulty hues, deepened a step in light mode so a white symbol on them,
  // or the hue on a light fill, keeps at least 3:1.
  static let teal = Color(light: 0x1A8FA8, dark: 0x29D1FF)
  static let purple = Color(light: 0xA045D3, dark: 0xBC85FF)
  static let red = Color(light: 0xE0362A, dark: 0xFF6767)
  static let brown = Color(light: 0x8E7049, dark: 0xC4A27A)
  /// Ink on a level colour: white on the deep light-mode hues, near-black on the bright dark-mode ones.
  static let onTint = Color(light: 0xFFFFFF, dark: 0x1A1A1A)

  static let shadow = Color(light: 0x000000, dark: 0x000000, lightAlpha: 0.07, darkAlpha: 0)
  static let hairline = Color(light: 0x000000, dark: 0xFFFFFF, lightAlpha: 0.06, darkAlpha: 0.07)

  /// What sits on every board theme; the squares themselves are `BoardTheme`'s.
  enum Board {
    static let edge = Color(light: 0x262626, dark: 0xD9D9D9)
    static let select = Color(light: 0x262626, dark: 0xFFFFFF, lightAlpha: 0.22, darkAlpha: 0.30)
    static let last = Color(light: 0x262626, dark: 0xFFFFFF, lightAlpha: 0.13, darkAlpha: 0.18)
    static let coordinate = Color(light: 0x262626, dark: 0xD9D9D9, lightAlpha: 0.38, darkAlpha: 0.45)
    static let check = Color(light: 0xFC3E30, dark: 0xFF6767, lightAlpha: 0.45, darkAlpha: 0.5)
    static let dot = Color(light: 0x262626, dark: 0x1A1A1A, lightAlpha: 0.28, darkAlpha: 0.42)
  }

  enum Radius {
    static let card: CGFloat = 36
    static let row: CGFloat = 20
    static let board: CGFloat = 12
  }

  /// Sudoku a Day's `--spring-standard`: a short spring that overshoots a touch.
  static let spring = Animation.spring(response: 0.32, dampingFraction: 0.72)
  static let pieceSlide = Animation.spring(response: 0.26, dampingFraction: 0.86)
  /// A sheet growing or shrinking to fit a new page.
  static let sheetResize = Animation.spring(response: 0.42, dampingFraction: 0.86)
}

extension Color {
  init(light: UInt32, dark: UInt32, lightAlpha: Double = 1, darkAlpha: Double = 1) {
    self.init(uiColor: UIColor { traits in
      traits.userInterfaceStyle == .dark
        ? UIColor(hex: dark, alpha: darkAlpha)
        : UIColor(hex: light, alpha: lightAlpha)
    })
  }
}

extension UIColor {
  convenience init(hex: UInt32, alpha: Double) {
    self.init(
      red: CGFloat((hex >> 16) & 0xFF) / 255,
      green: CGFloat((hex >> 8) & 0xFF) / 255,
      blue: CGFloat(hex & 0xFF) / 255,
      alpha: alpha
    )
  }
}

extension View {
  /// The soft, wide shadow every floating surface uses.
  func softShadow(radius: CGFloat = 24, y: CGFloat = 10) -> some View {
    shadow(color: Theme.shadow, radius: radius, x: 0, y: y)
  }
}
