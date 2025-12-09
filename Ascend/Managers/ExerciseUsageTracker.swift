import Foundation
import Combine

class ExerciseUsageTracker: ObservableObject {
    static let shared = ExerciseUsageTracker()
    
    @Published private(set) var recentExercises: [String] = []
    @Published private(set) var exerciseUsageCounts: [String: Int] = [:]
    
    private let recentExercisesKey = AppConstants.UserDefaultsKeys.recentExercises
    private let usageCountsKey = AppConstants.UserDefaultsKeys.exerciseUsageCounts
    private let maxRecentExercises = 20
    private var cancellables = Set<AnyCancellable>()
    
    // Cache for most used exercises to avoid repeated sorting
    private var cachedMostUsed: [String]?
    private var cachedMostUsedLimit: Int = 0
    
    private init() {
        loadData()
        setupAutoSave()
    }
    
    func trackExerciseUsage(_ exerciseName: String) {
        // Update recent exercises
        recentExercises.removeAll { $0 == exerciseName }
        recentExercises.insert(exerciseName, at: 0)
        
        // Keep only the most recent exercises
        if recentExercises.count > maxRecentExercises {
            recentExercises = Array(recentExercises.prefix(maxRecentExercises))
        }
        
        // Update usage count
        exerciseUsageCounts[exerciseName, default: 0] += 1
        
        // Invalidate cache when usage changes
        cachedMostUsed = nil
    }
    
    func getMostUsedExercises(limit: Int = 10) -> [String] {
        // Return cached result if available and limit matches
        if let cached = cachedMostUsed, cachedMostUsedLimit == limit {
            return cached
        }
        
        // Calculate and cache
        let result = exerciseUsageCounts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
        
        cachedMostUsed = result
        cachedMostUsedLimit = limit
        
        return result
    }
    
    func getUsageCount(for exerciseName: String) -> Int {
        return exerciseUsageCounts[exerciseName] ?? 0
    }
    
    func clearRecentExercises() {
        recentExercises = []
        cachedMostUsed = nil
    }
    
    func clearUsageCounts() {
        exerciseUsageCounts = [:]
        cachedMostUsed = nil
    }
    
    private func setupAutoSave() {
        Publishers.CombineLatest($recentExercises, $exerciseUsageCounts)
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _ in
                self?.saveData()
            }
            .store(in: &cancellables)
    }
    
    private func saveData() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            // Save recent exercises
            UserDefaults.standard.set(self.recentExercises, forKey: self.recentExercisesKey)
            
            // Save usage counts
            if let encoded = try? JSONEncoder().encode(self.exerciseUsageCounts) {
                UserDefaults.standard.set(encoded, forKey: self.usageCountsKey)
            }
        }
    }
    
    private func loadData() {
        // Load recent exercises
        if let recent = UserDefaults.standard.array(forKey: recentExercisesKey) as? [String] {
            recentExercises = recent
        }
        
        // Load usage counts
        if let data = UserDefaults.standard.data(forKey: usageCountsKey),
           let counts = try? JSONDecoder().decode([String: Int].self, from: data) {
            exerciseUsageCounts = counts
        }
    }
}

