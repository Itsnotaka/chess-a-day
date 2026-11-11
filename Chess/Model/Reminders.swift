import UserNotifications

/// The one daily reminder. iOS repeats it itself; the app only asks once and reschedules on change.
enum Reminders {
  private static let id = "daily-reminder"

  static func schedule(hour: Int) {
    Task {
      let center = UNUserNotificationCenter.current()
      guard (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) == true else { return }
      center.removePendingNotificationRequests(withIdentifiers: [id])
      let content = UNMutableNotificationContent()
      content.title = "Your game is waiting"
      content.body = "Today's game and puzzle are ready."
      content.sound = .default
      let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: hour, minute: 0), repeats: true)
      try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
  }

  static func cancel() {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
  }
}
