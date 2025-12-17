import SwiftUI

struct WorkoutGenerationSettingsView: View {
    @Binding var settings: WorkoutGenerationSettings
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Header Section
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Generation Settings")
                            .font(AppTypography.largeTitleBold)
                            .foregroundStyle(LinearGradient.primaryGradient)
                        
                        Text("Training guidelines and recommendations")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.md)
                    
                    // Core Rules Section
                    CoreRulesSection()
                        .padding(.horizontal, AppSpacing.lg)
                    
                    // Bulking Phase Section
                    PhaseGuidelinesSection(
                        phase: .bulking,
                        settings: settings
                    )
                    .padding(.horizontal, AppSpacing.lg)
                    
                    // Cutting Phase Section
                    PhaseGuidelinesSection(
                        phase: .cutting,
                        settings: settings
                    )
                    .padding(.horizontal, AppSpacing.lg)
                    
                    // Endurance Phase Section
                    PhaseGuidelinesSection(
                        phase: .endurance,
                        settings: settings
                    )
                    .padding(.horizontal, AppSpacing.lg)
                    
                    // Equipment Preferences Section
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Preferred Equipment")
                            .font(AppTypography.heading2)
                            .foregroundColor(AppColors.textPrimary)
                        
                        let equipmentOptions = ["Bodyweight", "Dumbbells", "Barbell", "Cable", "Machine"]
                        
                        VStack(spacing: AppSpacing.sm) {
                            ForEach(equipmentOptions, id: \.self) { equipment in
                                Toggle(isOn: Binding(
                                    get: { settings.preferredEquipment.contains(equipment) },
                                    set: { isOn in
                                        HapticManager.impact(style: .light)
                                        if isOn {
                                            if !settings.preferredEquipment.contains(equipment) {
                                                settings.preferredEquipment.append(equipment)
                                            }
                                        } else {
                                            settings.preferredEquipment.removeAll { $0 == equipment }
                                        }
                                    }
                                )) {
                                    Text(equipment)
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColors.textPrimary)
                                }
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.sm)
                                .background(AppColors.secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                    .shadow(color: AppColors.foreground.opacity(0.06), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, AppSpacing.lg)
                    
                    // Additional Options Section
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Additional Options")
                            .font(AppTypography.heading2)
                            .foregroundColor(AppColors.textPrimary)
                        
                        VStack(spacing: AppSpacing.sm) {
                            Toggle(isOn: Binding(
                                get: { settings.includeCalisthenics },
                                set: { 
                                    HapticManager.impact(style: .light)
                                    settings.includeCalisthenics = $0 
                                }
                            )) {
                                Text("Include Calisthenics")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(AppColors.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            Toggle(isOn: Binding(
                                get: { settings.includeCardio },
                                set: { 
                                    HapticManager.impact(style: .light)
                                    settings.includeCardio = $0 
                                }
                            )) {
                                Text("Include Cardio")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(AppColors.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            Toggle(isOn: Binding(
                                get: { settings.includeWarmup },
                                set: { 
                                    HapticManager.impact(style: .light)
                                    settings.includeWarmup = $0 
                                }
                            )) {
                                Text("Include Warmup")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(AppColors.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            Toggle(isOn: Binding(
                                get: { settings.includeStretch },
                                set: { 
                                    HapticManager.impact(style: .light)
                                    settings.includeStretch = $0 
                                }
                            )) {
                                Text("Include Stretch")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(AppColors.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            // Warmup/Stretch count
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Warmup & Stretch Exercises")
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColors.textPrimary)
                                    Text("Max number per workout (0–5)")
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Spacer()
                                Stepper(
                                    value: Binding(
                                        get: { settings.maxWarmupStretchExercises },
                                        set: {
                                            HapticManager.selection()
                                            settings.maxWarmupStretchExercises = max(0, min(5, $0))
                                        }
                                    ),
                                    in: 0...5
                                ) {
                                    Text("\(settings.maxWarmupStretchExercises)")
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColors.textPrimary)
                                }
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(AppColors.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            // Cardio count
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Cardio Exercises")
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColors.textPrimary)
                                    Text("Max number per workout (0–3)")
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Spacer()
                                Stepper(
                                    value: Binding(
                                        get: { settings.maxCardioExercises },
                                        set: {
                                            HapticManager.selection()
                                            settings.maxCardioExercises = max(0, min(3, $0))
                                        }
                                    ),
                                    in: 0...3
                                ) {
                                    Text("\(settings.maxCardioExercises)")
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColors.textPrimary)
                                }
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(AppColors.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                    .shadow(color: AppColors.foreground.opacity(0.06), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

struct CoreRulesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("FULL-BODY")
                    .font(AppTypography.heading2)
                    .foregroundStyle(LinearGradient.primaryGradient)
                
                Text("— CORE RULES")
                    .font(AppTypography.heading2)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                RuleItem(icon: "calendar", text: "Train 3–4× per week")
                RuleItem(icon: "target", text: "Hit every major muscle each session")
                RuleItem(icon: "arrow.triangle.2.circlepath", text: "Fewer exercises per muscle per workout, but higher weekly frequency")
            }
            .padding(AppSpacing.md)
            .background(AppColors.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(color: AppColors.foreground.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

struct RuleItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppColors.accent)
                .frame(width: 20)
            
            Text(text)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

struct PhaseGuidelinesSection: View {
    let phase: TrainingPhase
    let settings: WorkoutGenerationSettings
    
    private var phaseColor: LinearGradient {
        switch phase {
        case .bulking:
            return LinearGradient(
                colors: [Color(hex: "16a34a"), Color(hex: "10b981")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .cutting:
            return LinearGradient(
                colors: [Color(hex: "ea580c"), Color(hex: "f59e0b")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .endurance:
            return LinearGradient(
                colors: [Color(hex: "0891b2"), Color(hex: "0ea5e9")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var exerciseCounts: [String: Int] {
        TrainingPhase.getExerciseCounts(for: phase, splitType: "full body", dayType: "")
    }
    
    private var totalExerciseCount: String {
        switch phase {
        case .bulking:
            return "5–7"
        case .cutting:
            return "4–6"
        case .endurance:
            return "4–6"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Phase Header
            HStack {
                Text(phase.rawValue.uppercased())
                    .font(AppTypography.heading2)
                    .foregroundStyle(phaseColor)
                
                if phase == .bulking {
                    Text("(Full-Body)")
                        .font(AppTypography.heading2)
                        .foregroundColor(AppColors.textPrimary)
                } else if phase == .cutting {
                    Text("(Full-Body)")
                        .font(AppTypography.heading2)
                        .foregroundColor(AppColors.textPrimary)
                } else {
                    Text("(Full-Body)")
                        .font(AppTypography.heading2)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            
            // Goal and Recovery Info
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                InfoRow(label: "Goal", value: phaseGoal)
                InfoRow(label: "Recovery", value: phaseRecovery)
                InfoRow(label: "Weekly sets/muscle", value: weeklySetsRange)
            }
            .padding(AppSpacing.md)
            .background(AppColors.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Per Workout Exercise Count
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Per Workout Exercise Count")
                    .font(AppTypography.bodyBold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("\(totalExerciseCount) total exercises")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                
                // Muscle Group Table
                VStack(spacing: AppSpacing.xs) {
                    ForEach(muscleGroupRows, id: \.muscle) { row in
                        HStack {
                            Text(row.muscle)
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(row.count)
                                .font(AppTypography.bodyBold)
                                .foregroundColor(AppColors.primary)
                        }
                        .padding(.vertical, AppSpacing.xs)
                        
                        if row.muscle != muscleGroupRows.last?.muscle {
                            Divider()
                                .background(AppColors.border)
                        }
                    }
                }
                .padding(AppSpacing.sm)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(AppSpacing.md)
            .background(AppColors.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Sets/Reps Guidelines
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Sets/Reps:")
                    .font(AppTypography.bodyBold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(setsRepsGuideline)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(AppSpacing.md)
            .background(AppColors.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(color: AppColors.foreground.opacity(0.06), radius: 4, x: 0, y: 2)
    }
    
    private var phaseGoal: String {
        switch phase {
        case .bulking:
            return "Grow muscle"
        case .cutting:
            return "Maintain muscle"
        case .endurance:
            return "Fatigue resistance"
        }
    }
    
    private var phaseRecovery: String {
        switch phase {
        case .bulking:
            return "High"
        case .cutting:
            return "Lower"
        case .endurance:
            return "Moderate"
        }
    }
    
    private var weeklySetsRange: String {
        switch phase {
        case .bulking:
            return "12–18"
        case .cutting:
            return "8–12"
        case .endurance:
            return "8–15"
        }
    }
    
    private var muscleGroupRows: [(muscle: String, count: String)] {
        let counts = exerciseCounts
        var rows: [(muscle: String, count: String)] = []
        
        // Build rows based on phase
        switch phase {
        case .bulking:
            rows = [
                ("Quads", counts["Quads"] != nil && counts["Quads"]! > 0 ? "\(counts["Quads"]!)" : "1"),
                ("Hams/Glutes", (counts["Hamstrings"] ?? 0) + (counts["Glutes"] ?? 0) > 0 ? "1" : "1"),
                ("Chest", counts["Chest"] != nil && counts["Chest"]! > 0 ? "\(counts["Chest"]!)" : "1"),
                ("Back", counts["Lats"] != nil ? "\(counts["Lats"]!)" : "1–2"),
                ("Shoulders", counts["Shoulders"] != nil && counts["Shoulders"]! > 0 ? "\(counts["Shoulders"]!)" : "0–1"),
                ("Arms", ((counts["Biceps"] ?? 0) + (counts["Triceps"] ?? 0)) > 0 ? "0–1" : "0–1")
            ]
        case .cutting:
            rows = [
                ("Quads", counts["Quads"] != nil && counts["Quads"]! > 0 ? "\(counts["Quads"]!)" : "1"),
                ("Hams/Glutes", (counts["Hamstrings"] ?? 0) + (counts["Glutes"] ?? 0) > 0 ? "1" : "1"),
                ("Chest", counts["Chest"] != nil && counts["Chest"]! > 0 ? "\(counts["Chest"]!)" : "1"),
                ("Back", counts["Lats"] != nil && counts["Lats"]! > 0 ? "\(counts["Lats"]!)" : "1"),
                ("Shoulders/Arms", ((counts["Shoulders"] ?? 0) + (counts["Biceps"] ?? 0) + (counts["Triceps"] ?? 0)) > 0 ? "0–1 total" : "0–1 total")
            ]
        case .endurance:
            rows = [
                ("Legs", ((counts["Quads"] ?? 0) + (counts["Hamstrings"] ?? 0) + (counts["Glutes"] ?? 0)) > 0 ? "2" : "2"),
                ("Push", counts["Chest"] != nil && counts["Chest"]! > 0 ? "\(counts["Chest"]!)" : "1"),
                ("Pull", counts["Lats"] != nil && counts["Lats"]! > 0 ? "\(counts["Lats"]!)" : "1–2"),
                ("Core/Arms", ((counts["Abs"] ?? 0) + (counts["Biceps"] ?? 0) + (counts["Triceps"] ?? 0)) > 0 ? "0–1" : "0–1")
            ]
        }
        
        return rows
    }
    
    private var setsRepsGuideline: String {
        switch phase {
        case .bulking:
            return "3–4 sets × 6–12 reps"
        case .cutting:
            return "2–3 sets × 5–10 reps\nKeep loads heavy"
        case .endurance:
            return "2–3 sets × 12–20 reps\nFormat: Circuits or short rest"
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(AppTypography.bodyBold)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}
