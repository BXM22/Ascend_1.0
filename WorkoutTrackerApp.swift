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
        
        // Exercises are loaded from a curated JSON dataset via ExRxDirectoryManager
        Logger.info("📚 Using bundled JSON exercise dataset", category: Logger.Category.general)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

