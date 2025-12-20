//
//  TemplateFilterSheet.swift
//  Ascend
//
//  Created on 2024
//

import SwiftUI

struct TemplateFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: TemplateFilters
    @State private var localFilters: TemplateFilters
    
    init(filters: Binding<TemplateFilters>) {
        self._filters = filters
        self._localFilters = State(initialValue: filters.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Intensity Filter
                    FilterSection(title: "Intensity", icon: "flame.fill") {
                        VStack(spacing: AppSpacing.sm) {
                            ForEach([WorkoutIntensity.light, .moderate, .intense, .extreme], id: \.self) { intensity in
                                FilterToggle(
                                    title: intensity.rawValue,
                                    isOn: Binding(
                                        get: { localFilters.intensities.contains(intensity) },
                                        set: { isOn in
                                            if isOn {
                                                localFilters.intensities.insert(intensity)
                                            } else {
                                                localFilters.intensities.remove(intensity)
                                            }
                                        }
                                    ),
                                    gradient: intensityGradient(for: intensity)
                                )
                            }
                        }
                    }
                    
                    // Duration Filter
                    FilterSection(title: "Duration", icon: "clock.fill") {
                        VStack(spacing: AppSpacing.sm) {
                            FilterToggle(
                                title: "Quick (< 30 min)",
                                isOn: $localFilters.showQuick,
                                gradient: LinearGradient.primaryGradient
                            )
                            FilterToggle(
                                title: "Medium (30-60 min)",
                                isOn: $localFilters.showMedium,
                                gradient: LinearGradient.primaryGradient
                            )
                            FilterToggle(
                                title: "Long (> 60 min)",
                                isOn: $localFilters.showLong,
                                gradient: LinearGradient.primaryGradient
                            )
                        }
                    }
                    
                    // Muscle Group Filter
                    FilterSection(title: "Muscle Groups", icon: "figure.mixed.cardio") {
                        VStack(spacing: AppSpacing.sm) {
                            ForEach(["Chest", "Back", "Legs", "Arms", "Core", "Cardio"], id: \.self) { group in
                                FilterToggle(
                                    title: group,
                                    isOn: Binding(
                                        get: { localFilters.muscleGroups.contains(group) },
                                        set: { isOn in
                                            if isOn {
                                                localFilters.muscleGroups.insert(group)
                                            } else {
                                                localFilters.muscleGroups.remove(group)
                                            }
                                        }
                                    ),
                                    gradient: AppColors.categoryGradient(for: group)
                                )
                            }
                        }
                    }
                    
                    // Template Type Filter
                    FilterSection(title: "Template Type", icon: "doc.text.fill") {
                        VStack(spacing: AppSpacing.sm) {
                            FilterToggle(
                                title: "Default Templates",
                                isOn: $localFilters.showDefault,
                                gradient: LinearGradient.primaryGradient
                            )
                            FilterToggle(
                                title: "Custom Templates",
                                isOn: $localFilters.showCustom,
                                gradient: LinearGradient.primaryGradient
                            )
                        }
                    }
                    
                    // Reset Button
                    Button(action: {
                        localFilters = TemplateFilters()
                        HapticManager.impact(style: .light)
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset Filters")
                        }
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.destructive)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.destructive.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle("Filter Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        filters = localFilters
                        HapticManager.impact(style: .medium)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func intensityGradient(for intensity: WorkoutIntensity) -> LinearGradient {
        switch intensity {
        case .light:
            return LinearGradient(
                colors: [Color.green, Color.mint],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .moderate:
            return LinearGradient(
                colors: [Color.orange, Color.yellow],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .intense:
            return LinearGradient(
                colors: [Color.red, Color.orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .extreme:
            return LinearGradient(
                colors: [Color.purple, Color.pink],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

struct FilterSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.primary)
                Text(title)
                    .font(AppTypography.heading3)
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(.horizontal, 4)
            
            content
        }
    }
}

struct FilterToggle: View {
    let title: String
    @Binding var isOn: Bool
    let gradient: LinearGradient
    
    var body: some View {
        Button(action: {
            isOn.toggle()
            HapticManager.selection()
        }) {
            HStack {
                Text(title)
                    .font(AppTypography.body)
                    .foregroundColor(isOn ? .white : AppColors.textPrimary)
                
                Spacer()
                
                if isOn {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isOn ? gradient : LinearGradient(colors: [AppColors.card], startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isOn ? Color.clear : AppColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct TemplateFilters: Equatable {
    var intensities: Set<WorkoutIntensity> = []
    var showQuick: Bool = true
    var showMedium: Bool = true
    var showLong: Bool = true
    var muscleGroups: Set<String> = []
    var showDefault: Bool = true
    var showCustom: Bool = true
    
    var isActive: Bool {
        !intensities.isEmpty || !showQuick || !showMedium || !showLong || 
        !muscleGroups.isEmpty || !showDefault || !showCustom
    }
    
    func matches(_ template: WorkoutTemplate) -> Bool {
        // Intensity filter
        if !intensities.isEmpty {
            if let templateIntensity = template.intensity {
                if !intensities.contains(templateIntensity) {
                    return false
                }
            } else {
                return false
            }
        }
        
        // Duration filter
        let duration = template.estimatedDuration
        var matchesDuration = false
        if showQuick && duration < 30 { matchesDuration = true }
        if showMedium && duration >= 30 && duration <= 60 { matchesDuration = true }
        if showLong && duration > 60 { matchesDuration = true }
        if !matchesDuration { return false }
        
        // Muscle group filter
        if !muscleGroups.isEmpty {
            let templateMuscleGroup = template.exercises.first?.name ?? "General"
            var found = false
            for group in muscleGroups {
                if templateMuscleGroup.localizedCaseInsensitiveContains(group) {
                    found = true
                    break
                }
            }
            if !found { return false }
        }
        
        // Template type filter
        if template.isDefault && !showDefault { return false }
        if !template.isDefault && !showCustom { return false }
        
        return true
    }
}

#Preview {
    TemplateFilterSheet(filters: .constant(TemplateFilters()))
}
