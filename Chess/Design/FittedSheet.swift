import SwiftUI

/// Fits a sheet detent to measured content, with scrolling when the content exceeds the screen.
/// Height changes use a spring, or easing under Reduce Motion.
struct FittedSheet<Content: View>: View {
  @ViewBuilder let content: Content
  @State private var height: CGFloat?
  @AppStorage(Pref.appearance) private var appearance = Appearance.system
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    ScrollView {
      content
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { measured in
          // Leave room below the content without rounding its height down.
          let target = ceil(measured) + 16
          guard height != target else { return }
          // Avoid animating from the initial medium detent.
          if height == nil { height = target } else {
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : Theme.sheetResize) { height = target }
          }
        }
    }
    .scrollBounceBehavior(.basedOnSize)
    .presentationDetents([height.map { .height($0) } ?? .medium])
    .presentationDragIndicator(.visible)
    .presentationCornerRadius(Theme.Radius.card)
    .presentationBackground(Theme.card)
    // A presented sheet keeps its own scheme: follow the app's choice here too, live.
    .preferredColorScheme(appearance.scheme)
  }
}
