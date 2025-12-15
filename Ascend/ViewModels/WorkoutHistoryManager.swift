import Foundation
import Combine

class WorkoutHistoryManager: ObservableObject {
    static let shared = WorkoutHistoryManager()
    
    @Published var completedWorkouts: [Workout] = [] {
        didSet {
            // Invalidate caches when workouts change
            invalidateCaches()
            // Rebuild indexes on background queue
            rebuildIndexes()
            // Debounce saves to avoid excessive UserDefaults writes
            PerformanceOptimizer.shared.debouncedSave {
                self.saveWorkouts()
            }
        }
    }
    
    private let workoutsKey = AppConstants.UserDefaultsKeys.completedWorkouts
    private var volumeCache: [String: Int] = [:] // Cache volume calculations
    private var volumeCacheDate: Date?
    private let cacheValidityDuration: TimeInterval = AppConstants.Cache.volumeCacheValidityShort
    
    // Performance optimizations
    private var allTimeVolumeCache: Int?
    private var allTimeVolumeCacheDate: Date?
    private var workoutsByDate: [Date: [Workout]] = [:] // Index workouts by date for faster filtering
    private var sortedWorkoutDates: [Date] = [] // Sorted dates for binary search
    private let processingQueue = DispatchQueue(label: "com.ascend.workoutProcessing", qos: .utility)
    
    private init() {
        loadWorkouts()
        Logger.info("📝 WorkoutHistoryManager initialized - Workouts: \(completedWorkouts.count)", category: .general)
    }
    
    func loadWorkouts() {
        // Load synchronously on init, but use background queue for decoding
        guard let data = UserDefaults.standard.data(forKey: workoutsKey) else {
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let decoded = try JSONDecoder().decode([Workout].self, from: data)
                DispatchQueue.main.async {
                    self.completedWorkouts = decoded
                    // Rebuild indexes after loading
                    self.rebuildIndexes()
                }
            } catch {
                // Log error but don't crash - invalid data
                Logger.error("Failed to load workouts", error: error, category: .persistence)
                // Clear invalid data
                DispatchQueue.main.async {
                    UserDefaults.standard.removeObject(forKey: self.workoutsKey)
                }
            }
        }
    }
    
    private func saveWorkouts() {
        // Save on background queue
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let encoded = try JSONEncoder().encode(self.completedWorkouts)
                UserDefaults.standard.set(encoded, forKey: self.workoutsKey)
                // Invalidate cache when workouts change
                DispatchQueue.main.async {
                    self.volumeCache.removeAll()
                    self.volumeCacheDate = nil
                }
            } catch {
                // Log error but don't crash - workout saving is not critical
                Logger.error("Failed to save workouts", error: error, category: .persistence)
            }
        }
    }
    
    func addCompletedWorkout(_ workout: Workout) {
        completedWorkouts.append(workout)
        Logger.info("✅ Workout added to history - Name: '\(workout.name)', Exercises: \(workout.exercises.count), Total workouts: \(completedWorkouts.count)", category: .general)
    }
    
    func getWorkouts(in dateRange: DateInterval) -> [Workout] {
        // Use indexed lookup if available, otherwise fall back to filtering
        guard !workoutsByDate.isEmpty else {
            return completedWorkouts.filter { dateRange.contains($0.startDate) }
        }
        
        // Use binary search on sorted dates for faster lookup
        var results: [Workout] = []
        
        // Find workouts within date range using sorted dates
        for date in sortedWorkoutDates {
            if dateRange.contains(date) {
                results.append(contentsOf: workoutsByDate[date] ?? [])
            } else if date > dateRange.end {
                // Dates are sorted, so we can break early
                break
            }
        }
        
        return results
    }
    
    func getTotalVolume(for dateRange: DateInterval) -> Int {
        // Create cache key
        let cacheKey = "\(dateRange.start.timeIntervalSince1970)-\(dateRange.end.timeIntervalSince1970)"
        
        // Check cache validity
        if let cacheDate = volumeCacheDate,
           Date().timeIntervalSince(cacheDate) < cacheValidityDuration,
           let cached = volumeCache[cacheKey] {
            return cached
        }
        
        // Calculate volume on background queue for large datasets
        let workouts = getWorkouts(in: dateRange)
        
        // For small datasets, calculate synchronously
        if workouts.count < 50 {
            let volume = calculateVolume(for: workouts)
            volumeCache[cacheKey] = volume
            volumeCacheDate = Date()
            return volume
        }
        
        // For large datasets, calculate asynchronously and return cached or 0
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            let volume = self.calculateVolume(for: workouts)
            DispatchQueue.main.async {
                self.volumeCache[cacheKey] = volume
                self.volumeCacheDate = Date()
            }
        }
        
        // Return cached value if available, otherwise return 0 (will update when calculation completes)
        return volumeCache[cacheKey] ?? 0
    }
    
    private func calculateVolume(for workouts: [Workout]) -> Int {
        return workouts.reduce(0) { total, workout in
            let workoutVolume = workout.exercises.reduce(0) { exerciseTotal, exercise in
                let exerciseVolume = exercise.sets.reduce(0) { setTotal, set in
                    let volume = set.weight * Double(set.reps)
                    guard volume.isFinite else { return setTotal }
                    return setTotal + Int(volume)
                }
                return exerciseTotal + exerciseVolume
            }
            return total + workoutVolume
        }
    }
    
    func getWeeklyVolume(for weekStart: Date) -> Int {
        let calendar = Calendar.current
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let dateRange = DateInterval(start: weekStart, end: weekEnd)
        return getTotalVolume(for: dateRange)
    }
    
    /// Get total volume across all workouts (cached)
    func getAllTimeVolume() -> Int {
        guard !completedWorkouts.isEmpty else { return 0 }
        
        // Check cache validity
        if let cacheDate = allTimeVolumeCacheDate,
           let cached = allTimeVolumeCache,
           Date().timeIntervalSince(cacheDate) < cacheValidityDuration {
            return cached
        }
        
        // Calculate volume
        let volume = calculateVolume(for: completedWorkouts)
        
        // Cache the result
        allTimeVolumeCache = volume
        allTimeVolumeCacheDate = Date()
        
        return volume
    }
    
    // MARK: - Performance Optimization Methods
    
    private func rebuildIndexes() {
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            let calendar = Calendar.current
            var dateIndex: [Date: [Workout]] = [:]
            var dates: [Date] = []
            
            for workout in self.completedWorkouts {
                let dayStart = calendar.startOfDay(for: workout.startDate)
                if dateIndex[dayStart] == nil {
                    dateIndex[dayStart] = []
                    dates.append(dayStart)
                }
                dateIndex[dayStart]?.append(workout)
            }
            
            // Sort dates for binary search
            dates.sort()
            
            DispatchQueue.main.async {
                self.workoutsByDate = dateIndex
                self.sortedWorkoutDates = dates
            }
        }
    }
    
    private func invalidateCaches() {
        allTimeVolumeCache = nil
        allTimeVolumeCacheDate = nil
        volumeCache.removeAll()
        volumeCacheDate = nil
    }
}

