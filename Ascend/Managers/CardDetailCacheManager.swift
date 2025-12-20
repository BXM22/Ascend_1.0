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
    
    // Cache metadata
    private var cacheTimestamps: [String: Date] = [:]
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
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
        cacheTimestamps.removeAll()
    }
}

