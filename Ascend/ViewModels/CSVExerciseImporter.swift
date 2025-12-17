import Foundation

// MARK: - CSV Exercise Row
struct CSVExerciseRow {
    let title: String
    let description: String
    let type: String
    let bodyPart: String
    let equipment: String
    let level: String
    let rating: String
    let ratingDesc: String
}

// MARK: - CSV Exercise Importer
class CSVExerciseImporter {
    static let shared = CSVExerciseImporter()
    
    private init() {}
    
    // MARK: - Main Import Function
    
    /// Import exercises from CSV file and add them to ExRxDirectoryManager
    func importExercisesFromFile(at csvPath: String) throws -> ImportStats {
        let (exercises, stats) = try importExercises(from: csvPath)
        
        // Import into ExRxDirectoryManager
        ExRxDirectoryManager.shared.importExercises(exercises)
        
        return stats
    }
    
    func importExercises(from csvPath: String) throws -> (exercises: [ExRxExercise], stats: ImportStats) {
        let csvContent = try String(contentsOfFile: csvPath, encoding: .utf8)
        let rows = try parseCSV(content: csvContent)
        
        Logger.info("📊 Parsed \(rows.count) rows from CSV", category: .general)
        
        // Convert CSV rows to ExRxExercise objects
        var exercises: [ExRxExercise] = []
        var skippedCount = 0
        
        for (index, row) in rows.enumerated() {
            // Skip header row
            if index == 0 { continue }
            
            // Validate required fields
            guard !row.title.isEmpty else {
                skippedCount += 1
                continue
            }
            
            // Map fields to ExRxExercise
            if let exercise = mapCSVRowToExercise(row: row, index: index) {
                exercises.append(exercise)
            } else {
                skippedCount += 1
            }
        }
        
        Logger.info("✅ Mapped \(exercises.count) exercises (skipped \(skippedCount))", category: .general)
        
        // Deduplicate exercises
        let (deduplicatedExercises, dedupStats) = deduplicateExercises(exercises)
        
        let stats = ImportStats(
            totalRows: rows.count - 1, // Exclude header
            parsed: exercises.count,
            skipped: skippedCount,
            duplicatesRemoved: dedupStats.duplicatesRemoved,
            finalCount: deduplicatedExercises.count
        )
        
        Logger.info("📈 Import stats: \(stats)", category: .general)
        
        return (deduplicatedExercises, stats)
    }
    
    // MARK: - CSV Parsing
    
    private func parseCSV(content: String) throws -> [CSVExerciseRow] {
        var rows: [CSVExerciseRow] = []
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            
            let fields = parseCSVLine(line)
            guard fields.count >= 9 else { continue } // Need at least 9 fields
            
            let row = CSVExerciseRow(
                title: fields[1].trimmingCharacters(in: .whitespaces),
                description: fields[2].trimmingCharacters(in: .whitespaces),
                type: fields[3].trimmingCharacters(in: .whitespaces),
                bodyPart: fields[4].trimmingCharacters(in: .whitespaces),
                equipment: fields[5].trimmingCharacters(in: .whitespaces),
                level: fields[6].trimmingCharacters(in: .whitespaces),
                rating: fields[7].trimmingCharacters(in: .whitespaces),
                ratingDesc: fields[8].trimmingCharacters(in: .whitespaces)
            )
            
            rows.append(row)
        }
        
        return rows
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        let chars = Array(line)
        var i = 0
        
        while i < chars.count {
            let char = chars[i]
            
            if char == "\"" {
                // Check for escaped quote ("")
                if i + 1 < chars.count && chars[i + 1] == "\"" {
                    currentField.append("\"")
                    i += 2
                    continue
                }
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
            
            i += 1
        }
        
        // Add the last field
        fields.append(currentField)
        
        return fields
    }
    
    // MARK: - Field Mapping
    
    private func mapCSVRowToExercise(row: CSVExerciseRow, index: Int) -> ExRxExercise? {
        // Map BodyPart to MuscleGroup
        let muscleGroup = mapBodyPartToMuscleGroup(row.bodyPart)
        
        // Map Equipment
        let equipment = mapEquipment(row.equipment)
        
        // Map Type to Category (pass equipment to check for bodyweight exercises)
        let category = mapTypeToCategory(row.type, bodyPart: row.bodyPart, equipment: equipment)
        
        // Generate ID
        let id = generateExerciseID(from: row.title, index: index)
        
        // Create alternatives list (could be enhanced with similar exercises)
        let alternatives: [String]? = nil // Can be populated later if needed
        
        return ExRxExercise(
            id: id,
            name: row.title,
            category: category,
            muscleGroup: muscleGroup,
            equipment: equipment,
            url: nil,
            alternatives: alternatives
        )
    }
    
    // MARK: - BodyPart → MuscleGroup Mapping
    
    private func mapBodyPartToMuscleGroup(_ bodyPart: String) -> String {
        let normalized = bodyPart.lowercased().trimmingCharacters(in: .whitespaces)
        
        switch normalized {
        case "abdominals":
            return "Abs"
        case "quadriceps":
            return "Quads"
        case "lower back":
            // Lower back exercises (like hyperextensions) - map to Hamstrings for deadlift-like movements
            // This ensures they appear in Legs/Lower days
            return "Hamstrings"
        case "middle back":
            // Middle back typically refers to rowing movements which primarily target lats
            // Map to "Lats" so exercises appear in Pull/Upper days
            return "Lats"
        case "lats":
            return "Lats"
        case "biceps":
            return "Biceps"
        case "triceps":
            return "Triceps"
        case "chest":
            return "Chest"
        case "shoulders":
            return "Shoulders"
        case "hamstrings":
            return "Hamstrings"
        case "glutes":
            return "Glutes"
        case "calves":
            return "Calves"
        case "forearms":
            // Forearm exercises often work with biceps/triceps, map to Biceps for Pull days
            return "Biceps"
        case "traps":
            // Trap exercises are typically done with shoulders (shrugs, etc.)
            // Map to "Shoulders" so they appear in Push/Pull/Upper days
            return "Shoulders"
        case "abductors", "adductors":
            return "Glutes"
        case "neck":
            // Neck exercises are rare, but if present, map to Shoulders/Traps
            return "Shoulders"
        default:
            // Fallback to original if not recognized
            return bodyPart
        }
    }
    
    // MARK: - Equipment Mapping
    
    private func mapEquipment(_ equipment: String) -> String? {
        let normalized = equipment.lowercased().trimmingCharacters(in: .whitespaces)
        
        switch normalized {
        case "body only", "none":
            return "Bodyweight"
        case "e-z curl bar":
            return "Barbell"
        case "exercise ball", "foam roll", "medicine ball", "other":
            return "Other"
        case "bands":
            return "Bands"
        case "barbell":
            return "Barbell"
        case "cable":
            return "Cable"
        case "dumbbell":
            return "Dumbbell"
        case "kettlebells":
            return "Kettlebells"
        case "machine":
            return "Machine"
        default:
            return equipment.isEmpty ? nil : equipment
        }
    }
    
    // MARK: - Type → Category Mapping
    
    private func mapTypeToCategory(_ type: String, bodyPart: String, equipment: String?) -> String {
        // If equipment is Bodyweight, tag as Calisthenics
        if equipment == "Bodyweight" {
            return "Calisthenics"
        }
        
        let normalizedType = type.lowercased().trimmingCharacters(in: .whitespaces)
        
        switch normalizedType {
        case "cardio":
            return "Cardio"
        case "stretching":
            return "Stretching"
        case "warmup", "warm-up", "warm up":
            return "Warmup"
        case "plyometrics":
            return "Calisthenics"
        case "strength", "powerlifting", "olympic weightlifting", "strongman":
            // Determine category from BodyPart
            return mapBodyPartToCategory(bodyPart)
        default:
            return "Core" // Default fallback
        }
    }
    
    private func mapBodyPartToCategory(_ bodyPart: String) -> String {
        let normalized = bodyPart.lowercased()
        
        switch normalized {
        case "chest":
            return "Chest"
        case "lats", "middle back", "lower back", "traps":
            return "Back"
        case "shoulders":
            return "Shoulders"
        case "biceps", "triceps", "forearms":
            return "Arms"
        case "quadriceps", "hamstrings", "glutes", "calves", "abductors", "adductors":
            return "Legs"
        case "abdominals":
            return "Core"
        default:
            return "Core"
        }
    }
    
    // MARK: - Secondary Muscle Group Detection
    
    private func detectSecondaryMuscleGroups(description: String, name: String, primaryMuscleGroup: String) -> [String] {
        var secondary: [String] = []
        let lowerDesc = description.lowercased()
        let lowerName = name.lowercased()
        
        // Check for rotation/twist (obliques)
        if (lowerDesc.contains("oblique") || lowerDesc.contains("twist") || lowerDesc.contains("rotation") ||
            lowerName.contains("twist") || lowerName.contains("rotation")) && primaryMuscleGroup != "Obliques" {
            secondary.append("Obliques")
        }
        
        // Check for core/abs mentions
        if (lowerDesc.contains("core") || lowerDesc.contains("abdominal") || lowerDesc.contains("six-pack")) &&
            primaryMuscleGroup != "Abs" && primaryMuscleGroup != "Obliques" {
            secondary.append("Abs")
        }
        
        // Check for lower back
        if (lowerDesc.contains("lower back") || lowerDesc.contains("lumbar")) &&
            primaryMuscleGroup != "Lower Back" {
            secondary.append("Lower Back")
        }
        
        return secondary
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
        
        return "csv-\(normalized)-\(index)"
    }
    
    // MARK: - Deduplication
    
    private func deduplicateExercises(_ exercises: [ExRxExercise]) -> ([ExRxExercise], DeduplicationStats) {
        var groups: [String: [ExRxExercise]] = [:]
        var duplicatesRemoved = 0
        
        // Group exercises by normalized name
        for exercise in exercises {
            let normalized = normalizeExerciseName(exercise.name)
            if groups[normalized] == nil {
                groups[normalized] = []
            }
            groups[normalized]?.append(exercise)
        }
        
        // Select best exercise from each group
        var deduplicated: [ExRxExercise] = []
        
        for (_, group) in groups {
            if group.count == 1 {
                deduplicated.append(group[0])
            } else {
                // Multiple exercises with same normalized name - select best one
                if let best = selectBestExercise(from: group) {
                    deduplicated.append(best)
                    duplicatesRemoved += group.count - 1
                }
            }
        }
        
        let stats = DeduplicationStats(duplicatesRemoved: duplicatesRemoved)
        return (deduplicated, stats)
    }
    
    private func normalizeExerciseName(_ name: String) -> String {
        var normalized = name.lowercased()
        
        // Remove trainer-specific prefixes
        let trainerPrefixes = ["fyr", "fyr2", "holman", "metaburn", "kv", "hm", "taylor", "otis"]
        for prefix in trainerPrefixes {
            if normalized.hasPrefix(prefix + " ") {
                normalized = String(normalized.dropFirst(prefix.count + 1))
            }
        }
        
        // Remove position/technique modifiers
        let modifiers = [
            "on knees", "gethin variation", "30 ", "single-arm", "double", "variation",
            "fix", "alternating", "right side", "left side"
        ]
        
        for modifier in modifiers {
            normalized = normalized.replacingOccurrences(of: modifier, with: "", options: .caseInsensitive)
        }
        
        // Remove common suffixes
        normalized = normalized.replacingOccurrences(of: " - ", with: " ")
        normalized = normalized.replacingOccurrences(of: "  ", with: " ")
        
        // Remove special characters for comparison
        normalized = normalized
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        return normalized
    }
    
    private func selectBestExercise(from exercises: [ExRxExercise]) -> ExRxExercise? {
        guard !exercises.isEmpty else { return nil }
        
        // Priority order:
        // 1. Has description (we can't check this from ExRxExercise, so we'll use other criteria)
        // 2. Shorter, cleaner name (fewer special characters, no trainer prefixes)
        // 3. Most common equipment type
        // 4. First one if all else equal
        
        return exercises.sorted { ex1, ex2 in
            // Prefer shorter names
            let name1Clean = cleanExerciseName(ex1.name)
            let name2Clean = cleanExerciseName(ex2.name)
            
            if name1Clean.count != name2Clean.count {
                return name1Clean.count < name2Clean.count
            }
            
            // Prefer names without trainer prefixes
            let hasPrefix1 = hasTrainerPrefix(ex1.name)
            let hasPrefix2 = hasTrainerPrefix(ex2.name)
            
            if hasPrefix1 != hasPrefix2 {
                return !hasPrefix1 // Prefer the one without prefix
            }
            
            // Prefer names without special modifiers
            let hasModifier1 = hasSpecialModifier(ex1.name)
            let hasModifier2 = hasSpecialModifier(ex2.name)
            
            if hasModifier1 != hasModifier2 {
                return !hasModifier1 // Prefer the one without modifier
            }
            
            // If all equal, keep first
            return false
        }.first
    }
    
    private func cleanExerciseName(_ name: String) -> String {
        return name
            .replacingOccurrences(of: " - ", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }
    
    private func hasTrainerPrefix(_ name: String) -> Bool {
        let lower = name.lowercased()
        let prefixes = ["fyr", "fyr2", "holman", "metaburn", "kv", "hm", "taylor", "otis"]
        return prefixes.contains { lower.hasPrefix($0 + " ") }
    }
    
    private func hasSpecialModifier(_ name: String) -> Bool {
        let lower = name.lowercased()
        let modifiers = ["on knees", "gethin variation", "30 ", "variation", "fix"]
        return modifiers.contains { lower.contains($0) }
    }
}

// MARK: - Import Statistics

struct ImportStats {
    let totalRows: Int
    let parsed: Int
    let skipped: Int
    let duplicatesRemoved: Int
    let finalCount: Int
}

struct DeduplicationStats {
    let duplicatesRemoved: Int
}

extension ImportStats: CustomStringConvertible {
    var description: String {
        return "Total: \(totalRows), Parsed: \(parsed), Skipped: \(skipped), Duplicates Removed: \(duplicatesRemoved), Final: \(finalCount)"
    }
}

