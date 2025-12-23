//
//  DayTypeInfoCard.swift
//  Ascend
//
//  Created on December 18, 2025.
//

import SwiftUI

/// Card showing workout day type and suggested templates when no template is assigned
struct DayTypeInfoCard: View {
    let day: WorkoutDay
    let dayIndex: Int
    let program: WorkoutProgram
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    @State private var showEditTemplate = false
    @State private var showGeneratePrompt = false
    @State private var generatedTemplateInfo: (name: String, intensity: WorkoutIntensity)?
    
    // Cached computed properties for performance
    @State private var cachedDayType: String?
    @State private var cachedSuggestedTemplates: [WorkoutTemplate] = []
    @State private var cachedCurrentTemplate: WorkoutTemplate?
    
    private var dayType: String? {
        if let cached = cachedDayType {
            return cached
        }
        let extracted = WorkoutDayTypeExtractor.extract(from: day.name)
        cachedDayType = extracted
        return extracted
    }
    
    private var currentTemplate: WorkoutTemplate? {
        // Check cache first
        if let cached = cachedCurrentTemplate {
            return cached
        }
        
        guard let templateId = day.templateId else { return nil }
        
        // Try cache manager first
        if let cached = CardDetailCacheManager.shared.getCachedTemplate(templateId) {
            cachedCurrentTemplate = cached
            return cached
        }
        
        // Fallback to view model
        let template = templatesViewModel.templates.first { $0.id == templateId }
        if let template = template {
            cachedCurrentTemplate = template
            CardDetailCacheManager.shared.cacheTemplate(template)
        }
        return template
    }
    
    private var suggestedTemplates: [WorkoutTemplate] {
        if !cachedSuggestedTemplates.isEmpty {
            return cachedSuggestedTemplates
        }
        
        guard let dayType = dayType else { return [] }
        
        // Try cache manager first
        if let cached = CardDetailCacheManager.shared.getCachedTemplateSuggestions(for: dayType) {
            cachedSuggestedTemplates = cached
            return cached
        }
        
        // Try day type info cache
        if let dayTypeInfo = CardDetailCacheManager.shared.getCachedDayTypeInfo(day.name) {
            cachedSuggestedTemplates = dayTypeInfo.suggestedTemplates
            return dayTypeInfo.suggestedTemplates
        }
        
        // Compute and cache
        let suggestions = templatesViewModel.suggestTemplatesForDayType(dayType)
        cachedSuggestedTemplates = suggestions
        CardDetailCacheManager.shared.cacheTemplateSuggestions(for: dayType, templates: suggestions)
        CardDetailCacheManager.shared.cacheDayTypeInfo(day.name, dayType: dayType, suggestedTemplates: suggestions)
        return suggestions
    }
    
    private var dayTypeGradient: LinearGradient {
        guard let dayType = dayType else {
            return LinearGradient.primaryGradient
        }
        
        let dayTypeLower = dayType.lowercased()
        
        if dayTypeLower.contains("push") || dayTypeLower.contains("chest") {
            return LinearGradient.chestGradient
        }
        
        if dayTypeLower.contains("pull") || dayTypeLower.contains("back") {
            return LinearGradient.backGradient
        }
        
        if dayTypeLower.contains("leg") {
            return LinearGradient.legsGradient
        }
        
        if dayTypeLower.contains("arm") {
            return LinearGradient.armsGradient
        }
        
        if dayTypeLower.contains("core") {
            return LinearGradient.coreGradient
        }
        
        return LinearGradient.primaryGradient
    }
    
    private var dayTypeIcon: String {
        guard let dayType = dayType else {
            return "dumbbell.fill"
        }
        
        let dayTypeLower = dayType.lowercased()
        
        if dayTypeLower.contains("push") || dayTypeLower.contains("chest") {
            return "figure.strengthtraining.traditional"
        }
        
        if dayTypeLower.contains("pull") || dayTypeLower.contains("back") {
            return "figure.rower"
        }
        
        if dayTypeLower.contains("leg") {
            return "figure.run"
        }
        
        if dayTypeLower.contains("upper") {
            return "figure.arms.open"
        }
        
        if dayTypeLower.contains("lower") {
            return "figure.step.training"
        }
        
        if dayTypeLower.contains("full") || dayTypeLower.contains("body") {
            return "figure.flexibility"
        }
        
        return "dumbbell.fill"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            dayTypeHeaderView
            templateOrSuggestionsContent
        }
        .padding(16)
        .onAppear {
            // Preload data when card appears
            preloadCardData()
        }
        .onChange(of: day.templateId) { _ in
            // Invalidate cache when template changes
            cachedCurrentTemplate = nil
            preloadCardData()
        }
        .background(cardBackgroundView)
        .shadow(color: AppColors.foreground.opacity(0.1), radius: 8, x: 0, y: 4)
        .sheet(isPresented: $showEditTemplate) {
            editTemplateSheetView
        }
        .onChange(of: templatesViewModel.showEditTemplate) { newValue in
            if newValue {
                showEditTemplate = true
            }
        }
        .alert("Workout Generated", isPresented: $showGeneratePrompt, presenting: generatedTemplateInfo) { info in
            Button("Got it", role: .cancel) { }
        } message: { info in
            Text("A \(info.intensity.rawValue) intensity workout has been generated for \(info.name).")
        }
    }
    
    private var dayTypeHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Day Type")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.foreground.opacity(0.7))
                
                if let dayType = dayType {
                    HStack(spacing: 8) {
                        Image(systemName: dayTypeIcon)
                            .font(.system(size: 14))
                            .foregroundStyle(dayTypeGradient)
                        
                        Text(dayType)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppColors.foreground)
                    }
                } else {
                    Text("General")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.foreground)
                }
            }
            
            Spacer()
            
            if let dayType = dayType {
                Text(dayType)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(dayTypeGradient)
                    .clipShape(Capsule())
            }
        }
    }
    
    @ViewBuilder
    private var templateOrSuggestionsContent: some View {
        if let template = currentTemplate {
            templateContentView(template)
        } else {
            suggestionsContentView
        }
    }
    
    @ViewBuilder
    private func templateContentView(_ template: WorkoutTemplate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            templateHeaderView(template)
            exercisesListView(template)
        }
        .padding(12)
        .background(AppColors.accent.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func templateHeaderView(_ template: WorkoutTemplate) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Assigned Template")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.foreground.opacity(0.7))
                
                Text(template.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                
                if template.estimatedDuration > 0 {
                    Text("\(template.estimatedDuration) min")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(AppColors.foreground.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Inline actions
            HStack(spacing: 8) {
                Button(action: {
                    HapticManager.impact(style: .light)
                    templatesViewModel.editTemplate(template)
                    showEditTemplate = true
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.primary)
                }
                
                Button(action: {
                    HapticManager.impact(style: .medium)
                    programViewModel.removeTemplate(fromDay: dayIndex, inProgram: program.id)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.destructive)
                }
            }
        }
    }
    
    @ViewBuilder
    private func exercisesListView(_ template: WorkoutTemplate) -> some View {
        if !template.exercises.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Exercises")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.foreground.opacity(0.7))
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(template.exercises.prefix(3))) { exercise in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(AppColors.primary.opacity(0.2))
                                .frame(width: 6, height: 6)
                            
                            Text(exercise.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.foreground)
                            
                            Spacer()
                            
                            Text("\(exercise.sets) sets")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(AppColors.foreground.opacity(0.7))
                            
                            if !exercise.reps.isEmpty {
                                Text("• \(exercise.reps)")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(AppColors.foreground.opacity(0.7))
                            }
                        }
                    }
                    
                    if template.exercises.count > 3 {
                        Text("+\(template.exercises.count - 3) more exercises")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(AppColors.foreground.opacity(0.6))
                            .padding(.leading, 14)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var suggestionsContentView: some View {
        if !suggestedTemplates.isEmpty {
            suggestedTemplatesView
        } else {
            generateWorkoutView
        }
    }
    
    private var suggestedTemplatesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggested Templates")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.foreground.opacity(0.7))
            
            VStack(spacing: 8) {
                ForEach(suggestedTemplates.prefix(3), id: \.id) { template in
                    suggestedTemplateButton(template)
                }
            }
        }
    }
    
    private func suggestedTemplateButton(_ template: WorkoutTemplate) -> some View {
        Button(action: {
            HapticManager.impact(style: .medium)
            programViewModel.assignTemplate(template.id, toDay: dayIndex, inProgram: program.id, templatesViewModel: templatesViewModel)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.foreground)
                    
                    if template.estimatedDuration > 0 {
                        Text("\(template.estimatedDuration) min")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(AppColors.foreground.opacity(0.7))
                    }
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.primary)
            }
            .padding(12)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var generateWorkoutView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No Matching Templates")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.foreground.opacity(0.7))
            
            Text("Generate a workout for this \(dayType ?? "day") day?")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(AppColors.foreground.opacity(0.6))
            
            Button(action: {
                HapticManager.impact(style: .medium)
                generateWorkoutForDay()
            }) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                    Text("Generate Workout")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(LinearGradient.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    private var cardBackgroundView: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(AppColors.card)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.border.opacity(0.5), lineWidth: 1.5)
            )
    }
    
    @ViewBuilder
    private var editTemplateSheetView: some View {
        if let template = currentTemplate {
            TemplateEditView(
                template: template,
                onSave: { updatedTemplate in
                    templatesViewModel.saveTemplate(updatedTemplate)
                    showEditTemplate = false
                },
                onCancel: {
                    showEditTemplate = false
                }
            )
        }
    }
    
    private func preloadCardData() {
        // Preload day type
        if cachedDayType == nil {
            cachedDayType = WorkoutDayTypeExtractor.extract(from: day.name)
        }
        
        // Preload current template if assigned
        if cachedCurrentTemplate == nil, let templateId = day.templateId {
            // Check cache manager first
            if let cached = CardDetailCacheManager.shared.getCachedTemplate(templateId) {
                cachedCurrentTemplate = cached
            } else if let template = templatesViewModel.templates.first(where: { $0.id == templateId }) {
                cachedCurrentTemplate = template
                CardDetailCacheManager.shared.cacheTemplate(template)
            }
        }
        
        // Preload suggested templates if day type is available
        if cachedSuggestedTemplates.isEmpty, let dayType = dayType {
            let suggested = templatesViewModel.suggestTemplatesForDayType(dayType)
            cachedSuggestedTemplates = suggested
        }
    }
    
    private func generateWorkoutForDay() {
        guard let result = programViewModel.ensureTemplateForDay(
            dayIndex: dayIndex,
            inProgram: program.id,
            settings: templatesViewModel.generationSettings,
            templatesViewModel: templatesViewModel
        ) else {
            return
        }
        
        // Show alert if it was just generated
        if result.wasGenerated {
            generatedTemplateInfo = (name: result.template.name, intensity: result.intensity)
            showGeneratePrompt = true
        }
    }
}

