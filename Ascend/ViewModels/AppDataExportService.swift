import Foundation

/// Builds a single JSON snapshot of user data for backup / share (Progress → Export).
enum AppDataExportService {
    static let exportVersion = 1

    struct Payload: Codable {
        let exportVersion: Int
        let exportedAt: Date
        let workouts: [Workout]
        let personalRecords: [PersonalRecord]
        let workoutDates: [Date]
        let restDays: [Date]
        let templates: [WorkoutTemplate]
        let customExercises: [CustomExercise]
    }

    static func makeExportJSON(progressViewModel: ProgressViewModel) throws -> Data {
        let workouts = WorkoutHistoryManager.shared.completedWorkouts
        let templates: [WorkoutTemplate]
        if let data = UserDefaults.standard.data(forKey: AppConstants.UserDefaultsKeys.savedWorkoutTemplates) {
            templates = (try? JSONDecoder().decode([WorkoutTemplate].self, from: data)) ?? []
        } else {
            templates = []
        }
        let custom = ExerciseDataManager.shared.customExercises
        let payload = Payload(
            exportVersion: exportVersion,
            exportedAt: Date(),
            workouts: workouts,
            personalRecords: progressViewModel.prs,
            workoutDates: progressViewModel.workoutDates,
            restDays: progressViewModel.restDays,
            templates: templates,
            customExercises: custom
        )
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        return try enc.encode(payload)
    }

    /// Writes JSON to a temporary file suitable for `UIActivityViewController`.
    static func writeTempExportFile(progressViewModel: ProgressViewModel) throws -> URL {
        let data = try makeExportJSON(progressViewModel: progressViewModel)
        let dir = FileManager.default.temporaryDirectory
        let name = "Ascend-export-\(ISO8601DateFormatter().string(from: Date())).json"
        let url = dir.appendingPathComponent(name)
        try data.write(to: url, options: [.atomic])
        return url
    }
}
