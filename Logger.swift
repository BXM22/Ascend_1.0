import Foundation
import OSLog
import os

/// Lightweight logging facade to centralize logging and avoid scattering OSLog usage.
///
/// Usage:
///   Logger.info("message", category: .general)
///   Logger.error("message", category: .network)
public enum Logger {
    public enum Category: String {
        case general
        case network
        case database
        case notifications
        case ui
    }

    @usableFromInline static let subsystem: String = {
        // Use bundle identifier if available, otherwise fallback to app name or a default.
        if let id = Bundle.main.bundleIdentifier { return id }
        if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String { return name }
        return "App"
    }()

    @usableFromInline static func osLogger(for category: Category) -> os.Logger {
        os.Logger(subsystem: subsystem, category: category.rawValue)
    }

    @inlinable
    public static func info(_ message: String, category: Category = .general) {
        osLogger(for: category).info("\(message)")
    }

    @inlinable
    public static func debug(_ message: String, category: Category = .general) {
        osLogger(for: category).debug("\(message)")
    }

    @inlinable
    public static func error(_ message: String, category: Category = .general) {
        osLogger(for: category).error("\(message)")
    }

    @inlinable
    public static func fault(_ message: String, category: Category = .general) {
        osLogger(for: category).fault("\(message)")
    }
}
