import SwiftUI

@main
struct WorkoutTrackerApp: App {
    init() {
        // Request notification permissions on app launch
        Task {
            let hasPermission = await NotificationManager.shared.checkNotificationPermission()
            if !hasPermission {
                _ = await NotificationManager.shared.requestNotificationPermission()
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

