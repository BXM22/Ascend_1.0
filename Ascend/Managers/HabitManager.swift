import Foundation
import Combine

/// Manager for habit tracking with persistence and streak calculation
class HabitManager: ObservableObject {
    static let shared = HabitManager()
    
    @Published var habits: [Habit] = [] {
        didSet {
            saveHabits()
        }
    }
    
    @Published var completions: [UUID: [HabitCompletion]] = [:] {
        didSet {
            saveCompletions()
        }
    }
    
    private let habitsKey = "userHabits"
    private let completionsKey = "habitCompletions"
    private let calendar = Calendar.current
    
    private init() {
        loadHabits()
        loadCompletions()
    }
    
    // MARK: - Persistence
    
    private func saveHabits() {
        do {
            let encoded = try JSONEncoder().encode(habits)
            UserDefaults.standard.set(encoded, forKey: habitsKey)
        } catch {
            Logger.error("Failed to save habits", error: error, category: .persistence)
        }
    }
    
    private func loadHabits() {
        guard let data = UserDefaults.standard.data(forKey: habitsKey) else {
            habits = []
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([Habit].self, from: data)
            habits = decoded
        } catch {
            Logger.error("Failed to load habits", error: error, category: .persistence)
            habits = []
        }
    }
    
    private func saveCompletions() {
        do {
            // Convert UUID keys to String for JSON encoding
            let stringKeyedCompletions = completions.reduce(into: [String: [HabitCompletion]]()) { result, pair in
                result[pair.key.uuidString] = pair.value
            }
            let encoded = try JSONEncoder().encode(stringKeyedCompletions)
            UserDefaults.standard.set(encoded, forKey: completionsKey)
        } catch {
            Logger.error("Failed to save habit completions", error: error, category: .persistence)
        }
    }
    
    private func loadCompletions() {
        guard let data = UserDefaults.standard.data(forKey: completionsKey) else {
            completions = [:]
            return
        }
        
        do {
            // Decode [String: [HabitCompletion]] from JSON
            let decoded = try JSONDecoder().decode([String: [HabitCompletion]].self, from: data)
            // Convert String keys to UUID
            completions = decoded.reduce(into: [UUID: [HabitCompletion]]()) { result, pair in
                if let uuid = UUID(uuidString: pair.key) {
                    result[uuid] = pair.value
                }
            }
        } catch {
            Logger.error("Failed to load habit completions", error: error, category: .persistence)
            completions = [:]
        }
    }
    
    // MARK: - CRUD Operations
    
    func addHabit(_ habit: Habit) {
        habits.append(habit)
    }
    
    func updateHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
        }
    }
    
    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        completions.removeValue(forKey: habit.id)
    }
    
    func getHabit(byId id: UUID) -> Habit? {
        return habits.first { $0.id == id }
    }
    
    // MARK: - Completion Tracking
    
    func markComplete(habitId: UUID, date: Date = Date(), duration: Int? = nil) {
        let completion = HabitCompletion(date: date, completedAt: Date(), duration: duration)
        
        if completions[habitId] == nil {
            completions[habitId] = []
        }
        
        // Check if already completed today
        let dayStart = calendar.startOfDay(for: date)
        if let existingCompletions = completions[habitId],
           existingCompletions.contains(where: { calendar.startOfDay(for: $0.date) == dayStart }) {
            // Already completed today, update the completion
            if let index = completions[habitId]?.firstIndex(where: { calendar.startOfDay(for: $0.date) == dayStart }) {
                completions[habitId]?[index] = completion
            }
        } else {
            // New completion
            completions[habitId]?.append(completion)
        }
    }
    
    func markIncomplete(habitId: UUID, date: Date = Date()) {
        let dayStart = calendar.startOfDay(for: date)
        completions[habitId]?.removeAll { calendar.startOfDay(for: $0.date) == dayStart }
    }
    
    func isCompleted(habitId: UUID, date: Date = Date()) -> Bool {
        let dayStart = calendar.startOfDay(for: date)
        guard let habitCompletions = completions[habitId] else { return false }
        return habitCompletions.contains { calendar.startOfDay(for: $0.date) == dayStart }
    }
    
    func getCompletionCount(habitId: UUID) -> Int {
        return completions[habitId]?.count ?? 0
    }
    
    // MARK: - Streak Calculation
    
    /// Calculate current streak for a habit (consecutive days from today backwards)
    func getStreak(habitId: UUID) -> Int {
        guard let habitCompletions = completions[habitId], !habitCompletions.isEmpty else {
            return 0
        }
        
        let today = calendar.startOfDay(for: Date())
        let sortedDates = habitCompletions.map { calendar.startOfDay(for: $0.date) }
            .sorted(by: >) // Most recent first
        
        var streak = 0
        var checkDate = today
        
        // Check if today is completed
        if sortedDates.first == today {
            streak = 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        
        // Count consecutive days backwards
        for date in sortedDates {
            let daysDiff = calendar.dateComponents([.day], from: date, to: checkDate).day ?? Int.max
            
            if daysDiff == 0 || daysDiff == 1 {
                if daysDiff == 1 {
                    streak += 1
                    checkDate = date
                } else if daysDiff == 0 && streak == 0 {
                    // Today is in the list but we haven't started counting
                    streak = 1
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                }
            } else if daysDiff > 1 {
                // Gap found, streak broken
                break
            }
        }
        
        return streak
    }
    
    /// Calculate longest streak for a habit
    func getLongestStreak(habitId: UUID) -> Int {
        guard let habitCompletions = completions[habitId], !habitCompletions.isEmpty else {
            return 0
        }
        
        let sortedDates = habitCompletions.map { calendar.startOfDay(for: $0.date) }
            .sorted(by: >) // Most recent first
        
        var longestStreakCount = 1
        var currentStreakCount = 1
        
        for i in 1..<sortedDates.count {
            let daysBetween = calendar.dateComponents([.day], from: sortedDates[i], to: sortedDates[i-1]).day ?? Int.max
            
            if daysBetween == 1 {
                currentStreakCount += 1
                longestStreakCount = max(longestStreakCount, currentStreakCount)
            } else {
                currentStreakCount = 1
            }
        }
        
        return longestStreakCount
    }
    
    /// Get progress percentage for habits with target streak days
    func getProgress(habitId: UUID) -> Double? {
        guard let habit = getHabit(byId: habitId),
              let target = habit.targetStreakDays else {
            return nil // No target, return nil
        }
        
        let currentStreak = getStreak(habitId: habitId)
        return min(1.0, Double(currentStreak) / Double(target))
    }
    
    /// Get all completion dates for a habit
    func getCompletionDates(habitId: UUID) -> [Date] {
        guard let habitCompletions = completions[habitId] else { return [] }
        return habitCompletions.map { $0.date }
    }
}

