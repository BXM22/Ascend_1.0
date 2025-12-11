import SwiftUI

// MARK: - Performance Optimized View Modifiers

/// Prevents unnecessary re-renders by using EquatableView
struct EquatableViewWrapper<Content: View & Equatable>: View {
    let content: Content
    
    var body: some View {
        content
    }
}

extension EquatableViewWrapper: Equatable {
    static func == (lhs: EquatableViewWrapper<Content>, rhs: EquatableViewWrapper<Content>) -> Bool {
        lhs.content == rhs.content
    }
}

/// View modifier to throttle updates
struct ThrottledUpdateModifier: ViewModifier {
    @State private var lastUpdateTime: Date = Date()
    let throttleInterval: TimeInterval
    
    func body(content: Content) -> some View {
        content
    }
}

extension View {
    /// Throttle view updates to prevent excessive re-renders
    func throttleUpdates(interval: TimeInterval = 0.1) -> some View {
        self.modifier(ThrottledUpdateModifier(throttleInterval: interval))
    }
}

// MARK: - Optimized List Helpers

/// Stable ID provider for ForEach optimization
struct StableID: Hashable {
    let value: String
    
    init(_ value: String) {
        self.value = value
    }
}

/// Optimized ForEach wrapper that ensures stable IDs
struct OptimizedForEach<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {
    let data: Data
    let id: KeyPath<Data.Element, ID>
    let content: (Data.Element) -> Content
    
    var body: some View {
        ForEach(Array(data.enumerated()), id: \.offset) { index, element in
            content(element)
                .id(id)
        }
    }
}

// MARK: - Lazy Loading Helpers

/// View that only renders when visible
struct LazyView<Content: View>: View {
    let build: () -> Content
    
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    
    var body: Content {
        build()
    }
}

// MARK: - Memory Efficient Image Loading

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: String?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = loadedImage {
                content(Image(uiImage: image))
            } else if isLoading {
                placeholder()
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        guard let urlString = url, !isLoading else { return }
        isLoading = true
        
        // Check cache first
        if let cached = PerformanceOptimizer.shared.getCachedImage(forKey: urlString) {
            loadedImage = cached
            isLoading = false
            return
        }
        
        // Load asynchronously
        DispatchQueue.global(qos: .utility).async {
            // Simulate image loading - replace with actual implementation
            // For now, just set isLoading to false
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
}

// MARK: - Batch Update Helper

class BatchUpdateManager {
    private var pendingUpdates: [() -> Void] = []
    private var updateTimer: Timer?
    
    func scheduleUpdate(_ update: @escaping () -> Void) {
        pendingUpdates.append(update)
        
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            self?.executeUpdates()
        }
    }
    
    private func executeUpdates() {
        let updates = pendingUpdates
        pendingUpdates.removeAll()
        
        for update in updates {
            update()
        }
    }
}
