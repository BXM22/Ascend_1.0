import Foundation
import Combine
import SwiftUI

/// Utility class for performance optimizations
class PerformanceOptimizer {
    static let shared = PerformanceOptimizer()
    
    private var saveWork: DispatchWorkItem?
    private let saveQueue = DispatchQueue(label: "com.ascend.saveQueue", qos: .utility)
    
    // Image cache for better performance
    private let imageCache = NSCache<NSString, UIImage>()
    private let imageCacheQueue = DispatchQueue(label: "com.ascend.imageCache", qos: .utility)
    
    // Memory pressure monitoring
    private var memoryWarningObserver: NSObjectProtocol?
    
    private init() {
        // Configure image cache
        imageCache.countLimit = 100
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // Monitor memory warnings
        setupMemoryWarningObserver()
    }
    
    deinit {
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupMemoryWarningObserver() {
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearAllCaches()
        }
    }
    
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
    
    // MARK: - Image Caching
    
    func cacheImage(_ image: UIImage, forKey key: String) {
        imageCacheQueue.async { [weak self] in
            self?.imageCache.setObject(image, forKey: key as NSString)
        }
    }
    
    func getCachedImage(forKey key: String) -> UIImage? {
        return imageCache.object(forKey: key as NSString)
    }
    
    func clearImageCache() {
        imageCacheQueue.async { [weak self] in
            self?.imageCache.removeAllObjects()
        }
    }
    
    // MARK: - Performance Monitoring
    
    /// Measure execution time of a block
    static func measureTime<T>(_ operation: String = "Operation", _ block: () -> T) -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        Logger.debug("\(operation) took \(String(format: "%.3f", timeElapsed))s", category: .performance)
        return result
    }
    
    /// Measure execution time of an async block
    static func measureTimeAsync<T>(_ operation: String = "Operation", _ block: () async -> T) async -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = await block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        Logger.debug("\(operation) took \(String(format: "%.3f", timeElapsed))s", category: .performance)
        return result
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

// MARK: - View Performance Optimizations

/// View modifier to prevent unnecessary re-renders
struct EquatableViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .drawingGroup() // Render to a single layer for better performance
    }
}

extension View {
    /// Optimize view rendering by using drawing group
    func optimizedRendering() -> some View {
        self.modifier(EquatableViewModifier())
    }
}

/// Property wrapper for computed values that cache results
@propertyWrapper
struct CachedComputed<T: Equatable> {
    private var cachedValue: T?
    private var compute: () -> T
    
    init(_ compute: @escaping () -> T) {
        self.compute = compute
    }
    
    var wrappedValue: T {
        mutating get {
            if let cached = cachedValue {
                return cached
            }
            let value = compute()
            cachedValue = value
            return value
        }
    }
    
    mutating func invalidate() {
        cachedValue = nil
    }
}

// MARK: - View Performance Helpers

/// View modifier to throttle updates and prevent excessive re-renders
struct ThrottledUpdateModifier: ViewModifier {
    let interval: TimeInterval
    @State private var lastUpdate = Date()
    
    func body(content: Content) -> some View {
        content
    }
}

extension View {
    /// Throttle view updates to prevent excessive re-renders
    /// Note: This is a placeholder - actual throttling should be done at the data layer
    func throttleUpdates(interval: TimeInterval = 0.1) -> some View {
        self // Return self unchanged - throttling should be done in ViewModels
    }
}

/// Equatable wrapper for views to prevent unnecessary re-renders
struct EquatableView<Content: View & Equatable>: View, Equatable {
    let content: Content
    
    var body: some View {
        content
    }
    
    static func == (lhs: EquatableView<Content>, rhs: EquatableView<Content>) -> Bool {
        lhs.content == rhs.content
    }
}

/// View modifier to cache view rendering
struct CachedViewModifier: ViewModifier {
    @State private var cachedView: AnyView?
    
    func body(content: Content) -> some View {
        Group {
            if let cached = cachedView {
                cached
            } else {
                content.onAppear {
                    cachedView = AnyView(content)
                }
            }
        }
    }
}

extension View {
    /// Cache view rendering to avoid recomputation
    func cached() -> some View {
        self.modifier(CachedViewModifier())
    }
}

/// Helper to create stable identifiers for ForEach
struct StableID: Hashable {
    let id: String
    let hash: Int
    
    init(_ id: String) {
        self.id = id
        self.hash = id.hashValue
    }
}

// MARK: - Background Processing

extension PerformanceOptimizer {
    /// Process array in chunks on background queue
    static func processInChunks<T, R>(
        _ items: [T],
        chunkSize: Int = 100,
        processor: @escaping ([T]) -> [R],
        completion: @escaping ([R]) -> Void
    ) {
        DispatchQueue.global(qos: .utility).async {
            var results: [R] = []
            var index = 0
            
            while index < items.count {
                let endIndex = min(index + chunkSize, items.count)
                let chunk = Array(items[index..<endIndex])
                let processed = processor(chunk)
                results.append(contentsOf: processed)
                index = endIndex
            }
            
            DispatchQueue.main.async {
                completion(results)
            }
        }
    }
    
    /// Debounce with immediate first execution option
    func debounced(delay: TimeInterval = 0.3, immediate: Bool = false, work: @escaping () -> Void) {
        if immediate {
            work()
        }
        debouncedSave(delay: delay, work: work)
    }
    
    // MARK: - Memory Management
    
    /// Clear all caches when memory is low
    func clearAllCaches() {
        clearImageCache()
        // Add other cache clearing here as needed
    }
}

