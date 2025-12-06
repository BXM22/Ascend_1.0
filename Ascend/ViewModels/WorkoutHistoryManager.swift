import Foundation
import Combine

class WorkoutHistoryManager: ObservableObject {
    static let shared = WorkoutHistoryManager()
    
    @Published var completedWorkouts: [Workout] = [] {
        didSet {
            saveWorkouts()
        }
    }
    
    private let workoutsKey = "completedWorkouts"
    
    private init() {
        loadWorkouts()
    }
    
    func loadWorkouts() {
        if let data = UserDefaults.standard.data(forKey: workoutsKey),
           let decoded = try? JSONDecoder().decode([Workout].self, from: data) {
            completedWorkouts = decoded
        }
    }
    
    private func saveWorkouts() {
        if let encoded = try? JSONEncoder().encode(completedWorkouts) {
            UserDefaults.standard.set(encoded, forKey: workoutsKey)
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
        let workouts = getWorkouts(in: dateRange)
        return workouts.reduce(0) { total, workout in
            let workoutVolume = workout.exercises.reduce(0) { exerciseTotal, exercise in
                let exerciseVolume = exercise.sets.reduce(0) { setTotal, set in
                    return setTotal + Int(set.weight * Double(set.reps))
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
}

