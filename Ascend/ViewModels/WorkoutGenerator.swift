import Foundation

class WorkoutGenerator {
    static let shared = WorkoutGenerator()
    
    private init() {}
    
    // Generate a workout template based on settings
    func generateWorkout(settings: WorkoutGenerationSettings, name: String? = nil) -> WorkoutTemplate {
        var selectedExercises: [String] = []
        let allExercises = ExRxDirectoryManager.shared.getAllExercises()
        
        // Filter by preferred equipment
        let availableExercises = allExercises.filter { exercise in
            guard let equipment = exercise.equipment else { return true }
            return settings.preferredEquipment.contains(equipment)
        }
        
        // Group exercises by muscle group
        var exercisesByMuscleGroup: [String: [ExRxExercise]] = [:]
        for exercise in availableExercises {
            if exercisesByMuscleGroup[exercise.muscleGroup] == nil {
                exercisesByMuscleGroup[exercise.muscleGroup] = []
            }
            exercisesByMuscleGroup[exercise.muscleGroup]?.append(exercise)
        }
        
        // Select exercises based on settings with better variety
        var usedExercises: Set<String> = []
        var lastUsedExercises: [String: [String]] = [:] // Track recently used exercises per muscle group
        
        for (muscleGroup, count) in settings.exercisesPerMuscleGroup {
            guard let exercises = exercisesByMuscleGroup[muscleGroup],
                  count > 0 else { continue }
            
            // Filter out already selected exercises
            let available = exercises.filter { !usedExercises.contains($0.name) }
            
            // Get recently used exercises for this muscle group
            let recent = lastUsedExercises[muscleGroup] ?? []
            
            // Prioritize exercises not recently used
            let prioritized = available.sorted { ex1, ex2 in
                let ex1Recent = recent.contains(ex1.name)
                let ex2Recent = recent.contains(ex2.name)
                if ex1Recent != ex2Recent {
                    return !ex1Recent // Prefer non-recent
                }
                return false // Otherwise random order
            }
            
            // Shuffle and take the requested number
            let shuffled = prioritized.shuffled()
            let selected = Array(shuffled.prefix(count))
            let selectedNames = selected.map { $0.name }
            selectedExercises.append(contentsOf: selectedNames)
            usedExercises.formUnion(selectedNames)
            
            // Update recently used exercises
            lastUsedExercises[muscleGroup] = selectedNames
        }
        
        // Add calisthenics if enabled
        if settings.includeCalisthenics {
            let calisthenicsExercises = allExercises.filter { $0.category == "Calisthenics" }
            let selected = calisthenicsExercises.shuffled().prefix(2)
            selectedExercises.append(contentsOf: selected.map { $0.name })
        }
        
        // Limit to max exercises
        if selectedExercises.count > settings.maxExercises {
            selectedExercises = Array(selectedExercises.shuffled().prefix(settings.maxExercises))
        }
        
        // Ensure minimum exercises
        if selectedExercises.count < settings.minExercises {
            // Add more exercises to reach minimum
            let remaining = settings.minExercises - selectedExercises.count
            let additional = availableExercises
                .filter { !selectedExercises.contains($0.name) }
                .shuffled()
                .prefix(remaining)
            selectedExercises.append(contentsOf: additional.map { $0.name })
        }
        
        // Shuffle final list for variety
        selectedExercises = selectedExercises.shuffled()
        
        // Calculate estimated duration (3-4 minutes per exercise)
        let estimatedDuration = selectedExercises.count * 4
        
        // Generate workout name if not provided
        let workoutName = name ?? generateWorkoutName(settings: settings)
        
        // Convert exercise names to TemplateExercise format with intelligent defaults
        let templateExercises = selectedExercises.enumerated().map { index, exerciseName in
            // Vary sets and reps based on exercise position and type
            let sets: Int
            let reps: String
            
            // First exercise: more sets for main compound movement
            if index == 0 {
                sets = 4
                reps = "5-8"
            } else if index < 3 {
                // Second and third: moderate sets
                sets = 3
                reps = "8-10"
            } else {
                // Later exercises: fewer sets, higher reps
                sets = 3
                reps = "10-12"
            }
            
            return TemplateExercise(
                name: exerciseName,
                sets: sets,
                reps: reps,
                dropsets: index >= selectedExercises.count - 2, // Allow dropsets on last 2 exercises
                exerciseType: .weightReps
            )
        }
        
        return WorkoutTemplate(
            name: workoutName,
            exercises: templateExercises,
            estimatedDuration: estimatedDuration
        )
    }
    
    // Generate multiple workout variations
    func generateWorkoutVariations(settings: WorkoutGenerationSettings, count: Int) -> [WorkoutTemplate] {
        var workouts: [WorkoutTemplate] = []
        var usedNames: Set<String> = []
        
        for i in 1...count {
            var workoutName = "Generated Workout \(i)"
            var attempts = 0
            while usedNames.contains(workoutName) && attempts < 10 {
                attempts += 1
                workoutName = "Generated Workout \(i) (\(attempts))"
            }
            usedNames.insert(workoutName)
            
            let workout = generateWorkout(settings: settings, name: workoutName)
            workouts.append(workout)
        }
        
        return workouts
    }
    
    // Generate workout name based on settings
    private func generateWorkoutName(settings: WorkoutGenerationSettings) -> String {
        let muscleGroups = settings.exercisesPerMuscleGroup.keys.filter { 
            settings.getExerciseCount(for: $0) > 0 
        }
        
        if muscleGroups.count <= 2 {
            return "\(muscleGroups.joined(separator: " & ")) Focus"
        } else if muscleGroups.count <= 4 {
            return "Full Body Workout"
        } else {
            return "Upper Body Focus"
        }
    }
    
    // Generate specific workout types
    func generatePushWorkout(settings: WorkoutGenerationSettings) -> WorkoutTemplate {
        var pushSettings = settings
        // Push muscles: Chest (pushing), Triceps (assisting push), Shoulders (anterior deltoids for overhead press)
        pushSettings.exercisesPerMuscleGroup = [
            "Chest": 2,
            "Shoulders": 1,
            "Triceps": 1
        ]
        pushSettings.exercisesPerMuscleGroup["Lats"] = 0
        pushSettings.exercisesPerMuscleGroup["Biceps"] = 0
        pushSettings.exercisesPerMuscleGroup["Quads"] = 0
        pushSettings.exercisesPerMuscleGroup["Hamstrings"] = 0
        pushSettings.exercisesPerMuscleGroup["Glutes"] = 0
        pushSettings.exercisesPerMuscleGroup["Calves"] = 0
        pushSettings.exercisesPerMuscleGroup["Abs"] = 0
        pushSettings.exercisesPerMuscleGroup["Obliques"] = 0
        pushSettings.exercisesPerMuscleGroup["Upper Back"] = 0
        pushSettings.exercisesPerMuscleGroup["Traps"] = 0
        pushSettings.exercisesPerMuscleGroup["Lower Back"] = 0
        pushSettings.exercisesPerMuscleGroup["Forearms"] = 0
        
        return generateWorkout(settings: pushSettings, name: "Push Day")
    }
    
    func generatePullWorkout(settings: WorkoutGenerationSettings) -> WorkoutTemplate {
        var pullSettings = settings
        // Pull muscles: Lats (pulling movements - rows, pull-ups), Biceps (assisting pull)
        pullSettings.exercisesPerMuscleGroup = [
            "Lats": 3,
            "Biceps": 1
        ]
        pullSettings.exercisesPerMuscleGroup["Chest"] = 0
        pullSettings.exercisesPerMuscleGroup["Triceps"] = 0
        pullSettings.exercisesPerMuscleGroup["Shoulders"] = 0
        pullSettings.exercisesPerMuscleGroup["Quads"] = 0
        pullSettings.exercisesPerMuscleGroup["Hamstrings"] = 0
        pullSettings.exercisesPerMuscleGroup["Glutes"] = 0
        pullSettings.exercisesPerMuscleGroup["Calves"] = 0
        pullSettings.exercisesPerMuscleGroup["Abs"] = 0
        pullSettings.exercisesPerMuscleGroup["Obliques"] = 0
        pullSettings.exercisesPerMuscleGroup["Upper Back"] = 0
        pullSettings.exercisesPerMuscleGroup["Traps"] = 0
        pullSettings.exercisesPerMuscleGroup["Lower Back"] = 0
        pullSettings.exercisesPerMuscleGroup["Forearms"] = 0
        
        return generateWorkout(settings: pullSettings, name: "Pull Day")
    }
    
    func generateLegWorkout(settings: WorkoutGenerationSettings) -> WorkoutTemplate {
        var legSettings = settings
        // Leg muscles: Quads, Hamstrings, Glutes, Calves
        legSettings.exercisesPerMuscleGroup = [
            "Quads": 2,
            "Hamstrings": 1,
            "Glutes": 1,
            "Calves": 1
        ]
        legSettings.exercisesPerMuscleGroup["Chest"] = 0
        legSettings.exercisesPerMuscleGroup["Lats"] = 0
        legSettings.exercisesPerMuscleGroup["Shoulders"] = 0
        legSettings.exercisesPerMuscleGroup["Biceps"] = 0
        legSettings.exercisesPerMuscleGroup["Triceps"] = 0
        legSettings.exercisesPerMuscleGroup["Abs"] = 0
        legSettings.exercisesPerMuscleGroup["Obliques"] = 0
        legSettings.exercisesPerMuscleGroup["Upper Back"] = 0
        legSettings.exercisesPerMuscleGroup["Traps"] = 0
        legSettings.exercisesPerMuscleGroup["Lower Back"] = 0
        legSettings.exercisesPerMuscleGroup["Forearms"] = 0
        
        return generateWorkout(settings: legSettings, name: "Leg Day")
    }
    
    func generateFullBodyWorkout(settings: WorkoutGenerationSettings) -> WorkoutTemplate {
        var fullBodySettings = settings
        // Reduce per muscle group for full body
        for key in fullBodySettings.exercisesPerMuscleGroup.keys {
            fullBodySettings.exercisesPerMuscleGroup[key] = max(1, (fullBodySettings.exercisesPerMuscleGroup[key] ?? 1) / 2)
        }
        
        return generateWorkout(settings: fullBodySettings, name: "Full Body")
    }
}

