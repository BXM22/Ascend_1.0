import Foundation
import Combine

class ExerciseDataManager: ObservableObject {
    static let shared = ExerciseDataManager()
    
    // UserDefaults key for custom exercises
    private let customExercisesKey = AppConstants.UserDefaultsKeys.customExercises
    
    // Custom exercises stored persistently
    @Published private(set) var customExercises: [CustomExercise] = []
    
    // Exercise database with alternatives and video URLs
    // Organized by category for better maintainability
    private let exerciseDatabase: [String: ExerciseInfo] = {
        var db: [String: ExerciseInfo] = [:]
        
        // MARK: - Chest Exercises
        db["Bench Press"] = ExerciseInfo(
            alternatives: ["Push-ups", "Dumbbell Press", "Incline Push-ups"],
            videoURL: "https://www.youtube.com/watch?v=rT7DgCr-3pg"
        )
        db["Bench Press (Barbell)"] = ExerciseInfo(
            alternatives: ["Push-ups", "Dumbbell Press", "Incline Push-ups"],
            videoURL: "https://www.youtube.com/watch?v=rT7DgCr-3pg"
        )
        db["Incline Bench Press"] = ExerciseInfo(
            alternatives: ["Incline Push-ups", "Dumbbell Incline Press", "Push-ups"],
            videoURL: "https://exrx.net/WeightExercises/PectoralClavicular/BBInclineBenchPress"
        )
        db["Decline Bench Press"] = ExerciseInfo(
            alternatives: ["Decline Push-ups", "Dips", "Push-ups"],
            videoURL: "https://exrx.net/WeightExercises/PectoralSternal/BBDeclineBenchPress"
        )
        db["Dumbbell Fly"] = ExerciseInfo(
            alternatives: ["Push-ups", "Chest Dips", "Dumbbell Press"],
            videoURL: "https://exrx.net/WeightExercises/PectoralSternal/DBFly"
        )
        db["Push-ups"] = ExerciseInfo(
            alternatives: ["Incline Push-ups", "Diamond Push-ups", "Wide Push-ups", "Bench Press"],
            videoURL: "https://exrx.net/WeightExercises/PectoralSternal/BWPushUp"
        )
        db["Dips"] = ExerciseInfo(
            alternatives: ["Push-ups", "Bench Dips", "Dumbbell Press"],
            videoURL: "https://exrx.net/WeightExercises/PectoralSternal/BWDip"
        )
        db["Low Cable Fly Crossovers"] = ExerciseInfo(
            alternatives: ["Push-ups", "Dumbbell Fly", "Chest Dips"],
            videoURL: "https://www.youtube.com/results?search_query=low+cable+fly+crossovers"
        )
        
        // MARK: - Back Exercises
        db["Pull-ups"] = ExerciseInfo(
            alternatives: ["Chin-ups", "Inverted Rows", "Lat Pulldowns"],
            videoURL: "https://exrx.net/WeightExercises/LatissimusDorsi/BWPullup"
        )
        db["Chin-ups"] = ExerciseInfo(
            alternatives: ["Pull-ups", "Inverted Rows", "Bicep Curls"],
            videoURL: "https://exrx.net/WeightExercises/LatissimusDorsi/BWChinup"
        )
        db["Barbell Row"] = ExerciseInfo(
            alternatives: ["Inverted Rows", "Dumbbell Rows", "Pull-ups"],
            videoURL: "https://exrx.net/WeightExercises/LatissimusDorsi/BBBentOverRow"
        )
        db["Bent Over Row (Barbell)"] = ExerciseInfo(
            alternatives: ["Inverted Rows", "Dumbbell Rows", "Pull-ups"],
            videoURL: "https://exrx.net/WeightExercises/LatissimusDorsi/BBBentOverRow"
        )
        db["T-Bar Row"] = ExerciseInfo(
            alternatives: ["Barbell Row", "Dumbbell Rows", "Inverted Rows"],
            videoURL: "https://exrx.net/WeightExercises/LatissimusDorsi/BBTBarRow"
        )
        db["Lat Pulldown"] = ExerciseInfo(
            alternatives: ["Pull-ups", "Inverted Rows", "Chin-ups"],
            videoURL: "https://exrx.net/WeightExercises/LatissimusDorsi/CBLatPulldown"
        )
        db["Lat Pulldown (Cable)"] = ExerciseInfo(
            alternatives: ["Pull-ups", "Inverted Rows", "Chin-ups"],
            videoURL: "https://exrx.net/WeightExercises/LatissimusDorsi/CBLatPulldown"
        )
        db["Inverted Row"] = ExerciseInfo(
            alternatives: ["Pull-ups", "Barbell Row", "Lat Pulldowns"],
            videoURL: "https://exrx.net/WeightExercises/LatissimusDorsi/BWInvertedRow"
        )
        db["Face Pull"] = ExerciseInfo(
            alternatives: ["Rear Delt Fly", "Band Pull-Aparts", "Resistance Band Rear Delt Fly"],
            videoURL: "https://www.youtube.com/results?search_query=face+pull+exercise"
        )
        
        // MARK: - Shoulder Exercises
        db["Shoulder Press"] = ExerciseInfo(
            alternatives: ["Pike Push-ups", "Handstand Push-ups", "Dumbbell Press"],
            videoURL: "https://exrx.net/WeightExercises/DeltoidAnterior/BBShoulderPress"
        )
        db["Shoulder Press (Dumbbell)"] = ExerciseInfo(
            alternatives: ["Pike Push-ups", "Handstand Push-ups", "Barbell Shoulder Press"],
            videoURL: "https://www.youtube.com/results?search_query=dumbbell+shoulder+press"
        )
        db["Lateral Raise"] = ExerciseInfo(
            alternatives: ["Resistance Band Lateral Raise", "Bodyweight Lateral Raise", "Dumbbell Lateral Raise"],
            videoURL: "https://exrx.net/WeightExercises/DeltoidLateral/DBLateralRaise"
        )
        db["Front Raise"] = ExerciseInfo(
            alternatives: ["Resistance Band Front Raise", "Plate Front Raise", "Dumbbell Front Raise"],
            videoURL: "https://exrx.net/WeightExercises/DeltoidAnterior/DBFrontRaise"
        )
        db["Rear Delt Fly"] = ExerciseInfo(
            alternatives: ["Face Pulls", "Resistance Band Rear Delt Fly", "Dumbbell Rear Delt Fly"],
            videoURL: "https://exrx.net/WeightExercises/DeltoidPosterior/DBRearDeltFly"
        )
        db["Pike Push-up"] = ExerciseInfo(
            alternatives: ["Handstand Push-ups", "Shoulder Press", "Dumbbell Press"],
            videoURL: "https://exrx.net/WeightExercises/DeltoidAnterior/BWPikePushUp"
        )
        
        // MARK: - Arm Exercises
        db["Bicep Curl"] = ExerciseInfo(
            alternatives: ["Resistance Band Curls", "Bodyweight Curls", "Chin-ups"],
            videoURL: "https://exrx.net/WeightExercises/Biceps/DBBicepCurl"
        )
        db["Bicep Curl (Dumbbell)"] = ExerciseInfo(
            alternatives: ["Resistance Band Curls", "Bodyweight Curls", "Chin-ups"],
            videoURL: "https://exrx.net/WeightExercises/Biceps/DBBicepCurl"
        )
        db["Hammer Curl"] = ExerciseInfo(
            alternatives: ["Bicep Curl", "Resistance Band Hammer Curl", "Chin-ups"],
            videoURL: "https://exrx.net/WeightExercises/Brachialis/DBHammerCurl"
        )
        db["Hammer Curl (Dumbbell)"] = ExerciseInfo(
            alternatives: ["Bicep Curl", "Resistance Band Hammer Curl", "Chin-ups"],
            videoURL: "https://exrx.net/WeightExercises/Brachialis/DBHammerCurl"
        )
        db["Tricep Extension"] = ExerciseInfo(
            alternatives: ["Diamond Push-ups", "Overhead Extension", "Dips"],
            videoURL: "https://exrx.net/WeightExercises/Triceps/DBTricepExtension"
        )
        db["Triceps Extension (Dumbbell)"] = ExerciseInfo(
            alternatives: ["Diamond Push-ups", "Overhead Extension", "Dips"],
            videoURL: "https://exrx.net/WeightExercises/Triceps/DBTricepExtension"
        )
        db["Tricep Dip"] = ExerciseInfo(
            alternatives: ["Diamond Push-ups", "Bench Dips", "Dips"],
            videoURL: "https://exrx.net/WeightExercises/Triceps/BWTricepDip"
        )
        db["Triceps Rope Pushdown"] = ExerciseInfo(
            alternatives: ["Diamond Push-ups", "Tricep Extension", "Dips"],
            videoURL: "https://www.youtube.com/results?search_query=tricep+rope+pushdown"
        )
        db["Diamond Push-up"] = ExerciseInfo(
            alternatives: ["Tricep Dips", "Close Grip Push-ups", "Tricep Extension"],
            videoURL: "https://exrx.net/WeightExercises/Triceps/BWDiamondPushUp"
        )
        
        // MARK: - Leg Exercises
        db["Squat"] = ExerciseInfo(
            alternatives: ["Bodyweight Squat", "Jump Squats", "Lunges"],
            videoURL: "https://exrx.net/WeightExercises/Quadriceps/BBSquat"
        )
        db["Squat (Barbell)"] = ExerciseInfo(
            alternatives: ["Bodyweight Squat", "Jump Squats", "Lunges"],
            videoURL: "https://exrx.net/WeightExercises/Quadriceps/BBSquat"
        )
        db["Front Squat"] = ExerciseInfo(
            alternatives: ["Squat", "Goblet Squat", "Bodyweight Squat"],
            videoURL: "https://exrx.net/WeightExercises/Quadriceps/BBFrontSquat"
        )
        db["Leg Press"] = ExerciseInfo(
            alternatives: ["Squats", "Lunges", "Step-ups"],
            videoURL: "https://exrx.net/WeightExercises/Quadriceps/MLegPress"
        )
        db["Lunge"] = ExerciseInfo(
            alternatives: ["Reverse Lunge", "Walking Lunge", "Bulgarian Split Squat"],
            videoURL: "https://exrx.net/WeightExercises/Quadriceps/BWLunge"
        )
        db["Lunge (Dumbbell)"] = ExerciseInfo(
            alternatives: ["Reverse Lunge", "Walking Lunge", "Bulgarian Split Squat"],
            videoURL: "https://exrx.net/WeightExercises/Quadriceps/BWLunge"
        )
        db["Deadlift"] = ExerciseInfo(
            alternatives: ["Romanian Deadlift", "Good Mornings", "Hip Thrusts"],
            videoURL: "https://exrx.net/WeightExercises/Hamstrings/BBDeadlift"
        )
        db["Romanian Deadlift"] = ExerciseInfo(
            alternatives: ["Deadlift", "Good Mornings", "Hip Thrusts"],
            videoURL: "https://exrx.net/WeightExercises/Hamstrings/BBRomanianDeadlift"
        )
        db["Leg Curl"] = ExerciseInfo(
            alternatives: ["Nordic Curls", "Glute Ham Raise", "Romanian Deadlift"],
            videoURL: "https://exrx.net/WeightExercises/Hamstrings/MLegCurl"
        )
        db["Lying Leg Curl (Machine)"] = ExerciseInfo(
            alternatives: ["Nordic Curls", "Glute Ham Raise", "Romanian Deadlift"],
            videoURL: "https://exrx.net/WeightExercises/Hamstrings/MLegCurl"
        )
        db["Glute Ham Raise"] = ExerciseInfo(
            alternatives: ["Nordic Curls", "Leg Curl", "Romanian Deadlift"],
            videoURL: "https://www.youtube.com/results?search_query=glute+ham+raise"
        )
        db["Calf Raise"] = ExerciseInfo(
            alternatives: ["Weighted Calf Raise", "Single Leg Calf Raise", "Standing Calf Raise"],
            videoURL: "https://exrx.net/WeightExercises/Gastrocnemius/BWCalfRaise"
        )
        db["Standing Calf Raise (Smith)"] = ExerciseInfo(
            alternatives: ["Calf Raise", "Single Leg Calf Raise", "Weighted Calf Raise"],
            videoURL: "https://www.youtube.com/results?search_query=standing+calf+raise+smith+machine"
        )
        
        // MARK: - Core Exercises
        db["Plank"] = ExerciseInfo(
            alternatives: ["Side Plank", "Mountain Climbers", "Hollow Hold"],
            videoURL: "https://exrx.net/WeightExercises/RectusAbdominis/BWPlank"
        )
        db["Side Plank"] = ExerciseInfo(
            alternatives: ["Plank", "Russian Twist", "Mountain Climbers"],
            videoURL: "https://exrx.net/WeightExercises/Obliques/BWSidePlank"
        )
        db["Crunch"] = ExerciseInfo(
            alternatives: ["Sit-ups", "Bicycle Crunches", "Reverse Crunch"],
            videoURL: "https://exrx.net/WeightExercises/RectusAbdominis/BWCrunch"
        )
        db["Leg Raise"] = ExerciseInfo(
            alternatives: ["Hanging Leg Raises", "Reverse Crunch", "Knee Raises"],
            videoURL: "https://exrx.net/WeightExercises/RectusAbdominis/BWLegRaise"
        )
        db["Hanging Leg Raises"] = ExerciseInfo(
            alternatives: ["Leg Raise", "Knee Raises", "Reverse Crunch"],
            videoURL: "https://www.youtube.com/results?search_query=hanging+leg+raises"
        )
        db["Russian Twist"] = ExerciseInfo(
            alternatives: ["Side Plank", "Bicycle Crunches", "Plank"],
            videoURL: "https://exrx.net/WeightExercises/Obliques/BWRussianTwist"
        )
        db["Mountain Climber"] = ExerciseInfo(
            alternatives: ["Plank", "Burpees", "High Knees"],
            videoURL: "https://exrx.net/WeightExercises/RectusAbdominis/BWMountainClimber"
        )
        
        // MARK: - Calisthenics Skills
        db["Planche"] = ExerciseInfo(
            alternatives: ["Frog Stand", "Tuck Planche", "Push-ups"],
            videoURL: "https://exrx.net/WeightExercises/PectoralSternal/BWPlanche"
        )
        db["Handstand"] = ExerciseInfo(
            alternatives: ["Wall Handstand", "Chest-to-Wall", "Balance Practice"],
            videoURL: "https://exrx.net/WeightExercises/DeltoidAnterior/BWHandstand"
        )
        db["Handstand Push-up"] = ExerciseInfo(
            alternatives: ["Pike Push-ups", "Wall Handstand", "Dips"],
            videoURL: "https://exrx.net/WeightExercises/DeltoidAnterior/BWHandstandPushUp"
        )
        db["Muscle Up"] = ExerciseInfo(
            alternatives: ["Pull-ups", "Chin-ups", "Dips"],
            videoURL: "https://exrx.net/WeightExercises/LatissimusDorsi/BWMuscleUp"
        )
        db["Front Lever"] = ExerciseInfo(
            alternatives: ["Tuck Front Lever", "Hanging Leg Raises", "Pull-ups"],
            videoURL: "https://exrx.net/WeightExercises/LatissimusDorsi/BWFrontLever"
        )
        db["Back Lever"] = ExerciseInfo(
            alternatives: ["Tuck Back Lever", "Skin the Cat", "Pull-ups"],
            videoURL: "https://exrx.net/WeightExercises/LatissimusDorsi/BWBackLever"
        )
        db["Human Flag"] = ExerciseInfo(
            alternatives: ["Side Plank", "Tucked Human Flag", "Core Work"],
            videoURL: "https://exrx.net/WeightExercises/Obliques/BWHumanFlag"
        )
        db["L-Sit"] = ExerciseInfo(
            alternatives: ["Tucked L-Sit", "V-Sit", "Hanging Leg Raises"],
            videoURL: "https://exrx.net/WeightExercises/RectusAbdominis/BWLSit"
        )
        
        // MARK: - Program-Specific Exercises (Muscle-Up Progression)
        // Warm-up and Foundational Exercises
        db["Scapular Pull-Ups"] = ExerciseInfo(
            alternatives: ["Pull-ups", "Inverted Rows", "Band Pull-Aparts"],
            videoURL: "https://www.youtube.com/results?search_query=scapular+pull+ups"
        )
        db["Band Shoulder Rotations"] = ExerciseInfo(
            alternatives: ["Shoulder Circles", "Arm Swings", "Band Pull-Aparts"],
            videoURL: "https://www.youtube.com/results?search_query=band+shoulder+rotations"
        )
        db["Light Explosive Dead Hang Pulls"] = ExerciseInfo(
            alternatives: ["Pull-ups", "Explosive Pull-ups", "Dead Hangs"],
            videoURL: "https://www.youtube.com/results?search_query=explosive+pull+ups"
        )
        
        // Pull-Up Variations
        db["Strict Pull-Ups"] = ExerciseInfo(
            alternatives: ["Pull-ups", "Chin-ups", "Inverted Rows"],
            videoURL: "https://exrx.net/WeightExercises/LatissimusDorsi/BWPullup"
        )
        db["High Pull-Ups (Chest-To-Bar)"] = ExerciseInfo(
            alternatives: ["Pull-ups", "Explosive Pull-ups", "Chin-ups"],
            videoURL: "https://www.youtube.com/results?search_query=chest+to+bar+pull+ups"
        )
        db["High Pull-Ups"] = ExerciseInfo(
            alternatives: ["Pull-ups", "Explosive Pull-ups", "Chin-ups"],
            videoURL: "https://www.youtube.com/results?search_query=high+pull+ups"
        )
        db["Explosive Pull-Ups"] = ExerciseInfo(
            alternatives: ["Pull-ups", "High Pulls", "Strict Pull-Ups"],
            videoURL: "https://www.youtube.com/results?search_query=explosive+pull+ups"
        )
        db["Explosive Chest-to-Bar Pull-Ups"] = ExerciseInfo(
            alternatives: ["Pull-ups", "High Pulls", "Explosive Pull-Ups"],
            videoURL: "https://www.youtube.com/results?search_query=explosive+chest+to+bar+pull+ups"
        )
        db["Slow Pull-Up Negatives"] = ExerciseInfo(
            alternatives: ["Pull-ups", "Eccentric Pull-ups", "Strict Pull-Ups"],
            videoURL: "https://www.youtube.com/results?search_query=slow+pull+up+negatives"
        )
        db["Pull-Ups (Volume Work)"] = ExerciseInfo(
            alternatives: ["Pull-ups", "Chin-ups", "Inverted Rows"],
            videoURL: "https://exrx.net/WeightExercises/LatissimusDorsi/BWPullup"
        )
        
        // Muscle-Up Progressions
        db["Jump-Assisted Muscle-Ups"] = ExerciseInfo(
            alternatives: ["Muscle Up", "Assisted Muscle-Ups", "Pull-ups"],
            videoURL: "https://www.youtube.com/results?search_query=jump+assisted+muscle+up"
        )
        db["Muscle-Up Negatives"] = ExerciseInfo(
            alternatives: ["Muscle Up", "Pull-ups", "Dips"],
            videoURL: "https://www.youtube.com/results?search_query=muscle+up+negatives"
        )
        db["Band-Assisted Muscle-Ups"] = ExerciseInfo(
            alternatives: ["Muscle Up", "Assisted Muscle-Ups", "Pull-ups"],
            videoURL: "https://www.youtube.com/results?search_query=band+assisted+muscle+up"
        )
        db["Single Rep Muscle-Up Attempts"] = ExerciseInfo(
            alternatives: ["Muscle Up", "Assisted Muscle-Ups", "Pull-ups"],
            videoURL: "https://www.youtube.com/results?search_query=muscle+up+attempts"
        )
        
        // Dip Variations
        db["Straight Bar Dips"] = ExerciseInfo(
            alternatives: ["Dips", "Bench Dips", "Parallel Bar Dips"],
            videoURL: "https://www.youtube.com/results?search_query=straight+bar+dips"
        )
        db["Bar Dips"] = ExerciseInfo(
            alternatives: ["Dips", "Bench Dips", "Parallel Bar Dips"],
            videoURL: "https://exrx.net/WeightExercises/PectoralSternal/BWDip"
        )
        
        // Core and Accessory Exercises
        db["Hanging Knee or L-Raises"] = ExerciseInfo(
            alternatives: ["Hanging Leg Raises", "Knee Raises", "Leg Raises"],
            videoURL: "https://www.youtube.com/results?search_query=hanging+knee+raises"
        )
        db["Hanging Knee Raises"] = ExerciseInfo(
            alternatives: ["Hanging Leg Raises", "Knee Raises", "Leg Raises"],
            videoURL: "https://www.youtube.com/results?search_query=hanging+knee+raises"
        )
        db["Toes-to-Bar or Knee Raises"] = ExerciseInfo(
            alternatives: ["Hanging Leg Raises", "Knee Raises", "Toes-to-Bar"],
            videoURL: "https://www.youtube.com/results?search_query=toes+to+bar"
        )
        db["Toes-to-Bar"] = ExerciseInfo(
            alternatives: ["Hanging Leg Raises", "Knee Raises", "Leg Raises"],
            videoURL: "https://www.youtube.com/results?search_query=toes+to+bar"
        )
        db["Knee Raises"] = ExerciseInfo(
            alternatives: ["Hanging Leg Raises", "Leg Raises", "Toes-to-Bar"],
            videoURL: "https://www.youtube.com/results?search_query=knee+raises"
        )
        
        // Grip and Transition Exercises
        db["False Grip Hangs"] = ExerciseInfo(
            alternatives: ["Pull-ups", "Dead Hangs", "False Grip Pull-ups"],
            videoURL: "https://www.youtube.com/results?search_query=false+grip+hangs"
        )
        db["Shoulder Band Warm-up"] = ExerciseInfo(
            alternatives: ["Band Pull-Aparts", "Shoulder Rotations", "Band Shoulder Rotations"],
            videoURL: "https://www.youtube.com/results?search_query=shoulder+band+warm+up"
        )
        db["Transition Rows"] = ExerciseInfo(
            alternatives: ["Inverted Rows", "High Rows", "Pull-ups"],
            videoURL: "https://www.youtube.com/results?search_query=transition+rows+muscle+up"
        )
        db["Transition Rows (Bar at Chest Height)"] = ExerciseInfo(
            alternatives: ["Inverted Rows", "High Rows", "Pull-ups"],
            videoURL: "https://www.youtube.com/results?search_query=transition+rows+muscle+up"
        )
        db["Front Lever Tuck Raises"] = ExerciseInfo(
            alternatives: ["Front Lever", "Hanging Leg Raises", "Tuck Front Lever"],
            videoURL: "https://www.youtube.com/results?search_query=front+lever+tuck+raises"
        )
        
        return db
    }()
    
    private init() {
        loadCustomExercises()
    }
    
    // MARK: - Custom Exercise Management
    
    /// Load custom exercises from UserDefaults
    private func loadCustomExercises() {
        if let data = UserDefaults.standard.data(forKey: customExercisesKey),
           let exercises = try? JSONDecoder().decode([CustomExercise].self, from: data) {
            customExercises = exercises
        }
    }
    
    /// Save custom exercises to UserDefaults (debounced)
    private func saveCustomExercises() {
        PerformanceOptimizer.shared.debouncedSave {
            if let data = try? JSONEncoder().encode(self.customExercises) {
                UserDefaults.standard.set(data, forKey: self.customExercisesKey)
            }
        }
    }
    
    /// Add a custom exercise
    func addCustomExercise(_ exercise: CustomExercise) {
        // Check if exercise with same name already exists
        if !customExercises.contains(where: { $0.name.lowercased() == exercise.name.lowercased() }) {
            customExercises.append(exercise)
            saveCustomExercises()
        }
    }
    
    /// Update a custom exercise
    func updateCustomExercise(_ exercise: CustomExercise) {
        if let index = customExercises.firstIndex(where: { $0.id == exercise.id }) {
            customExercises[index] = exercise
            saveCustomExercises()
        }
    }
    
    /// Delete a custom exercise
    func deleteCustomExercise(_ exercise: CustomExercise) {
        customExercises.removeAll { $0.id == exercise.id }
        saveCustomExercises()
    }
    
    /// Clear all custom exercises
    func clearAllCustomExercises() {
        customExercises = []
        saveCustomExercises()
    }
    
    /// Get custom exercise by name
    func getCustomExercise(name: String) -> CustomExercise? {
        return customExercises.first { $0.name.lowercased() == name.lowercased() }
    }
    
    /// Get all muscle groups for an exercise (from custom or database)
    func getMuscleGroups(for exerciseName: String) -> (primary: [String], secondary: [String]) {
        // Check custom exercises first
        if let custom = getCustomExercise(name: exerciseName) {
            return (custom.primaryMuscleGroups, custom.secondaryMuscleGroups)
        }
        
        // Check ExRx directory
        if let exRx = ExRxDirectoryManager.shared.findExercise(name: exerciseName) {
            return ([exRx.muscleGroup], [])
        }
        
        return ([], [])
    }
    
    func getAlternatives(for exerciseName: String) -> [String] {
        var alternatives: [String] = []
        
        // Check custom exercises first
        if let custom = getCustomExercise(name: exerciseName) {
            alternatives.append(contentsOf: custom.alternatives)
        }
        
        // Check exact match in local database
        if let info = exerciseDatabase[exerciseName] {
            alternatives.append(contentsOf: info.alternatives)
        }
        
        // Check if it's a skill progression exercise (e.g., "Planche - Tuck Planche")
        for (skillName, info) in exerciseDatabase {
            if exerciseName.contains(skillName) {
                alternatives.append(contentsOf: info.alternatives)
            }
        }
        
        // If no alternatives found, check ExRx directory
        if alternatives.isEmpty {
            let exRxAlternatives = ExRxDirectoryManager.shared.getAlternatives(for: exerciseName)
            alternatives.append(contentsOf: exRxAlternatives)
        } else {
            // Merge with ExRx alternatives, avoiding duplicates
            let exRxAlternatives = ExRxDirectoryManager.shared.getAlternatives(for: exerciseName)
            for alt in exRxAlternatives {
                if !alternatives.contains(alt) {
                    alternatives.append(alt)
                }
            }
        }
        
        return alternatives
    }
    
    func getVideoURL(for exerciseName: String) -> String? {
        // Check custom exercises first
        if let custom = getCustomExercise(name: exerciseName) {
            return custom.videoURL
        }
        
        // Check exact match first
        if let info = exerciseDatabase[exerciseName] {
            return info.videoURL
        }
        
        // Check if it's a skill progression exercise
        for (skillName, info) in exerciseDatabase {
            if exerciseName.contains(skillName) {
                return info.videoURL
            }
        }
        
        // Check calisthenics skills
        for skill in CalisthenicsSkillManager.shared.skills {
            if exerciseName.contains(skill.name) {
                return skill.videoURL
            }
        }
        
        return nil
    }
    
    func hasAlternatives(for exerciseName: String) -> Bool {
        // Check local database first
        if let info = exerciseDatabase[exerciseName] {
            return !info.alternatives.isEmpty
        }
        
        // Check skill progression
        for (skillName, info) in exerciseDatabase {
            if exerciseName.contains(skillName) {
                return !info.alternatives.isEmpty
            }
        }
        
        // Check ExRx directory
        let exRxAlternatives = ExRxDirectoryManager.shared.getAlternatives(for: exerciseName)
        return !exRxAlternatives.isEmpty
    }
    
    // Get ExRx URL for an exercise
    func getExRxURL(for exerciseName: String) -> String? {
        return ExRxDirectoryManager.shared.getExRxURL(for: exerciseName)
    }
    
    // Search ExRx directory
    func searchExRxDirectory(query: String) -> [ExRxExercise] {
        return ExRxDirectoryManager.shared.searchExercises(query: query)
    }
    
    func hasVideo(for exerciseName: String) -> Bool {
        return getVideoURL(for: exerciseName) != nil
    }
}

struct ExerciseInfo {
    let alternatives: [String]
    let videoURL: String?
    let primaryMuscleGroups: [String]?
    let secondaryMuscleGroups: [String]?
    
    init(alternatives: [String], videoURL: String? = nil, primaryMuscleGroups: [String]? = nil, secondaryMuscleGroups: [String]? = nil) {
        self.alternatives = alternatives
        self.videoURL = videoURL
        self.primaryMuscleGroups = primaryMuscleGroups
        self.secondaryMuscleGroups = secondaryMuscleGroups
    }
}


