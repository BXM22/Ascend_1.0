import Foundation

// MARK: - JSON Exercise Models

struct JSONExerciseDataset: Decodable {
    let push: [String: [JSONExercise]]?
    let pull: [String: [JSONExercise]]?
    let legs: [String: [JSONExercise]]?
    let cardio: [JSONExercise]?
    let stretches: [JSONExercise]?
}

struct JSONExercise: Decodable {
    let name: String
    let equipment: String
    let type: String
    let primaryMuscles: [String]?
    let musclesStretched: [String]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case equipment
        case type
        case primaryMuscles = "primary_muscles"
        case musclesStretched = "muscles_stretched"
    }
}

// MARK: - JSON Exercise Importer

final class JSONExerciseImporter {
    static let shared = JSONExerciseImporter()
    
    private init() {}
    
    /// Load exercises from bundled JSON file (exercises.json)
    func loadFromBundle() -> [ExRxExercise] {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            Logger.error("❌ exercises.json not found in app bundle", category: .general)
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            return try decode(from: data)
        } catch {
            Logger.error("❌ Failed to decode exercises.json", error: error, category: .general)
            return []
        }
    }
    
    /// Decode exercises from raw JSON data (used by tests and bundle loader)
    func decode(from data: Data) throws -> [ExRxExercise] {
        let decoder = JSONDecoder()
        let dataset = try decoder.decode(JSONExerciseDataset.self, from: data)
        return flatten(dataset)
    }
    
    // MARK: - Flatten & Mapping
    
    private func flatten(_ dataset: JSONExerciseDataset) -> [ExRxExercise] {
        var results: [ExRxExercise] = []
        var index = 0
        
        if let push = dataset.push {
            for (subgroup, exercises) in push {
                for entry in exercises {
                    results.append(mapEntry(entry, section: "push", subgroup: subgroup, index: index))
                    index += 1
                }
            }
        }
        
        if let pull = dataset.pull {
            for (subgroup, exercises) in pull {
                for entry in exercises {
                    results.append(mapEntry(entry, section: "pull", subgroup: subgroup, index: index))
                    index += 1
                }
            }
        }
        
        if let legs = dataset.legs {
            for (subgroup, exercises) in legs {
                for entry in exercises {
                    results.append(mapEntry(entry, section: "legs", subgroup: subgroup, index: index))
                    index += 1
                }
            }
        }
        
        if let cardio = dataset.cardio {
            for entry in cardio {
                results.append(mapEntry(entry, section: "cardio", subgroup: nil, index: index))
                index += 1
            }
        }
        
        if let stretches = dataset.stretches {
            for entry in stretches {
                results.append(mapEntry(entry, section: "stretches", subgroup: nil, index: index))
                index += 1
            }
        }
        
        Logger.info("📚 Loaded \(results.count) exercises from JSON dataset", category: .general)
        return results
    }
    
    private func mapEntry(_ entry: JSONExercise, section: String, subgroup: String?, index: Int) -> ExRxExercise {
        let id = generateExerciseID(from: entry.name, index: index)
        let category = mapCategory(section: section, subgroup: subgroup)
        let muscleGroup = mapMuscleGroup(
            primary: entry.primaryMuscles?.first,
            stretched: entry.musclesStretched?.first,
            section: section,
            subgroup: subgroup
        )
        let equipment = mapEquipment(entry.equipment)
        
        return ExRxExercise(
            id: id,
            name: entry.name,
            category: category,
            muscleGroup: muscleGroup,
            equipment: equipment,
            url: nil,
            alternatives: nil
        )
    }
    
    // MARK: - Category / Muscle Group / Equipment Mapping
    
    private func mapCategory(section: String, subgroup: String?) -> String {
        let s = section.lowercased()
        let g = (subgroup ?? "").lowercased()
        
        switch s {
        case "push":
            if g.contains("chest") { return "Chest" }
            if g.contains("shoulder") { return "Shoulders" }
            if g.contains("tricep") { return "Arms" }
            return "Chest"
        case "pull":
            if g.contains("back") { return "Back" }
            if g.contains("bicep") { return "Arms" }
            return "Back"
        case "legs":
            return "Legs"
        case "cardio":
            return "Cardio"
        case "stretches":
            return "Stretching"
        default:
            return "Full Body"
        }
    }
    
    private func mapMuscleGroup(primary: String?, stretched: String?, section: String, subgroup: String?) -> String {
        if let primary = primary, let mapped = mapMuscleName(primary) {
            return mapped
        }
        
        if let stretched = stretched, let mapped = mapMuscleName(stretched) {
            return mapped
        }
        
        // Fallback to subgroup or section
        if let subgroup = subgroup, let mapped = mapMuscleName(subgroup) {
            return mapped
        }
        
        switch section.lowercased() {
        case "push":
            return "Chest"
        case "pull":
            return "Back"
        case "legs":
            return "Legs"
        case "cardio":
            return "Full Body"
        case "stretches":
            return "Stretching"
        default:
            return "Full Body"
        }
    }
    
    private func mapMuscleName(_ name: String) -> String? {
        let n = name.lowercased()
        
        switch n {
        case "chest", "upper_chest", "lower_chest":
            return "Chest"
        case "triceps", "long_head_triceps":
            return "Triceps"
        case "front_delts", "lateral_delts", "rear_delts", "delts", "shoulders", "front delts", "lateral delts", "rear delts":
            return "Shoulders"
        case "lats":
            return "Lats"
        case "upper_back", "mid_back", "back":
            return "Upper Back"
        case "hamstrings":
            return "Hamstrings"
        case "quads", "quadriceps":
            return "Quads"
        case "glutes":
            return "Glutes"
        case "gastrocnemius", "soleus", "calves", "calf":
            return "Calves"
        case "biceps", "brachialis":
            return "Biceps"
        case "abs", "core":
            return "Abs"
        case "obliques":
            return "Obliques"
        case "hip_flexors", "hips":
            return "Glutes"
        case "full_body":
            return "Full Body"
        default:
            return nil
        }
    }
    
    private func mapEquipment(_ equipment: String) -> String? {
        let e = equipment.lowercased()
        
        switch e {
        case "barbell":
            return "Barbell"
        case "dumbbell":
            return "Dumbbell"
        case "machine":
            return "Machine"
        case "bodyweight":
            return "Bodyweight"
        case "bands":
            return "Bands"
        case "other":
            return "Other"
        default:
            return equipment.isEmpty ? nil : equipment
        }
    }
    
    // MARK: - ID Generation
    
    private func generateExerciseID(from name: String, index: Int) -> String {
        let normalized = name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "&", with: "and")
        
        return "json-\(normalized)-\(index)"
    }
}


