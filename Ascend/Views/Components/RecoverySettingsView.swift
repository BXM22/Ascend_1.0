//
//  RecoverySettingsView.swift
//  Ascend
//
//  Customization settings for recovery tracking
//

import SwiftUI

struct RecoverySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recoveryManager = RecoveryManager.shared
    
    @State private var selectedTrainingStyle: RecoveryTrainingStyle
    @State private var selectedFrequency: TrainingFrequency
    @State private var sleepHours: Double
    @State private var deloadInterval: Int
    @State private var customRecoveryHours: [String: Int]
    @State private var showMuscleCustomization = false
    @State private var selectedMuscle: String?
    
    init() {
        let settings = RecoveryManager.shared.settings
        _selectedTrainingStyle = State(initialValue: settings.trainingStyle)
        _selectedFrequency = State(initialValue: settings.trainingFrequency)
        _sleepHours = State(initialValue: settings.sleepHoursPerNight)
        _deloadInterval = State(initialValue: settings.deloadWeekInterval)
        _customRecoveryHours = State(initialValue: settings.customRecoveryHours)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Training Type Section
                    trainingTypeSection
                    
                    // Training Frequency Section
                    trainingFrequencySection
                    
                    // Sleep Section
                    sleepSection
                    
                    // Deload Section
                    deloadSection
                    
                    // Custom Muscle Recovery Times
                    customRecoverySection
                    
                    // Recovery Rules Reference
                    recoveryRulesSection
                    
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(AppColors.background)
            .navigationTitle("Recovery Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.mutedForeground)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(AppColors.accent)
                }
            }
        }
        .sheet(isPresented: $showMuscleCustomization) {
            MuscleRecoveryCustomizationView(
                customRecoveryHours: $customRecoveryHours,
                selectedMuscle: selectedMuscle
            )
        }
    }
    
    // MARK: - Training Type Section
    
    private var trainingTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Training Type", icon: "figure.strengthtraining.traditional")
            
            VStack(spacing: 8) {
                ForEach(RecoveryTrainingStyle.allCases, id: \.self) { style in
                    Button(action: { selectedTrainingStyle = style }) {
                        HStack(spacing: 12) {
                            Image(systemName: style.icon)
                                .font(.system(size: 20))
                                .foregroundColor(selectedTrainingStyle == style ? .white : AppColors.accent)
                                .frame(width: 36, height: 36)
                                .background(selectedTrainingStyle == style ? AppColors.accent : AppColors.accent.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(style.rawValue)
                                    .font(AppTypography.bodyBold)
                                    .foregroundColor(AppColors.foreground)
                                
                                Text(style.description)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.mutedForeground)
                            }
                            
                            Spacer()
                            
                            if selectedTrainingStyle == style {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                        .padding(12)
                        .background(selectedTrainingStyle == style ? AppColors.accent.opacity(0.1) : AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedTrainingStyle == style ? AppColors.accent : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Training Frequency Section
    
    private var trainingFrequencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Training Frequency", icon: "calendar")
            
            VStack(spacing: 8) {
                ForEach(TrainingFrequency.allCases, id: \.self) { frequency in
                    Button(action: { selectedFrequency = frequency }) {
                        HStack(spacing: 12) {
                            Text("\(frequency.daysPerWeek)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(selectedFrequency == frequency ? .white : AppColors.accent)
                                .frame(width: 36, height: 36)
                                .background(selectedFrequency == frequency ? AppColors.accent : AppColors.accent.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(frequency.rawValue)
                                    .font(AppTypography.bodyBold)
                                    .foregroundColor(AppColors.foreground)
                                
                                Text(frequency.description)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.mutedForeground)
                            }
                            
                            Spacer()
                            
                            if selectedFrequency == frequency {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                        .padding(12)
                        .background(selectedFrequency == frequency ? AppColors.accent.opacity(0.1) : AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedFrequency == frequency ? AppColors.accent : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Sleep Section
    
    private var sleepSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Average Sleep", icon: "bed.double.fill")
            
            VStack(spacing: 12) {
                HStack {
                    Text("\(sleepHours, specifier: "%.1f") hours/night")
                        .font(AppTypography.heading4)
                        .foregroundColor(AppColors.foreground)
                    
                    Spacer()
                    
                    Text(sleepQualityLabel)
                        .font(AppTypography.captionBold)
                        .foregroundColor(sleepQualityColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(sleepQualityColor.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                Slider(value: $sleepHours, in: 4...12, step: 0.5)
                    .tint(sleepQualityColor)
                
                HStack {
                    Text("4h")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Spacer()
                    
                    Text("12h")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                if sleepHours < 7 {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "f59e0b"))
                        
                        Text("Less than 7 hours may slow recovery. Recovery times will be adjusted.")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.mutedForeground)
                    }
                    .padding(10)
                    .background(Color(hex: "f59e0b").opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(16)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var sleepQualityLabel: String {
        switch sleepHours {
        case 9...: return "Optimal"
        case 7..<9: return "Good"
        case 6..<7: return "Below Optimal"
        default: return "Poor"
        }
    }
    
    private var sleepQualityColor: Color {
        switch sleepHours {
        case 9...: return Color(hex: "22c55e")
        case 7..<9: return Color(hex: "22c55e")
        case 6..<7: return Color(hex: "f59e0b")
        default: return Color(hex: "ef4444")
        }
    }
    
    // MARK: - Deload Section
    
    private var deloadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Deload Schedule", icon: "arrow.down.circle.fill")
            
            VStack(spacing: 12) {
                HStack {
                    Text("Deload every")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.foreground)
                    
                    Spacer()
                    
                    Picker("Weeks", selection: $deloadInterval) {
                        ForEach(4...12, id: \.self) { weeks in
                            Text("\(weeks) weeks").tag(weeks)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppColors.accent)
                }
                
                Text("A deload week helps prevent overtraining. Reduce volume by 40-50% during deload.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.mutedForeground)
                
                if let lastDeload = recoveryManager.settings.lastDeloadDate {
                    HStack {
                        Text("Last deload:")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Text(lastDeload, style: .date)
                            .font(AppTypography.captionBold)
                            .foregroundColor(AppColors.foreground)
                    }
                }
            }
            .padding(16)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Custom Recovery Section
    
    private var customRecoverySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(title: "Custom Recovery Times", icon: "slider.horizontal.3")
                
                Spacer()
                
                Button(action: { showMuscleCustomization = true }) {
                    Text("Edit")
                        .font(AppTypography.captionBold)
                        .foregroundColor(AppColors.accent)
                }
            }
            
            if customRecoveryHours.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 32))
                        .foregroundColor(AppColors.mutedForeground.opacity(0.5))
                    
                    Text("No custom times set")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Text("Tap Edit to customize recovery hours for specific muscles")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.mutedForeground.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(customRecoveryHours.sorted(by: { $0.key < $1.key })), id: \.key) { muscle, hours in
                        HStack {
                            Text(muscle)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.foreground)
                            
                            Spacer()
                            
                            Text("\(hours)h")
                                .font(AppTypography.bodyBold)
                                .foregroundColor(AppColors.accent)
                            
                            Button(action: {
                                customRecoveryHours.removeValue(forKey: muscle)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppColors.mutedForeground)
                            }
                        }
                        .padding(12)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }
    
    // MARK: - Recovery Rules Reference
    
    private var recoveryRulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Recovery Guidelines", icon: "book.fill")
            
            VStack(alignment: .leading, spacing: 16) {
                ruleItem(title: "Same Muscle Group", value: "48-72 hours", icon: "arrow.triangle.2.circlepath")
                ruleItem(title: "Heavy / Max Effort", value: "72-96 hours", icon: "bolt.fill")
                ruleItem(title: "Skill Work", value: "24 hours or less", icon: "figure.gymnastics")
                ruleItem(title: "CNS Recovery", value: "Extra rest needed", icon: "brain.head.profile")
                ruleItem(title: "Sleep", value: "7-9 hours (non-negotiable)", icon: "bed.double.fill")
                
                Divider()
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("⚠️ Signs You Need More Rest")
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.foreground)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        signItem("Progress plateau")
                        signItem("Poor sleep quality")
                        signItem("Joint pain")
                        signItem("Motivation drop")
                    }
                }
            }
            .padding(16)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private func ruleItem(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppColors.accent)
                .frame(width: 20)
            
            Text(title)
                .font(AppTypography.body)
                .foregroundColor(AppColors.foreground)
            
            Spacer()
            
            Text(value)
                .font(AppTypography.captionBold)
                .foregroundColor(AppColors.mutedForeground)
        }
    }
    
    private func signItem(_ text: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: "f59e0b"))
                .frame(width: 6, height: 6)
            
            Text(text)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.mutedForeground)
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.accent)
            
            Text(title)
                .font(AppTypography.heading4)
                .foregroundColor(AppColors.foreground)
        }
    }
    
    // MARK: - Save Settings
    
    private func saveSettings() {
        recoveryManager.settings = RecoverySettings(
            trainingStyle: selectedTrainingStyle,
            trainingFrequency: selectedFrequency,
            customRecoveryHours: customRecoveryHours,
            sleepHoursPerNight: sleepHours,
            deloadWeekInterval: deloadInterval,
            lastDeloadDate: recoveryManager.settings.lastDeloadDate
        )
    }
}

// MARK: - Muscle Recovery Customization View

struct MuscleRecoveryCustomizationView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var customRecoveryHours: [String: Int]
    var selectedMuscle: String?
    
    @State private var currentMuscle: String = "Chest"
    @State private var currentHours: Double = 48
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Muscle selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(RecoveryManager.allMuscleGroups, id: \.self) { muscle in
                            Button(action: {
                                currentMuscle = muscle
                                currentHours = Double(customRecoveryHours[muscle] ?? defaultHours(for: muscle))
                            }) {
                                Text(muscle)
                                    .font(AppTypography.caption)
                                    .foregroundColor(currentMuscle == muscle ? .white : AppColors.foreground)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(currentMuscle == muscle ? AppColors.accent : AppColors.muted)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Hours selector
                VStack(spacing: 16) {
                    Text(currentMuscle)
                        .font(AppTypography.heading3)
                        .foregroundColor(AppColors.foreground)
                    
                    Text("\(Int(currentHours)) hours")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.accent)
                    
                    Slider(value: $currentHours, in: 24...120, step: 6)
                        .tint(AppColors.accent)
                        .padding(.horizontal, 20)
                    
                    HStack {
                        Text("24h")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Spacer()
                        
                        Text("Default: \(defaultHours(for: currentMuscle))h")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Spacer()
                        
                        Text("120h")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.mutedForeground)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 24)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: {
                        customRecoveryHours.removeValue(forKey: currentMuscle)
                    }) {
                        Text("Reset to Default")
                            .font(AppTypography.bodyBold)
                            .foregroundColor(AppColors.mutedForeground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.muted)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: {
                        customRecoveryHours[currentMuscle] = Int(currentHours)
                    }) {
                        Text("Apply")
                            .font(AppTypography.bodyBold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 20)
            .background(AppColors.background)
            .navigationTitle("Custom Recovery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
        }
        .onAppear {
            if let selected = selectedMuscle {
                currentMuscle = selected
                currentHours = Double(customRecoveryHours[selected] ?? defaultHours(for: selected))
            }
        }
    }
    
    private func defaultHours(for muscle: String) -> Int {
        let defaults: [String: Int] = [
            "Chest": 72, "Back": 72, "Shoulders": 48, "Biceps": 48, "Triceps": 48,
            "Quads": 72, "Hamstrings": 72, "Glutes": 72, "Calves": 48,
            "Core": 48, "Traps": 48, "Forearms": 48, "Lower Back": 72
        ]
        return defaults[muscle] ?? 48
    }
}

// MARK: - Preview

#Preview {
    RecoverySettingsView()
}
