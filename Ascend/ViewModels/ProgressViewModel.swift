import Foundation
import SwiftUI
import Combine

class ProgressViewModel: ObservableObject {
    @Published var prs: [PersonalRecord] = []
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var workoutDates: [Date] = []
    @Published var totalVolume: Int = 15000
    @Published var workoutCount: Int = 12
    @Published var selectedView: ProgressViewType = .week
    @Published var selectedExercise: String = ""
    
    enum ProgressViewType {
        case week, month
    }
    
    // Get all unique exercise names from PRs
    var availableExercises: [String] {
        Array(Set(prs.map { $0.exercise })).sorted()
    }
    
    // Update selected exercise when PRs change
    func updateSelectedExerciseIfNeeded() {
        // If current selection is invalid or empty, select first available
        if selectedExercise.isEmpty || !availableExercises.contains(selectedExercise) {
            if !availableExercises.isEmpty {
                selectedExercise = availableExercises[0]
            }
        }
    }
    
    // Get PRs for the selected exercise, sorted by date (newest first)
    var selectedExercisePRs: [PersonalRecord] {
        guard !selectedExercise.isEmpty else { return [] }
        return prs.filter { $0.exercise == selectedExercise }
            .sorted { $0.date > $1.date }
    }
    
    // Get current PR for selected exercise
    var currentPR: PersonalRecord? {
        selectedExercisePRs.first
    }
    
    init() {
        calculateStreaks()
        // Set initial selected exercise if available
        if !availableExercises.isEmpty {
            selectedExercise = availableExercises[0]
        }
    }
    
    func loadSampleData() {
        // Sample PR data with history for each exercise
        let calendar = Calendar.current
        let today = Date()
        
        prs = [
            // Bench Press PRs (newest to oldest)
            PersonalRecord(exercise: "Bench Press", weight: 200, reps: 5, date: today),
            PersonalRecord(exercise: "Bench Press", weight: 195, reps: 5, date: calendar.date(byAdding: .day, value: -7, to: today) ?? today),
            PersonalRecord(exercise: "Bench Press", weight: 190, reps: 5, date: calendar.date(byAdding: .day, value: -14, to: today) ?? today),
            PersonalRecord(exercise: "Bench Press", weight: 185, reps: 5, date: calendar.date(byAdding: .day, value: -21, to: today) ?? today),
            
            // Squat PRs
            PersonalRecord(exercise: "Squat", weight: 275, reps: 3, date: calendar.date(byAdding: .day, value: -2, to: today) ?? today),
            PersonalRecord(exercise: "Squat", weight: 270, reps: 3, date: calendar.date(byAdding: .day, value: -9, to: today) ?? today),
            PersonalRecord(exercise: "Squat", weight: 265, reps: 3, date: calendar.date(byAdding: .day, value: -16, to: today) ?? today),
            
            // Deadlift PRs
            PersonalRecord(exercise: "Deadlift", weight: 315, reps: 1, date: calendar.date(byAdding: .day, value: -3, to: today) ?? today),
            PersonalRecord(exercise: "Deadlift", weight: 310, reps: 1, date: calendar.date(byAdding: .day, value: -10, to: today) ?? today),
        ]
        
        // Sample workout dates for streak calculation
        workoutDates = [
            today, // Today
            calendar.date(byAdding: .day, value: -1, to: today) ?? today, // Yesterday
            calendar.date(byAdding: .day, value: -2, to: today) ?? today, // 2 days ago
            calendar.date(byAdding: .day, value: -3, to: today) ?? today, // 3 days ago
            calendar.date(byAdding: .day, value: -5, to: today) ?? today, // 5 days ago
            calendar.date(byAdding: .day, value: -6, to: today) ?? today, // 6 days ago
            calendar.date(byAdding: .day, value: -7, to: today) ?? today, // 7 days ago
        ]
    }
    
    func calculateStreaks() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get unique dates and sort in descending order
        let uniqueDates = Array(Set(workoutDates.map { calendar.startOfDay(for: $0) }))
        let sortedDates = uniqueDates.sorted(by: >)
        
        guard !sortedDates.isEmpty else {
            currentStreak = 0
            longestStreak = 0
            return
        }
        
        // Calculate current streak (consecutive days from today backwards)
        var streak = 0
        var checkDate = today
        
        for date in sortedDates {
            let daysDiff = calendar.dateComponents([.day], from: date, to: checkDate).day ?? Int.max
            
            if daysDiff == 0 || daysDiff == 1 {
                streak += 1
                if daysDiff == 1 {
                    checkDate = date
                } else {
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                }
            } else {
                break
            }
        }
        
        currentStreak = streak
        
        // Calculate longest streak
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
        
        longestStreak = longestStreakCount
    }
    
    func addWorkoutDate(_ date: Date = Date()) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        // Only add if not already in the list
        if !workoutDates.contains(where: { calendar.startOfDay(for: $0) == dayStart }) {
            workoutDates.append(date)
            calculateStreaks()
        }
    }
    
    // Add or update a PR for an exercise
    func addOrUpdatePR(exercise: String, weight: Double, reps: Int, date: Date = Date()) -> Bool {
        // Check if this is a new PR (better than existing)
        let existingPRs = prs.filter { $0.exercise == exercise }
        let isNewPR: Bool
        
        if existingPRs.isEmpty {
            // First PR for this exercise
            isNewPR = true
        } else {
            // Check if this beats the current PR
            let currentPR = existingPRs.max { pr1, pr2 in
                // Compare by weight first, then reps
                if pr1.weight != pr2.weight {
                    return pr1.weight < pr2.weight
                }
                return pr1.reps < pr2.reps
            }
            
            if let current = currentPR {
                // New PR if weight is higher, or same weight with more reps
                isNewPR = weight > current.weight || (weight == current.weight && reps > current.reps)
            } else {
                isNewPR = true
            }
        }
        
        // Only add the PR entry if it's actually a new PR
        if isNewPR {
            let newPR = PersonalRecord(exercise: exercise, weight: weight, reps: reps, date: date)
            prs.append(newPR)
            
            // Update selected exercise if needed
            updateSelectedExerciseIfNeeded()
        }
        
        return isNewPR
    }
    
    // Add initial PR entry for a new exercise (so it appears in dropdown)
    func addInitialExerciseEntry(exercise: String, weight: Double, reps: Int, date: Date = Date()) {
        // Check if exercise already exists
        if !availableExercises.contains(exercise) {
            let newPR = PersonalRecord(exercise: exercise, weight: weight, reps: reps, date: date)
            prs.append(newPR)
            updateSelectedExerciseIfNeeded()
        }
    }
    
    // MARK: - Trend Data for Graphs
    
    // Weekly volume data for the last 8 weeks
    var weeklyVolumeData: [VolumeDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        var data: [VolumeDataPoint] = []
        
        // Generate data for last 8 weeks
        for weekOffset in (0..<8).reversed() {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today) ?? today
            let weekStartOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart)) ?? weekStart
            
            // Calculate volume for this week (sample data - replace with actual workout volume)
            // For now, generate sample data based on workout dates
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStartOfWeek) ?? weekStartOfWeek
            let workoutsInWeek = workoutDates.filter { date in
                let dayStart = calendar.startOfDay(for: date)
                return dayStart >= weekStartOfWeek && dayStart <= weekEnd
            }.count
            
            // Sample volume calculation (replace with actual volume from workouts)
            let volume = workoutsInWeek * 2000 + Int.random(in: 1000...3000)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            let weekLabel = formatter.string(from: weekStartOfWeek)
            
            data.append(VolumeDataPoint(week: weekOffset, weekLabel: weekLabel, volume: volume))
        }
        
        return data
    }
    
    // Weekly workout frequency for the last 8 weeks
    var weeklyWorkoutFrequency: [FrequencyDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        var data: [FrequencyDataPoint] = []
        
        // Generate data for last 8 weeks
        for weekOffset in (0..<8).reversed() {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today) ?? today
            let weekStartOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart)) ?? weekStart
            
            // Count workouts in this week
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStartOfWeek) ?? weekStartOfWeek
            let workoutsInWeek = workoutDates.filter { date in
                let dayStart = calendar.startOfDay(for: date)
                return dayStart >= weekStartOfWeek && dayStart <= weekEnd
            }.count
            
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            let weekLabel = formatter.string(from: weekStartOfWeek)
            
            data.append(FrequencyDataPoint(week: weekOffset, weekLabel: weekLabel, count: workoutsInWeek))
        }
        
        return data
    }
}

// MARK: - Data Point Models for Graphs
struct VolumeDataPoint {
    let week: Int
    let weekLabel: String
    let volume: Int
}

struct FrequencyDataPoint {
    let week: Int
    let weekLabel: String
    let count: Int
}

