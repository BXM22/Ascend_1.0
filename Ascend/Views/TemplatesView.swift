//
//  TemplatesView.swift
//  Ascend
//
//  Redesigned Templates View with:
//  - Streamlined header with consolidated buttons
//  - Search with filter integration
//  - Segmented content organization (Programs/Skills/Templates)
//  - Swipe actions for delete/duplicate
//  - Tap-to-preview with medium detent sheet
//  - Multi-select mode for bulk actions
//  - Enhanced empty states with CTAs
//  - Improved accessibility
//  - Performance optimizations
//

import SwiftUI

struct TemplatesView: View {
    @ObservedObject var viewModel: TemplatesViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    @ObservedObject var themeManager: ThemeManager
    let onStartTemplate: () -> Void
    let onSettings: () -> Void
    
    // State
    @State private var showGenerateSheet = false
    @State private var showCalisthenicProgression = false
    @State private var searchText: String = ""
    @State private var debouncedSearchText: String = ""
    @State private var debounceTask: Task<Void, Never>?
    @State private var sortOption: SortOption = .name
    @State private var showFilterSheet = false
    @State private var filters = TemplateFilters()
    @State private var selectedSegment: ContentSegment = .templates
    @State private var showDetailSheet = false
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var isMultiSelectMode = false
    @State private var selectedTemplates: Set<UUID> = []
    @State private var showGrouped = false
    
    enum ContentSegment: String, CaseIterable {
        case programs = "Programs"
        case skills = "Skills"
        case templates = "Templates"
    }
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case exerciseCount = "Exercise Count"
        case intensity = "Intensity"
        case duration = "Duration"
        
        func sort(_ templates: [WorkoutTemplate]) -> [WorkoutTemplate] {
            switch self {
            case .name:
                return templates.sorted { $0.name < $1.name }
            case .exerciseCount:
                return templates.sorted { $0.exercises.count > $1.exercises.count }
            case .intensity:
                return templates.sorted { lhs, rhs in
                    let lhsIntensity = lhs.intensity?.rawValue ?? "None"
                    let rhsIntensity = rhs.intensity?.rawValue ?? "None"
                    return lhsIntensity < rhsIntensity
                }
            case .duration:
                return templates.sorted { $0.estimatedDuration > $1.estimatedDuration }
            }
        }
    }
    
    private var filteredTemplates: [WorkoutTemplate] {
        let filtered = viewModel.templates.filter { template in
            if template.name.contains("Progression") { return false }
            
            // Apply search filter
            if !debouncedSearchText.isEmpty {
                let matchesSearch = template.name.localizedCaseInsensitiveContains(debouncedSearchText) ||
                       template.exercises.contains { $0.name.localizedCaseInsensitiveContains(debouncedSearchText) }
                if !matchesSearch { return false }
            }
            
            // Apply custom filters
            if filters.isActive {
                return filters.matches(template)
            }
            
            return true
        }
        return sortOption.sort(filtered)
    }
    
    private var groupedTemplates: [String: [WorkoutTemplate]] {
        Dictionary(grouping: filteredTemplates) { template in
            detectMuscleGroup(template.exercises.first?.name ?? "General")
        }
    }
    
    private func detectMuscleGroup(_ exerciseName: String) -> String {
        let name = exerciseName.lowercased()
        if name.contains("chest") || name.contains("bench") || name.contains("press") { return "Chest" }
        if name.contains("back") || name.contains("row") || name.contains("pull") { return "Back" }
        if name.contains("leg") || name.contains("squat") || name.contains("deadlift") { return "Legs" }
        if name.contains("bicep") || name.contains("tricep") || name.contains("arm") { return "Arms" }
        if name.contains("core") || name.contains("ab") || name.contains("plank") { return "Core" }
        if name.contains("cardio") || name.contains("run") { return "Cardio" }
        return "General"
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Streamlined Header
                StreamlinedTemplatesHeader(
                    isMultiSelectMode: $isMultiSelectMode,
                    themeManager: themeManager,
                    selectedCount: selectedTemplates.count,
                    onGenerate: {
                        showGenerateSheet = true
                    },
                    onSettings: onSettings,
                    onGenerationSettings: {
                        viewModel.showGenerationSettings = true
                    },
                    onDeleteSelected: {
                        deleteSelectedTemplates()
                    },
                    onCancelMultiSelect: {
                        isMultiSelectMode = false
                        selectedTemplates.removeAll()
                    }
                )
                
                // Search Bar with Filter Button
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.mutedForeground)
                            .accessibilityHidden(true)
                        
                        TextField("Search templates...", text: $searchText)
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.foreground)
                            .accessibilityLabel("Search templates")
                            .onChange(of: searchText) { _, newValue in
                                debounceTask?.cancel()
                                debounceTask = Task { @MainActor in
                                    try? await Task.sleep(nanoseconds: 300_000_000)
                                    if !Task.isCancelled {
                                        debouncedSearchText = newValue
                                    }
                                }
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                debouncedSearchText = ""
                                HapticManager.selection()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppColors.mutedForeground)
                            }
                            .accessibilityLabel("Clear search")
                        }
                        
                        // Filter Button
                        Button(action: {
                            showFilterSheet = true
                            HapticManager.impact(style: .light)
                        }) {
                            ZStack {
                                Image(systemName: filters.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(filters.isActive ? AppColors.primary : AppColors.mutedForeground)
                                
                                if filters.isActive {
                                    Circle()
                                        .fill(AppColors.destructive)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
                        .accessibilityLabel(filters.isActive ? "Filters active" : "Filter templates")
                        .accessibilityHint("Tap to \(filters.isActive ? "modify" : "add") filters")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Segmented Control
                    Picker("Content", selection: $selectedSegment) {
                        ForEach(ContentSegment.allCases, id: \.self) { segment in
                            Text(segment.rawValue).tag(segment)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .accessibilityLabel("Select content type")
                    
                    // Sort and Stats Row
                    HStack {
                        // Template count
                        if selectedSegment == .templates {
                            Text("\(filteredTemplates.count) template\(filteredTemplates.count == 1 ? "" : "s")")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                                .accessibilityLabel("\(filteredTemplates.count) templates found")
                        }
                        
                        Spacer()
                        
                        // Group toggle (templates view only)
                        if selectedSegment == .templates && !filteredTemplates.isEmpty {
                            Button(action: {
                                showGrouped.toggle()
                                HapticManager.selection()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: showGrouped ? "rectangle.grid.1x2.fill" : "square.grid.2x2")
                                        .font(.system(size: 12))
                                    Text(showGrouped ? "Grouped" : "List")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(AppColors.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppColors.primary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .accessibilityLabel(showGrouped ? "Switch to list view" : "Switch to grouped view")
                        }
                        
                        // Sort menu
                        if selectedSegment == .templates {
                            Menu {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Button(action: {
                                        sortOption = option
                                        HapticManager.selection()
                                    }) {
                                        HStack {
                                            Text(option.rawValue)
                                            if sortOption == option {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.up.arrow.down")
                                        .font(.system(size: 12))
                                    Text("Sort: \(sortOption.rawValue)")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(AppColors.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppColors.primary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .accessibilityLabel("Sort by \(sortOption.rawValue)")
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
                
                // Segmented Content
                VStack(spacing: AppSpacing.lg) {
                    if selectedSegment == .programs {
                        // Workout Programs Section
                        WorkoutSplitsSection(
                            programViewModel: programViewModel,
                            templatesViewModel: viewModel,
                            workoutViewModel: workoutViewModel,
                            onStartWorkout: onStartTemplate
                        )
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.lg)
                        .transition(.opacity)
                    } else if selectedSegment == .skills {
                        // Calisthenics Skills Section
                        CalisthenicsSkillsSection(
                            workoutViewModel: workoutViewModel,
                            templatesViewModel: viewModel,
                            onStart: onStartTemplate
                        )
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.lg)
                        .transition(.opacity)
                    } else {
                        // Regular Templates Section
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            HStack {
                                Text("Workout Templates")
                                    .font(AppTypography.heading2)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Spacer()
                                
                                // Multi-select toggle
                                if !filteredTemplates.isEmpty && !isMultiSelectMode {
                                    Button(action: {
                                        isMultiSelectMode = true
                                        HapticManager.impact(style: .light)
                                    }) {
                                        Text("Select")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.primary)
                                    }
                                    .accessibilityLabel("Select multiple templates")
                                }
                            }
                            .padding(.horizontal, AppSpacing.lg)
                            
                            // Add Template Button (full-width at top)
                            if !isMultiSelectMode {
                                Button(action: {
                                    viewModel.createTemplate()
                                    HapticManager.impact(style: .medium)
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 18))
                                        Text("Create Template")
                                            .font(AppTypography.bodyBold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(LinearGradient.primaryGradient)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                                .padding(.horizontal, AppSpacing.lg)
                                .padding(.top, AppSpacing.sm)
                                .accessibilityLabel("Create new template")
                            }
                            
                            if filteredTemplates.isEmpty {
                                // Enhanced Empty State
                                EnhancedEmptyState(
                                    hasSearchText: !debouncedSearchText.isEmpty,
                                    hasFilters: filters.isActive,
                                    onClearSearch: {
                                        searchText = ""
                                        debouncedSearchText = ""
                                        HapticManager.selection()
                                    },
                                    onClearFilters: {
                                        filters = TemplateFilters()
                                        HapticManager.selection()
                                    },
                                    onCreateTemplate: {
                                        viewModel.createTemplate()
                                        HapticManager.impact(style: .medium)
                                    },
                                    onGenerateWorkout: {
                                        showGenerateSheet = true
                                        HapticManager.impact(style: .medium)
                                    }
                                )
                                .padding(.horizontal, AppSpacing.lg)
                                .padding(.vertical, 60)
                            } else {
                                if showGrouped {
                                    // Grouped View
                                    ForEach(groupedTemplates.keys.sorted(), id: \.self) { group in
                                        GroupedTemplateSection(
                                            groupName: group,
                                            templates: groupedTemplates[group] ?? [],
                                            isMultiSelectMode: isMultiSelectMode,
                                            selectedTemplates: $selectedTemplates,
                                            onTapTemplate: { template in
                                                if isMultiSelectMode {
                                                    toggleSelection(template)
                                                } else {
                                                    selectedTemplate = template
                                                    showDetailSheet = true
                                                }
                                            },
                                            onStartTemplate: { template in
                                                viewModel.startTemplate(template, workoutViewModel: workoutViewModel)
                                                onStartTemplate()
                                            },
                                            onDeleteTemplate: { template in
                                                viewModel.deleteTemplate(template)
                                            },
                                            onDuplicateTemplate: { template in
                                                duplicateTemplate(template)
                                            }
                                        )
                                        .padding(.horizontal, AppSpacing.lg)
                                    }
                                } else {
                                    // List View with Swipe Actions
                                    ForEach(filteredTemplates, id: \.id) { template in
                                        RedesignedTemplateCard(
                                            template: template,
                                            isMultiSelectMode: isMultiSelectMode,
                                            isSelected: selectedTemplates.contains(template.id),
                                            onTap: {
                                                if isMultiSelectMode {
                                                    toggleSelection(template)
                                                } else {
                                                    selectedTemplate = template
                                                    showDetailSheet = true
                                                    HapticManager.impact(style: .light)
                                                }
                                            },
                                            onStart: {
                                                viewModel.startTemplate(template, workoutViewModel: workoutViewModel)
                                                onStartTemplate()
                                            }
                                        )
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            if !template.isDefault {
                                                Button(role: .destructive) {
                                                    viewModel.deleteTemplate(template)
                                                    HapticManager.success()
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                                .accessibilityLabel("Delete \(template.name)")
                                            }
                                        }
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                duplicateTemplate(template)
                                                HapticManager.impact(style: .medium)
                                            } label: {
                                                Label("Duplicate", systemImage: "doc.on.doc")
                                            }
                                            .tint(AppColors.accent)
                                            .accessibilityLabel("Duplicate \(template.name)")
                                        }
                                        .padding(.horizontal, AppSpacing.lg)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 20)
                        .transition(.opacity)
                    }
                }
            }
            .padding(.bottom, 100)
        }
        .background(AppColors.background)
        .id(AppColors.themeID)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .sheet(isPresented: $viewModel.showEditTemplate) {
            if let template = viewModel.editingTemplate {
                TemplateEditView(
                    template: template,
                    onSave: { template in
                        viewModel.saveTemplate(template)
                    },
                    onCancel: {
                        viewModel.showEditTemplate = false
                        viewModel.editingTemplate = nil
                    },
                    onDelete: {
                        viewModel.deleteTemplate(template)
                        viewModel.showEditTemplate = false
                        viewModel.editingTemplate = nil
                    }
                )
            }
        }
        .sheet(isPresented: $viewModel.showCreateTemplate) {
            TemplateEditView(
                template: nil,
                onSave: { template in
                    viewModel.saveTemplate(template)
                },
                onCancel: {
                    viewModel.showCreateTemplate = false
                }
            )
        }
        .sheet(isPresented: $viewModel.showGenerationSettings) {
            WorkoutGenerationSettingsView(settings: $viewModel.generationSettings)
        }
        .sheet(isPresented: $showGenerateSheet) {
            WorkoutGenerationView(viewModel: viewModel, onStart: onStartTemplate)
        }
        .sheet(isPresented: $showCalisthenicProgression) {
            CreateCustomSkillView(skillManager: CalisthenicsSkillManager.shared)
        }
        .sheet(isPresented: $showFilterSheet) {
            TemplateFilterSheet(filters: $filters)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showDetailSheet) {
            if let template = selectedTemplate {
                TemplateDetailView(
                    template: template,
                    onStart: {
                        viewModel.startTemplate(template, workoutViewModel: workoutViewModel)
                        onStartTemplate()
                    },
                    onEdit: {
                        viewModel.editTemplate(template)
                    },
                    onDuplicate: {
                        duplicateTemplate(template)
                    },
                    onDelete: template.isDefault ? nil : {
                        viewModel.deleteTemplate(template)
                        // Invalidate cache when template is deleted
                        CardDetailCacheManager.shared.invalidateTemplateCache(template.id)
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedSegment)
        .animation(.easeInOut(duration: 0.3), value: showGrouped)
    }
    
    // MARK: - Helper Functions
    
    private func duplicateTemplate(_ template: WorkoutTemplate) {
        let duplicated = WorkoutTemplate(
            name: "\(template.name) (Copy)",
            exercises: template.exercises,
            estimatedDuration: template.estimatedDuration,
            intensity: template.intensity,
            isDefault: false,
            colorHex: template.colorHex
        )
        viewModel.saveTemplate(duplicated)
        HapticManager.impact(style: .light)
    }
    
    private func toggleSelection(_ template: WorkoutTemplate) {
        if selectedTemplates.contains(template.id) {
            selectedTemplates.remove(template.id)
        } else {
            selectedTemplates.insert(template.id)
        }
        HapticManager.selection()
    }
    
    private func deleteSelectedTemplates() {
        for templateId in selectedTemplates {
            if let template = viewModel.templates.first(where: { $0.id == templateId }) {
                if !template.isDefault {
                    viewModel.deleteTemplate(template)
                }
            }
        }
        selectedTemplates.removeAll()
        isMultiSelectMode = false
        HapticManager.success()
    }
}

// MARK: - Supporting Components

struct StreamlinedTemplatesHeader: View {
    @Binding var isMultiSelectMode: Bool
    @ObservedObject var themeManager: ThemeManager
    let selectedCount: Int
    let onGenerate: () -> Void
    let onSettings: () -> Void
    let onGenerationSettings: () -> Void
    let onDeleteSelected: () -> Void
    let onCancelMultiSelect: () -> Void
    
    var body: some View {
        HStack {
            if isMultiSelectMode {
                Button("Cancel", action: onCancelMultiSelect)
                    .foregroundColor(AppColors.primary)
                
                Spacer()
                
                Text("\(selectedCount) selected")
                    .font(AppTypography.bodyBold)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button(action: onDeleteSelected) {
                    Image(systemName: "trash")
                        .foregroundColor(selectedCount > 0 ? AppColors.destructive : AppColors.mutedForeground)
                }
                .disabled(selectedCount == 0)
            } else {
                Text("Templates")
                    .font(AppTypography.largeTitleBold)
                    .foregroundStyle(LinearGradient.primaryGradient)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Spacer()
                
                HStack(spacing: 12) {
                    HelpButton(pageType: .templates)
                    
                    // Theme Toggle
                    HeaderThemeToggle(themeManager: themeManager)
                    
                    // Settings Menu
                    Menu {
                        Button(action: onSettings) {
                            Label("App Settings", systemImage: "gearshape")
                        }
                        Button(action: onGenerationSettings) {
                            Label("Generation Settings", systemImage: "slider.horizontal.3")
                        }
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(width: 40, height: 40)
                            .background(AppColors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel("Settings")
                    
                    Button(action: onGenerate) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.primary)
                            .frame(width: 40, height: 40)
                            .background(AppColors.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel("Generate workout")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .animation(.easeInOut(duration: 0.2), value: isMultiSelectMode)
    }
}

struct RedesignedTemplateCard: View {
    let template: WorkoutTemplate
    let isMultiSelectMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onStart: () -> Void
    
    private var gradient: LinearGradient {
        AppColors.templateGradient(for: template)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                // Selection indicator
                if isMultiSelectMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? AppColors.primary : AppColors.mutedForeground)
                        .accessibilityHidden(true)
                }
                
                // Icon
                ZStack {
                    Circle()
                        .fill(gradient.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(gradient)
                }
                
                // Template Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(AppTypography.heading3)
                        .foregroundColor(AppColors.foreground)
                        .lineLimit(1)
                        .accessibilityLabel(template.name)
                    
                    HStack(spacing: 8) {
                        Label("\(template.exercises.count)", systemImage: "figure.mixed.cardio")
                            .font(AppTypography.caption)
                        
                        if template.estimatedDuration > 0 {
                            Text("•")
                            Label("\(template.estimatedDuration) min", systemImage: "clock")
                                .font(AppTypography.caption)
                        }
                        
                        if let intensity = template.intensity {
                            Text("•")
                            Text(intensity.rawValue)
                                .font(AppTypography.caption)
                                .foregroundStyle(gradient)
                        }
                    }
                    .foregroundColor(AppColors.mutedForeground)
                }
                
                Spacer()
                
                // Quick Start button (not in multi-select)
                if !isMultiSelectMode {
                    Button(action: onStart) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(gradient)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityLabel("Start \(template.name)")
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedEmptyState: View {
    let hasSearchText: Bool
    let hasFilters: Bool
    let onClearSearch: () -> Void
    let onClearFilters: () -> Void
    let onCreateTemplate: () -> Void
    let onGenerateWorkout: () -> Void
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: hasSearchText ? "magnifyingglass" : "doc.text")
                    .font(.system(size: 48))
                    .foregroundColor(AppColors.primary.opacity(0.6))
            }
            
            // Title & Message
            VStack(spacing: 8) {
                Text(hasSearchText ? "No Templates Found" : "No Templates Yet")
                    .font(AppTypography.heading2)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(hasSearchText || hasFilters ?
                     "Try adjusting your search or filters" :
                     "Create your first workout template or generate one with AI")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Actions
            VStack(spacing: 12) {
                if hasSearchText {
                    Button(action: onClearSearch) {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Clear Search")
                        }
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                if hasFilters {
                    Button(action: onClearFilters) {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text("Clear Filters")
                        }
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                if !hasSearchText && !hasFilters {
                    Button(action: onCreateTemplate) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Template")
                        }
                        .font(AppTypography.bodyBold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    Button(action: onGenerateWorkout) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Generate with AI")
                        }
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct FloatingAddButton: View {
    let onCreateTemplate: () -> Void
    
    var body: some View {
        Button(action: onCreateTemplate) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(LinearGradient.primaryGradient)
                .clipShape(Circle())
                .shadow(color: AppColors.primary.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Create new template")
    }
}

struct GroupedTemplateSection: View {
    let groupName: String
    let templates: [WorkoutTemplate]
    let isMultiSelectMode: Bool
    @Binding var selectedTemplates: Set<UUID>
    let onTapTemplate: (WorkoutTemplate) -> Void
    let onStartTemplate: (WorkoutTemplate) -> Void
    let onDeleteTemplate: (WorkoutTemplate) -> Void
    let onDuplicateTemplate: (WorkoutTemplate) -> Void
    
    @State private var isExpanded = true
    
    // Note: Grouped sections use group-based gradients, individual templates use their own colors
    var gradient: LinearGradient {
        AppColors.categoryGradient(for: groupName)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Group Header
            Button(action: {
                isExpanded.toggle()
                HapticManager.selection()
            }) {
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(gradient)
                            .frame(width: 12, height: 12)
                        
                        Text(groupName)
                            .font(AppTypography.heading3)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("(\(templates.count))")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.mutedForeground)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.mutedForeground)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Templates in Group
            if isExpanded {
                ForEach(templates, id: \.id) { template in
                    RedesignedTemplateCard(
                        template: template,
                        isMultiSelectMode: isMultiSelectMode,
                        isSelected: selectedTemplates.contains(template.id),
                        onTap: { onTapTemplate(template) },
                        onStart: { onStartTemplate(template) }
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if !template.isDefault {
                            Button(role: .destructive) {
                                onDeleteTemplate(template)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            onDuplicateTemplate(template)
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                        .tint(AppColors.accent)
                    }
                }
            }
        }
    }
}
struct TemplateEditView: View {
    @State private var templateName: String
    @State private var exercises: [TemplateExercise]
    @State private var intensity: WorkoutIntensity?
    @State private var templateColorHex: String?
    @State private var newExerciseName: String = ""
    @State private var newExerciseSets: Int = 3
    @State private var newExerciseReps: String = "8-10"
    @State private var newExerciseDropsets: Bool = false
    @State private var newExerciseType: ExerciseType = .weightReps
    @State private var newExerciseHoldDuration: Int = 30
    @State private var showAddCustomExercise = false
    @State private var showClearTemplateConfirmation = false
    @ObservedObject private var exerciseDataManager = ExerciseDataManager.shared
    
    private let originalTemplate: WorkoutTemplate?
    let onSave: (WorkoutTemplate) -> Void
    let onCancel: () -> Void
    let onDelete: (() -> Void)?
    
    init(template: WorkoutTemplate?, onSave: @escaping (WorkoutTemplate) -> Void, onCancel: @escaping () -> Void, onDelete: (() -> Void)? = nil) {
        self.originalTemplate = template
        if let template = template {
            _templateName = State(initialValue: template.name)
            _exercises = State(initialValue: template.exercises)
            _intensity = State(initialValue: template.intensity)
            _templateColorHex = State(initialValue: template.colorHex)
        } else {
            _templateName = State(initialValue: "")
            _exercises = State(initialValue: [])
            _intensity = State(initialValue: nil)
            _templateColorHex = State(initialValue: nil)
        }
        self.onSave = onSave
        self.onCancel = onCancel
        self.onDelete = onDelete
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Template Name
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Template Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        TextField("e.g., Push Day", text: $templateName)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.foreground)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(AppColors.input)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.border, lineWidth: 2)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Intensity Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Intensity (Optional)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Picker("Intensity", selection: $intensity) {
                            Text("None").tag(WorkoutIntensity?.none)
                            ForEach(WorkoutIntensity.allCases, id: \.self) { intensityOption in
                                Text(intensityOption.rawValue).tag(WorkoutIntensity?.some(intensityOption))
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(AppColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Template Color Selection
                    TemplateColorPicker(selectedColorHex: $templateColorHex)
                    
                    // Exercises List
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Exercises")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                            
                            Spacer()
                            
                            // Clear Template Button (only show if there are exercises)
                            if !exercises.isEmpty {
                                Button(action: {
                                    showClearTemplateConfirmation = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 12))
                                        Text("Clear All")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(AppColors.destructive)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppColors.destructive.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        
                        ForEach(exercises) { exercise in
                            TemplateExerciseEditView(
                                exercise: Binding(
                                    get: { 
                                        exercises.first(where: { $0.id == exercise.id }) ?? exercise
                                    },
                                    set: { newValue in
                                        if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
                                            exercises[index] = newValue
                                        }
                                    }
                                ),
                                onDelete: {
                                    if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
                                        exercises.remove(at: index)
                                    }
                                }
                            )
                        }
                        
                        // Add Exercise Input
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Add Exercise")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.mutedForeground)
                                
                                Spacer()
                                
                                Button(action: {
                                    showAddCustomExercise = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 12))
                                        Text("Create Custom")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundColor(AppColors.primary)
                                }
                            }
                            
                            ExerciseAutocompleteField(
                                text: $newExerciseName,
                                placeholder: "Exercise name",
                                fontSize: 16
                            )
                            
                            HStack(spacing: 12) {
                                // Sets
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Sets")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.mutedForeground)
                                    Stepper(value: $newExerciseSets, in: 1...10) {
                                        Text("\(newExerciseSets)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.foreground)
                                    }
                                }
                                
                                // Reps
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Reps")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.mutedForeground)
                                    TextField("8-10", text: $newExerciseReps)
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.foreground)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(AppColors.input)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                
                                // Dropsets
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Dropsets")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.mutedForeground)
                                    Toggle("", isOn: $newExerciseDropsets)
                                        .toggleStyle(SwitchToggleStyle(tint: AppColors.accent))
                                }
                            }
                            
                            Button(action: {
                                if !newExerciseName.isEmpty {
                                    let newExercise = TemplateExercise(
                                        name: newExerciseName,
                                        sets: newExerciseSets,
                                        reps: newExerciseReps,
                                        dropsets: newExerciseDropsets,
                                        exerciseType: newExerciseType,
                                        targetHoldDuration: newExerciseType == .hold ? newExerciseHoldDuration : nil
                                    )
                                    exercises.append(newExercise)
                                    newExerciseName = ""
                                    newExerciseSets = 3
                                    newExerciseReps = "8-10"
                                    newExerciseDropsets = false
                                    newExerciseType = .weightReps
                                }
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Exercise")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.alabasterGrey)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(LinearGradient.primaryGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(newExerciseName.isEmpty)
                            .opacity(newExerciseName.isEmpty ? 0.6 : 1.0)
                        }
                        .padding(16)
                        .background(AppColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Delete Button (only for editing non-default templates)
                    if onDelete != nil && !(originalTemplate?.isDefault ?? false) {
                        Button(action: {
                            onDelete?()
                        }) {
                            Text("Delete Template")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.destructive)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppColors.secondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(AppColors.destructive, lineWidth: 2)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    
                    // Show message for default templates
                    if originalTemplate?.isDefault ?? false {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(AppColors.primary)
                            Text("This is a default template and cannot be deleted")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.mutedForeground)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(AppColors.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(24)
            }
            .background(AppColors.background)
            .navigationTitle(templateName.isEmpty ? "New Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .sheet(isPresented: $showAddCustomExercise) {
                AddCustomExerciseView { exercise in
                    exerciseDataManager.addCustomExercise(exercise)
                    // Pre-fill the exercise name if it was already typed
                    if newExerciseName.isEmpty {
                        newExerciseName = exercise.name
                    }
                }
            }
            .alert("Clear All Exercises?", isPresented: $showClearTemplateConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    exercises.removeAll()
                }
            } message: {
                Text("This will remove all exercises from the template. This action cannot be undone.")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let template: WorkoutTemplate
                        if let original = originalTemplate {
                            // Preserve ID when editing, keep existing estimatedDuration
                            template = WorkoutTemplate(
                                id: original.id,
                                name: templateName,
                                exercises: exercises,
                                estimatedDuration: original.estimatedDuration,
                                intensity: intensity,
                                colorHex: templateColorHex
                            )
                        } else {
                            // New template gets new ID, use default estimatedDuration
                            template = WorkoutTemplate(
                                name: templateName,
                                exercises: exercises,
                                estimatedDuration: 60,
                                intensity: intensity,
                                colorHex: templateColorHex
                            )
                        }
                        onSave(template)
                    }
                    .disabled(templateName.isEmpty || exercises.isEmpty)
                }
            }
        }
    }
}

struct AddExerciseView: View {
    @State private var exerciseName: String = ""
    @State private var targetSets: Int = 4
    // Local mode used to drive the UI. This maps down to ExerciseType for the model layer.
    private enum ExerciseMode {
        case weights      // Barbell/dumbbell style weight + reps
        case calisthenics // Bodyweight calisthenics: reps + optional additional weight
        case timeBased    // Time-based (cardio / stretching)
    }
    @State private var mode: ExerciseMode = .weights
    @State private var holdDuration: Int = 30
    @State private var showAddCustomExercise = false
    @ObservedObject private var exerciseDataManager = ExerciseDataManager.shared
    let onAdd: (String, Int, ExerciseType, Int) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Exercise Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                            
                            Spacer()
                            
                            Button(action: {
                                showAddCustomExercise = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 14))
                                    Text("Create Custom")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(AppColors.primary)
                            }
                        }
                        
                        ExerciseAutocompleteField(
                            text: $exerciseName,
                            placeholder: "e.g., Bench Press"
                        )
                    }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercise Type")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    HStack(spacing: 12) {
                        // Weights
                        Button(action: { mode = .weights }) {
                            HStack {
                                Image(systemName: "dumbbell.fill")
                                Text("Weights")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(mode == .weights ? AppColors.alabasterGrey : AppColors.foreground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(mode == .weights ? LinearGradient.primaryGradient : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Calisthenics (reps + additional weight)
                        Button(action: { mode = .calisthenics }) {
                            HStack {
                                Image(systemName: "figure.strengthtraining.traditional")
                                Text("Calisthenics")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(mode == .calisthenics ? AppColors.alabasterGrey : AppColors.foreground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(mode == .calisthenics ? LinearGradient.primaryGradient : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Time-based (cardio / stretch)
                        Button(action: { mode = .timeBased }) {
                            HStack {
                                Image(systemName: "timer")
                                Text("Time")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(mode == .timeBased ? AppColors.alabasterGrey : AppColors.foreground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(mode == .timeBased ? LinearGradient.primaryGradient : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                
                if mode == .timeBased {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Target Hold Duration (seconds)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Stepper(value: $holdDuration, in: 5...300, step: 5) {
                            Text("\(holdDuration) seconds")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppColors.foreground)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(AppColors.input)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.border, lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Target Sets")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Stepper(value: $targetSets, in: 1...10) {
                        Text("\(targetSets) sets")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.foreground)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(AppColors.input)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.border, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.foreground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.secondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.border, lineWidth: 2)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    Button(action: {
                        if !exerciseName.isEmpty {
                            let type: ExerciseType = (mode == .timeBased) ? .hold : .weightReps
                            onAdd(exerciseName, targetSets, type, holdDuration)
                        }
                    }) {
                        Text("Add Exercise")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppColors.alabasterGrey)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 14, x: 0, y: 4)
                    }
                    .disabled(exerciseName.isEmpty)
                    .opacity(exerciseName.isEmpty ? 0.6 : 1.0)
                }
                }
                .padding(24)
            }
            .background(AppColors.background)
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddCustomExercise) {
                AddCustomExerciseView { exercise in
                    exerciseDataManager.addCustomExercise(exercise)
                    // Pre-fill the exercise name if it was already typed
                    if exerciseName.isEmpty {
                        exerciseName = exercise.name
                    }
                }
            }
        }
    }
}
