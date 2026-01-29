import Foundation
import Combine

/// Manager for habit tracking with persistence and streak calculation
class HabitManager: ObservableObject {
    static let shared = HabitManager()
    
    @Published var habits: [Habit] = [] {
        didSet {
            invalidateStreakCache()
            debouncedSaveHabits()
        }
    }
    
    @Published var completions: [UUID: [HabitCompletion]] = [:] {
        didSet {
            invalidateStreakCache()
            debouncedSaveCompletions()
        }
    }
    
    private let habitsKey = "userHabits"
    private let completionsKey = "habitCompletions"
    private let calendar = Calendar.current
    private let streakCalculator: StreakCalculatable
    
    // Caching for performance
    private var streakCache: [UUID: (streak: Int, longest: Int, date: Date)] = [:]
    private let cacheValidityDuration: TimeInterval = 60 // 1 minute cache
    
    // Debounce timers
    private var habitsSaveWorkItem: DispatchWorkItem?
    private var completionsSaveWorkItem: DispatchWorkItem?
    private let saveQueue = DispatchQueue(label: "com.ascend.habitManager.save", qos: .utility)
    
    private init(streakCalculator: StreakCalculatable = StreakCalculator()) {
        self.streakCalculator = streakCalculator
        loadHabits()
        loadCompletions()
    }
    
    // MARK: - Persistence
    
    private func debouncedSaveHabits() {
        habitsSaveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.saveHabits()
        }
        habitsSaveWorkItem = workItem
        saveQueue.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
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
    
    private func debouncedSaveCompletions() {
        completionsSaveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.saveCompletions()
        }
        completionsSaveWorkItem = workItem
        saveQueue.asyncAfter(deadline: .now() + 0.5, execute: workItem)
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
    
    // MARK: - Cache Management
    
    private func invalidateStreakCache() {
        streakCache.removeAll()
    }
    
    private func invalidateStreakCache(for habitId: UUID) {
        streakCache.removeValue(forKey: habitId)
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
        let dayStart = DateHelper.startOfDay(date)
        if let existingCompletions = completions[habitId],
           existingCompletions.contains(where: { DateHelper.startOfDay($0.date) == dayStart }) {
            // Already completed today, update the completion
            if let index = completions[habitId]?.firstIndex(where: { DateHelper.startOfDay($0.date) == dayStart }) {
                completions[habitId]?[index] = completion
            }
        } else {
            // New completion
            completions[habitId]?.append(completion)
        }
        
        invalidateStreakCache(for: habitId)
    }
    
    func markIncomplete(habitId: UUID, date: Date = Date()) {
        let dayStart = DateHelper.startOfDay(date)
        completions[habitId]?.removeAll { DateHelper.startOfDay($0.date) == dayStart }
        invalidateStreakCache(for: habitId)
    }
    
    func isCompleted(habitId: UUID, date: Date = Date()) -> Bool {
        let dayStart = DateHelper.startOfDay(date)
        guard let habitCompletions = completions[habitId] else { return false }
        return habitCompletions.contains { DateHelper.startOfDay($0.date) == dayStart }
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
        
        // Check cache
        if let cached = streakCache[habitId],
           Date().timeIntervalSince(cached.date) < cacheValidityDuration {
            return cached.streak
        }
        
        // Calculate both streaks at once for efficiency
        let completionDates = habitCompletions.map { $0.date }
        let today = DateHelper.today
        let streak = streakCalculator.calculateCurrentStreak(dates: completionDates, from: today)
        let longest = streakCalculator.calculateLongestStreak(dates: completionDates)
        
        // Update cache with both values
        streakCache[habitId] = (
            streak: streak,
            longest: longest,
            date: Date()
        )
        
        return streak
    }
    
    /// Calculate longest streak for a habit
    func getLongestStreak(habitId: UUID) -> Int {
        guard let habitCompletions = completions[habitId], !habitCompletions.isEmpty else {
            return 0
        }
        
        // Check cache
        if let cached = streakCache[habitId],
           Date().timeIntervalSince(cached.date) < cacheValidityDuration {
            return cached.longest
        }
        
        // Calculate both streaks at once for efficiency
        let completionDates = habitCompletions.map { $0.date }
        let today = DateHelper.today
        let streak = streakCalculator.calculateCurrentStreak(dates: completionDates, from: today)
        let longest = streakCalculator.calculateLongestStreak(dates: completionDates)
        
        // Update cache with both values
        streakCache[habitId] = (
            streak: streak,
            longest: longest,
            date: Date()
        )
        
        return longest
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

