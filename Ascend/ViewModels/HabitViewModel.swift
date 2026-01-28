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
        
        // Observe habit changes to update notifications
        habitManager.$habits
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] habits in
                // Update notifications when habits change
                NotificationManager.shared.updateAllHabitReminders(habits: habits)
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
        let today = Calendar.current.startOfDay(for: Date())
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
        
        // Update notification if reminder settings changed
        if oldHabit?.reminderEnabled != habit.reminderEnabled ||
           oldHabit?.reminderTime != habit.reminderTime {
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
    }
    
    func toggleCompletion(habitId: UUID, date: Date = Date()) {
        if habitManager.isCompleted(habitId: habitId, date: date) {
            habitManager.markIncomplete(habitId: habitId, date: date)
        } else {
            habitManager.markComplete(habitId: habitId, date: date)
            HapticManager.success()
        }
    }
    
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
}

