import Foundation
import CloudKit
import Combine

class CloudKitSyncManager: ObservableObject {
    static let shared = CloudKitSyncManager()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: AppError?
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    
    // Record types
    private let workoutRecordType = AppConstants.CloudKit.workoutRecordType
    private let templateRecordType = AppConstants.CloudKit.templateRecordType
    private let programRecordType = AppConstants.CloudKit.programRecordType
    private let customExerciseRecordType = AppConstants.CloudKit.customExerciseRecordType
    
    private init() {
        container = CKContainer(identifier: AppConstants.CloudKit.containerIdentifier)
        privateDatabase = container.privateCloudDatabase
    }
    
    // MARK: - Sync Workouts
    
    func syncWorkouts() async throws {
        await MainActor.run { isSyncing = true }
        defer { Task { @MainActor in isSyncing = false } }
        
        do {
            let historyManager = WorkoutHistoryManager.shared
            
            // Fetch workouts from CloudKit
            let query = CKQuery(recordType: workoutRecordType, predicate: NSPredicate(value: true))
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            // Convert CloudKit records to Workout objects
            var cloudWorkouts: [Workout] = []
            var fetchErrors: [Error] = []
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let workout = workoutFromRecord(record) {
                        cloudWorkouts.append(workout)
                    }
                case .failure(let error):
                    fetchErrors.append(error)
                    Logger.error("Error fetching workout from CloudKit", error: error, category: .cloudKit)
                }
            }
            
            // If we have too many fetch errors, throw
            if fetchErrors.count > matchResults.count / 2 {
                throw AppError.cloudKitError("Failed to fetch most workouts from iCloud")
            }
            
            // Merge with local workouts
            let localWorkouts = historyManager.completedWorkouts
            var mergedWorkouts = localWorkouts
            
            // Add workouts from cloud that don't exist locally
            for cloudWorkout in cloudWorkouts {
                if !mergedWorkouts.contains(where: { $0.id == cloudWorkout.id }) {
                    mergedWorkouts.append(cloudWorkout)
                }
            }
            
            // Update local storage
            historyManager.completedWorkouts = mergedWorkouts
            
            // Upload local workouts to cloud (with error handling)
            var uploadErrors: [Error] = []
            for workout in localWorkouts {
                do {
                    try await uploadWorkout(workout)
                } catch {
                    uploadErrors.append(error)
                    Logger.error("Error uploading workout to CloudKit", error: error, category: .cloudKit)
                }
            }
            
            // If we have too many upload errors, throw
            if uploadErrors.count > localWorkouts.count / 2 {
                throw AppError.cloudKitError("Failed to upload most workouts to iCloud")
            }
            
            await MainActor.run {
                lastSyncDate = Date()
                syncError = nil
            }
        } catch {
            let appError = error.toAppError()
            await MainActor.run {
                syncError = appError
            }
            throw appError
        }
    }
    
    // MARK: - Sync Templates
    
    func syncTemplates(templatesViewModel: TemplatesViewModel) async throws {
        await MainActor.run { isSyncing = true }
        defer { Task { @MainActor in isSyncing = false } }
        
        do {
            // Fetch templates from CloudKit
            let query = CKQuery(recordType: templateRecordType, predicate: NSPredicate(value: true))
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            // Convert CloudKit records to WorkoutTemplate objects
            var cloudTemplates: [WorkoutTemplate] = []
            var fetchErrors: [Error] = []
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let template = templateFromRecord(record) {
                        cloudTemplates.append(template)
                    }
                case .failure(let error):
                    fetchErrors.append(error)
                    Logger.error("Error fetching template from CloudKit", error: error, category: .cloudKit)
                }
            }
            
            // If we have too many fetch errors, throw
            if fetchErrors.count > matchResults.count / 2 {
                throw AppError.cloudKitError("Failed to fetch most templates from iCloud")
            }
            
            // Merge with local templates
            let localTemplates = templatesViewModel.templates.filter { !$0.name.contains("Progression") }
            var mergedTemplates = localTemplates
            
            // Add templates from cloud that don't exist locally
            for cloudTemplate in cloudTemplates {
                if !mergedTemplates.contains(where: { $0.id == cloudTemplate.id }) {
                    mergedTemplates.append(cloudTemplate)
                }
            }
            
            // Update local storage
            templatesViewModel.templates = mergedTemplates
            
            // Upload local templates to cloud (with error handling)
            var uploadErrors: [Error] = []
            for template in localTemplates {
                do {
                    try await uploadTemplate(template)
                } catch {
                    uploadErrors.append(error)
                    Logger.error("Error uploading template to CloudKit", error: error, category: .cloudKit)
                }
            }
            
            // If we have too many upload errors, throw
            if uploadErrors.count > localTemplates.count / 2 {
                throw AppError.cloudKitError("Failed to upload most templates to iCloud")
            }
            
            await MainActor.run {
                lastSyncDate = Date()
                syncError = nil
            }
        } catch {
            let appError = error.toAppError()
            await MainActor.run {
                syncError = appError
            }
            throw appError
        }
    }
    
    // MARK: - Upload Functions
    
    private func uploadWorkout(_ workout: Workout) async throws {
        let record = recordFromWorkout(workout)
        _ = try await privateDatabase.save(record)
    }
    
    private func uploadTemplate(_ template: WorkoutTemplate) async throws {
        let record = recordFromTemplate(template)
        _ = try await privateDatabase.save(record)
    }
    
    // MARK: - Conversion Functions
    
    private func recordFromWorkout(_ workout: Workout) -> CKRecord {
        let record = CKRecord(recordType: workoutRecordType, recordID: CKRecord.ID(recordName: workout.id.uuidString))
        record["name"] = workout.name
        record["startDate"] = workout.startDate
        
        // Encode exercises as JSON
        if let exercisesData = try? JSONEncoder().encode(workout.exercises) {
            record["exercises"] = String(data: exercisesData, encoding: .utf8)
        }
        
        return record
    }
    
    private func workoutFromRecord(_ record: CKRecord) -> Workout? {
        guard let name = record["name"] as? String,
              record["startDate"] as? Date != nil else {
            return nil
        }
        
        var exercises: [Exercise] = []
        if let exercisesString = record["exercises"] as? String,
           let exercisesData = exercisesString.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([Exercise].self, from: exercisesData) {
            exercises = decoded
        }
        
        let workout = Workout(name: name, exercises: exercises)
        // Note: Workout.id is let, so we can't change it. This is a limitation.
        return workout
    }
    
    private func recordFromTemplate(_ template: WorkoutTemplate) -> CKRecord {
        let record = CKRecord(recordType: templateRecordType, recordID: CKRecord.ID(recordName: template.id.uuidString))
        record["name"] = template.name
        record["estimatedDuration"] = template.estimatedDuration
        
        // Encode exercises as JSON
        if let exercisesData = try? JSONEncoder().encode(template.exercises) {
            record["exercises"] = String(data: exercisesData, encoding: .utf8)
        }
        
        if let intensity = template.intensity {
            record["intensity"] = intensity.rawValue
        }
        
        return record
    }
    
    private func templateFromRecord(_ record: CKRecord) -> WorkoutTemplate? {
        guard let name = record["name"] as? String,
              let estimatedDuration = record["estimatedDuration"] as? Int else {
            return nil
        }
        
        var exercises: [TemplateExercise] = []
        if let exercisesString = record["exercises"] as? String,
           let exercisesData = exercisesString.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([TemplateExercise].self, from: exercisesData) {
            exercises = decoded
        }
        
        var intensity: WorkoutIntensity? = nil
        if let intensityString = record["intensity"] as? String {
            intensity = WorkoutIntensity(rawValue: intensityString)
        }
        
        return WorkoutTemplate(
            name: name,
            exercises: exercises,
            estimatedDuration: estimatedDuration,
            intensity: intensity
        )
    }
    
    // MARK: - Account Status
    
    func checkAccountStatus() async throws -> CKAccountStatus {
        return try await container.accountStatus()
    }
}

