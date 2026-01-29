//
//  StreakCalculator.swift
//  Ascend
//
//  Created on 2025
//

import Foundation

/// Protocol for streak calculation to enable testability and abstraction
protocol StreakCalculatable {
    func calculateCurrentStreak(dates: [Date], from referenceDate: Date) -> Int
    func calculateLongestStreak(dates: [Date]) -> Int
}

/// Service for calculating streaks from completion dates
struct StreakCalculator: StreakCalculatable {
    private let calendar = Calendar.current
    
    /// Calculate current streak (consecutive days from reference date backwards)
    func calculateCurrentStreak(dates: [Date], from referenceDate: Date) -> Int {
        guard !dates.isEmpty else { return 0 }
        
        let today = DateHelper.startOfDay(referenceDate)
        let sortedDates = dates.map { DateHelper.startOfDay($0) }
            .sorted(by: >) // Most recent first
        
        var streak = 0
        var checkDate = today
        
        // Check if today is completed
        if sortedDates.first == today {
            streak = 1
            checkDate = DateHelper.addDays(-1, to: checkDate)
        }
        
        // Count consecutive days backwards
        for date in sortedDates {
            let daysDiff = DateHelper.daysBetween(date, checkDate)
            
            if daysDiff == 0 || daysDiff == 1 {
                if daysDiff == 1 {
                    streak += 1
                    checkDate = date
                } else if daysDiff == 0 && streak == 0 {
                    streak = 1
                    checkDate = DateHelper.addDays(-1, to: checkDate)
                }
            } else if daysDiff > 1 {
                break
            }
        }
        
        return streak
    }
    
    /// Calculate longest streak in all dates
    func calculateLongestStreak(dates: [Date]) -> Int {
        guard !dates.isEmpty else { return 0 }
        
        let sortedDates = dates.map { DateHelper.startOfDay($0) }
            .sorted(by: >) // Most recent first
        
        var longestStreakCount = 1
        var currentStreakCount = 1
        
        for i in 1..<sortedDates.count {
            let daysBetween = DateHelper.daysBetween(sortedDates[i], sortedDates[i-1])
            
            if daysBetween == 1 {
                currentStreakCount += 1
                longestStreakCount = max(longestStreakCount, currentStreakCount)
            } else {
                currentStreakCount = 1
            }
        }
        
        return longestStreakCount
    }
}

