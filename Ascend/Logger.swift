import Foundation
import os.log

/// Centralized logging utility for the application
/// Supports different log levels and can be controlled by build configuration
enum Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.app.Ascend"
    
    // MARK: - Log Categories
    
    private static let general = OSLog(subsystem: subsystem, category: "General")
    private static let persistence = OSLog(subsystem: subsystem, category: "Persistence")
    private static let cloudKit = OSLog(subsystem: subsystem, category: "CloudKit")
    private static let validation = OSLog(subsystem: subsystem, category: "Validation")
    private static let notification = OSLog(subsystem: subsystem, category: "Notification")
    private static let performance = OSLog(subsystem: subsystem, category: "Performance")
    
    // MARK: - Log Levels
    
    enum Level {
        case debug
        case info
        case error
        case fault
    }
    
    // MARK: - Logging Methods
    
    /// Log a debug message (only in DEBUG builds)
    static func debug(_ message: String, category: Category = .general) {
        #if DEBUG
        os_log("%{public}@", log: logForCategory(category), type: .debug, message)
        #endif
    }
    
    /// Log an info message
    static func info(_ message: String, category: Category = .general) {
        os_log("%{public}@", log: logForCategory(category), type: .info, message)
    }
    
    /// Log an error message
    static func error(_ message: String, error: Error? = nil, category: Category = .general) {
        let fullMessage = error != nil ? "\(message): \(error!.localizedDescription)" : message
        os_log("%{public}@", log: logForCategory(category), type: .error, fullMessage)
    }
    
    /// Log a fault (critical error)
    static func fault(_ message: String, category: Category = .general) {
        os_log("%{public}@", log: logForCategory(category), type: .fault, message)
    }
    
    // MARK: - Categories
    
    enum Category {
        case general
        case persistence
        case cloudKit
        case validation
        case notification
        case performance
    }
    
    private static func logForCategory(_ category: Category) -> OSLog {
        switch category {
        case .general:
            return general
        case .persistence:
            return persistence
        case .cloudKit:
            return cloudKit
        case .validation:
            return validation
        case .notification:
            return notification
        case .performance:
            return performance
        }
    }
}

