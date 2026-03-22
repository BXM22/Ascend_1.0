import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@main
struct WorkoutTrackerApp: App {
    init() {
        // Pre-initialize ColorThemeProvider to ensure colors load instantly
        _ = ColorThemeProvider.shared
        
        #if canImport(UIKit)
        // Avoid white flash behind SwiftUI; match `BrandHex.surfaceBase` (#131313).
        UIWindow.appearance().backgroundColor = UIColor(red: 19 / 255, green: 19 / 255, blue: 19 / 255, alpha: 1)
        #endif
        
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
                .environmentObject(ColorThemeProvider.shared)
        }
    }
}

