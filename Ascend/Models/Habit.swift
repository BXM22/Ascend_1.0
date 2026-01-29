import Foundation
import SwiftUI

// MARK: - Habit Completion
struct HabitCompletion: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date // Normalized to start of day
    let completedAt: Date // Actual completion timestamp
    let duration: Int? // Actual time spent in minutes (optional)
    
    init(date: Date, completedAt: Date = Date(), duration: Int? = nil) {
        self.id = UUID()
        self.date = DateHelper.startOfDay(date)
        self.completedAt = completedAt
        self.duration = duration
    }
}

// MARK: - Habit
struct Habit: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var completionDuration: Int // Minutes to complete
    var targetStreakDays: Int? // Optional goal, nil = forever
    var reminderTime: Date? // Optional daily reminder time
    var reminderEnabled: Bool
    var colorHex: String? // Custom color for card (hex string)
    var icon: String // SF Symbol name
    let createdDate: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        completionDuration: Int,
        targetStreakDays: Int? = nil,
        reminderTime: Date? = nil,
        reminderEnabled: Bool = false,
        colorHex: String? = nil,
        icon: String = "checkmark.circle.fill",
        createdDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.completionDuration = completionDuration
        self.targetStreakDays = targetStreakDays
        self.reminderTime = reminderTime
        self.reminderEnabled = reminderEnabled
        self.colorHex = colorHex
        self.icon = icon
        self.createdDate = createdDate
    }
    
    // Computed property to check if habit is "forever" (no target)
    var isForever: Bool {
        targetStreakDays == nil
    }
    
    // Computed property to get custom color or default
    var color: Color {
        if let hex = colorHex {
            return Color(hex: hex)
        }
        return AppColors.primary
    }
}


