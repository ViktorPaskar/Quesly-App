import Foundation
import UserNotifications

/// Local daily reminder ("Next Day → Notification / Reminder" in the user journey).
/// Replace with push notifications from the backend later.
enum NotificationScheduler {
    private static let reminderId = "quesly.daily.reminder"
    private static let streakAlertId = "quesly.streak.protection"

    @MainActor
    static func requestAuthorization(store: AppStore) {
        guard !DemoConfig.isActive else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            Task { @MainActor in reschedule(store: store) }
        }
    }

    @MainActor
    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    @MainActor
    static func reschedule(store: AppStore) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderId, streakAlertId])
        guard store.isSignedIn else { return }

        // 1. Daily question reminder
        if store.remindersEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Today's question is here ✨"
            content.body = "One question a day. Take a minute and share your story."
            content.sound = .default

            let time = Calendar.current.dateComponents([.hour, .minute], from: store.reminderTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
            center.add(UNNotificationRequest(identifier: reminderId, content: content, trigger: trigger))
        }

        // 2. Streak protection alert (evening at 21:00)
        if store.streakAlerts && store.streak > 0 {
            let content = UNMutableNotificationContent()
            content.title = "Keep your \(store.streak)-day streak alive 🔥"
            content.body = "Answer today's question before midnight to protect your momentum."
            content.sound = .default

            var components = DateComponents()
            components.hour = 21
            components.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            center.add(UNNotificationRequest(identifier: streakAlertId, content: content, trigger: trigger))
        }
    }
}
