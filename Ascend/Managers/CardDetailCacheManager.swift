//
//  CardDetailCacheManager.swift
//  Ascend
//
//  Manages caching of card details for improved performance
//

import Foundation
import SwiftUI

/// Manages caching of card detail data to improve load performance
class CardDetailCacheManager {
    static let shared = CardDetailCacheManager()
    
    // Cache storage
    private var templateDetailCache: [UUID: WorkoutTemplate] = [:]
    private var exerciseHistoryCache: [String: ExerciseHistoryCache] = [:]
    private var programDetailCache: [UUID: WorkoutProgram] = [:]
    private var dayTypeInfoCache: [String: DayTypeInfoCache] = [:]
    private var templateSuggestionsIndex: [String: [WorkoutTemplate]] = [:] // Index by day type
    
    // Cache metadata
    private var cacheTimestamps: [String: Date] = [:]
    private let cacheValidityDuration: TimeInterval = 1800 // 30 minutes for detail cards
    private let detailCardCacheValidityDuration: TimeInterval = 1800 // 30 minutes for detail cards
    
    // Background processing queue
    private let cacheQueue = DispatchQueue(label: "com.ascend.cardDetailCache", qos: .utility)
    
    private init() {
        // Monitor memory warnings
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearExpiredCache()
        }
    }
    
    // MARK: - Template Detail Caching
    
    func getCachedTemplate(_ templateId: UUID) -> WorkoutTemplate? {
        let key = "template-\(templateId.uuidString)"
        guard let timestamp = cacheTimestamps[key],
              Date().timeIntervalSince(timestamp) < cacheValidityDuration else {
            return nil
        }
        return templateDetailCache[templateId]
    }
    
    func cacheTemplate(_ template: WorkoutTemplate) {
        let key = "template-\(template.id.uuidString)"
        templateDetailCache[template.id] = template
        cacheTimestamps[key] = Date()
    }
    
    func invalidateTemplateCache(_ templateId: UUID) {
        templateDetailCache.removeValue(forKey: templateId)
        let key = "template-\(templateId.uuidString)"
        cacheTimestamps.removeValue(forKey: key)
    }
    
    // MARK: - Exercise History Caching
    
    struct ExerciseHistoryCache {
        let exerciseName: String
        let history: [ExerciseSetData]
        let prs: [PersonalRecord]
        let chartData: [ChartDataPoint]
        let timestamp: Date
    }
    
    func getCachedExerciseHistory(_ exerciseName: String) -> ExerciseHistoryCache? {
        guard let cached = exerciseHistoryCache[exerciseName],
              Date().timeIntervalSince(cached.timestamp) < cacheValidityDuration else {
            return nil
        }
        return cached
    }
    
    func cacheExerciseHistory(_ exerciseName: String, history: [ExerciseSetData], prs: [PersonalRecord], chartData: [ChartDataPoint]) {
        let cache = ExerciseHistoryCache(
            exerciseName: exerciseName,
            history: history,
            prs: prs,
            chartData: chartData,
            timestamp: Date()
        )
        exerciseHistoryCache[exerciseName] = cache
        let key = "exercise-\(exerciseName)"
        cacheTimestamps[key] = Date()
    }
    
    func invalidateExerciseHistoryCache(_ exerciseName: String) {
        exerciseHistoryCache.removeValue(forKey: exerciseName)
        let key = "exercise-\(exerciseName)"
        cacheTimestamps.removeValue(forKey: key)
    }
    
    // MARK: - Program Detail Caching
    
    func getCachedProgram(_ programId: UUID) -> WorkoutProgram? {
        let key = "program-\(programId.uuidString)"
        guard let timestamp = cacheTimestamps[key],
              Date().timeIntervalSince(timestamp) < cacheValidityDuration else {
            return nil
        }
        return programDetailCache[programId]
    }
    
    func cacheProgram(_ program: WorkoutProgram) {
        let key = "program-\(program.id.uuidString)"
        programDetailCache[program.id] = program
        cacheTimestamps[key] = Date()
    }
    
    func invalidateProgramCache(_ programId: UUID) {
        programDetailCache.removeValue(forKey: programId)
        let key = "program-\(programId.uuidString)"
        cacheTimestamps.removeValue(forKey: key)
    }
    
    // MARK: - Cache Management
    
    func clearExpiredCache() {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            let now = Date()
            var keysToRemove: [String] = []
            
            for (key, timestamp) in self.cacheTimestamps {
                if now.timeIntervalSince(timestamp) >= self.cacheValidityDuration {
                    keysToRemove.append(key)
                }
            }
            
            DispatchQueue.main.async {
                for key in keysToRemove {
                    if key.hasPrefix("template-") {
                        let idString = String(key.dropFirst("template-".count))
                        if let id = UUID(uuidString: idString) {
                            self.templateDetailCache.removeValue(forKey: id)
                        }
                    } else if key.hasPrefix("exercise-") {
                        let exerciseName = String(key.dropFirst("exercise-".count))
                        self.exerciseHistoryCache.removeValue(forKey: exerciseName)
                    } else if key.hasPrefix("program-") {
                        let idString = String(key.dropFirst("program-".count))
                        if let id = UUID(uuidString: idString) {
                            self.programDetailCache.removeValue(forKey: id)
                        }
                    }
                    self.cacheTimestamps.removeValue(forKey: key)
                }
            }
        }
    }
    
    func clearAllCache() {
        templateDetailCache.removeAll()
        exerciseHistoryCache.removeAll()
        programDetailCache.removeAll()
        dayTypeInfoCache.removeAll()
        templateSuggestionsIndex.removeAll()
        cacheTimestamps.removeAll()
    }
    
    // MARK: - Day Type Info Caching
    
    struct DayTypeInfoCache {
        let dayName: String
        let dayType: String?
        let suggestedTemplates: [WorkoutTemplate]
        let timestamp: Date
    }
    
    func getCachedDayTypeInfo(_ dayName: String) -> DayTypeInfoCache? {
        guard let cached = dayTypeInfoCache[dayName],
              Date().timeIntervalSince(cached.timestamp) < detailCardCacheValidityDuration else {
            return nil
        }
        return cached
    }
    
    func cacheDayTypeInfo(_ dayName: String, dayType: String?, suggestedTemplates: [WorkoutTemplate]) {
        let cache = DayTypeInfoCache(
            dayName: dayName,
            dayType: dayType,
            suggestedTemplates: suggestedTemplates,
            timestamp: Date()
        )
        dayTypeInfoCache[dayName] = cache
        let key = "daytype-\(dayName)"
        cacheTimestamps[key] = Date()
    }
    
    func invalidateDayTypeInfoCache(_ dayName: String) {
        dayTypeInfoCache.removeValue(forKey: dayName)
        let key = "daytype-\(dayName)"
        cacheTimestamps.removeValue(forKey: key)
    }
    
    // MARK: - Template Suggestions Indexing
    
    func getCachedTemplateSuggestions(for dayType: String) -> [WorkoutTemplate]? {
        return templateSuggestionsIndex[dayType.lowercased()]
    }
    
    func cacheTemplateSuggestions(for dayType: String, templates: [WorkoutTemplate]) {
        templateSuggestionsIndex[dayType.lowercased()] = templates
    }
    
    func invalidateTemplateSuggestionsIndex() {
        templateSuggestionsIndex.removeAll()
    }
    
    // MARK: - Cache Warming
    
    func warmCache(programs: [WorkoutProgram], templates: [WorkoutTemplate]) {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Cache all programs
            for program in programs {
                DispatchQueue.main.async {
                    self.cacheProgram(program)
                }
            }
            
            // Cache frequently accessed templates
            let frequentTemplates = templates.prefix(20)
            for template in frequentTemplates {
                DispatchQueue.main.async {
                    self.cacheTemplate(template)
                }
            }
        }
    }
}

