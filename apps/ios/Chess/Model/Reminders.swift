import UserNotifications

enum Reminders {
  private static let id = "daily-reminder"

  enum Permission { case unknown, allowed, blocked }

  static func permission() async -> Permission {
    switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
    case .notDetermined: .unknown
    case .denied: .blocked
    default: .allowed
    }
  }

  /// Adding a request with the same identifier replaces the previous one.
  static func enable(minute: Int) async -> Bool {
    let center = UNUserNotificationCenter.current()
    let allowed: Bool = switch await permission() {
    case .allowed: true
    case .blocked: false
    case .unknown: (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) == true
    }
    guard allowed else { return false }
    let content = UNMutableNotificationContent()
    content.title = "Your game is waiting"
    content.body = "A calm game against the computer is ready when you are."
    content.sound = .default
    let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: minute / 60, minute: minute % 60), repeats: true)
    do {
      try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
      return true
    } catch {
      return false
    }
  }

  static func cancel() {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
  }
}
