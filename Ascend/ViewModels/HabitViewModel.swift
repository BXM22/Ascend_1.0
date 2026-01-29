import Foundation
import SwiftUI
import Combine

class HabitViewModel: ObservableObject {
    @ObservedObject var habitManager: HabitManager
    
    @Published var showCreateHabit = false
    @Published var editingHabit: Habit?
    @Published var showEditHabit = false
    @Published var selectedHabit: Habit?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(habitManager: HabitManager = .shared) {
        self.habitManager = habitManager
        
        // Observe habit changes to update notifications and trigger view updates
        habitManager.$habits
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] habits in
                // Update notifications when habits change
                NotificationManager.shared.updateAllHabitReminders(habits: habits)
                // Trigger view update
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties
    
    var totalHabits: Int {
        habitManager.habits.count
    }
    
    var activeHabits: [Habit] {
        habitManager.habits
    }
    
    var todayCompletions: Int {
        let today = DateHelper.today
        return habitManager.habits.filter { habit in
            habitManager.isCompleted(habitId: habit.id, date: today)
        }.count
    }
    
    var todayCompletionRate: Double {
        guard totalHabits > 0 else { return 0.0 }
        return Double(todayCompletions) / Double(totalHabits)
    }
    
    var habitsDueToday: [Habit] {
        habitManager.habits.filter { habit in
            !habitManager.isCompleted(habitId: habit.id) && habit.reminderEnabled
        }
    }
    
    // MARK: - Actions
    
    func createHabit(_ habit: Habit) {
        habitManager.addHabit(habit)
        
        // Schedule reminder if enabled
        if habit.reminderEnabled {
            Task {
                let hasPermission = await NotificationManager.shared.requestNotificationPermission()
                if hasPermission {
                    NotificationManager.shared.scheduleHabitReminder(habit: habit)
                }
            }
        }
    }
    
    func updateHabit(_ habit: Habit) {
        let oldHabit = habitManager.getHabit(byId: habit.id)
        habitManager.updateHabit(habit)
        
        // Trigger view update
        objectWillChange.send()
        
        // Update notification if reminder settings changed
        // Only update if there's an actual change to avoid unnecessary work
        let reminderChanged = oldHabit?.reminderEnabled != habit.reminderEnabled ||
                              oldHabit?.reminderTime != habit.reminderTime
        
        if reminderChanged {
            if habit.reminderEnabled {
                NotificationManager.shared.scheduleHabitReminder(habit: habit)
            } else {
                NotificationManager.shared.cancelHabitReminder(habitId: habit.id)
            }
        }
    }
    
    func deleteHabit(_ habit: Habit) {
        NotificationManager.shared.cancelHabitReminder(habitId: habit.id)
        habitManager.deleteHabit(habit)
        
        // Clear selected habit if it was deleted
        if selectedHabit?.id == habit.id {
            selectedHabit = nil
        }
        
        // Clear editing habit if it was deleted
        if editingHabit?.id == habit.id {
            editingHabit = nil
            showEditHabit = false
        }
        
        // Trigger view update
        objectWillChange.send()
    }
    
    func toggleCompletion(habitId: UUID, date: Date = Date()) {
        if habitManager.isCompleted(habitId: habitId, date: date) {
            habitManager.markIncomplete(habitId: habitId, date: date)
        } else {
            habitManager.markComplete(habitId: habitId, date: date)
            HapticManager.success()
        }
    }
    
    // MARK: - Delegated Methods (DRY - avoid duplication)
    // These methods delegate to HabitManager to maintain single source of truth
    
    func getStreak(habitId: UUID) -> Int {
        habitManager.getStreak(habitId: habitId)
    }
    
    func getLongestStreak(habitId: UUID) -> Int {
        habitManager.getLongestStreak(habitId: habitId)
    }
    
    func getProgress(habitId: UUID) -> Double? {
        habitManager.getProgress(habitId: habitId)
    }
    
    func getCompletionCount(habitId: UUID) -> Int {
        habitManager.getCompletionCount(habitId: habitId)
    }
    
    func isCompleted(habitId: UUID, date: Date = Date()) -> Bool {
        habitManager.isCompleted(habitId: habitId, date: date)
    }
    
    // MARK: - Recent Completions
    
    /// Get recent habit completions from the last N days
    func recentCompletions(days: Int = 7) -> [(habit: Habit, date: Date)] {
        let calendar = Calendar.current
        let endDate = DateHelper.today
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return []
        }
        
        var completions: [(habit: Habit, date: Date)] = []
        
        for habit in habitManager.habits {
            let completionDates = habitManager.getCompletionDates(habitId: habit.id)
            for completionDate in completionDates {
                if completionDate >= startDate && completionDate <= endDate {
                    completions.append((habit: habit, date: completionDate))
                }
            }
        }
        
        // Sort by date, most recent first
        return completions.sorted { $0.date > $1.date }
    }
}

