import Foundation
import Combine

class ExRxDirectoryManager: ObservableObject {
    static let shared = ExRxDirectoryManager()
    
    @Published private var exercises: [ExRxExercise] = []
    @Published private var importedExercises: [ExRxExercise] = []
    private let baseURL = "https://exrx.net/Lists/Directory"
    private let importedExercisesKey = "importedExercises"
    
    private init() {
        // Load imported exercises FIRST, then load hardcoded and merge
        loadImportedExercises()
        loadExercises() // This will merge imported exercises with hardcoded ones
    }
    
    // Load exercises from ExRx directory
    // This is a comprehensive list based on ExRx.net's exercise directory structure
    private func loadExercises() {
        let hardcodedExercises: [ExRxExercise] = [
            // Chest Exercises
            ExRxExercise(id: "bench-press", name: "Bench Press", category: "Chest", muscleGroup: "Chest", equipment: "Barbell", url: "https://exrx.net/WeightExercises/PectoralSternal/BBBenchPress", alternatives: ["Push-ups", "Dumbbell Press", "Incline Push-ups"]),
            ExRxExercise(id: "incline-bench-press", name: "Incline Bench Press", category: "Chest", muscleGroup: "Chest", equipment: "Barbell", url: "https://exrx.net/WeightExercises/PectoralClavicular/BBInclineBenchPress", alternatives: ["Incline Push-ups", "Dumbbell Incline Press"]),
            ExRxExercise(id: "decline-bench-press", name: "Decline Bench Press", category: "Chest", muscleGroup: "Chest", equipment: "Barbell", url: "https://exrx.net/WeightExercises/PectoralSternal/BBDeclineBenchPress", alternatives: ["Decline Push-ups", "Dips"]),
            ExRxExercise(id: "dumbbell-fly", name: "Dumbbell Fly", category: "Chest", muscleGroup: "Chest", equipment: "Dumbbells", url: "https://exrx.net/WeightExercises/PectoralSternal/DBFly", alternatives: ["Push-ups", "Chest Dips"]),
            ExRxExercise(id: "push-ups", name: "Push-ups", category: "Chest", muscleGroup: "Chest", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/PectoralSternal/BWPushUp", alternatives: ["Incline Push-ups", "Diamond Push-ups", "Wide Push-ups"]),
            ExRxExercise(id: "dips", name: "Dips", category: "Chest", muscleGroup: "Chest", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/PectoralSternal/BWDip", alternatives: ["Push-ups", "Bench Dips", "Dumbbell Press"]),
            
            // Back Exercises
            ExRxExercise(id: "pull-ups", name: "Pull-ups", category: "Back", muscleGroup: "Lats", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/LatissimusDorsi/BWPullup", alternatives: ["Chin-ups", "Inverted Rows", "Lat Pulldowns"]),
            ExRxExercise(id: "chin-ups", name: "Chin-ups", category: "Back", muscleGroup: "Lats", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/LatissimusDorsi/BWChinup", alternatives: ["Pull-ups", "Inverted Rows"]),
            ExRxExercise(id: "barbell-row", name: "Barbell Row", category: "Back", muscleGroup: "Lats", equipment: "Barbell", url: "https://exrx.net/WeightExercises/LatissimusDorsi/BBBentOverRow", alternatives: ["Inverted Rows", "Dumbbell Rows", "Pull-ups"]),
            ExRxExercise(id: "t-bar-row", name: "T-Bar Row", category: "Back", muscleGroup: "Lats", equipment: "Barbell", url: "https://exrx.net/WeightExercises/LatissimusDorsi/BBTBarRow", alternatives: ["Barbell Row", "Dumbbell Rows"]),
            ExRxExercise(id: "lat-pulldown", name: "Lat Pulldown", category: "Back", muscleGroup: "Lats", equipment: "Cable", url: "https://exrx.net/WeightExercises/LatissimusDorsi/CBLatPulldown", alternatives: ["Pull-ups", "Inverted Rows"]),
            ExRxExercise(id: "inverted-row", name: "Inverted Row", category: "Back", muscleGroup: "Lats", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/LatissimusDorsi/BWInvertedRow", alternatives: ["Pull-ups", "Barbell Row"]),
            
            // Shoulder Exercises
            ExRxExercise(id: "shoulder-press", name: "Shoulder Press", category: "Shoulders", muscleGroup: "Shoulders", equipment: "Barbell", url: "https://exrx.net/WeightExercises/DeltoidAnterior/BBShoulderPress", alternatives: ["Pike Push-ups", "Handstand Push-ups", "Dumbbell Press"]),
            ExRxExercise(id: "lateral-raise", name: "Lateral Raise", category: "Shoulders", muscleGroup: "Shoulders", equipment: "Dumbbells", url: "https://exrx.net/WeightExercises/DeltoidLateral/DBLateralRaise", alternatives: ["Resistance Band Lateral Raise", "Bodyweight Lateral Raise"]),
            ExRxExercise(id: "front-raise", name: "Front Raise", category: "Shoulders", muscleGroup: "Shoulders", equipment: "Dumbbells", url: "https://exrx.net/WeightExercises/DeltoidAnterior/DBFrontRaise", alternatives: ["Resistance Band Front Raise", "Plate Front Raise"]),
            ExRxExercise(id: "rear-delt-fly", name: "Rear Delt Fly", category: "Shoulders", muscleGroup: "Shoulders", equipment: "Dumbbells", url: "https://exrx.net/WeightExercises/DeltoidPosterior/DBRearDeltFly", alternatives: ["Face Pulls", "Resistance Band Rear Delt Fly"]),
            ExRxExercise(id: "pike-push-up", name: "Pike Push-up", category: "Shoulders", muscleGroup: "Shoulders", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/DeltoidAnterior/BWPikePushUp", alternatives: ["Handstand Push-ups", "Shoulder Press"]),
            
            // Arm Exercises
            ExRxExercise(id: "bicep-curl", name: "Bicep Curl", category: "Arms", muscleGroup: "Biceps", equipment: "Dumbbells", url: "https://exrx.net/WeightExercises/Biceps/DBBicepCurl", alternatives: ["Resistance Band Curls", "Bodyweight Curls", "Chin-ups"]),
            ExRxExercise(id: "hammer-curl", name: "Hammer Curl", category: "Arms", muscleGroup: "Biceps", equipment: "Dumbbells", url: "https://exrx.net/WeightExercises/Brachialis/DBHammerCurl", alternatives: ["Bicep Curl", "Resistance Band Hammer Curl"]),
            ExRxExercise(id: "tricep-extension", name: "Tricep Extension", category: "Arms", muscleGroup: "Triceps", equipment: "Dumbbells", url: "https://exrx.net/WeightExercises/Triceps/DBTricepExtension", alternatives: ["Diamond Push-ups", "Overhead Extension", "Dips"]),
            ExRxExercise(id: "tricep-dip", name: "Tricep Dip", category: "Arms", muscleGroup: "Triceps", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/Triceps/BWTricepDip", alternatives: ["Diamond Push-ups", "Bench Dips"]),
            ExRxExercise(id: "diamond-push-up", name: "Diamond Push-up", category: "Arms", muscleGroup: "Triceps", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/Triceps/BWDiamondPushUp", alternatives: ["Tricep Dips", "Close Grip Push-ups"]),
            
            // Leg Exercises
            ExRxExercise(id: "squat", name: "Squat", category: "Legs", muscleGroup: "Quads", equipment: "Barbell", url: "https://exrx.net/WeightExercises/Quadriceps/BBSquat", alternatives: ["Bodyweight Squat", "Jump Squats", "Lunges"]),
            ExRxExercise(id: "front-squat", name: "Front Squat", category: "Legs", muscleGroup: "Quads", equipment: "Barbell", url: "https://exrx.net/WeightExercises/Quadriceps/BBFrontSquat", alternatives: ["Squat", "Goblet Squat"]),
            ExRxExercise(id: "leg-press", name: "Leg Press", category: "Legs", muscleGroup: "Quads", equipment: "Machine", url: "https://exrx.net/WeightExercises/Quadriceps/MLegPress", alternatives: ["Squats", "Lunges", "Step-ups"]),
            ExRxExercise(id: "lunge", name: "Lunge", category: "Legs", muscleGroup: "Quads", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/Quadriceps/BWLunge", alternatives: ["Reverse Lunge", "Walking Lunge", "Bulgarian Split Squat"]),
            ExRxExercise(id: "deadlift", name: "Deadlift", category: "Legs", muscleGroup: "Hamstrings", equipment: "Barbell", url: "https://exrx.net/WeightExercises/Hamstrings/BBDeadlift", alternatives: ["Romanian Deadlift", "Good Mornings", "Hip Thrusts"]),
            ExRxExercise(id: "romanian-deadlift", name: "Romanian Deadlift", category: "Legs", muscleGroup: "Hamstrings", equipment: "Barbell", url: "https://exrx.net/WeightExercises/Hamstrings/BBRomanianDeadlift", alternatives: ["Deadlift", "Good Mornings"]),
            ExRxExercise(id: "leg-curl", name: "Leg Curl", category: "Legs", muscleGroup: "Hamstrings", equipment: "Machine", url: "https://exrx.net/WeightExercises/Hamstrings/MLegCurl", alternatives: ["Nordic Curls", "Glute Ham Raise"]),
            ExRxExercise(id: "calf-raise", name: "Calf Raise", category: "Legs", muscleGroup: "Calves", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/Gastrocnemius/BWCalfRaise", alternatives: ["Weighted Calf Raise", "Single Leg Calf Raise"]),
            
            // Core Exercises
            ExRxExercise(id: "plank", name: "Plank", category: "Core", muscleGroup: "Abs", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/RectusAbdominis/BWPlank", alternatives: ["Side Plank", "Mountain Climbers", "Hollow Hold"]),
            ExRxExercise(id: "side-plank", name: "Side Plank", category: "Core", muscleGroup: "Obliques", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/Obliques/BWSidePlank", alternatives: ["Plank", "Russian Twist"]),
            ExRxExercise(id: "crunch", name: "Crunch", category: "Core", muscleGroup: "Abs", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/RectusAbdominis/BWCrunch", alternatives: ["Sit-ups", "Bicycle Crunches", "Reverse Crunch"]),
            ExRxExercise(id: "leg-raise", name: "Leg Raise", category: "Core", muscleGroup: "Abs", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/RectusAbdominis/BWLegRaise", alternatives: ["Hanging Leg Raises", "Reverse Crunch"]),
            ExRxExercise(id: "russian-twist", name: "Russian Twist", category: "Core", muscleGroup: "Obliques", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/Obliques/BWRussianTwist", alternatives: ["Side Plank", "Bicycle Crunches"]),
            ExRxExercise(id: "mountain-climber", name: "Mountain Climber", category: "Core", muscleGroup: "Abs", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/RectusAbdominis/BWMountainClimber", alternatives: ["Plank", "Burpees"]),
            
            // Calisthenics Skills
            ExRxExercise(id: "planche", name: "Planche", category: "Calisthenics", muscleGroup: "Chest", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/PectoralSternal/BWPlanche", alternatives: ["Frog Stand", "Tuck Planche", "Push-ups"]),
            ExRxExercise(id: "handstand", name: "Handstand", category: "Calisthenics", muscleGroup: "Shoulders", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/DeltoidAnterior/BWHandstand", alternatives: ["Wall Handstand", "Chest-to-Wall", "Balance Practice"]),
            ExRxExercise(id: "handstand-push-up", name: "Handstand Push-up", category: "Calisthenics", muscleGroup: "Shoulders", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/DeltoidAnterior/BWHandstandPushUp", alternatives: ["Pike Push-ups", "Wall Handstand", "Dips"]),
            ExRxExercise(id: "muscle-up", name: "Muscle Up", category: "Calisthenics", muscleGroup: "Lats", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/LatissimusDorsi/BWMuscleUp", alternatives: ["Pull-ups", "Chin-ups", "Dips"]),
            ExRxExercise(id: "front-lever", name: "Front Lever", category: "Calisthenics", muscleGroup: "Lats", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/LatissimusDorsi/BWFrontLever", alternatives: ["Tuck Front Lever", "Hanging Leg Raises", "Pull-ups"]),
            ExRxExercise(id: "back-lever", name: "Back Lever", category: "Calisthenics", muscleGroup: "Lats", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/LatissimusDorsi/BWBackLever", alternatives: ["Tuck Back Lever", "Skin the Cat", "Pull-ups"]),
            ExRxExercise(id: "human-flag", name: "Human Flag", category: "Calisthenics", muscleGroup: "Obliques", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/Obliques/BWHumanFlag", alternatives: ["Side Plank", "Tucked Human Flag", "Core Work"]),
            ExRxExercise(id: "l-sit", name: "L-Sit", category: "Calisthenics", muscleGroup: "Abs", equipment: "Bodyweight", url: "https://exrx.net/WeightExercises/RectusAbdominis/BWLSit", alternatives: ["Tucked L-Sit", "V-Sit", "Hanging Leg Raises"])
        ]
        
        exercises = hardcodedExercises
        mergeImportedExercises()
    }
    
    // MARK: - Imported Exercises Management
    
    /// Load imported exercises from UserDefaults
    private func loadImportedExercises() {
        if let data = UserDefaults.standard.data(forKey: importedExercisesKey),
           let decoded = try? JSONDecoder().decode([ExRxExercise].self, from: data) {
            importedExercises = decoded
            Logger.info("📥 Loaded \(importedExercises.count) imported exercises from UserDefaults", category: .general)
        }
    }
    
    /// Save imported exercises to UserDefaults
    private func saveImportedExercises() {
        if let data = try? JSONEncoder().encode(importedExercises) {
            UserDefaults.standard.set(data, forKey: importedExercisesKey)
            Logger.info("💾 Saved \(importedExercises.count) imported exercises to UserDefaults", category: .general)
        }
    }
    
    /// Merge imported exercises with hardcoded exercises
    /// Imported exercises take precedence for duplicates (by name)
    private func mergeImportedExercises() {
        // Get hardcoded exercises (stored temporarily)
        let hardcodedExercises = exercises
        var merged: [ExRxExercise] = []
        let importedNames = Set(importedExercises.map { $0.name.lowercased() })
        
        // Add hardcoded exercises that aren't in imported list
        for exercise in hardcodedExercises {
            if !importedNames.contains(exercise.name.lowercased()) {
                merged.append(exercise)
            }
        }
        
        // Add all imported exercises (they take precedence)
        merged.append(contentsOf: importedExercises)
        
        exercises = merged
        
        // Verify merge was successful
        let totalExpected = hardcodedExercises.count + importedExercises.count
        let duplicatesRemoved = totalExpected - merged.count
        
        Logger.info("🔄 Merged exercises: \(exercises.count) total (hardcoded: \(hardcodedExercises.count), imported: \(importedExercises.count), duplicates removed: \(duplicatesRemoved))", category: .general)
        
        // Ensure imported exercises are actually in the merged list
        if importedExercises.count > 0 {
            let importedInMerged = merged.filter { exercise in
                importedExercises.contains { $0.id == exercise.id }
            }
            if importedInMerged.count != importedExercises.count {
                Logger.error("⚠️ Not all imported exercises were merged! Expected \(importedExercises.count), found \(importedInMerged.count)", category: .general)
            }
        }
    }
    
    /// Import exercises from CSV importer
    func importExercises(_ newExercises: [ExRxExercise]) {
        // Remove existing imported exercises
        importedExercises.removeAll()
        
        // Add new imported exercises
        importedExercises = newExercises
        
        // Save to UserDefaults immediately - this is critical for persistence
        saveImportedExercises()
        
        // Force UserDefaults to synchronize to ensure data is written
        UserDefaults.standard.synchronize()
        
        // Re-merge with hardcoded exercises
        // This will reload hardcoded exercises and merge with imported ones
        loadExercises()
        
        // Verify the merge worked
        let importedInFinal = exercises.filter { exercise in
            importedExercises.contains { $0.id == exercise.id }
        }
        
        // Ensure merge happened correctly
        Logger.info("✅ Imported \(newExercises.count) exercises into ExRxDirectoryManager", category: .general)
        Logger.info("📊 Total exercises after import: \(exercises.count) (hardcoded + imported)", category: .general)
        Logger.info("🔍 Verification: \(importedInFinal.count) of \(importedExercises.count) imported exercises found in final list", category: .general)
        
        if importedInFinal.count != importedExercises.count {
            Logger.error("❌ Import verification failed! Expected \(importedExercises.count) imported exercises, but only \(importedInFinal.count) found in final list", category: .general)
        }
    }
    
    /// Clear all imported exercises
    func clearImportedExercises() {
        importedExercises.removeAll()
        saveImportedExercises()
        loadExercises()
        Logger.info("🗑️ Cleared all imported exercises", category: .general)
    }
    
    /// Get count of imported exercises
    func getImportedExerciseCount() -> Int {
        return importedExercises.count
    }
    
    /// Update an imported exercise
    func updateImportedExercise(_ exercise: ExRxExercise) {
        guard let index = importedExercises.firstIndex(where: { $0.id == exercise.id }) else {
            Logger.info("⚠️ Exercise not found for update: \(exercise.name)", category: .general)
            return
        }
        
        importedExercises[index] = exercise
        saveImportedExercises()
        loadExercises() // Re-merge with hardcoded exercises
        Logger.info("✅ Updated exercise: \(exercise.name)", category: .general)
    }
    
    /// Delete an imported exercise
    func deleteImportedExercise(_ exercise: ExRxExercise) {
        guard let index = importedExercises.firstIndex(where: { $0.id == exercise.id }) else {
            Logger.info("⚠️ Exercise not found for deletion: \(exercise.name)", category: .general)
            return
        }
        
        importedExercises.remove(at: index)
        saveImportedExercises()
        loadExercises() // Re-merge with hardcoded exercises
        Logger.info("🗑️ Deleted exercise: \(exercise.name)", category: .general)
    }
    
    /// Check if an exercise is imported (can be edited/deleted)
    func isImportedExercise(_ exercise: ExRxExercise) -> Bool {
        return importedExercises.contains(where: { $0.id == exercise.id })
    }
    
    // Search exercises by name (fuzzy matching)
    func searchExercises(query: String) -> [ExRxExercise] {
        guard !query.isEmpty else { return [] }
        let lowerQuery = query.lowercased()
        return exercises.filter { exercise in
            exercise.name.lowercased().contains(lowerQuery) ||
            exercise.category.lowercased().contains(lowerQuery) ||
            exercise.muscleGroup.lowercased().contains(lowerQuery) ||
            (exercise.equipment?.lowercased().contains(lowerQuery) ?? false)
        }
    }
    
    // Find exercises by exact name match
    func findExercise(name: String) -> ExRxExercise? {
        return exercises.first { $0.name.lowercased() == name.lowercased() }
    }
    
    // Get alternatives from ExRx directory
    func getAlternatives(for exerciseName: String) -> [String] {
        // First try exact match
        if let exercise = findExercise(name: exerciseName) {
            return exercise.alternatives ?? []
        }
        
        // Try fuzzy search
        let matches = searchExercises(query: exerciseName)
        if let match = matches.first {
            return match.alternatives ?? []
        }
        
        // Try to find exercises in the same category/muscle group
        if let exercise = exercises.first(where: { exerciseName.lowercased().contains($0.name.lowercased()) || $0.name.lowercased().contains(exerciseName.lowercased()) }) {
            return exercise.alternatives ?? []
        }
        
        // Find exercises targeting the same muscle group
        if let exercise = exercises.first(where: { exerciseName.lowercased().contains($0.name.lowercased()) }) {
            let sameMuscleGroup = exercises.filter { $0.muscleGroup == exercise.muscleGroup && $0.name != exercise.name }
            return Array(sameMuscleGroup.prefix(5).map { $0.name })
        }
        
        return []
    }
    
    // Get all exercises in a category
    func getExercises(in category: ExRxCategory) -> [ExRxExercise] {
        return exercises.filter { $0.category == category.rawValue }
    }
    
    // Get all exercises for a muscle group
    func getExercises(for muscleGroup: ExRxMuscleGroup) -> [ExRxExercise] {
        return exercises.filter { $0.muscleGroup == muscleGroup.rawValue }
    }
    
    // Get all exercises
    func getAllExercises() -> [ExRxExercise] {
        return exercises
    }
    
    // Get ExRx URL for an exercise
    func getExRxURL(for exerciseName: String) -> String? {
        return findExercise(name: exerciseName)?.url
    }
    
    // Get all exercise names for autocomplete
    func getAllExerciseNames() -> [String] {
        return exercises.map { $0.name }
    }
}

