import SwiftUI

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
    .preferredColorScheme(appearance.scheme)
  }
}
