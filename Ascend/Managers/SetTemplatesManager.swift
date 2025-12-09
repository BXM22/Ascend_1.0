import Foundation
import Combine

struct SetTemplate: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var weight: Double
    var reps: Int
    
    init(id: UUID = UUID(), name: String, weight: Double, reps: Int) {
        self.id = id
        self.name = name
        self.weight = weight
        self.reps = reps
    }
}

class SetTemplatesManager: ObservableObject {
    static let shared = SetTemplatesManager()
    
    @Published private(set) var templates: [SetTemplate] = []
    
    private let templatesKey = AppConstants.UserDefaultsKeys.setTemplates
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadTemplates()
        setupAutoSave()
    }
    
    func addTemplate(name: String, weight: Double, reps: Int) {
        // Validate inputs
        guard weight >= 0, reps > 0, reps <= 1000 else {
            Logger.error("Invalid template values: weight=\(weight), reps=\(reps)", category: .validation)
            return
        }
        
        // Check for duplicates (same weight and reps)
        if templates.contains(where: { abs($0.weight - weight) < 0.1 && $0.reps == reps }) {
            return // Don't add duplicate
        }
        
        let template = SetTemplate(name: name, weight: weight, reps: reps)
        templates.append(template)
    }
    
    func deleteTemplate(_ template: SetTemplate) {
        templates.removeAll { $0.id == template.id }
    }
    
    func updateTemplate(_ template: SetTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
        }
    }
    
    func createTemplateFromCurrent(weight: Double, reps: Int) -> SetTemplate {
        let name = "\(Int(weight)) lbs × \(reps) reps"
        return SetTemplate(name: name, weight: weight, reps: reps)
    }
    
    private func setupAutoSave() {
        $templates
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.saveTemplates()
            }
            .store(in: &cancellables)
    }
    
    private func saveTemplates() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            do {
                let encoded = try JSONEncoder().encode(self.templates)
                UserDefaults.standard.set(encoded, forKey: self.templatesKey)
            } catch {
                Logger.error("Failed to save set templates", error: error, category: .persistence)
            }
        }
    }
    
    private func loadTemplates() {
        guard let data = UserDefaults.standard.data(forKey: templatesKey) else {
            templates = []
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([SetTemplate].self, from: data)
            templates = decoded
        } catch {
            Logger.error("Failed to load set templates", error: error, category: .persistence)
            templates = []
        }
    }
}

