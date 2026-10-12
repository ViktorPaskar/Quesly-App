import Foundation
import UserNotifications

/// Local daily reminder ("Next Day → Notification / Reminder" in the user journey).
/// Replace with push notifications from the backend later.
enum NotificationScheduler {
    private static let reminderId = "quesly.daily.reminder"

    @MainActor
    static func requestAuthorization(store: AppStore) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            Task { @MainActor in reschedule(store: store) }
        }
    }

    @MainActor
    static func reschedule(store: AppStore) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderId])
        guard store.remindersEnabled, store.isSignedIn else { return }

        let content = UNMutableNotificationContent()
        content.title = "Today's question is here ✨"
        content.body = "One question a day. Take a minute and share your story."
        content.sound = .default

        let time = Calendar.current.dateComponents([.hour, .minute], from: store.reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        center.add(UNNotificationRequest(identifier: reminderId, content: content, trigger: trigger))
    }
}
