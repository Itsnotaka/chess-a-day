import UIKit

/// Haptics, silent when the person turned them off in App Settings.
@MainActor
enum Haptics {
  private static var on: Bool { UserDefaults.standard.object(forKey: Pref.haptics) as? Bool ?? true }

  static func selection() {
    guard on else { return }
    UISelectionFeedbackGenerator().selectionChanged()
  }

  static func move(capture: Bool) {
    guard on else { return }
    UIImpactFeedbackGenerator(style: capture ? .medium : .soft).impactOccurred()
  }

  static func finish(won: Bool) {
    guard on else { return }
    UINotificationFeedbackGenerator().notificationOccurred(won ? .success : .warning)
  }

  static func tap() {
    guard on else { return }
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
  }
}
