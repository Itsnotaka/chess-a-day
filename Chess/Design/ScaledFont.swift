import SwiftUI

struct ScaledFont: ViewModifier {
  @ScaledMetric private var size: CGFloat
  private let weight: Font.Weight

  init(size: CGFloat, weight: Font.Weight) {
    _size = ScaledMetric(wrappedValue: size, relativeTo: Self.style(for: size))
    self.weight = weight
  }

  func body(content: Content) -> some View {
    content.font(.system(size: size, weight: weight))
  }

  private static func style(for size: CGFloat) -> Font.TextStyle {
    switch size {
    case 30...: .largeTitle
    case 22..<30: .title2
    case 19..<22: .title3
    case 16..<19: .body
    case 14..<16: .subheadline
    default: .footnote
    }
  }
}

extension View {
  func scaledFont(_ size: CGFloat, _ weight: Font.Weight = .regular) -> some View {
    modifier(ScaledFont(size: size, weight: weight))
  }
}
