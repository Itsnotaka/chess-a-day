import UserNotifications

/// The one daily reminder. iOS repeats it; the app asks for permission when the person turns
/// it on and reports whether it may notify.
enum Reminders {
  private static let id = "daily-reminder"

  /// Authorization status, not a guarantee that alerts will be delivered.
  enum Permission { case unknown, allowed, blocked }

  static func permission() async -> Permission {
    switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
    case .notDetermined: .unknown
    case .denied: .blocked
    default: .allowed
    }
  }

  /// Requests permission if needed, then attempts to schedule.
  /// Returns authorization success; scheduling errors are ignored.
  /// `minute` counts from midnight: 540 is 9:00.
  static func enable(minute: Int) async -> Bool {
    let center = UNUserNotificationCenter.current()
    let allowed: Bool = switch await permission() {
    case .allowed: true
    case .blocked: false
    case .unknown: (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) == true
    }
    guard allowed else { return false }
    center.removePendingNotificationRequests(withIdentifiers: [id])
    let content = UNMutableNotificationContent()
    content.title = "Your game is waiting"
    content.body = "A calm game against the computer is ready when you are."
    content.sound = .default
    let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: minute / 60, minute: minute % 60), repeats: true)
    try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    return true
  }

  static func cancel() {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
  }
}
