import Foundation
import UserNotifications

/// A lightweight singleton that manages notification authorization and simple scheduling.
final class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    /// Checks the current notification authorization status.
    /// - Returns: `true` if the app is authorized to post notifications (authorized, provisional, or ephemeral), otherwise `false`.
    func checkNotificationPermission() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .ephemeral:
            // Treat ephemeral as allowed for in-app ephemeral notifications
            return true
        case .denied, .notDetermined:
            return false
        @unknown default:
            return false
        }
    }

    /// Requests notification authorization from the user.
    /// - Returns: `true` if permission is granted (authorized/provisional/ephemeral), otherwise `false`.
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted { return true }
            // Re-check in case of provisional/ephemeral states
            return await checkNotificationPermission()
        } catch {
            return false
        }
    }

    /// Schedules a simple local notification in 5 seconds, if permission is available.
    func scheduleTestNotification() async {
        let hasPermission = await checkNotificationPermission()
        guard hasPermission else { return }

        let content = UNMutableNotificationContent()
        content.title = "Workout Reminder"
        content.body = "Time to move! Log your next set."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        do {
            try await center.add(request)
        } catch {
            // Intentionally ignore errors for this helper; consider logging in your project
        }
    }
}
