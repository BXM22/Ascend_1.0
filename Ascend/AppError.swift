import Foundation

/// Application-specific error types
enum AppError: LocalizedError {
    case invalidInput(String)
    case validationFailed(String)
    case persistenceFailed(String)
    case cloudKitError(String)
    case networkError(String)
    case themeImportError(String)
    case exerciseNotFound(String)
    case workoutNotFound
    case templateNotFound
    case programNotFound
    case invalidState(String)
    case healthKitNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        case .persistenceFailed(let message):
            return "Failed to save data: \(message)"
        case .cloudKitError(let message):
            return "CloudKit error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .themeImportError(let message):
            return "Theme import error: \(message)"
        case .exerciseNotFound(let name):
            return "Exercise '\(name)' not found"
        case .workoutNotFound:
            return "Workout not found"
        case .templateNotFound:
            return "Template not found"
        case .programNotFound:
            return "Program not found"
        case .invalidState(let message):
            return "Invalid state: \(message)"
        case .healthKitNotAvailable:
            return "HealthKit is not available on this device"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .invalidInput:
            return "The provided input does not meet the required format or constraints."
        case .validationFailed:
            return "The data failed validation checks."
        case .persistenceFailed:
            return "The data could not be saved to persistent storage."
        case .cloudKitError:
            return "An error occurred while syncing with iCloud."
        case .networkError:
            return "A network error occurred. Please check your connection."
        case .themeImportError:
            return "The theme could not be imported from the provided URL."
        case .exerciseNotFound:
            return "The requested exercise is not available in the database."
        case .workoutNotFound:
            return "The requested workout could not be found."
        case .templateNotFound:
            return "The requested template could not be found."
        case .programNotFound:
            return "The requested program could not be found."
        case .invalidState:
            return "The application is in an invalid state for this operation."
        case .healthKitNotAvailable:
            return "The HealthKit framework is not supported or accessible on this device."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidInput:
            return "Please check your input and try again."
        case .validationFailed:
            return "Please verify the data meets all requirements."
        case .persistenceFailed:
            return "Please try again. If the problem persists, restart the app."
        case .cloudKitError:
            return "Please check your iCloud settings and try again."
        case .networkError:
            return "Please check your internet connection and try again."
        case .themeImportError:
            return "Please verify the URL is a valid Coolors.co theme URL."
        case .exerciseNotFound:
            return "Please check the exercise name or add it as a custom exercise."
        case .workoutNotFound:
            return "The workout may have been deleted. Please start a new workout."
        case .templateNotFound:
            return "The template may have been deleted. Please create a new template."
        case .programNotFound:
            return "The program may have been deleted. Please select a different program."
        case .invalidState:
            return "Please try again or restart the app."
        case .healthKitNotAvailable:
            return "HealthKit is only available on iOS devices. Your workout data will be saved locally."
        }
    }
}

/// Result type alias for operations that can fail
typealias AppResult<T> = Result<T, AppError>

/// Extension to convert other error types to AppError
extension Error {
    func toAppError() -> AppError {
        if let appError = self as? AppError {
            return appError
        }
        
        // Convert common system errors
        let nsError = self as NSError
        switch nsError.domain {
        case NSURLErrorDomain:
            return .networkError(nsError.localizedDescription)
        case NSCocoaErrorDomain:
            return .persistenceFailed(nsError.localizedDescription)
        default:
            return .invalidState(nsError.localizedDescription)
        }
    }
}

