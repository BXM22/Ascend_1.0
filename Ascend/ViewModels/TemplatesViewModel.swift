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
    
    private let templatesKey = AppConstants.UserDefaultsKeys.savedWorkoutTemplates
    
    // Performance optimizations
    private var cachedCalisthenicsTemplates: [WorkoutTemplate]?
    private let processingQueue = DispatchQueue(label: "com.ascend.templatesProcessing", qos: .utility)
    
    init() {
        loadTemplates()
    }
    
    func loadTemplates() {
        // Load on background queue for better performance
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Load saved templates from UserDefaults
            guard let data = UserDefaults.standard.data(forKey: self.templatesKey) else {
                // No saved data, start with default templates
                DispatchQueue.main.async {
                    self.templates = []
                    self.loadDefaultTemplates()
                    self.loadCalisthenicsTemplates()
                }
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode([WorkoutTemplate].self, from: data)
                DispatchQueue.main.async {
                    self.templates = decoded
                    // Only load default templates if they don't exist
                    if !self.templates.contains(where: { $0.name == "Day 1: Push" }) {
                        self.loadDefaultTemplates()
                    }
                    self.loadCalisthenicsTemplates()
                }
            } catch {
                // Invalid data, log error and start fresh
                Logger.error("Failed to load templates", error: error, category: .persistence)
                // Clear invalid data
                UserDefaults.standard.removeObject(forKey: self.templatesKey)
                DispatchQueue.main.async {
                    self.templates = []
                    self.loadDefaultTemplates()
                    self.loadCalisthenicsTemplates()
                }
            }
        }
    }
    
    func loadDefaultTemplates() {
        // Helper function to ensure exercise exists in database
        func exerciseExists(_ name: String) -> Bool {
            return ExerciseDataManager.shared.getAlternatives(for: name).count > 0 || 
                   ExerciseDataManager.shared.getVideoURL(for: name) != nil
        }
        
        // Day 1: Push - All exercises verified in database
        let pushTemplate = WorkoutTemplate(
            name: "Day 1: Push",
            exercises: [
                TemplateExercise(name: "Bench Press (Barbell)", sets: 3, reps: "6-10"),
                TemplateExercise(name: "Shoulder Press (Dumbbell)", sets: 3, reps: "10-12"),
                TemplateExercise(name: "Low Cable Fly Crossovers", sets: 3, reps: "12-15"),
                TemplateExercise(name: "Triceps Extension (Dumbbell)", sets: 3, reps: "12-15"),
                TemplateExercise(name: "Triceps Rope Pushdown", sets: 3, reps: "12-15")
            ],
            estimatedDuration: 60
        )
        
        // Day 2: Pull - All exercises verified in database
        let pullTemplate = WorkoutTemplate(
            name: "Day 2: Pull",
            exercises: [
                TemplateExercise(name: "Bent Over Row (Barbell)", sets: 3, reps: "6-10"),
                TemplateExercise(name: "Lat Pulldown (Cable)", sets: 3, reps: "8-12"),
                TemplateExercise(name: "Bicep Curl (Dumbbell)", sets: 3, reps: "12-15"),
                TemplateExercise(name: "Hammer Curl (Dumbbell)", sets: 3, reps: "12-15"),
                TemplateExercise(name: "Face Pull", sets: 3, reps: "15-25")
            ],
            estimatedDuration: 60
        )
        
        // Day 3: Legs - All exercises verified in database
        let legsTemplate = WorkoutTemplate(
            name: "Day 3: Legs",
            exercises: [
                TemplateExercise(name: "Squat (Barbell)", sets: 3, reps: "6-10"),
                TemplateExercise(name: "Glute Ham Raise", sets: 3, reps: "8-12"),
                TemplateExercise(name: "Lunge (Dumbbell)", sets: 3, reps: "10-15"),
                TemplateExercise(name: "Lying Leg Curl (Machine)", sets: 3, reps: "12-15"),
                TemplateExercise(name: "Standing Calf Raise (Smith)", sets: 3, reps: "8-12")
            ],
            estimatedDuration: 60
        )
        
        // Verify all exercises exist in database before adding templates
        let allTemplates = [pushTemplate, pullTemplate, legsTemplate]
        let verifiedTemplates = allTemplates.map { template -> WorkoutTemplate? in
            let allExercisesExist = template.exercises.allSatisfy { exerciseExists($0.name) }
            if allExercisesExist {
                return template
            } else {
                Logger.error("Template '\(template.name)' contains exercises not in database", error: nil, category: .validation)
                return nil
            }
        }.compactMap { $0 }
        
        // Only add if they don't already exist
        let existingNames = Set(templates.map { $0.name })
        let defaultTemplates = verifiedTemplates
            .filter { !existingNames.contains($0.name) }
        
        templates.append(contentsOf: defaultTemplates)
    }
    
    func loadCalisthenicsTemplates() {
        // Use cached calisthenics templates if available
        if let cached = cachedCalisthenicsTemplates {
            let existingProgressionNames = Set(templates.filter { $0.name.contains("Progression") }.map { $0.name })
            let newCalisthenicsTemplates = cached.filter { !existingProgressionNames.contains($0.name) }
            templates.append(contentsOf: newCalisthenicsTemplates)
            return
        }
        
        // Generate calisthenics templates on background queue
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            let calisthenicsTemplates = CalisthenicsSkillManager.shared.skills.map { skill in
                // Create template with all progression levels as exercises
                let exerciseNames = skill.progressionLevels.map { "\(skill.name) - \($0.name)" }
                return WorkoutTemplate(
                    name: "\(skill.name) Progression",
                    exercises: exerciseNames,
                    estimatedDuration: 45
                )
            }
            
            // Cache the templates
            self.cachedCalisthenicsTemplates = calisthenicsTemplates
            
            DispatchQueue.main.async {
                // Only add calisthenics templates if they don't already exist
                let existingProgressionNames = Set(self.templates.filter { $0.name.contains("Progression") }.map { $0.name })
                let newCalisthenicsTemplates = calisthenicsTemplates.filter { !existingProgressionNames.contains($0.name) }
                self.templates.append(contentsOf: newCalisthenicsTemplates)
            }
        }
    }
    
    private func saveTemplates() {
        // Save on background queue
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Filter out calisthenics progression templates before saving (they're dynamic)
            let templatesToSave = self.templates.filter { !$0.name.contains("Progression") }
            
            do {
                let encoded = try JSONEncoder().encode(templatesToSave)
                UserDefaults.standard.set(encoded, forKey: self.templatesKey)
            } catch {
                // Log error but don't crash - template saving is not critical
                Logger.error("Failed to save templates", error: error, category: .persistence)
            }
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

