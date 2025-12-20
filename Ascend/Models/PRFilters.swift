//
//  PRFilters.swift
//  Ascend
//
//  Created on 2025
//

import Foundation

struct PRFilters {
    var timeRange: TimeRange = .allTime
    var muscleGroups: Set<String> = []
    var minWeight: Double? = nil
    var sortOrder: SortOrder = .dateDescending
    
    enum TimeRange: String, CaseIterable {
        case week = "This Week"
        case month = "This Month"
        case year = "This Year"
        case allTime = "All Time"
        
        var dateFilter: Date? {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .week:
                return calendar.date(byAdding: .day, value: -7, to: now)
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: now)
            case .year:
                return calendar.date(byAdding: .year, value: -1, to: now)
            case .allTime:
                return nil
            }
        }
    }
    
    enum SortOrder: String, CaseIterable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case weightDescending = "Highest Weight"
        case improvementDescending = "Biggest Gains"
        case alphabetical = "A-Z"
    }
    
    var isActive: Bool {
        timeRange != .allTime || !muscleGroups.isEmpty || minWeight != nil
    }
    
    func matches(_ pr: PersonalRecord) -> Bool {
        // Time range filter
        if let startDate = timeRange.dateFilter {
            if pr.date < startDate {
                return false
            }
        }
        
        // Muscle group filter
        if !muscleGroups.isEmpty {
            let (primary, secondary) = ExerciseDataManager.shared.getMuscleGroups(for: pr.exercise)
            let allMuscleGroups = primary + secondary
            let hasMatch = muscleGroups.contains { group in
                allMuscleGroups.contains { muscleGroup in
                    muscleGroup.localizedCaseInsensitiveContains(group) || group.localizedCaseInsensitiveContains(muscleGroup)
                }
            }
            if !hasMatch {
                return false
            }
        }
        
        // Minimum weight filter
        if let minWeight = minWeight {
            if pr.weight < minWeight {
                return false
            }
        }
        
        return true
    }
}
