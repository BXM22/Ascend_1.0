import Foundation
import SwiftUI
import Combine

class WorkoutProgramViewModel: ObservableObject {
    @Published var programs: [WorkoutProgram] = [] {
        didSet {
            // Debounce saves to avoid excessive UserDefaults writes
            PerformanceOptimizer.shared.debouncedSave {
                self.savePrograms()
            }
        }
    }
    
    @Published var activeProgram: ActiveProgram? {
        didSet {
            // Debounce saves to avoid excessive UserDefaults writes
            PerformanceOptimizer.shared.debouncedSave {
                self.saveActiveProgram()
            }
        }
    }
    
    private let programsKey = AppConstants.UserDefaultsKeys.savedWorkoutPrograms
    private let activeProgramKey = AppConstants.UserDefaultsKeys.activeWorkoutProgram
    
    init() {
        loadPrograms()
        loadActiveProgram()
    }
    
    func loadPrograms() {
        // Load saved programs from UserDefaults
        guard let data = UserDefaults.standard.data(forKey: programsKey) else {
            loadDefaultPrograms()
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([WorkoutProgram].self, from: data)
            programs = decoded
        } catch {
            // Invalid data, log error and load defaults
            Logger.error("Failed to load programs", error: error, category: .persistence)
            UserDefaults.standard.removeObject(forKey: programsKey)
            loadDefaultPrograms()
        }
    }
    
    func loadDefaultPrograms() {
        // Keep the existing muscle-up program
        programs = WorkoutProgramManager.shared.programs
    }
    
    private func savePrograms() {
        do {
            let encoded = try JSONEncoder().encode(programs)
            UserDefaults.standard.set(encoded, forKey: programsKey)
        } catch {
            // Log error but don't crash - program saving is not critical
            Logger.error("Failed to save programs", error: error, category: .persistence)
        }
    }
    
    func loadActiveProgram() {
        guard let data = UserDefaults.standard.data(forKey: activeProgramKey) else {
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode(ActiveProgram.self, from: data)
            // Verify the program still exists
            if programs.contains(where: { $0.id == decoded.programId }) {
                activeProgram = decoded
            } else {
                activeProgram = nil
                // Clear invalid data
                UserDefaults.standard.removeObject(forKey: activeProgramKey)
            }
        } catch {
            // Invalid data, log error and clear
            Logger.error("Failed to load active program", error: error, category: .persistence)
            UserDefaults.standard.removeObject(forKey: activeProgramKey)
        }
    }
    
    private func saveActiveProgram() {
        if let active = activeProgram {
            do {
                let encoded = try JSONEncoder().encode(active)
                UserDefaults.standard.set(encoded, forKey: activeProgramKey)
            } catch {
                // Log error but don't crash
                Logger.error("Failed to save active program", error: error, category: .persistence)
            }
        } else {
            UserDefaults.standard.removeObject(forKey: activeProgramKey)
        }
    }
    
    func setActiveProgram(_ program: WorkoutProgram) {
        activeProgram = ActiveProgram(programId: program.id, startDate: Date())
    }
    
    func clearActiveProgram() {
        activeProgram = nil
    }
    
    func getCurrentDay(for program: WorkoutProgram) -> WorkoutDay? {
        guard let active = activeProgram,
              active.programId == program.id else { return nil }
        
        let currentIndex = active.getCurrentDayIndex(totalDays: program.days.count)
        guard currentIndex < program.days.count else { return nil }
        return program.days[currentIndex]
    }
    
    func advanceToNextDay(for program: WorkoutProgram) {
        guard let active = activeProgram,
              active.programId == program.id else { return }
        
        var updated = active
        let currentIndex = active.getCurrentDayIndex(totalDays: program.days.count)
        
        // Mark current day as completed
        updated.completedDays.insert(currentIndex)
        
        // Advance to next day
        updated.currentDayIndex = (currentIndex + 1) % program.days.count
        updated.lastWorkoutDate = Date()
        activeProgram = updated
    }
    
    func markDayAsCompleted(_ dayIndex: Int, inProgram programId: UUID) {
        guard let active = activeProgram,
              active.programId == programId else { return }
        
        var updated = active
        updated.completedDays.insert(dayIndex)
        activeProgram = updated
    }
    
    func unmarkDayAsCompleted(_ dayIndex: Int, inProgram programId: UUID) {
        guard let active = activeProgram,
              active.programId == programId else { return }
        
        var updated = active
        updated.completedDays.remove(dayIndex)
        activeProgram = updated
    }
    
    func isDayCompleted(_ dayIndex: Int, inProgram programId: UUID) -> Bool {
        guard let active = activeProgram,
              active.programId == programId else { return false }
        return active.isDayCompleted(dayIndex)
    }
    
    func createProgram(name: String, description: String, splitType: WorkoutSplitType, frequency: String = "") -> WorkoutProgram {
        let dayNames = splitType.dayNames
        let days = dayNames.enumerated().map { index, dayName in
            WorkoutDay(
                dayNumber: index + 1,
                name: dayName,
                description: dayName == "Rest" ? "Rest day" : "\(dayName) workout day",
                isRestDay: dayName == "Rest"
            )
        }
        
        let program = WorkoutProgram(
            name: name,
            description: description.isEmpty ? splitType.description : description,
            days: days,
            frequency: frequency.isEmpty ? "Follow the split schedule" : frequency,
            category: .split,
            splitType: splitType
        )
        
        programs.append(program)
        return program
    }
    
    func createCustomProgram(name: String, description: String, dayNames: [String]) -> WorkoutProgram {
        let days = dayNames.enumerated().map { index, dayName in
            WorkoutDay(
                dayNumber: index + 1,
                name: dayName,
                description: dayName.lowercased().contains("rest") ? "Rest day" : "\(dayName) workout day",
                isRestDay: dayName.lowercased().contains("rest")
            )
        }
        
        let program = WorkoutProgram(
            name: name,
            description: description.isEmpty ? "Custom split program" : description,
            days: days,
            frequency: "Follow the custom split schedule",
            category: .split,
            splitType: .custom
        )
        
        programs.append(program)
        return program
    }
    
    func updateProgram(_ program: WorkoutProgram) {
        if let index = programs.firstIndex(where: { $0.id == program.id }) {
            programs[index] = program
        }
    }
    
    func deleteProgram(_ program: WorkoutProgram) {
        programs.removeAll { $0.id == program.id }
    }
    
    func assignTemplate(_ templateId: UUID, toDay dayIndex: Int, inProgram programId: UUID, templatesViewModel: TemplatesViewModel? = nil) {
        if let programIndex = programs.firstIndex(where: { $0.id == programId }),
           dayIndex < programs[programIndex].days.count {
            programs[programIndex].days[dayIndex].templateId = templateId
            // Update estimated duration from template if available
            if let templatesVM = templatesViewModel,
               let template = templatesVM.templates.first(where: { $0.id == templateId }) {
                programs[programIndex].days[dayIndex].estimatedDuration = template.estimatedDuration
            }
        }
    }
    
    func removeTemplate(fromDay dayIndex: Int, inProgram programId: UUID) {
        if let programIndex = programs.firstIndex(where: { $0.id == programId }),
           dayIndex < programs[programIndex].days.count {
            programs[programIndex].days[dayIndex].templateId = nil
            programs[programIndex].days[dayIndex].estimatedDuration = 0
        }
    }
    
    /// Generate and assign a template for a day if it doesn't have one
    /// Returns: (template, intensity, wasGenerated) - template is the generated/assigned template, intensity is the calculated intensity, wasGenerated indicates if a new template was created
    func ensureTemplateForDay(dayIndex: Int, inProgram programId: UUID, settings: WorkoutGenerationSettings, templatesViewModel: TemplatesViewModel) -> (template: WorkoutTemplate, intensity: WorkoutIntensity, wasGenerated: Bool)? {
        guard let programIndex = programs.firstIndex(where: { $0.id == programId }),
              dayIndex < programs[programIndex].days.count else {
            return nil
        }
        
        let day = programs[programIndex].days[dayIndex]
        
        // If day already has a template, return it
        if let templateId = day.templateId,
           let existingTemplate = templatesViewModel.templates.first(where: { $0.id == templateId }) {
            let intensity = calculateIntensity(from: day)
            return (existingTemplate, intensity, false)
        }
        
        // Skip rest days
        if day.isRestDay {
            return nil
        }
        
        // Generate new template based on day name
        let generatedTemplate = autoGenerateTemplate(forDay: day, inProgram: programs[programIndex], settings: settings)
        
        // Save the generated template
        templatesViewModel.saveTemplate(generatedTemplate)
        
        // Assign template to the day
        assignTemplate(generatedTemplate.id, toDay: dayIndex, inProgram: programId, templatesViewModel: templatesViewModel)
        
        // Calculate intensity from the generated template
        // Create a temporary WorkoutDay with the template's exercises to calculate intensity
        let templateExercises = generatedTemplate.exercises.map { templateExercise in
            ProgramExercise(
                name: templateExercise.name,
                sets: templateExercise.sets,
                reps: templateExercise.reps,
                notes: nil,
                exerciseType: templateExercise.exerciseType,
                targetHoldDuration: templateExercise.targetHoldDuration
            )
        }
        let tempDay = WorkoutDay(
            dayNumber: day.dayNumber,
            name: day.name,
            description: day.description,
            exercises: templateExercises,
            estimatedDuration: generatedTemplate.estimatedDuration,
            templateId: generatedTemplate.id,
            isRestDay: false
        )
        let intensity = calculateIntensity(from: tempDay)
        
        return (generatedTemplate, intensity, true)
    }
    
    func autoGenerateTemplate(forDay day: WorkoutDay, inProgram program: WorkoutProgram, settings: WorkoutGenerationSettings) -> WorkoutTemplate {
        let dayName = day.name.lowercased()
        
        // Determine workout type based on day name
        if dayName.contains("push") || (dayName.contains("chest") && dayName.contains("triceps")) {
            return WorkoutGenerator.shared.generatePushWorkout(settings: settings)
        } else if dayName.contains("pull") || (dayName.contains("back") && dayName.contains("biceps")) {
            return WorkoutGenerator.shared.generatePullWorkout(settings: settings)
        } else if dayName.contains("leg") {
            return WorkoutGenerator.shared.generateLegWorkout(settings: settings)
        } else if dayName.contains("chest") && dayName.contains("back") {
            // Chest & Back day
            var settings = settings
            settings.exercisesPerMuscleGroup = ["Chest": 2, "Lats": 2]
            settings.exercisesPerMuscleGroup["Shoulders"] = 0
            settings.exercisesPerMuscleGroup["Biceps"] = 0
            settings.exercisesPerMuscleGroup["Triceps"] = 0
            settings.exercisesPerMuscleGroup["Quads"] = 0
            settings.exercisesPerMuscleGroup["Hamstrings"] = 0
            settings.exercisesPerMuscleGroup["Glutes"] = 0
            settings.exercisesPerMuscleGroup["Calves"] = 0
            settings.exercisesPerMuscleGroup["Abs"] = 0
            settings.exercisesPerMuscleGroup["Obliques"] = 0
            let dayType = WorkoutDayTypeExtractor.extract(from: day.name)
            return WorkoutGenerator.shared.generateWorkout(settings: settings, name: day.name, workoutDayType: dayType)
        } else if dayName.contains("shoulders") && dayName.contains("arms") {
            // Shoulders & Arms day
            var settings = settings
            settings.exercisesPerMuscleGroup = ["Shoulders": 2, "Biceps": 1, "Triceps": 1]
            settings.exercisesPerMuscleGroup["Chest"] = 0
            settings.exercisesPerMuscleGroup["Lats"] = 0
            settings.exercisesPerMuscleGroup["Quads"] = 0
            settings.exercisesPerMuscleGroup["Hamstrings"] = 0
            settings.exercisesPerMuscleGroup["Glutes"] = 0
            settings.exercisesPerMuscleGroup["Calves"] = 0
            settings.exercisesPerMuscleGroup["Abs"] = 0
            settings.exercisesPerMuscleGroup["Obliques"] = 0
            let dayType = WorkoutDayTypeExtractor.extract(from: day.name)
            return WorkoutGenerator.shared.generateWorkout(settings: settings, name: day.name, workoutDayType: dayType)
        } else if dayName.contains("chest") {
            // Just Chest day
            var settings = settings
            settings.exercisesPerMuscleGroup = ["Chest": 3, "Triceps": 1]
            settings.exercisesPerMuscleGroup["Lats"] = 0
            settings.exercisesPerMuscleGroup["Shoulders"] = 0
            settings.exercisesPerMuscleGroup["Biceps"] = 0
            settings.exercisesPerMuscleGroup["Quads"] = 0
            settings.exercisesPerMuscleGroup["Hamstrings"] = 0
            settings.exercisesPerMuscleGroup["Glutes"] = 0
            settings.exercisesPerMuscleGroup["Calves"] = 0
            settings.exercisesPerMuscleGroup["Abs"] = 0
            settings.exercisesPerMuscleGroup["Obliques"] = 0
            let dayType = WorkoutDayTypeExtractor.extract(from: day.name)
            return WorkoutGenerator.shared.generateWorkout(settings: settings, name: day.name, workoutDayType: dayType)
        } else if dayName.contains("back") {
            // Just Back day
            var settings = settings
            settings.exercisesPerMuscleGroup = ["Lats": 3, "Biceps": 1]
            settings.exercisesPerMuscleGroup["Chest"] = 0
            settings.exercisesPerMuscleGroup["Shoulders"] = 0
            settings.exercisesPerMuscleGroup["Triceps"] = 0
            settings.exercisesPerMuscleGroup["Quads"] = 0
            settings.exercisesPerMuscleGroup["Hamstrings"] = 0
            settings.exercisesPerMuscleGroup["Glutes"] = 0
            settings.exercisesPerMuscleGroup["Calves"] = 0
            settings.exercisesPerMuscleGroup["Abs"] = 0
            settings.exercisesPerMuscleGroup["Obliques"] = 0
            let dayType = WorkoutDayTypeExtractor.extract(from: day.name)
            return WorkoutGenerator.shared.generateWorkout(settings: settings, name: day.name, workoutDayType: dayType)
        } else if dayName.contains("shoulders") {
            // Just Shoulders day
            var settings = settings
            settings.exercisesPerMuscleGroup = ["Shoulders": 3]
            settings.exercisesPerMuscleGroup["Chest"] = 0
            settings.exercisesPerMuscleGroup["Lats"] = 0
            settings.exercisesPerMuscleGroup["Biceps"] = 0
            settings.exercisesPerMuscleGroup["Triceps"] = 0
            settings.exercisesPerMuscleGroup["Quads"] = 0
            settings.exercisesPerMuscleGroup["Hamstrings"] = 0
            settings.exercisesPerMuscleGroup["Glutes"] = 0
            settings.exercisesPerMuscleGroup["Calves"] = 0
            settings.exercisesPerMuscleGroup["Abs"] = 0
            settings.exercisesPerMuscleGroup["Obliques"] = 0
            let dayType = WorkoutDayTypeExtractor.extract(from: day.name)
            return WorkoutGenerator.shared.generateWorkout(settings: settings, name: day.name, workoutDayType: dayType)
        } else if dayName.contains("upper") {
            return WorkoutGenerator.shared.generateUpperWorkout(settings: settings)
        } else if dayName.contains("lower") {
            return WorkoutGenerator.shared.generateLowerWorkout(settings: settings)
        } else if dayName.contains("full body") || dayName.contains("fullbody") {
            return WorkoutGenerator.shared.generateFullBodyWorkout(settings: settings)
        }
        
        // Default: generate custom workout
        let dayType = WorkoutDayTypeExtractor.extract(from: day.name)
        return WorkoutGenerator.shared.generateWorkout(settings: settings, name: day.name, workoutDayType: dayType)
    }
    
    // MARK: - Helper Functions
    
    // MARK: - Calendar Helpers
    
    /// Get the day index for a specific date based on the active program's start date
    func getDayIndex(for date: Date, inProgram programId: UUID) -> Int? {
        guard let active = activeProgram,
              active.programId == programId,
              let program = programs.first(where: { $0.id == programId }) else {
            return nil
        }
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: active.startDate)
        let targetDate = calendar.startOfDay(for: date)
        
        guard targetDate >= startDate else { return nil }
        
        let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: targetDate).day ?? 0
        return daysSinceStart % program.days.count
    }
    
    /// Get the workout day for a specific date
    func getWorkoutDay(for date: Date, inProgram programId: UUID) -> WorkoutDay? {
        guard let dayIndex = getDayIndex(for: date, inProgram: programId),
              let program = programs.first(where: { $0.id == programId }),
              dayIndex < program.days.count else {
            return nil
        }
        return program.days[dayIndex]
    }
    
    /// Check if a specific date is completed
    func isDateCompleted(_ date: Date, inProgram programId: UUID) -> Bool {
        guard let dayIndex = getDayIndex(for: date, inProgram: programId) else {
            return false
        }
        return isDayCompleted(dayIndex, inProgram: programId)
    }
    
    // MARK: - Intensity and Progress Calculation
    
    /// Calculate workout intensity from WorkoutDay data
    func calculateIntensity(from workoutDay: WorkoutDay) -> WorkoutIntensity {
        // Filter out warm-up exercises (notes contain "Warm-up")
        let mainExercises = workoutDay.exercises.filter { 
            !($0.notes?.lowercased().contains("warm-up") ?? false) 
        }
        
        // If it's a rest day, return light
        if workoutDay.isRestDay {
            return .light
        }
        
        // If no exercises, return light
        guard !mainExercises.isEmpty else {
            return .light
        }
        
        let exerciseCount = mainExercises.count
        let totalSets = mainExercises.reduce(0) { $0 + $1.sets }
        let duration = workoutDay.estimatedDuration
        
        // Scoring: exercise count (40%), sets (40%), duration (20%)
        // Normalize: exercise count (max 10), sets (max 20), duration (max 90 min)
        let exerciseScore = min(Double(exerciseCount) / 10.0, 1.0) * 0.4
        let setsScore = min(Double(totalSets) / 20.0, 1.0) * 0.4
        let durationScore = min(Double(duration) / 90.0, 1.0) * 0.2
        
        let totalScore = exerciseScore + setsScore + durationScore
        
        switch totalScore {
        case 0..<0.3:
            return .light
        case 0.3..<0.6:
            return .moderate
        case 0.6..<0.85:
            return .intense
        default:
            return .extreme
        }
    }
    
    /// Get exercise completion progress for a date (0.0 to 1.0)
    func getCompletionProgress(for date: Date, inProgram programId: UUID) -> Double {
        // Check if workout was completed for that date
        if isDateCompleted(date, inProgram: programId) {
            return 1.0
        }
        
        // Check if there's a completed workout in WorkoutHistoryManager for that date
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        
        let workouts = WorkoutHistoryManager.shared.getWorkouts(
            in: DateInterval(start: dayStart, end: dayEnd)
        )
        
        // If there's a completed workout for that date, return 1.0
        if !workouts.isEmpty {
            return 1.0
        }
        
        // Otherwise, return 0.0 (no completion)
        return 0.0
    }
    
    /// Get the next program workout template (for Dashboard quick actions)
    func nextProgramWorkout() -> WorkoutTemplate? {
        guard let active = activeProgram,
              let program = programs.first(where: { $0.id == active.programId }),
              let currentDay = getCurrentDay(for: program) else {
            return nil
        }
        
        // Convert WorkoutDay to WorkoutTemplate
        let exercises = currentDay.exercises.map { dayExercise in
            TemplateExercise(
                name: dayExercise.name,
                sets: dayExercise.sets,
                reps: dayExercise.reps,
                dropsets: false,
                exerciseType: dayExercise.exerciseType,
                targetHoldDuration: dayExercise.targetHoldDuration
            )
        }
        
        return WorkoutTemplate(
            id: UUID(),
            name: currentDay.name,
            exercises: exercises,
            estimatedDuration: currentDay.estimatedDuration,
            intensity: .moderate,
            isDefault: false
        )
    }
}

