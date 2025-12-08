import Foundation
import Combine

/// Tracks the last weight and reps used for each exercise
struct ExerciseHistory: Codable {
    let exerciseName: String
    let lastWeight: Double
    let lastReps: Int
    let lastDate: Date
    
    init(exerciseName: String, lastWeight: Double, lastReps: Int, lastDate: Date = Date()) {
        self.exerciseName = exerciseName
        self.lastWeight = lastWeight
        self.lastReps = lastReps
        self.lastDate = lastDate
    }
}

class ExerciseHistoryManager: ObservableObject {
    static let shared = ExerciseHistoryManager()
    
    @Published private(set) var exerciseHistory: [String: ExerciseHistory] = [:]
    
    private let historyKey = "exerciseHistory"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadHistory()
        setupAutoSave()
    }
    
    /// Get the last weight and reps for an exercise
    func getLastWeightReps(for exerciseName: String) -> (weight: Double, reps: Int)? {
        guard let history = exerciseHistory[exerciseName] else { return nil }
        return (history.lastWeight, history.lastReps)
    }
    
    /// Update the last weight and reps for an exercise
    func updateLastWeightReps(exerciseName: String, weight: Double, reps: Int) {
        let history = ExerciseHistory(
            exerciseName: exerciseName,
            lastWeight: weight,
            lastReps: reps,
            lastDate: Date()
        )
        exerciseHistory[exerciseName] = history
    }
    
    /// Clear history for a specific exercise
    func clearHistory(for exerciseName: String) {
        exerciseHistory.removeValue(forKey: exerciseName)
    }
    
    /// Clear all history
    func clearAllHistory() {
        exerciseHistory.removeAll()
    }
    
    private func setupAutoSave() {
        $exerciseHistory
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.saveHistory()
            }
            .store(in: &cancellables)
    }
    
    private func saveHistory() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            do {
                let encoded = try JSONEncoder().encode(self.exerciseHistory)
                UserDefaults.standard.set(encoded, forKey: self.historyKey)
            } catch {
                Logger.error("Failed to save exercise history", error: error, category: .persistence)
            }
        }
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else {
            exerciseHistory = [:]
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([String: ExerciseHistory].self, from: data)
            exerciseHistory = decoded
        } catch {
            Logger.error("Failed to load exercise history", error: error, category: .persistence)
            exerciseHistory = [:]
        }
    }
}

