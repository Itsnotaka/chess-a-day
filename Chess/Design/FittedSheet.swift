import SwiftUI

/// A sheet as tall as what it shows. Its content reports its height, and the sheet's detent
/// follows it on a spring, so the sheet grows and shrinks as its content changes. Content taller
/// than the screen scrolls inside a large sheet.
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
          let target = ceil(measured) + 16
          guard height != target else { return }
          // The first height lands at once; every later one morphs.
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
