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
        
        // Import CSV exercises if not already imported
        Task {
            Self.importCSVExercisesIfNeeded()
        }
    }
    
    private static func importCSVExercisesIfNeeded() {
        // Check if exercises have already been imported
        let importedCount = ExRxDirectoryManager.shared.getImportedExerciseCount()
        
        // Only import if no exercises have been imported yet
        guard importedCount == 0 else {
            Logger.info("📚 CSV exercises already imported (\(importedCount) exercises)", category: .general)
            return
        }
        
        // Try to find CSV file in multiple locations
        var csvPath: String?
        
        // 1. First, try to find in app bundle (for production builds)
        // Try multiple possible file names (prioritize "exercises")
        let possibleNames = [
            "exercises",  // Primary name - matches the file in the project
            "Gym Exercise Dataset export 2025-12-16 07-12-04",
            "gym-exercises",
            "exercise-dataset"
        ]
        
        // Try Bundle.main.path(forResource:ofType:) - works for files at bundle root
        for name in possibleNames {
            if let bundlePath = Bundle.main.path(forResource: name, ofType: "csv") {
                csvPath = bundlePath
                Logger.info("📚 Found CSV in app bundle: \(name).csv", category: .general)
                break
            }
        }
        
        // If not found, try searching in bundle directory structure
        if csvPath == nil {
            if let bundleURL = Bundle.main.resourceURL {
                let possiblePaths = [
                    bundleURL.appendingPathComponent("exercises.csv"),
                    bundleURL.appendingPathComponent("Ascend/exercises.csv"),
                    bundleURL.appendingPathComponent("Gym Exercise Dataset export 2025-12-16 07-12-04.csv")
                ]
                
                for url in possiblePaths {
                    if FileManager.default.fileExists(atPath: url.path) {
                        csvPath = url.path
                        Logger.info("📚 Found CSV in bundle directory: \(url.lastPathComponent)", category: .general)
                        break
                    }
                }
            }
        }
        
        // 2. Fallback to Downloads folder (for development only)
        if csvPath == nil {
            let downloadsPath = "/Users/brennenmeregillano/Downloads/Gym Exercise Dataset export 2025-12-16 07-12-04.csv"
            if FileManager.default.fileExists(atPath: downloadsPath) {
                csvPath = downloadsPath
                Logger.info("📚 Found CSV in Downloads folder (development)", category: .general)
            }
        }
        
        // Check if file was found
        guard let path = csvPath, FileManager.default.fileExists(atPath: path) else {
            Logger.info("📚 CSV file not found. Please add 'Gym Exercise Dataset export 2025-12-16 07-12-04.csv' to the app bundle.", category: .general)
            return
        }
        
        // Import exercises
        do {
            let stats = try CSVExerciseImporter.shared.importExercisesFromFile(at: path)
            Logger.info("✅ CSV import successful: \(stats)", category: .general)
        } catch {
            Logger.error("❌ CSV import failed", error: error, category: .general)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

