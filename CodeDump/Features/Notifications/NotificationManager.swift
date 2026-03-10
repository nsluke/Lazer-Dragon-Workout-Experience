import UserNotifications
import Foundation

// MARK: - Protocol (enables mock injection in tests)

protocol NotificationScheduling: AnyObject {
    func requestAuthorization() async -> Bool
    func scheduleReminder(hour: Int, minute: Int) async
    func cancelReminder() async
    func authorizationStatus() async -> UNAuthorizationStatus
}

// MARK: - Manager

@MainActor
final class NotificationManager: NotificationScheduling {

    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    let reminderIdentifier = "com.ldwe.daily-reminder"

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: - Schedule

    func scheduleReminder(hour: Int, minute: Int) async {
        await cancelReminder()

        let content = UNMutableNotificationContent()
        content.title = "TIME TO TRAIN"
        content.body = "Your workout is waiting. Let's go."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: reminderIdentifier,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    // MARK: - Cancel

    func cancelReminder() async {
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
    }
}
