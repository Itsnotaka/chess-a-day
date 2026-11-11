import SwiftUI

extension View {
  func tray<Content: View>(
    isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    modifier(TrayPresenter(
      item: Binding(
        get: { isPresented.wrappedValue ? TrayFlag.on : nil },
        set: { isPresented.wrappedValue = $0 != nil }),
      onDismiss: onDismiss,
      content: { _ in content() }))
  }

  func tray<Item: Identifiable, Content: View>(
    item: Binding<Item?>, onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: @escaping (Item) -> Content
  ) -> some View {
    modifier(TrayPresenter(item: item, onDismiss: onDismiss, content: content))
  }
}

private enum TrayFlag: Identifiable {
  case on
  var id: Self { self }
}

private struct TrayPresenter<Item: Identifiable, TrayContent: View>: ViewModifier {
  @Binding var item: Item?
  let onDismiss: (() -> Void)?
  let content: (Item) -> TrayContent

  @State private var shown: Item?
  @State private var presented = false
  @State private var drag: CGFloat = 0
  @State private var height: CGFloat = 0
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private static var closeDistance: CGFloat { 110 }
  private static var closeSpeed: CGFloat { 1000 }

  func body(content base: Content) -> some View {
    base
      .accessibilityHidden(shown != nil)
      .overlay {
        if let shown {
          GeometryReader { proxy in
            tray(shown, in: proxy)
          }
          .ignoresSafeArea()
        }
      }
      .onChange(of: item?.id, initial: true) { _, id in
        if id == nil { close() } else { open() }
      }
  }

  private func tray(_ shown: Item, in proxy: GeometryProxy) -> some View {
    let bottom = max(proxy.safeAreaInsets.bottom, 16)
    let room = proxy.size.height - proxy.safeAreaInsets.top - bottom - 16 - Self.handleHeight
    let fade = 1 - 0.6 * min(max(drag, 0) / 1000, 1)
    return ZStack(alignment: .bottom) {
      Theme.scrim
        .opacity(presented ? fade : 0)
        .contentShape(Rectangle())
        .onTapGesture { item = nil }
        .accessibilityHidden(true)

      card(shown, room: room)
        .padding(.horizontal, 16)
        .padding(.bottom, bottom)
        .scaleEffect(presented || reduceMotion ? 1 : 0.94, anchor: .bottom)
        .offset(y: (presented || reduceMotion ? 0 : proxy.size.height) + drag)
        .opacity(presented || !reduceMotion ? 1 : 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
  }

  private static var handleHeight: CGFloat { 20 }

  private func card(_ shown: Item, room: CGFloat) -> some View {
    VStack(spacing: 0) {
      Capsule()
        .fill(Theme.inkFaint)
        .frame(width: 40, height: 4)
        .frame(maxWidth: .infinity, minHeight: Self.handleHeight)
        .contentShape(Rectangle())
        .accessibilityHidden(true)
      ScrollView {
        content(shown)
          .frame(maxWidth: .infinity)
          .padding(.bottom, 16)
          .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { measured in
            resize(to: ceil(measured))
          }
      }
      .scrollDisabled(height <= room)
      .scrollBounceBehavior(.basedOnSize)
      .frame(height: height == 0 ? room : min(height, room))
    }
    .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    .gesture(dismissDrag)
    .accessibilityAddTraits(.isModal)
    .accessibilityAction(.escape) { item = nil }
  }

  private var dismissDrag: some Gesture {
    DragGesture(minimumDistance: 10, coordinateSpace: .global)
      .onChanged { value in
        let pull = value.translation.height
        drag = pull > 0 ? pull : pull / 8
      }
      .onEnded { value in
        if value.translation.height > Self.closeDistance || value.velocity.height > Self.closeSpeed {
          item = nil
        } else {
          withAnimation(reduceMotion ? Theme.Tray.reduced : Theme.Tray.dragReturn) { drag = 0 }
        }
      }
  }

  private func resize(to measured: CGFloat) {
    guard height != measured else { return }
    let first = height == 0
    if first {
      height = measured
      withAnimation(reduceMotion ? Theme.Tray.reduced : Theme.Tray.present) { presented = true }
    } else {
      withAnimation(reduceMotion ? Theme.Tray.reduced : Theme.Tray.resize) { height = measured }
    }
  }

  private func open() {
    guard let item else { return }
    if shown?.id == item.id {
      // Reopened mid-exit: turn the exit around.
      if !presented, height > 0 {
        withAnimation(reduceMotion ? Theme.Tray.reduced : Theme.Tray.present) { presented = true }
      }
      return
    }
    if shown == nil {
      drag = 0
      height = 0
      presented = false
    }
    shown = item
  }

  private func close() {
    guard shown != nil else { return }
    guard presented else {
      shown = nil
      onDismiss?()
      return
    }
    withAnimation(reduceMotion ? Theme.Tray.reduced : Theme.Tray.close) {
      presented = false
    } completion: {
      guard item == nil else { return }
      shown = nil
      drag = 0
      height = 0
      onDismiss?()
    }
  }
}
