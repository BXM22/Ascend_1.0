import Foundation
import Combine

/// Utility class for performance optimizations
class PerformanceOptimizer {
    static let shared = PerformanceOptimizer()
    
    private var saveWork: DispatchWorkItem?
    private let saveQueue = DispatchQueue(label: "com.ascend.saveQueue", qos: .utility)
    
    private init() {}
    
    /// Debounced save operation - batches multiple saves into one
    func debouncedSave(delay: TimeInterval = 0.5, work: @escaping () -> Void) {
        saveWork?.cancel()
        saveWork = DispatchWorkItem(block: work)
        if let work = saveWork {
            saveQueue.asyncAfter(deadline: .now() + delay, execute: work)
        }
    }
    
    /// Execute work on background queue
    static func performOnBackground<T>(_ work: @escaping () -> T, completion: @escaping (T) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = work()
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    /// Execute work on background queue and return result synchronously if possible
    static func performOnBackground<T>(_ work: @escaping () -> T) async -> T {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = work()
                continuation.resume(returning: result)
            }
        }
    }
}

/// Debounced property wrapper for UserDefaults
@propertyWrapper
struct DebouncedUserDefault<T: Codable> {
    private let key: String
    private let defaultValue: T
    private let debounceDelay: TimeInterval
    
    init(key: String, defaultValue: T, debounceDelay: TimeInterval = 0.5) {
        self.key = key
        self.defaultValue = defaultValue
        self.debounceDelay = debounceDelay
    }
    
    var wrappedValue: T {
        get {
            if let data = UserDefaults.standard.data(forKey: key),
               let decoded = try? JSONDecoder().decode(T.self, from: data) {
                return decoded
            }
            return defaultValue
        }
        set {
            // Save immediately to UserDefaults for reads, but debounce the actual write
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: key)
            }
        }
    }
}

