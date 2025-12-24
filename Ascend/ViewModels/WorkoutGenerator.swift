import Foundation

class WorkoutGenerator {
    static let shared = WorkoutGenerator()
    
    private init() {}
    
    // MARK: - Helper Methods
    
    /// Get training phase from settings
    private func getTrainingPhase(from settings: WorkoutGenerationSettings) -> TrainingPhase {
        switch (settings.trainingType, settings.trainingGoal) {
        case (.endurance, _):
            return .endurance
        case (_, .bulk):
            return .bulking
        case (_, .cut):
            return .cutting
        }
    }
    
    /// Get target exercise count for a phase and workout type
    private func getTargetExerciseCount(for phase: TrainingPhase, workoutType: String) -> Int {
        let typeLower = workoutType.lowercased()
        let isPPL = typeLower.contains("push") || typeLower.contains("pull") || typeLower.contains("leg")
        let isUpperLower = typeLower.contains("upper") || typeLower.contains("lower")
        let isFullBody = typeLower.contains("full") || typeLower.contains("body")
        
        switch phase {
        case .bulking:
            if isPPL {
                return Int.random(in: 5...7)
            } else if isUpperLower {
                return Int.random(in: 5...6)
            } else if isFullBody {
                return Int.random(in: 5...7)
            } else {
                return Int.random(in: 5...8)
            }
        case .cutting:
            if isPPL {
                return Int.random(in: 3...5)
            } else if isUpperLower {
                return Int.random(in: 4...5)
            } else if isFullBody {
                return Int.random(in: 4...6)
            } else {
                return Int.random(in: 3...6)
            }
        case .endurance:
            return Int.random(in: 4...6)
        }
    }
    
    /// Allowed ExRx muscle groups for a given structured day type
    private func allowedMuscleGroups(for dayType: String) -> Set<String>? {
        let lower = dayType.lowercased()
        
        // Push day: chest, shoulders, triceps, upper back, traps
        if lower.contains("push") {
            return ["Chest", "Shoulders", "Triceps", "Upper Back", "Traps"]
        }
        
        // Pull day: back, lats, biceps, forearms, traps
        if lower.contains("pull") {
            return ["Lats", "Upper Back", "Lower Back", "Biceps", "Forearms", "Traps"]
        }
        
        // Legs / Lower: lower body + supporting lower back
        if lower.contains("leg") || lower.contains("lower") {
            return ["Quads", "Hamstrings", "Glutes", "Calves", "Lower Back"]
        }
        
        // Upper: all upper body muscle groups
        if lower.contains("upper") {
            return ["Chest", "Lats", "Shoulders", "Biceps", "Triceps", "Upper Back", "Traps", "Forearms"]
        }
        
        // Full Body: allow all primary groups
        if lower.contains("full") || lower.contains("body") {
            return ["Chest", "Lats", "Shoulders", "Biceps", "Triceps", "Quads", "Hamstrings", "Glutes", "Calves", "Abs", "Obliques", "Upper Back", "Lower Back", "Traps", "Forearms"]
        }
        
        // Unknown / custom day type: don't restrict by muscle group here
        return nil
    }
    
    /// Get exercise distribution for a workout type and phase
    private func getExerciseDistribution(for phase: TrainingPhase, splitType: String, dayType: String, targetCount: Int) -> [String: Int] {
        var counts = TrainingPhase.getExerciseCounts(for: phase, splitType: splitType, dayType: dayType)
        
        // Constrain distribution to allowed muscle groups for this day type, if defined
        if let allowed = allowedMuscleGroups(for: dayType) {
            var filtered: [String: Int] = [:]
            var removedTotal = 0
            
            for (group, count) in counts {
                if allowed.contains(group) {
                    filtered[group] = count
                } else {
                    removedTotal += count
                }
            }
            
            // Redistribute any removed volume into allowed priority groups
            if removedTotal > 0 && !allowed.isEmpty {
                // Use the existing priority list, filtered to allowed groups
                let priorityBase = ["Quads", "Chest", "Lats", "Hamstrings", "Glutes", "Shoulders"]
                let priority = priorityBase.filter { allowed.contains($0) }
                var adjusted = filtered
                var remaining = removedTotal
                
                for group in priority where remaining > 0 {
                    adjusted[group] = (adjusted[group] ?? 0) + 1
                    remaining -= 1
                }
                
                counts = adjusted
            } else {
                counts = filtered
            }
        }
        
        let total = counts.values.reduce(0, +)
        
        // Adjust to match target count
        if total < targetCount {
            // Add exercises to priority groups
            let priority = ["Quads", "Chest", "Lats", "Hamstrings", "Glutes", "Shoulders"]
            var needed = targetCount - total
            var adjusted = counts
            
            for group in priority {
                if needed <= 0 { break }
                adjusted[group] = (adjusted[group] ?? 0) + 1
                needed -= 1
            }
            return adjusted
        } else if total > targetCount {
            // Remove from optional groups
            let optional = ["Biceps", "Triceps", "Calves", "Abs", "Obliques"]
            var excess = total - targetCount
            var adjusted = counts
            
            for group in optional {
                if excess <= 0 { break }
                if let current = adjusted[group], current > 0 {
                    let reduction = min(current, excess)
                    adjusted[group] = current - reduction
                    excess -= reduction
                }
            }
            return adjusted
        }
        
        return counts
    }
    
    // MARK: - Main Generation Method
    
    /// Generate a workout template based on settings
    func generateWorkout(settings: WorkoutGenerationSettings, name: String? = nil, workoutDayType: String? = nil) -> WorkoutTemplate {
        let phase = getTrainingPhase(from: settings)
        let allExercises = ExRxDirectoryManager.shared.getAllExercises()
        
        // Filter available exercises
        var availableExercises = allExercises.filter { exercise in
            if exercise.category == "Calisthenics" { return false }
            guard let equipment = exercise.equipment else { return true }
            return settings.preferredEquipment.contains(equipment)
        }
        
        // Filter out warmup/stretch exercises based on settings
        if !settings.includeWarmup {
            availableExercises = availableExercises.filter { exercise in
                !exercise.name.isWarmupExercise(category: exercise.category)
            }
        }
        
        if !settings.includeStretch {
            availableExercises = availableExercises.filter { exercise in
                !exercise.name.isStretchExercise(category: exercise.category)
            }
        } else if let dayType = workoutDayType {
            // Filter stretch exercises to be relevant to the workout day type
            availableExercises = availableExercises.filter { exercise in
                if exercise.name.isStretchExercise(category: exercise.category) {
                    return isStretchRelevantToDayType(exercise: exercise, dayType: dayType)
                }
                return true // Keep all non-stretch exercises
            }
        }
        
        // If we know the workout day type, further restrict available exercises by allowed muscle groups
        if let dayType = workoutDayType,
           let allowedGroups = allowedMuscleGroups(for: dayType),
           !allowedGroups.isEmpty {
            availableExercises = availableExercises.filter { exercise in
                // Always keep warmup/stretch/cardio if enabled; they have their own filters
                if exercise.name.isWarmupExercise(category: exercise.category) ||
                    exercise.name.isStretchExercise(category: exercise.category) ||
                    exercise.name.isCardioExercise(category: exercise.category) {
                    return true
                }
                return allowedGroups.contains(exercise.muscleGroup)
            }
        }
        
        // Group by muscle group with case-insensitive matching
        var exercisesByMuscleGroup: [String: [ExRxExercise]] = [:]
        for exercise in availableExercises {
            let key = exercise.muscleGroup
            
            // Validate muscle group assignment
            let validMuscleGroups = ["Chest", "Lats", "Shoulders", "Biceps", "Triceps", "Quads", "Hamstrings", "Glutes", "Calves", "Abs", "Obliques", "Upper Back", "Lower Back", "Traps", "Forearms", "Full Body"]
            if !validMuscleGroups.contains(key) {
                Logger.error("⚠️ Exercise '\(exercise.name)' has unrecognized muscle group: '\(key)'. This may cause it to be excluded from workout generation.", category: .validation)
            }
            
            if exercisesByMuscleGroup[key] == nil {
                exercisesByMuscleGroup[key] = []
            }
            exercisesByMuscleGroup[key]?.append(exercise)
        }
        
        // Select exercises based on settings
        var selectedExercises: [String] = []
        var usedExercises = Set<String>()
        
        // Get exercise distribution from settings
        for (muscleGroup, count) in settings.exercisesPerMuscleGroup where count > 0 {
            // Find matching exercises (case-insensitive)
            var groupExercises: [ExRxExercise] = []
            
            // Try exact match
            if let exact = exercisesByMuscleGroup[muscleGroup] {
                groupExercises = exact
            } else {
                // Try case-insensitive match
                for (key, exercises) in exercisesByMuscleGroup {
                    if key.lowercased() == muscleGroup.lowercased() {
                        groupExercises = exercises
                        break
                    }
                }
            }
            
            // Log if no exercises found for requested muscle group
            if groupExercises.isEmpty {
                Logger.error("⚠️ No exercises found for muscle group '\(muscleGroup)' (requested: \(count)). This may result in fewer exercises than expected.", category: .validation)
            }
            
            // Filter out already used
            let available = groupExercises.filter { !usedExercises.contains($0.name) }
            
            // Select requested number
            let toSelect = min(count, available.count)
            let selected = Array(available.shuffled().prefix(toSelect))
            
            if selected.count < count {
                Logger.debug("📊 Selected \(selected.count) of \(count) requested exercises for \(muscleGroup) (available: \(available.count))", category: .general)
            }
            
            for exercise in selected {
                selectedExercises.append(exercise.name)
                usedExercises.insert(exercise.name)
            }
        }
        
        // Create lookup dictionary for faster exercise access (used multiple times)
        let exerciseLookup = Dictionary(uniqueKeysWithValues: allExercises.map { ($0.name, $0) })
        
        // Separate working sets from warmup/cardio
        var workingSetExercises: [String] = []
        var warmupExercises: [String] = []
        var cardioExercises: [String] = []
        
        for exerciseName in selectedExercises {
            let exercise = exerciseLookup[exerciseName]
            if exerciseName.isWarmupExercise(category: exercise?.category) ||
                exerciseName.isStretchExercise(category: exercise?.category) {
                warmupExercises.append(exerciseName)
            } else if exerciseName.isCardioExercise(category: exercise?.category) {
                cardioExercises.append(exerciseName)
            } else {
                workingSetExercises.append(exerciseName)
            }
        }
        
        // Ensure we meet min/max requirements (only for working sets)
        if workingSetExercises.count < settings.minExercises {
            let needed = settings.minExercises - workingSetExercises.count
            
            let additional = availableExercises
                .filter { exercise in
                    !selectedExercises.contains(exercise.name) &&
                    exercise.category != "Calisthenics" &&
                    exercise.name.isWorkingSetExercise(category: exercise.category)
                }
                .filter { exercise in
                    // If we know the workout day type, enforce allowed muscle groups for additional picks too
                    if let dayType = workoutDayType,
                       let allowed = allowedMuscleGroups(for: dayType),
                       !allowed.isEmpty {
                        return allowed.contains(exercise.muscleGroup)
                    }
                    return true
                }
                .shuffled()
                .prefix(needed)
            
            workingSetExercises.append(contentsOf: additional.map { $0.name })
        } else if workingSetExercises.count > settings.maxExercises {
            workingSetExercises = Array(workingSetExercises.shuffled().prefix(settings.maxExercises))
        }
        
        // Clamp warmup/stretch and cardio counts according to settings
        if settings.includeWarmup || settings.includeStretch {
            if settings.maxWarmupStretchExercises >= 0 {
                warmupExercises = Array(warmupExercises.prefix(settings.maxWarmupStretchExercises))
            }
        } else {
            warmupExercises.removeAll()
        }
        
        if settings.includeCardio {
            if settings.maxCardioExercises >= 0 {
                cardioExercises = Array(cardioExercises.prefix(settings.maxCardioExercises))
            }
        } else {
            cardioExercises.removeAll()
        }
        
        // Recombine: working sets + warmup/stretch + cardio
        selectedExercises = workingSetExercises + warmupExercises + cardioExercises
        
        // Convert to TemplateExercise format
        let templateExercises = selectedExercises.enumerated().map { index, exerciseName in
            let exercise = exerciseLookup[exerciseName]
            let muscleGroup = exercise?.muscleGroup ?? "General"
            let isCompound = exerciseName.isCompoundExercise()
            
            // Check exercise type
            let isCardio = exerciseName.isCardioExercise(category: exercise?.category)
            
            if isCardio {
                // Cardio exercises use time instead of weight/reps
                // Generate time in seconds: 5-30 minutes (300-1800 seconds)
                let timeMinutes = Int.random(in: 5...30)
                let timeSeconds = timeMinutes * 60
                
                return TemplateExercise(
                    name: exerciseName,
                    sets: 1, // Cardio is typically one continuous session
                    reps: "Time", // Indicates time-based
                    dropsets: false,
                    exerciseType: .hold,
                    targetHoldDuration: timeSeconds
                )
            } else {
                // Regular working set exercise
                let sets = phase.getRandomSets(isCompound: isCompound, muscleGroup: muscleGroup)
                let reps = phase.getRepString(isCompound: isCompound, muscleGroup: muscleGroup)
                
                // Only apply dropsets to working sets, and only to the last 2 working set exercises
                let workingSetIndex = workingSetExercises.firstIndex(of: exerciseName) ?? -1
                let dropsets = workingSetIndex >= workingSetExercises.count - 2 && workingSetIndex >= 0
                
                return TemplateExercise(
                    name: exerciseName,
                    sets: sets,
                    reps: reps,
                    dropsets: dropsets,
                    exerciseType: .weightReps
                )
            }
        }
        
        // Sort exercises by type: warmup/stretch → working sets → cardio
        // Within each category, maintain compound-first sorting
        let sortedTemplateExercises = templateExercises.sorted { ex1, ex2 in
            let exercise1 = exerciseLookup[ex1.name]
            let exercise2 = exerciseLookup[ex2.name]
            
            let priority1 = ex1.name.getExerciseTypePriority(category: exercise1?.category)
            let priority2 = ex2.name.getExerciseTypePriority(category: exercise2?.category)
            
            // First sort by type priority
            if priority1 != priority2 {
                return priority1 < priority2
            }
            
            // Within same type, sort compounds first (only for working sets)
            if priority1 == 1 { // Working sets
                return ex1.name.isCompoundExercise() && !ex2.name.isCompoundExercise()
            }
            
            // For warmup/stretch/cardio, maintain original order
            return false
        }
        
        let workoutName = name ?? generateWorkoutName(settings: settings)
        let estimatedDuration = selectedExercises.count * 4
        
        return WorkoutTemplate(
            name: workoutName,
            exercises: sortedTemplateExercises,
            estimatedDuration: estimatedDuration
        )
    }
    
    
    /// Check if a stretch exercise is relevant to the workout day type
    private func isStretchRelevantToDayType(exercise: ExRxExercise, dayType: String) -> Bool {
        let dayTypeLower = dayType.lowercased()
        let muscleGroup = exercise.muscleGroup.lowercased()
        let exerciseName = exercise.name.lowercased()
        
        // Push day: chest, shoulders, triceps
        if dayTypeLower.contains("push") {
            return muscleGroup == "chest" || muscleGroup == "shoulders" || muscleGroup == "triceps" ||
                   exerciseName.contains("chest") || exerciseName.contains("shoulder") || exerciseName.contains("tricep") ||
                   exerciseName.contains("pec") || exerciseName.contains("deltoid")
        }
        
        // Pull day: back, biceps, lats
        if dayTypeLower.contains("pull") {
            return muscleGroup == "lats" || muscleGroup == "upper back" || muscleGroup == "lower back" || 
                   muscleGroup == "biceps" || muscleGroup == "traps" ||
                   exerciseName.contains("back") || exerciseName.contains("bicep") || exerciseName.contains("lat") ||
                   exerciseName.contains("rhomboid") || exerciseName.contains("trap")
        }
        
        // Legs day: quads, hamstrings, glutes, calves
        if dayTypeLower.contains("leg") {
            return muscleGroup == "quads" || muscleGroup == "hamstrings" || muscleGroup == "glutes" || 
                   muscleGroup == "calves" ||
                   exerciseName.contains("quad") || exerciseName.contains("hamstring") || 
                   exerciseName.contains("glute") || exerciseName.contains("calf") || exerciseName.contains("leg")
        }
        
        // Upper day: all upper body muscles
        if dayTypeLower.contains("upper") {
            return muscleGroup == "chest" || muscleGroup == "lats" || muscleGroup == "shoulders" || 
                   muscleGroup == "biceps" || muscleGroup == "triceps" || muscleGroup == "upper back" ||
                   muscleGroup == "traps" || exerciseName.contains("upper")
        }
        
        // Lower day: all lower body muscles
        if dayTypeLower.contains("lower") {
            return muscleGroup == "quads" || muscleGroup == "hamstrings" || muscleGroup == "glutes" || 
                   muscleGroup == "calves" || exerciseName.contains("lower") || exerciseName.contains("leg")
        }
        
        // Full body: accept all stretches
        if dayTypeLower.contains("full") || dayTypeLower.contains("body") {
            return true
        }
        
        // Default: accept all stretches if day type is unclear
        return true
    }
    
    
    /// Generate workout name
    private func generateWorkoutName(settings: WorkoutGenerationSettings) -> String {
        let muscleGroups = settings.exercisesPerMuscleGroup.keys.filter { 
            settings.getExerciseCount(for: $0) > 0 
        }
        
        if muscleGroups.count <= 2 {
            return "\(muscleGroups.joined(separator: " & ")) Focus"
        } else if muscleGroups.count <= 4 {
            return "Full Body Workout"
        } else {
            return "Generated Workout"
        }
    }
    
    // MARK: - Specific Workout Type Generators
    
    func generatePushWorkout(settings: WorkoutGenerationSettings) -> WorkoutTemplate {
        var pushSettings = settings
        let phase = getTrainingPhase(from: settings)
        let targetCount = getTargetExerciseCount(for: phase, workoutType: "push")
        
        // Reset muscle groups
        for key in pushSettings.exercisesPerMuscleGroup.keys {
            pushSettings.exercisesPerMuscleGroup[key] = 0
        }
        
        // Get and apply distribution
        let distribution = getExerciseDistribution(for: phase, splitType: "ppl", dayType: "push", targetCount: targetCount)
        for (muscle, count) in distribution {
            pushSettings.exercisesPerMuscleGroup[muscle] = count
        }
        
        pushSettings.minExercises = targetCount
        pushSettings.maxExercises = targetCount
        
        return generateWorkout(settings: pushSettings, name: "Push Day", workoutDayType: "Push")
    }
    
    func generatePullWorkout(settings: WorkoutGenerationSettings) -> WorkoutTemplate {
        var pullSettings = settings
        let phase = getTrainingPhase(from: settings)
        let targetCount = getTargetExerciseCount(for: phase, workoutType: "pull")
        
        for key in pullSettings.exercisesPerMuscleGroup.keys {
            pullSettings.exercisesPerMuscleGroup[key] = 0
        }
        
        let distribution = getExerciseDistribution(for: phase, splitType: "ppl", dayType: "pull", targetCount: targetCount)
        for (muscle, count) in distribution {
            pullSettings.exercisesPerMuscleGroup[muscle] = count
        }
        
        pullSettings.minExercises = targetCount
        pullSettings.maxExercises = targetCount
        
        return generateWorkout(settings: pullSettings, name: "Pull Day", workoutDayType: "Pull")
    }
    
    func generateLegWorkout(settings: WorkoutGenerationSettings) -> WorkoutTemplate {
        var legSettings = settings
        let phase = getTrainingPhase(from: settings)
        let targetCount = getTargetExerciseCount(for: phase, workoutType: "legs")
        
        for key in legSettings.exercisesPerMuscleGroup.keys {
            legSettings.exercisesPerMuscleGroup[key] = 0
        }
        
        let distribution = getExerciseDistribution(for: phase, splitType: "ppl", dayType: "legs", targetCount: targetCount)
        for (muscle, count) in distribution {
            legSettings.exercisesPerMuscleGroup[muscle] = count
        }
        
        legSettings.minExercises = targetCount
        legSettings.maxExercises = targetCount
        
        return generateWorkout(settings: legSettings, name: "Leg Day", workoutDayType: "Legs")
    }
    
    func generateUpperWorkout(settings: WorkoutGenerationSettings) -> WorkoutTemplate {
        var upperSettings = settings
        let phase = getTrainingPhase(from: settings)
        let targetCount = getTargetExerciseCount(for: phase, workoutType: "upper")
        
        for key in upperSettings.exercisesPerMuscleGroup.keys {
            upperSettings.exercisesPerMuscleGroup[key] = 0
        }
        
        let distribution = getExerciseDistribution(for: phase, splitType: "upper/lower", dayType: "upper", targetCount: targetCount)
        for (muscle, count) in distribution {
            upperSettings.exercisesPerMuscleGroup[muscle] = count
        }
        
        upperSettings.minExercises = targetCount
        upperSettings.maxExercises = targetCount
        
        return generateWorkout(settings: upperSettings, name: "Upper Day", workoutDayType: "Upper")
    }
    
    func generateLowerWorkout(settings: WorkoutGenerationSettings) -> WorkoutTemplate {
        var lowerSettings = settings
        let phase = getTrainingPhase(from: settings)
        let targetCount = getTargetExerciseCount(for: phase, workoutType: "lower")
        
        for key in lowerSettings.exercisesPerMuscleGroup.keys {
            lowerSettings.exercisesPerMuscleGroup[key] = 0
        }
        
        let distribution = getExerciseDistribution(for: phase, splitType: "upper/lower", dayType: "lower", targetCount: targetCount)
        for (muscle, count) in distribution {
            lowerSettings.exercisesPerMuscleGroup[muscle] = count
        }
        
        lowerSettings.minExercises = targetCount
        lowerSettings.maxExercises = targetCount
        
        return generateWorkout(settings: lowerSettings, name: "Lower Day", workoutDayType: "Lower")
    }
    
    func generateFullBodyWorkout(settings: WorkoutGenerationSettings) -> WorkoutTemplate {
        var fullBodySettings = settings
        let phase = getTrainingPhase(from: settings)
        let targetCount = getTargetExerciseCount(for: phase, workoutType: "full body")
        
        for key in fullBodySettings.exercisesPerMuscleGroup.keys {
            fullBodySettings.exercisesPerMuscleGroup[key] = 0
        }
        
        let distribution = getExerciseDistribution(for: phase, splitType: "full body", dayType: "", targetCount: targetCount)
        
        // Handle Hamstrings/Glutes for full body
        var adjustedDistribution = distribution
        if distribution["Hamstrings"] == 0 && distribution["Glutes"] == 1 {
            adjustedDistribution["Hamstrings"] = 1
            adjustedDistribution["Glutes"] = 0
        }
        
        for (muscle, count) in adjustedDistribution {
            fullBodySettings.exercisesPerMuscleGroup[muscle] = count
        }
        
        fullBodySettings.minExercises = targetCount
        fullBodySettings.maxExercises = targetCount
        
        return generateWorkout(settings: fullBodySettings, name: "Full Body", workoutDayType: "Full Body")
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
            
            // Extract day type from workout name if possible
            let dayType = WorkoutDayTypeExtractor.extract(from: workoutName)
            let workout = generateWorkout(settings: settings, name: workoutName, workoutDayType: dayType)
            workouts.append(workout)
        }
        
        return workouts
    }
}
