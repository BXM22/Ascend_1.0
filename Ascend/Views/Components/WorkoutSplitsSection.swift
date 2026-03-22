import SwiftUI

struct WorkoutSplitsSection: View {
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    let onStartWorkout: () -> Void
    /// Section heading (e.g. "Your programs" when shown below the Atelier catalog).
    var sectionTitle: String = "Workout Programs"
    /// When true, only the add button row is shown (use an external kinetic label above).
    var hidesSectionTitle: Bool = false
    @State private var expandedProgramId: UUID?
    @State private var showCreateProgram = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                if !hidesSectionTitle {
                    Text(sectionTitle)
                        .font(AppTypography.heading2)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Spacer()
                
                // Add Program Button in header
                Button(action: {
                    showCreateProgram = true
                    HapticManager.impact(style: .medium)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.primary)
                }
            }
            
            // Programs List
            let splitPrograms = programViewModel.programs.filter { $0.category == .split }
            
            if splitPrograms.isEmpty {
                VStack(spacing: AppSpacing.sm) {
                    Text("No workout programs yet")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Button(action: {
                        showCreateProgram = true
                    }) {
                        Text("Create Your First Program")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.primary)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(AppColors.primary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xl)
            } else {
                ForEach(splitPrograms) { program in
                    WorkoutProgramCard(
                        program: program,
                        templatesViewModel: templatesViewModel,
                        workoutViewModel: workoutViewModel,
                        programViewModel: programViewModel,
                        onStartWorkout: onStartWorkout,
                        isExpanded: expandedProgramId == program.id,
                        onToggleExpand: {
                            withAnimation(AppAnimations.standard) {
                                expandedProgramId = expandedProgramId == program.id ? nil : program.id
                            }
                        },
                        onDelete: {
                            programViewModel.deleteProgram(program)
                        }
                    )
                }
            }
        }
        .sheet(isPresented: $showCreateProgram) {
            CreateWorkoutProgramView(
                programViewModel: programViewModel,
                templatesViewModel: templatesViewModel,
                onDismiss: {
                    showCreateProgram = false
                }
            )
        }
    }
}

struct WorkoutProgramCard: View {
    let program: WorkoutProgram
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    let onStartWorkout: () -> Void
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.name)
                        .font(AppTypography.heading3)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if let splitType = program.splitType {
                        Text(splitType.description)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    } else {
                        Text(program.description)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: AppSpacing.sm) {
                    // Set as Active Button
                    if programViewModel.activeProgram?.programId != program.id {
                        Button(action: {
                            programViewModel.setActiveProgram(program)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "star")
                                    .font(.system(size: 12))
                                Text("Set Active")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(AppColors.accent)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, 6)
                            .background(AppColors.accent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    } else {
                        Button(action: {
                            programViewModel.clearActiveProgram()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                Text("Active")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(AppColors.alabasterGrey)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, 6)
                            .background(LinearGradient.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    
                    Button(action: onToggleExpand) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(AppColors.secondary)
                            .clipShape(Circle())
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.destructive)
                            .frame(width: 32, height: 32)
                            .background(AppColors.destructive.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            
            // Days List (expanded)
            if isExpanded {
                VStack(spacing: AppSpacing.xs) {
                    ForEach(Array(program.days.enumerated()), id: \.element.id) { index, day in
                        WorkoutProgramDayRow(
                            day: day,
                            dayIndex: index,
                            program: program,
                            templatesViewModel: templatesViewModel,
                            programViewModel: programViewModel,
                            workoutViewModel: workoutViewModel,
                            onStartWorkout: onStartWorkout,
                            isCompleted: programViewModel.isDayCompleted(index, inProgram: program.id),
                            onToggleCompletion: {
                                if programViewModel.isDayCompleted(index, inProgram: program.id) {
                                    programViewModel.unmarkDayAsCompleted(index, inProgram: program.id)
                                } else {
                                    programViewModel.markDayAsCompleted(index, inProgram: program.id)
                                }
                            }
                        )
                    }
                }
                .padding(.top, AppSpacing.sm)
                .onAppear {
                    // Preload template data for all visible days
                    preloadDayTemplates(program: program)
                }
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.border)
                .offset(x: 4, y: 4)
        )
        .shadow(color: AppColors.foreground.opacity(0.08), radius: 8, x: 0, y: 2)
    }
    
    private func preloadDayTemplates(program: WorkoutProgram) {
        // Preload templates for all days in the program
        for day in program.days {
            if let templateId = day.templateId {
                // Check if already cached
                if CardDetailCacheManager.shared.getCachedTemplate(templateId) == nil {
                    // Try to find and cache the template
                    if let template = templatesViewModel.templates.first(where: { $0.id == templateId }) {
                        CardDetailCacheManager.shared.cacheTemplate(template)
                    }
                }
            }
            
            // Preload day type info if available
            if let dayType = WorkoutDayTypeExtractor.extract(from: day.name) {
                // Check if already cached
                if CardDetailCacheManager.shared.getCachedDayTypeInfo(day.name) == nil {
                    // Get suggested templates
                    let suggested = templatesViewModel.suggestTemplatesForDayType(dayType)
                    // Cache day type info (gradient and icon are computed in the view, not cached)
                    CardDetailCacheManager.shared.cacheDayTypeInfo(
                        day.name,
                        dayType: dayType,
                        suggestedTemplates: suggested
                    )
                }
            }
        }
    }
    
}

struct WorkoutProgramDayRow: View {
    let day: WorkoutDay
    let dayIndex: Int
    let program: WorkoutProgram
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    let onStartWorkout: () -> Void
    let isCompleted: Bool
    let onToggleCompletion: () -> Void
    
    @State private var showTemplatePicker = false
    @State private var showAutoGenerate = false
    @State private var isExpanded: Bool = false
    
    var selectedTemplate: WorkoutTemplate? {
        guard let templateId = day.templateId else { return nil }
        return templatesViewModel.templates.first { $0.id == templateId }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Completion Checkbox
                Button(action: onToggleCompletion) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(isCompleted ? AppColors.accent : AppColors.textSecondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Day Name (tappable to expand) with inline day type badge
                HStack(spacing: 6) {
                    Button(action: {
                        if !day.isRestDay {
                            withAnimation(AppAnimations.smooth) {
                                isExpanded.toggle()
                            }
                            HapticManager.impact(style: .light)
                        }
                    }) {
                        Text(day.name)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(day.isRestDay ? AppColors.textSecondary : (isCompleted ? AppColors.textSecondary : AppColors.textPrimary))
                            .strikethrough(isCompleted && !day.isRestDay)
                            .frame(width: 100, alignment: .leading)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(day.isRestDay)
                    
                    // Inline day type badge
                    if !day.isRestDay, let dayType = WorkoutDayTypeExtractor.extract(from: day.name) {
                        Text(dayType)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(dayTypeGradient(for: dayType))
                            .clipShape(Capsule())
                    }
                }
                
                // Template Selection
                if day.isRestDay {
                    Text("Rest Day")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .italic()
                    Spacer()
                } else {
                    if let template = selectedTemplate {
                        HStack(spacing: AppSpacing.xs) {
                            Text(template.name)
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Button(action: {
                                if let templateId = day.templateId,
                                   let template = templatesViewModel.templates.first(where: { $0.id == templateId }) {
                                    templatesViewModel.startTemplate(template, workoutViewModel: workoutViewModel)
                                    onStartWorkout()
                                }
                            }) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppColors.accent)
                            }
                            
                            Button(action: {
                                programViewModel.removeTemplate(fromDay: dayIndex, inProgram: program.id)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        HStack(spacing: AppSpacing.xs) {
                            Button(action: {
                                showTemplatePicker = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle")
                                    Text("Add Template")
                                }
                                .font(AppTypography.captionMedium)
                                .foregroundColor(AppColors.accent)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, AppSpacing.xs)
                                .background(AppColors.secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            Button(action: {
                                // Auto-generate template
                                let generatedTemplate = programViewModel.autoGenerateTemplate(
                                    forDay: day,
                                    inProgram: program,
                                    settings: templatesViewModel.generationSettings
                                )
                                templatesViewModel.saveTemplate(generatedTemplate)
                                programViewModel.assignTemplate(generatedTemplate.id, toDay: dayIndex, inProgram: program.id, templatesViewModel: templatesViewModel)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                    Text("Auto Generate")
                                }
                                .font(AppTypography.captionMedium)
                                .foregroundColor(AppColors.primary)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, AppSpacing.xs)
                                .background(AppColors.primary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Expand/Collapse indicator
                    if !day.isRestDay {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.leading, AppSpacing.xs)
                    }
                }
            }
            
            // Day Type Info Card (expanded)
            if isExpanded && !day.isRestDay {
                DayTypeInfoCard(
                    day: day,
                    dayIndex: dayIndex,
                    program: program,
                    templatesViewModel: templatesViewModel,
                    programViewModel: programViewModel
                )
                .padding(.top, AppSpacing.sm)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(AppAnimations.smooth, value: isExpanded)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showTemplatePicker) {
            TemplatePickerView(
                templates: templatesViewModel.templates,
                onSelect: { template in
                    programViewModel.assignTemplate(template.id, toDay: dayIndex, inProgram: program.id, templatesViewModel: templatesViewModel)
                    showTemplatePicker = false
                },
                onCancel: {
                    showTemplatePicker = false
                }
            )
        }
    }
    
    private func dayTypeGradient(for dayType: String) -> LinearGradient {
        let dayTypeLower = dayType.lowercased()
        if dayTypeLower.contains("push") || dayTypeLower.contains("chest") {
            return LinearGradient.chestGradient
        } else if dayTypeLower.contains("pull") || dayTypeLower.contains("back") {
            return LinearGradient.backGradient
        } else if dayTypeLower.contains("leg") {
            return LinearGradient.legsGradient
        } else if dayTypeLower.contains("arm") {
            return LinearGradient.armsGradient
        } else if dayTypeLower.contains("core") {
            return LinearGradient.coreGradient
        } else {
            return LinearGradient.primaryGradient
        }
    }
}

struct TemplatePickerView: View {
    let templates: [WorkoutTemplate]
    let onSelect: (WorkoutTemplate) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) var dismiss
    
    // Filter out progression templates from picker
    var availableTemplates: [WorkoutTemplate] {
        templates.filter { !$0.name.contains("Progression") }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(availableTemplates) { template in
                        Button(action: {
                            onSelect(template)
                            dismiss()
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textPrimary)
                                Text("\(template.exercises.count) exercises\(template.intensity != nil ? " • \(template.intensity!.rawValue)" : "")")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(AppSpacing.md)
                            .background(AppColors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(AppSpacing.md)
            }
            .background(AppColors.background)
            .navigationTitle("Select Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
        }
    }
}

struct CreateWorkoutProgramView: View {
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    @ObservedObject var templatesViewModel: TemplatesViewModel
    let onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.kineticPalette) private var kp
    
    @State private var programName: String = ""
    @State private var programDescription: String = ""
    @State private var selectedSplitType: WorkoutSplitType = .pushPullLegs
    @State private var customDayNames: [String] = ["Day 1", "Day 2", "Rest"]
    @State private var newDayName: String = ""
    @State private var autoGenerateWorkouts = true
    @State private var setAsActiveProgram = false
    @State private var showGenerationSettings = false
    
    private var trimmedName: String { programName.trimmingCharacters(in: .whitespacesAndNewlines) }
    
    /// Name of the program currently marked active (for replacement copy).
    private var existingActiveProgramName: String? {
        guard let active = programViewModel.activeProgram,
              let current = programViewModel.programs.first(where: { $0.id == active.programId }) else {
            return nil
        }
        return current.name
    }
    private var canCreate: Bool {
        guard !trimmedName.isEmpty else { return false }
        if selectedSplitType == .custom {
            let names = customDayNames.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            return !names.isEmpty
        }
        return true
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    headerBlock
                    nameField
                    blueprintField
                    splitSection
                    if selectedSplitType == .custom {
                        customDaysEditor
                    }
                    autoGenerateSection
                    activeProgramSection
                    createButton
                }
                .padding(.horizontal, AppConstants.UI.mainColumnGutter)
                .padding(.vertical, 24)
                .padding(.bottom, 32)
            }
            .background(kp.background.ignoresSafeArea())
            .navigationTitle("New program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onDismiss()
                        dismiss()
                    }
                    .font(.custom("Manrope-SemiBold", size: 16, relativeTo: .body))
                    .foregroundStyle(kp.primary)
                }
            }
            .sheet(isPresented: $showGenerationSettings) {
                WorkoutGenerationSettingsView(settings: $templatesViewModel.generationSettings)
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
    
    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Define your split")
                .font(.custom("Manrope-ExtraBold", size: 22, relativeTo: .title2))
                .foregroundStyle(kp.onSurface)
            Text("Name it, choose a structure—then optionally generate exercises for every training day from your generator settings.")
                .font(.custom("Manrope-Medium", size: 14, relativeTo: .subheadline))
                .foregroundStyle(kp.onSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var nameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROGRAM NAME")
                .font(.custom("Manrope-Bold", size: 10, relativeTo: .caption))
                .tracking(2)
                .foregroundStyle(kp.primary)
            TextField("e.g. My offseason PPL", text: $programName)
                .font(.custom("Manrope-SemiBold", size: 17, relativeTo: .body))
                .foregroundStyle(kp.onSurface)
                .padding(16)
                .background(kp.surfaceContainerHigh)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(kp.outlineVariant.opacity(0.35), lineWidth: 1)
                )
        }
    }
    
    private var blueprintField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("THE BLUEPRINT")
                .font(.custom("Manrope-Bold", size: 10, relativeTo: .caption))
                .tracking(2)
                .foregroundStyle(kp.primary)
            TextField("Short description (optional)", text: $programDescription, axis: .vertical)
                .font(.custom("Manrope-Medium", size: 15, relativeTo: .body))
                .foregroundStyle(kp.onSurface)
                .lineLimit(3...6)
                .padding(16)
                .background(kp.surfaceContainerHigh)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(kp.outlineVariant.opacity(0.35), lineWidth: 1)
                )
        }
    }
    
    private var splitSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SPLIT TYPE")
                .font(.custom("Manrope-Bold", size: 10, relativeTo: .caption))
                .tracking(2)
                .foregroundStyle(kp.primary)
            VStack(spacing: 12) {
                ForEach(WorkoutSplitType.allCases, id: \.self) { splitType in
                    splitTypeCard(splitType)
                }
            }
        }
    }
    
    private func splitTypeCard(_ splitType: WorkoutSplitType) -> some View {
        let selected = selectedSplitType == splitType
        return Button {
            selectedSplitType = splitType
            HapticManager.selection()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(splitType.rawValue)
                        .font(.custom("Manrope-Bold", size: 16, relativeTo: .body))
                        .foregroundStyle(selected ? kp.onPrimaryContainer : kp.onSurface)
                        .multilineTextAlignment(.leading)
                    Text(splitType.description)
                        .font(.custom("Manrope-Medium", size: 12, relativeTo: .caption))
                        .foregroundStyle(selected ? kp.onPrimaryContainer.opacity(0.85) : kp.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(kp.primary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selected ? kp.primaryContainer.opacity(0.35) : kp.surfaceContainerHigh)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected ? kp.primary.opacity(0.65) : kp.outlineVariant.opacity(0.3), lineWidth: selected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var customDaysEditor: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("CUSTOM DAYS")
                .font(.custom("Manrope-Bold", size: 10, relativeTo: .caption))
                .tracking(2)
                .foregroundStyle(kp.primary)
            VStack(spacing: 10) {
                ForEach(Array(customDayNames.enumerated()), id: \.offset) { index, _ in
                    HStack(spacing: 10) {
                        TextField("Day name", text: Binding(
                            get: { customDayNames[index] },
                            set: { customDayNames[index] = $0 }
                        ))
                        .font(.custom("Manrope-Medium", size: 15, relativeTo: .body))
                        .foregroundStyle(kp.onSurface)
                        .padding(12)
                        .background(kp.surfaceContainerLow)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        Button {
                            customDayNames.remove(at: index)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(kp.onSurfaceVariant)
                        }
                    }
                }
                HStack(spacing: 10) {
                    TextField("Add day", text: $newDayName)
                        .font(.custom("Manrope-Medium", size: 15, relativeTo: .body))
                        .foregroundStyle(kp.onSurface)
                        .padding(12)
                        .background(kp.surfaceContainerLow)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Button {
                        let t = newDayName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !t.isEmpty else { return }
                        customDayNames.append(t)
                        newDayName = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(kp.primary)
                    }
                    .disabled(newDayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(16)
            .background(kp.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(kp.outlineVariant.opacity(0.25), lineWidth: 1)
            )
        }
    }
    
    private var autoGenerateSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $autoGenerateWorkouts) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Auto-generate workouts")
                        .font(.custom("Manrope-Bold", size: 16, relativeTo: .body))
                        .foregroundStyle(kp.onSurface)
                    Text("Creates a saved template and exercise list for each training day (push/pull/legs, upper/lower, etc.) from your generator rules.")
                        .font(.custom("Manrope-Medium", size: 12, relativeTo: .caption))
                        .foregroundStyle(kp.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(kp.primaryContainer)
            Button {
                showGenerationSettings = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                    Text("Generator settings")
                }
                .font(.custom("Manrope-SemiBold", size: 14, relativeTo: .subheadline))
                .foregroundStyle(kp.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(kp.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(kp.outlineVariant.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var activeProgramSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $setAsActiveProgram) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Set as active program")
                        .font(.custom("Manrope-Bold", size: 16, relativeTo: .body))
                        .foregroundStyle(kp.onSurface)
                    Text("Uses this plan for the dashboard program card, calendar alignment, and day tracking.")
                        .font(.custom("Manrope-Medium", size: 12, relativeTo: .caption))
                        .foregroundStyle(kp.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(kp.primaryContainer)
            if let name = existingActiveProgramName {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(kp.secondary)
                    Text("Turning this on replaces “\(name)” as your active program.")
                        .font(.custom("Manrope-Medium", size: 12, relativeTo: .caption))
                        .foregroundStyle(kp.onSurfaceVariant)
                }
            }
        }
        .padding(18)
        .background(kp.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(kp.outlineVariant.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var createButton: some View {
        Button(action: createProgramTapped) {
            Text("Create program")
                .font(.custom("Manrope-Bold", size: 17, relativeTo: .body))
                .tracking(0.5)
                .foregroundStyle(kp.onPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(LinearGradient.heroCTA)
                .clipShape(Capsule())
                .shadow(color: kp.primaryContainer.opacity(0.35), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!canCreate)
        .opacity(canCreate ? 1 : 0.55)
    }
    
    private func createProgramTapped() {
        guard canCreate else { return }
        let desc = programDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let program: WorkoutProgram
        if selectedSplitType == .custom {
            let names = customDayNames.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            program = programViewModel.createCustomProgram(name: trimmedName, description: desc, dayNames: names)
        } else {
            program = programViewModel.createProgram(name: trimmedName, description: desc, splitType: selectedSplitType)
        }
        if autoGenerateWorkouts {
            programViewModel.populateProgramDaysWithAutoGeneratedWorkouts(
                programId: program.id,
                settings: templatesViewModel.generationSettings,
                templatesViewModel: templatesViewModel
            )
        }
        if setAsActiveProgram {
            programViewModel.setActiveProgram(program)
        }
        HapticManager.success()
        onDismiss()
        dismiss()
    }
}

