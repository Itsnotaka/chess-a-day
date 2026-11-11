import UIKit

@MainActor
enum Haptics {
  private static var on: Bool { UserDefaults.standard.object(forKey: Pref.haptics) as? Bool ?? true }

  private static let selectionGenerator = UISelectionFeedbackGenerator()
  private static let soft = UIImpactFeedbackGenerator(style: .soft)
  private static let medium = UIImpactFeedbackGenerator(style: .medium)
  private static let light = UIImpactFeedbackGenerator(style: .light)
  private static let notification = UINotificationFeedbackGenerator()

  static func selection() {
    guard on else { return }
    selectionGenerator.selectionChanged()
    selectionGenerator.prepare()
  }

  static func prepareDrop() {
    guard on else { return }
    soft.prepare()
    medium.prepare()
  }

  static func move(capture: Bool) {
    guard on else { return }
    (capture ? medium : soft).impactOccurred()
  }

  static func finish(won: Bool) {
    guard on else { return }
    notification.notificationOccurred(won ? .success : .warning)
  }

  static func miss() {
    guard on else { return }
    notification.notificationOccurred(.warning)
  }

  static func tap() {
    guard on else { return }
    light.impactOccurred()
  }
}
