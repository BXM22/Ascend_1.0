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
    
    private let programsKey = "savedWorkoutPrograms"
    private let activeProgramKey = "activeWorkoutProgram"
    
    init() {
        loadPrograms()
        loadActiveProgram()
    }
    
    func loadPrograms() {
        // Load saved programs from UserDefaults
        if let data = UserDefaults.standard.data(forKey: programsKey),
           let decoded = try? JSONDecoder().decode([WorkoutProgram].self, from: data) {
            programs = decoded
        } else {
            // Load default programs
            loadDefaultPrograms()
        }
    }
    
    func loadDefaultPrograms() {
        // Keep the existing muscle-up program
        programs = WorkoutProgramManager.shared.programs
    }
    
    private func savePrograms() {
        if let encoded = try? JSONEncoder().encode(programs) {
            UserDefaults.standard.set(encoded, forKey: programsKey)
        }
    }
    
    func loadActiveProgram() {
        if let data = UserDefaults.standard.data(forKey: activeProgramKey),
           let decoded = try? JSONDecoder().decode(ActiveProgram.self, from: data) {
            // Verify the program still exists
            if programs.contains(where: { $0.id == decoded.programId }) {
                activeProgram = decoded
            } else {
                activeProgram = nil
            }
        }
    }
    
    private func saveActiveProgram() {
        if let active = activeProgram, let encoded = try? JSONEncoder().encode(active) {
            UserDefaults.standard.set(encoded, forKey: activeProgramKey)
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
            return WorkoutGenerator.shared.generateWorkout(settings: settings, name: day.name)
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
            return WorkoutGenerator.shared.generateWorkout(settings: settings, name: day.name)
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
            return WorkoutGenerator.shared.generateWorkout(settings: settings, name: day.name)
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
            return WorkoutGenerator.shared.generateWorkout(settings: settings, name: day.name)
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
            return WorkoutGenerator.shared.generateWorkout(settings: settings, name: day.name)
        }
        
        // Default: generate custom workout
        return WorkoutGenerator.shared.generateWorkout(settings: settings, name: day.name)
    }
    
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
}

