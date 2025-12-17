//
//  HealthKitManager.swift
//  Ascend
//
//  Created on 2024
//

import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    
    private let healthStore = HKHealthStore()
    
    // HealthKit types we want to read/write
    private var readTypes: Set<HKObjectType> {
        return Set([
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ])
    }
    
    private var writeTypes: Set<HKSampleType> {
        return Set([
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ])
    }
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.info("HealthKit is not available on this device", category: .general)
            return
        }
        
        let workoutType = HKObjectType.workoutType()
        authorizationStatus = healthStore.authorizationStatus(for: workoutType)
        isAuthorized = authorizationStatus == .sharingAuthorized
    }
    
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw AppError.healthKitNotAvailable
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            await MainActor.run {
                checkAuthorizationStatus()
            }
            Logger.info("✅ HealthKit authorization requested", category: .general)
        } catch {
            Logger.error("Failed to request HealthKit authorization", error: error, category: .general)
            throw error
        }
    }
    
    // MARK: - Save Workout
    
    func saveWorkout(
        name: String,
        exercises: [Exercise],
        startDate: Date,
        endDate: Date,
        totalVolume: Int
    ) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.info("HealthKit not available - skipping workout save", category: .general)
            return
        }
        
        // Check authorization status
        let workoutType = HKObjectType.workoutType()
        let status = healthStore.authorizationStatus(for: workoutType)
        
        guard status == .sharingAuthorized else {
            Logger.info("HealthKit not authorized - skipping workout save", category: .general)
            return
        }
        
        // Determine workout activity type based on exercises
        let activityType = determineWorkoutActivityType(exercises: exercises)
        
        // Create workout
        let workout = HKWorkout(
            activityType: activityType,
            start: startDate,
            end: endDate,
            duration: endDate.timeIntervalSince(startDate),
            totalEnergyBurned: nil,
            totalDistance: nil,
            metadata: [
                "app": "Ascend",
                "exerciseCount": exercises.count,
                "totalVolume": totalVolume,
                "workoutName": name
            ]
        )
        
        // Save workout
        do {
            try await healthStore.save(workout)
            Logger.info("✅ Workout saved to HealthKit: \(name)", category: .general)
            
            // Optionally save additional metrics
            try await saveWorkoutMetrics(workout: workout, exercises: exercises, totalVolume: totalVolume)
        } catch {
            Logger.error("Failed to save workout to HealthKit", error: error, category: .general)
            throw error
        }
    }
    
    // MARK: - Save Workout Metrics
    
    private func saveWorkoutMetrics(
        workout: HKWorkout,
        exercises: [Exercise],
        totalVolume: Int
    ) async throws {
        var samples: [HKSample] = []
        
        // Calculate total active energy (rough estimate: 0.1 kcal per lb of volume)
        let estimatedCalories = Double(totalVolume) * 0.1
        
        if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            let energyQuantity = HKQuantity(
                unit: HKUnit.kilocalorie(),
                doubleValue: estimatedCalories
            )
            let energySample = HKQuantitySample(
                type: energyType,
                quantity: energyQuantity,
                start: workout.startDate,
                end: workout.endDate
            )
            samples.append(energySample)
        }
        
        // Save all samples
        if !samples.isEmpty {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                healthStore.add(samples, to: workout) { success, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: NSError(domain: "HealthKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to save samples"]))
                    }
                }
            }
            Logger.info("✅ Workout metrics saved to HealthKit", category: .general)
        }
    }
    
    // MARK: - Helper Methods
    
    private func determineWorkoutActivityType(exercises: [Exercise]) -> HKWorkoutActivityType {
        // Analyze exercises to determine primary activity type
        let exerciseNames = exercises.map { $0.name.lowercased() }
        
        // Check for specific activity types
        if exerciseNames.contains(where: { $0.contains("run") || $0.contains("cardio") }) {
            return .running
        }
        
        if exerciseNames.contains(where: { $0.contains("bike") || $0.contains("cycling") }) {
            return .cycling
        }
        
        if exerciseNames.contains(where: { $0.contains("swim") }) {
            return .swimming
        }
        
        // Default to traditional strength training
        return .traditionalStrengthTraining
    }
}

