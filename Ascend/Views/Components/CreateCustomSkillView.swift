import SwiftUI

struct CreateCustomSkillView: View {
    @ObservedObject var skillManager: CalisthenicsSkillManager
    @Environment(\.dismiss) var dismiss
    
    @State private var skillName: String = ""
    @State private var skillDescription: String = ""
    @State private var selectedCategory: CalisthenicsSkill.SkillCategory = .push
    @State private var selectedIcon: String = "figure.strengthtraining.traditional"
    @State private var numberOfLevels: Int = 3
    @State private var levels: [LevelConfig] = []
    
    struct LevelConfig: Identifiable {
        let id = UUID()
        var levelNumber: Int
        var name: String = ""
        var description: String = ""
        var targetType: TargetType = .reps
        var targetReps: Int = 10
        var targetHoldDuration: Int = 30
        
        enum TargetType: String, CaseIterable {
            case reps = "Reps"
            case hold = "Hold Time"
        }
    }
    
    private let iconOptions = [
        "figure.strengthtraining.traditional",
        "figure.handpush",
        "figure.climbing",
        "figure.flexibility",
        "figure.balance",
        "flag.fill",
        "figure.seated.side",
        "figure.handstand",
        "figure.arms.open",
        "figure.core.training"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Basic Info Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Information")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppColors.foreground)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Skill Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                            
                            TextField("e.g., Iron Cross", text: $skillName)
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.foreground)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(AppColors.input)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Description")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                            
                            TextField("What makes this skill unique?", text: $skillDescription)
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.foreground)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(AppColors.input)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Category")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                            
                            Picker("Category", selection: $selectedCategory) {
                                ForEach([CalisthenicsSkill.SkillCategory.push, .pull, .core, .fullBody], id: \.self) { category in
                                    Text(category.rawValue).tag(category)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.vertical, 4)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Icon")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(iconOptions, id: \.self) { icon in
                                        Button(action: {
                                            selectedIcon = icon
                                        }) {
                                            Image(systemName: icon)
                                                .font(.system(size: 24))
                                                .foregroundColor(selectedIcon == icon ? AppColors.alabasterGrey : AppColors.foreground)
                                                .frame(width: 50, height: 50)
                                                .background(selectedIcon == icon ? LinearGradient.primaryGradient : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Levels Configuration Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Progression Levels")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppColors.foreground)
                            
                            Spacer()
                            
                            Stepper(value: $numberOfLevels, in: 1...10) {
                                Text("\(numberOfLevels) levels")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.primary)
                            }
                            .onChange(of: numberOfLevels) { _, newValue in
                                updateLevels(count: newValue)
                            }
                        }
                        
                        ForEach($levels) { $level in
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Level \(level.levelNumber)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppColors.foreground)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Name")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppColors.mutedForeground)
                                    
                                    TextField("e.g., Beginner Hold", text: $level.name)
                                        .font(.system(size: 15))
                                        .foregroundColor(AppColors.foreground)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(AppColors.input)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.border, lineWidth: 1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Description")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppColors.mutedForeground)
                                    
                                    TextField("Criteria for this level", text: $level.description)
                                        .font(.system(size: 15))
                                        .foregroundColor(AppColors.foreground)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(AppColors.input)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.border, lineWidth: 1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Target Type")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppColors.mutedForeground)
                                    
                                    Picker("Target Type", selection: $level.targetType) {
                                        ForEach(LevelConfig.TargetType.allCases, id: \.self) { type in
                                            Text(type.rawValue).tag(type)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                                
                                if level.targetType == .reps {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Target Reps")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(AppColors.mutedForeground)
                                        
                                        Stepper(value: $level.targetReps, in: 1...50) {
                                            Text("\(level.targetReps) reps")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(AppColors.foreground)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(AppColors.secondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                } else {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Target Hold Duration")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(AppColors.mutedForeground)
                                        
                                        Stepper(value: $level.targetHoldDuration, in: 5...300, step: 5) {
                                            Text("\(level.targetHoldDuration) seconds")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(AppColors.foreground)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(AppColors.secondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                            .padding(12)
                            .background(AppColors.secondary.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(16)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Save Button
                    Button(action: saveSkill) {
                        Text("Create Skill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppColors.alabasterGrey)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 14, x: 0, y: 4)
                    }
                    .disabled(!isValid)
                    .opacity(isValid ? 1.0 : 0.6)
                    .padding(.horizontal, 16)
                }
                .padding(20)
            }
            .background(AppColors.background)
            .navigationTitle("New Skill Progression")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
            .onAppear {
                if levels.isEmpty {
                    updateLevels(count: numberOfLevels)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !skillName.isEmpty &&
        !skillDescription.isEmpty &&
        levels.count == numberOfLevels &&
        levels.allSatisfy { !$0.name.isEmpty && !$0.description.isEmpty }
    }
    
    private func updateLevels(count: Int) {
        if levels.count < count {
            // Add more levels
            for i in levels.count..<count {
                levels.append(LevelConfig(levelNumber: i + 1))
            }
        } else if levels.count > count {
            // Remove excess levels
            levels = Array(levels.prefix(count))
        }
    }
    
    private func saveSkill() {
        let progressionLevels = levels.map { level in
            SkillProgressionLevel(
                level: level.levelNumber,
                name: level.name,
                description: level.description,
                targetHoldDuration: level.targetType == .hold ? level.targetHoldDuration : nil,
                targetReps: level.targetType == .reps ? level.targetReps : nil
            )
        }
        
        let newSkill = CalisthenicsSkill(
            name: skillName,
            icon: selectedIcon,
            description: skillDescription,
            progressionLevels: progressionLevels,
            videoURL: nil,
            category: selectedCategory,
            isCustom: true
        )
        
        skillManager.addCustomSkill(newSkill)
        dismiss()
    }
}

#Preview {
    CreateCustomSkillView(skillManager: CalisthenicsSkillManager.shared)
}






















