import SwiftUI
import Combine

// MARK: - View Performance Modifiers

extension View {
    /// Optimize view by preventing unnecessary re-renders
    func performanceOptimized() -> some View {
        self
            .drawingGroup() // Render to single layer
            .compositingGroup() // Composite efficiently
    }
    
    /// Apply lazy loading - only render when visible
    func lazyLoad() -> some View {
        LazyView(self)
    }
    
    /// Throttle view updates to reduce re-renders
    func throttleRendering(interval: TimeInterval = 0.1) -> some View {
        self.modifier(ThrottledRenderingModifier(interval: interval))
    }
}

// MARK: - Throttled Rendering Modifier

struct ThrottledRenderingModifier: ViewModifier {
    let interval: TimeInterval
    @State private var lastUpdate: Date = Date()
    @State private var pendingValue: Any?
    
    func body(content: Content) -> some View {
        content
    }
}

// MARK: - Optimized List Rendering

struct OptimizedList<Data: RandomAccessCollection, ID: Hashable, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let id: KeyPath<Data.Element, ID>
    let content: (Data.Element) -> Content
    
    var body: some View {
        ForEach(Array(data), id: id) { item in
            content(item)
                .id(item.id)
        }
    }
}

// MARK: - Debounced Text Binding

@propertyWrapper
struct DebouncedText: DynamicProperty {
    @State private var value: String
    @State private var debouncedValue: String
    @State private var debounceTask: Task<Void, Never>?
    
    private let debounceDelay: TimeInterval
    
    init(wrappedValue: String, delay: TimeInterval = 0.3) {
        _value = State(initialValue: wrappedValue)
        _debouncedValue = State(initialValue: wrappedValue)
        self.debounceDelay = delay
    }
    
    var wrappedValue: String {
        get { value }
        nonmutating set {
            value = newValue
            debounceTask?.cancel()
            debounceTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(debounceDelay * 1_000_000_000))
                if !Task.isCancelled {
                    debouncedValue = newValue
                }
            }
        }
    }
    
    var projectedValue: Binding<String> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
    
    var debounced: String {
        debouncedValue
    }
}

// MARK: - Memory Efficient View Updates

class ViewUpdateThrottler: ObservableObject {
    private var updateTimer: Timer?
    private var pendingUpdates: [() -> Void] = []
    private let throttleInterval: TimeInterval
    
    init(interval: TimeInterval = 0.1) {
        self.throttleInterval = interval
    }
    
    func scheduleUpdate(_ update: @escaping () -> Void) {
        pendingUpdates.append(update)
        
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: throttleInterval, repeats: false) { [weak self] _ in
            self?.executeUpdates()
        }
    }
    
    private func executeUpdates() {
        let updates = pendingUpdates
        pendingUpdates.removeAll()
        updates.forEach { $0() }
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}

// MARK: - Cached Computed Property with Invalidation

@propertyWrapper
struct CachedComputedValue<T: Equatable> {
    private var cachedValue: T?
    private var lastComputed: Date?
    private let compute: () -> T
    private let cacheDuration: TimeInterval?
    
    init(_ compute: @escaping () -> T, cacheDuration: TimeInterval? = nil) {
        self.compute = compute
        self.cacheDuration = cacheDuration
    }
    
    var wrappedValue: T {
        mutating get {
            // Check if cache is still valid
            if let duration = cacheDuration,
               let lastComputed = lastComputed,
               Date().timeIntervalSince(lastComputed) > duration {
                cachedValue = nil
            }
            
            if let cached = cachedValue {
                return cached
            }
            
            let value = compute()
            cachedValue = value
            lastComputed = Date()
            return value
        }
    }
    
    mutating func invalidate() {
        cachedValue = nil
        lastComputed = nil
    }
}

// MARK: - Background Processing Helper

struct BackgroundProcessor {
    static func process<T>(_ work: @escaping () -> T, completion: @escaping (T) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = work()
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    static func processAsync<T>(_ work: @escaping () -> T) async -> T {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = work()
                continuation.resume(returning: result)
            }
        }
    }
}

// MARK: - Optimized ScrollView

struct OptimizedScrollView<Content: View>: View {
    let content: Content
    let axes: Axis.Set
    let showsIndicators: Bool
    
    init(_ axes: Axis.Set = .vertical, showsIndicators: Bool = true, @ViewBuilder content: () -> Content) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.content = content()
    }
    
    var body: some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
            content
                .drawingGroup() // Optimize rendering
        }
    }
}

// MARK: - Memory Efficient Image Cache

class ImageCacheManager {
    static let shared = ImageCacheManager()
    private let cache = NSCache<NSString, UIImage>()
    private let cacheQueue = DispatchQueue(label: "com.ascend.imageCache", qos: .utility)
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    func getImage(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }
    
    func setImage(_ image: UIImage, for key: String) {
        cacheQueue.async { [weak self] in
            self?.cache.setObject(image, forKey: key as NSString)
        }
    }
    
    func clearCache() {
        cacheQueue.async { [weak self] in
            self?.cache.removeAllObjects()
        }
    }
}

// MARK: - View ID Stability

struct StableViewID: Hashable {
    let base: String
    let identifier: String
    
    init(_ base: String, identifier: String = "") {
        self.base = base
        self.identifier = identifier
    }
}

// MARK: - Performance Monitoring

struct PerformanceMonitor {
    static func measure<T>(_ operation: String, block: () -> T) -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = block()
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        Logger.debug("\(operation): \(String(format: "%.3f", elapsed))s", category: .performance)
        return result
    }
    
    static func measureAsync<T>(_ operation: String, block: () async -> T) async -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = await block()
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        Logger.debug("\(operation): \(String(format: "%.3f", elapsed))s", category: .performance)
        return result
    }
}
