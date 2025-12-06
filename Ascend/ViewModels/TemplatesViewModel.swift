import Foundation
import SwiftUI
import Combine

class TemplatesViewModel: ObservableObject {
    @Published var templates: [WorkoutTemplate] = [] {
        didSet {
            // Debounce saves to avoid excessive UserDefaults writes
            PerformanceOptimizer.shared.debouncedSave {
                self.saveTemplates()
            }
        }
    }
    @Published var generationSettings = WorkoutGenerationSettings()
    @Published var showGenerationSettings = false
    
    private let templatesKey = "savedWorkoutTemplates"
    
    init() {
        loadTemplates()
    }
    
    func loadTemplates() {
        // Load saved templates from UserDefaults
        if let data = UserDefaults.standard.data(forKey: templatesKey),
           let decoded = try? JSONDecoder().decode([WorkoutTemplate].self, from: data) {
            templates = decoded
        } else {
            // Load sample templates if no saved data
            loadSampleTemplates()
        }
        
        // Always add calisthenics skill progression templates (these are dynamic)
        loadCalisthenicsTemplates()
    }
    
    func loadSampleTemplates() {
        let sampleTemplates = [
            WorkoutTemplate(
                name: "Push Day",
                exercises: ["Bench Press", "Overhead Press", "Incline Dumbbell", "Tricep Dips", "Lateral Raises", "Chest Flyes"],
                estimatedDuration: 60
            ),
            WorkoutTemplate(
                name: "Pull Day",
                exercises: ["Deadlift", "Pull-ups", "Barbell Rows", "Cable Rows", "Face Pulls"],
                estimatedDuration: 50
            ),
            WorkoutTemplate(
                name: "Leg Day",
                exercises: ["Squat", "Romanian Deadlift", "Leg Press", "Leg Curls", "Calf Raises", "Lunges", "Leg Extensions"],
                estimatedDuration: 70
            )
        ]
        
        // Only add sample templates if we have no saved templates
        if templates.isEmpty {
            templates = sampleTemplates
        }
    }
    
    func loadCalisthenicsTemplates() {
        let calisthenicsTemplates = CalisthenicsSkillManager.shared.skills.map { skill in
            // Create template with all progression levels as exercises
            let exerciseNames = skill.progressionLevels.map { "\(skill.name) - \($0.name)" }
            return WorkoutTemplate(
                name: "\(skill.name) Progression",
                exercises: exerciseNames,
                estimatedDuration: 45
            )
        }
        
        // Only add calisthenics templates if they don't already exist
        let existingProgressionNames = Set(templates.filter { $0.name.contains("Progression") }.map { $0.name })
        let newCalisthenicsTemplates = calisthenicsTemplates.filter { !existingProgressionNames.contains($0.name) }
        templates.append(contentsOf: newCalisthenicsTemplates)
    }
    
    private func saveTemplates() {
        // Filter out calisthenics progression templates before saving (they're dynamic)
        let templatesToSave = templates.filter { !$0.name.contains("Progression") }
        
        if let encoded = try? JSONEncoder().encode(templatesToSave) {
            UserDefaults.standard.set(encoded, forKey: templatesKey)
        }
    }
    
    @Published var showEditTemplate: Bool = false
    @Published var showCreateTemplate: Bool = false
    @Published var editingTemplate: WorkoutTemplate?
    
    func startTemplate(_ template: WorkoutTemplate, workoutViewModel: WorkoutViewModel) {
        workoutViewModel.startWorkoutFromTemplate(template)
    }
    
    func editTemplate(_ template: WorkoutTemplate) {
        editingTemplate = template
        showEditTemplate = true
    }
    
    func createTemplate() {
        editingTemplate = nil
        showCreateTemplate = true
    }
    
    func saveTemplate(_ template: WorkoutTemplate) {
        if let editingTemplate = editingTemplate,
           let index = templates.firstIndex(where: { $0.id == editingTemplate.id }) {
            // Update existing template
            templates[index] = template
        } else {
            // Add new template
            templates.append(template)
        }
        // Templates are automatically saved via didSet
        showEditTemplate = false
        showCreateTemplate = false
        editingTemplate = nil
    }
    
    func deleteTemplate(_ template: WorkoutTemplate) {
        templates.removeAll { $0.id == template.id }
    }
    
    // Generate workout using WorkoutGenerator
    func generateWorkout(name: String? = nil) -> WorkoutTemplate {
        return WorkoutGenerator.shared.generateWorkout(settings: generationSettings, name: name)
    }
    
    // Generate specific workout types
    func generatePushWorkout() -> WorkoutTemplate {
        return WorkoutGenerator.shared.generatePushWorkout(settings: generationSettings)
    }
    
    func generatePullWorkout() -> WorkoutTemplate {
        return WorkoutGenerator.shared.generatePullWorkout(settings: generationSettings)
    }
    
    func generateLegWorkout() -> WorkoutTemplate {
        return WorkoutGenerator.shared.generateLegWorkout(settings: generationSettings)
    }
    
    func generateFullBodyWorkout() -> WorkoutTemplate {
        return WorkoutGenerator.shared.generateFullBodyWorkout(settings: generationSettings)
    }
    
    // Generate multiple variations
    func generateWorkoutVariations(count: Int) -> [WorkoutTemplate] {
        return WorkoutGenerator.shared.generateWorkoutVariations(settings: generationSettings, count: count)
    }
}

