import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private let restTimerNotificationIdentifier = "restTimerNotification"
    
    private init() {}
    
    // MARK: - Permission Request
    
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }
    
    func checkNotificationPermission() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    // MARK: - Rest Timer Notifications
    
    func scheduleRestTimerNotification(duration: Int) {
        // Remove any existing rest timer notification
        cancelRestTimerNotification()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Rest Timer Complete"
        content.body = "Your rest period is over. Time to get back to your workout! 💪"
        content.sound = .default
        content.categoryIdentifier = "REST_TIMER"
        
        // Schedule notification for when timer completes
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(duration), repeats: false)
        let request = UNNotificationRequest(
            identifier: restTimerNotificationIdentifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling rest timer notification: \(error)")
            }
        }
    }
    
    func cancelRestTimerNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [restTimerNotificationIdentifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [restTimerNotificationIdentifier])
    }
}

