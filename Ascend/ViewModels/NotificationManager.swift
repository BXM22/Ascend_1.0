import Foundation
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    private let restTimerNotificationIdentifier = "restTimerNotification"
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Permission Request
    
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            Logger.error("Error requesting notification permission", error: error, category: .notification)
            return false
        }
    }
    
    func checkNotificationPermission() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    // MARK: - Rest Timer Notifications
    
    func scheduleRestTimerNotification(duration: Int, title: String = "Rest Timer Complete", body: String = "Your rest period is over. Time to get back to your workout! 💪") {
        // Remove any existing rest timer notification
        cancelRestTimerNotification()
        
        // Validate duration
        guard duration > 0 else {
            Logger.debug("Cannot schedule notification with invalid duration: \(duration)", category: .notification)
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "REST_TIMER"
        content.userInfo = ["restTimerCompleted": true]
        
        // Schedule notification for when timer completes
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(duration), repeats: false)
        let request = UNNotificationRequest(
            identifier: restTimerNotificationIdentifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.error("Error scheduling rest timer notification", error: error, category: .notification)
            } else {
                Logger.debug("Scheduled rest timer notification for \(duration) seconds", category: .notification)
            }
        }
    }
    
    func cancelRestTimerNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [restTimerNotificationIdentifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [restTimerNotificationIdentifier])
        Logger.debug("Cancelled rest timer notification", category: .notification)
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        Logger.debug("Cancelled all notifications", category: .notification)
    }
    
    // MARK: - Habit Reminders
    
    /// Schedules a daily repeating notification for a habit
    func scheduleHabitReminder(habit: Habit) {
        guard habit.reminderEnabled,
              let reminderTime = habit.reminderTime else {
            Logger.debug("Cannot schedule habit reminder - reminder not enabled or no time set", category: .notification)
            return
        }
        
        // Cancel any existing reminder for this habit
        cancelHabitReminder(habitId: habit.id)
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = habit.name
        content.body = "Time to complete your habit! (\(habit.completionDuration) min)"
        content.sound = .default
        content.categoryIdentifier = "HABIT_REMINDER"
        content.userInfo = [
            "habitId": habit.id.uuidString,
            "habitName": habit.name
        ]
        
        // Create daily repeating trigger
        var dateComponents = DateComponents()
        dateComponents.hour = components.hour
        dateComponents.minute = components.minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let identifier = "habitReminder_\(habit.id.uuidString)"
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.error("Error scheduling habit reminder", error: error, category: .notification)
            } else {
                Logger.debug("Scheduled daily habit reminder for \(habit.name) at \(components.hour ?? 0):\(components.minute ?? 0)", category: .notification)
            }
        }
    }
    
    /// Cancels the reminder for a specific habit
    func cancelHabitReminder(habitId: UUID) {
        let identifier = "habitReminder_\(habitId.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
        Logger.debug("Cancelled habit reminder for \(habitId)", category: .notification)
    }
    
    /// Updates all habit reminders (call when habits change)
    func updateAllHabitReminders(habits: [Habit]) {
        Task {
            // Cancel all existing habit reminders
            let center = UNUserNotificationCenter.current()
            let requests = await center.pendingNotificationRequests()
            let habitReminderIds = requests
                .filter { $0.identifier.hasPrefix("habitReminder_") }
                .map { $0.identifier }
            
            center.removePendingNotificationRequests(withIdentifiers: habitReminderIds)
            
            // Schedule reminders for habits that have them enabled
            for habit in habits {
                if habit.reminderEnabled {
                    await scheduleHabitReminderAsync(habit: habit)
                }
            }
        }
    }
    
    /// Async version for scheduling habit reminder
    private func scheduleHabitReminderAsync(habit: Habit) async {
        guard habit.reminderEnabled,
              let reminderTime = habit.reminderTime else {
            return
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        let content = UNMutableNotificationContent()
        content.title = habit.name
        content.body = "Time to complete your habit! (\(habit.completionDuration) min)"
        content.sound = .default
        content.categoryIdentifier = "HABIT_REMINDER"
        content.userInfo = [
            "habitId": habit.id.uuidString,
            "habitName": habit.name
        ]
        
        var dateComponents = DateComponents()
        dateComponents.hour = components.hour
        dateComponents.minute = components.minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let identifier = "habitReminder_\(habit.id.uuidString)"
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            Logger.debug("Scheduled daily habit reminder for \(habit.name)", category: .notification)
        } catch {
            Logger.error("Error scheduling habit reminder", error: error, category: .notification)
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Handle rest timer notification
        if notification.request.identifier == restTimerNotificationIdentifier {
            // Post notification that rest timer completed
            // This ensures the timer completes even if notification fires while app is in foreground
            NotificationCenter.default.post(
                name: Notification.Name("RestTimerCompletedFromNotification"),
                object: nil
            )
            Logger.info("Rest timer notification received in foreground - posting completion event", category: .notification)
        }
        
        // Show notification even when app is in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    /// Handle notification tap/interaction when app is opened from notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle rest timer notification
        if response.notification.request.identifier == restTimerNotificationIdentifier {
            // Post notification that rest timer completed
            NotificationCenter.default.post(
                name: Notification.Name("RestTimerCompletedFromNotification"),
                object: nil
            )
            Logger.info("Rest timer notification tapped - posting completion event", category: .notification)
        }
        
        completionHandler()
    }
}

