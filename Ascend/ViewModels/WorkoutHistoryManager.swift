import Foundation
import Combine

class WorkoutHistoryManager: ObservableObject {
    static let shared = WorkoutHistoryManager()
    
    @Published var completedWorkouts: [Workout] = [] {
        didSet {
            // Debounce saves to avoid excessive UserDefaults writes
            PerformanceOptimizer.shared.debouncedSave {
                self.saveWorkouts()
            }
        }
    }
    
    private let workoutsKey = "completedWorkouts"
    private var volumeCache: [String: Int] = [:] // Cache volume calculations
    private var volumeCacheDate: Date?
    private let cacheValidityDuration: TimeInterval = 60 // Cache for 60 seconds
    
    private init() {
        loadWorkouts()
    }
    
    func loadWorkouts() {
        // Load synchronously on init, but use background queue for decoding
        if let data = UserDefaults.standard.data(forKey: workoutsKey) {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                if let decoded = try? JSONDecoder().decode([Workout].self, from: data) {
                    DispatchQueue.main.async {
                        self.completedWorkouts = decoded
                    }
                }
            }
        }
    }
    
    private func saveWorkouts() {
        // Save on background queue
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            if let encoded = try? JSONEncoder().encode(self.completedWorkouts) {
                UserDefaults.standard.set(encoded, forKey: self.workoutsKey)
                // Invalidate cache when workouts change
                DispatchQueue.main.async {
                    self.volumeCache.removeAll()
                    self.volumeCacheDate = nil
                }
            }
        }
    }
    
    func addCompletedWorkout(_ workout: Workout) {
        completedWorkouts.append(workout)
    }
    
    func getWorkouts(in dateRange: DateInterval) -> [Workout] {
        return completedWorkouts.filter { workout in
            dateRange.contains(workout.startDate)
        }
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
        
        // Calculate volume on background queue
        let workouts = getWorkouts(in: dateRange)
        let volume = workouts.reduce(0) { total, workout in
            let workoutVolume = workout.exercises.reduce(0) { exerciseTotal, exercise in
                let exerciseVolume = exercise.sets.reduce(0) { setTotal, set in
                    return setTotal + Int(set.weight * Double(set.reps))
                }
                return exerciseTotal + exerciseVolume
            }
            return total + workoutVolume
        }
        
        // Cache the result
        volumeCache[cacheKey] = volume
        volumeCacheDate = Date()
        
        return volume
    }
    
    func getWeeklyVolume(for weekStart: Date) -> Int {
        let calendar = Calendar.current
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let dateRange = DateInterval(start: weekStart, end: weekEnd)
        return getTotalVolume(for: dateRange)
    }
}

