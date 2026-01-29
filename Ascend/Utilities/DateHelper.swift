//
//  DateHelper.swift
//  Ascend
//
//  Created on 2025
//

import Foundation

/// Utility for date operations to avoid duplication
enum DateHelper {
    private static let calendar = Calendar.current
    
    /// Normalizes a date to the start of day
    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    /// Calculates the number of days between two dates
    static func daysBetween(_ date1: Date, _ date2: Date) -> Int {
        calendar.dateComponents([.day], from: date1, to: date2).day ?? Int.max
    }
    
    /// Gets today's date normalized to start of day
    static var today: Date {
        startOfDay(Date())
    }
    
    /// Adds days to a date
    static func addDays(_ days: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }
}


