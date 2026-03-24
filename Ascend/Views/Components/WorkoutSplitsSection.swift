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
    private struct CustomDayDraft: Identifiable, Equatable {
        let id: UUID
        var name: String
        
        init(id: UUID = UUID(), name: String) {
            self.id = id
            self.name = name
        }
    }
    
    private enum CustomDayRowError: String {
        case empty = "Day name is required."
        case duplicate = "Day names must be unique."
    }
    
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    @ObservedObject var templatesViewModel: TemplatesViewModel
    let onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.kineticPalette) private var kp
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var programName: String = ""
    @State private var programDescription: String = ""
    @State private var selectedSplitType: WorkoutSplitType = .pushPullLegs
    @State private var customDays: [CustomDayDraft] = [
        CustomDayDraft(name: "Heavy Pull / Posterior"),
        CustomDayDraft(name: "Anterior Focus / Quads"),
        CustomDayDraft(name: "")
    ]
    @State private var autoGenerateWorkouts = true
    @State private var setAsActiveProgram = false
    @State private var showGenerationSettings = false
    @State private var showValidationErrors = false
    
    private var trimmedName: String { programName.trimmingCharacters(in: .whitespacesAndNewlines) }
    
    private var presetSplitTypes: [WorkoutSplitType] {
        WorkoutSplitType.allCases.filter { $0 != .custom }
    }
    
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
            return customRowErrors.values.allSatisfy { $0 == nil } && !normalizedCustomDayNames.isEmpty
        }
        return true
    }
    
    private var normalizedCustomDayNames: [String] {
        customDays.map { normalizeDayName($0.name) }
    }
    
    private var duplicateNormalizedNames: Set<String> {
        var counts: [String: Int] = [:]
        for name in normalizedCustomDayNames where !name.isEmpty {
            counts[name, default: 0] += 1
        }
        return Set(counts.filter { $0.value > 1 }.map(\.key))
    }
    
    private var customRowErrors: [UUID: CustomDayRowError?] {
        var result: [UUID: CustomDayRowError?] = [:]
        for day in customDays {
            let normalized = normalizeDayName(day.name)
            if normalized.isEmpty {
                result[day.id] = .empty
            } else if duplicateNormalizedNames.contains(normalized) {
                result[day.id] = .duplicate
            } else {
                result[day.id] = nil
            }
        }
        return result
    }
    
    private var showMobileFooterCTA: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        ZStack {
            kp.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                newProgramChromeHeader
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        programIdentitySection
                        blueprintFieldCompact
                        structureAndSplitSection
                        if selectedSplitType == .custom {
                            trainingDaysSection
                        }
                        autoGenerateRow
                        activeProgramRow
                        if !showMobileFooterCTA {
                            createProgramPrimaryButton
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, showMobileFooterCTA ? 120 : 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            
            GeometryReader { geo in
                Circle()
                    .fill(kp.primary.opacity(0.05))
                    .frame(width: 220, height: 220)
                    .blur(radius: 60)
                    .offset(x: geo.size.width - 80, y: -40)
                    .allowsHitTesting(false)
                Circle()
                    .fill(kp.secondaryContainer.opacity(0.12))
                    .frame(width: 280, height: 280)
                    .blur(radius: 70)
                    .offset(x: -60, y: geo.size.height - 120)
                    .allowsHitTesting(false)
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showMobileFooterCTA {
                mobileFooterCTA
            }
        }
        .sheet(isPresented: $showGenerationSettings) {
            WorkoutGenerationSettingsView(settings: $templatesViewModel.generationSettings)
        }
    }
    
    // MARK: - Chrome (close | title | SAVE)
    
    private var newProgramChromeHeader: some View {
        HStack(spacing: 12) {
            Button {
                HapticManager.impact(style: .light)
                onDismiss()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(kp.onSurfaceVariant)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
            
            Spacer()
            
            Text("New Program")
                .font(.custom("Manrope-Bold", size: 20, relativeTo: .title2))
                .foregroundStyle(kp.onSurface)
                .tracking(-0.4)
            
            Spacer()
            
            Button(action: createProgramTapped) {
                Text("SAVE")
                    .font(.custom("Manrope-Bold", size: 13, relativeTo: .caption))
                    .tracking(1.2)
                    .foregroundStyle(canCreate ? kp.onPrimaryContainer : kp.onSurfaceVariant.opacity(0.5))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(canCreate ? kp.primaryContainer : kp.surfaceContainerHighest.opacity(0.5))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canCreate)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // MARK: - Sections
    
    private var programIdentitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Program Identity")
                .font(.custom("Manrope-Bold", size: 11, relativeTo: .caption))
                .tracking(1.6)
                .foregroundStyle(kp.primary)
                .textCase(.uppercase)
            TextField("", text: $programName, prompt: Text("E.g., Hypertrophy Protocol 2.0").foregroundStyle(kp.outlineVariant.opacity(0.9)))
                .font(.custom("Manrope-SemiBold", size: 18, relativeTo: .body))
                .foregroundStyle(kp.onSurface)
                .padding(18)
                .background(kp.surfaceContainerHigh)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
    
    private var blueprintFieldCompact: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Blueprint (optional)")
                .font(.custom("Manrope-Bold", size: 10, relativeTo: .caption))
                .tracking(1.8)
                .foregroundStyle(kp.onSurfaceVariant)
                .textCase(.uppercase)
            TextField("Short description", text: $programDescription, axis: .vertical)
                .font(.custom("Manrope-Medium", size: 14, relativeTo: .body))
                .foregroundStyle(kp.onSurface)
                .lineLimit(2...5)
                .padding(14)
                .background(kp.surfaceContainerHigh.opacity(0.65))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(kp.outlineVariant.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    private var structureAndSplitSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .bottom) {
                Text("Structure & Split")
                    .font(.custom("Manrope-Bold", size: 11, relativeTo: .caption))
                    .tracking(1.6)
                    .foregroundStyle(kp.primary)
                    .textCase(.uppercase)
                Spacer()
                Text("REQUIRED")
                    .font(.custom("Manrope-SemiBold", size: 10, relativeTo: .caption))
                    .foregroundStyle(kp.outlineVariant.opacity(0.85))
            }
            
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(presetSplitTypes, id: \.self) { splitType in
                    splitGridCell(splitType)
                }
            }
            
            splitGridCell(.custom)
        }
    }
    
    private func splitGridCell(_ splitType: WorkoutSplitType) -> some View {
        let selected = selectedSplitType == splitType
        return Button {
            selectedSplitType = splitType
            HapticManager.selection()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(splitShortTitle(splitType))
                        .font(.custom("Manrope-Bold", size: 14, relativeTo: .body))
                        .foregroundStyle(selected ? kp.primary : kp.onSurface)
                        .multilineTextAlignment(.leading)
                    Text(splitSubtitle(splitType))
                        .font(.custom("Manrope-Medium", size: 10, relativeTo: .caption))
                        .foregroundStyle(selected ? kp.primary.opacity(0.88) : kp.onSurfaceVariant)
                        .lineLimit(splitType == .custom ? 2 : 3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(kp.primary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selected ? kp.primaryContainer.opacity(0.22) : kp.surfaceContainerHighest)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        selected ? kp.primary.opacity(0.55) : kp.outlineVariant.opacity(0.12),
                        lineWidth: selected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var trainingDaysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Training Days")
                    .font(.custom("Manrope-Bold", size: 11, relativeTo: .caption))
                    .tracking(1.4)
                    .foregroundStyle(kp.onSurfaceVariant)
                    .textCase(.uppercase)
                Spacer()
                Button {
                    customDays.append(CustomDayDraft(name: ""))
                    HapticManager.impact(style: .light)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("ADD DAY")
                            .font(.custom("Manrope-Bold", size: 11, relativeTo: .caption))
                    }
                    .foregroundStyle(kp.primary)
                }
                .buttonStyle(.plain)
            }
            
            ForEach(Array(customDays.enumerated()), id: \.element.id) { index, day in
                trainingDayRow(index: index, day: day)
            }
        }
    }
    
    private func trainingDayRow(index: Int, day: CustomDayDraft) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Text(String(format: "%02d", index + 1))
                    .font(.custom("Manrope-Bold", size: 10, relativeTo: .caption))
                    .foregroundStyle(kp.outlineVariant)
                    .frame(width: 22, alignment: .leading)
                TextField(
                    "Name this training day…",
                    text: customDayBinding(for: day.id)
                )
                .font(.custom("Manrope-Medium", size: 14, relativeTo: .body))
                .foregroundStyle(kp.onSurface)
                
                HStack(spacing: 4) {
                    Button {
                        moveCustomDayUp(day.id)
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(kp.onSurfaceVariant)
                    }
                    .buttonStyle(.plain)
                    .disabled(index == 0)
                    .accessibilityLabel("Move day up")
                    
                    Button {
                        moveCustomDayDown(day.id)
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(kp.onSurfaceVariant)
                    }
                    .buttonStyle(.plain)
                    .disabled(index == customDays.count - 1)
                    .accessibilityLabel("Move day down")
                }
                
                if customDays.count > 1 {
                    Button {
                        removeCustomDay(day.id)
                        HapticManager.impact(style: .light)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 18))
                            .foregroundStyle(AppColors.destructive.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove day")
                }
            }
            
            if showValidationErrors, let err = customRowErrors[day.id] ?? nil {
                Text(err.rawValue)
                    .font(.custom("Manrope-Medium", size: 11, relativeTo: .caption))
                    .foregroundStyle(AppColors.destructive)
                    .padding(.leading, 34)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(kp.surfaceContainerLow)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    (showValidationErrors && (customRowErrors[day.id] ?? nil) != nil)
                    ? AppColors.destructive.opacity(0.5)
                    : kp.outlineVariant.opacity(0.15),
                    lineWidth: 1
                )
        )
    }
    
    private var autoGenerateRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $autoGenerateWorkouts) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auto-generate workouts")
                        .font(.custom("Manrope-Bold", size: 14, relativeTo: .body))
                        .foregroundStyle(kp.onSurface)
                    Text("Populate exercises from your Kinetic generator rules for each training day.")
                        .font(.custom("Manrope-Medium", size: 12, relativeTo: .caption))
                        .foregroundStyle(kp.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(kp.primary)
            Button {
                showGenerationSettings = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                    Text("Generator settings")
                }
                .font(.custom("Manrope-SemiBold", size: 13, relativeTo: .subheadline))
                .foregroundStyle(kp.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(kp.surfaceContainerHigh.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    
    private var activeProgramRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $setAsActiveProgram) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Set as active program")
                        .font(.custom("Manrope-Bold", size: 14, relativeTo: .body))
                        .foregroundStyle(kp.onSurface)
                    Text("Use this plan for the dashboard program card and day tracking.")
                        .font(.custom("Manrope-Medium", size: 12, relativeTo: .caption))
                        .foregroundStyle(kp.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(kp.primary)
            if let name = existingActiveProgramName {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(kp.secondary)
                    Text("Replaces “\(name)” as your active program.")
                        .font(.custom("Manrope-Medium", size: 11, relativeTo: .caption))
                        .foregroundStyle(kp.onSurfaceVariant)
                }
            }
        }
        .padding(18)
        .background(kp.surfaceContainerHigh.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    
    private var createProgramPrimaryButton: some View {
        Button(action: createProgramTapped) {
            Text("CREATE PROGRAM")
                .font(.custom("Manrope-Bold", size: 14, relativeTo: .body))
                .tracking(2.5)
                .foregroundStyle(kp.onPrimaryContainer)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(kp.primaryContainer)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: kp.primary.opacity(0.22), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!canCreate)
        .opacity(canCreate ? 1 : 0.5)
    }
    
    private var mobileFooterCTA: some View {
        VStack(spacing: 0) {
            createProgramPrimaryButton
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(kp.outlineVariant.opacity(0.12))
                .frame(height: 1)
        }
    }
    
    // MARK: - Split copy helpers
    
    private func splitShortTitle(_ t: WorkoutSplitType) -> String {
        switch t {
        case .pushPullLegs: return "PPL"
        case .chestBackLegsShouldersArms: return "C&B/L"
        case .backBicepsChestTricepsLegsShoulders: return "4-Day BB"
        case .chestBackLegsShouldersArms4Day: return "C/B/L"
        case .upperLower: return "U/L"
        case .fullBody: return "Full Body"
        case .custom: return "Custom"
        }
    }
    
    private func splitSubtitle(_ t: WorkoutSplitType) -> String {
        switch t {
        case .pushPullLegs: return "Push, Pull, Legs"
        case .chestBackLegsShouldersArms: return "Chest & Back / Legs / S&A"
        case .backBicepsChestTricepsLegsShoulders: return "Back&Bi / Chest&Tri / Legs / Shoulders"
        case .chestBackLegsShouldersArms4Day: return "Chest, Back, Legs, S&A"
        case .upperLower: return "Upper, Lower body"
        case .fullBody: return "Total system load"
        case .custom: return "Bespoke training architecture"
        }
    }
    
    // MARK: - Actions
    
    private func createProgramTapped() {
        showValidationErrors = true
        guard canCreate else { return }
        guard let program = buildProgramFromForm() else { return }
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
    
    private func buildProgramFromForm() -> WorkoutProgram? {
        let desc = programDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if selectedSplitType == .custom {
            return programViewModel.createCustomProgram(name: trimmedName, description: desc, dayNames: normalizedCustomDayNames)
        }
        return programViewModel.createProgram(name: trimmedName, description: desc, splitType: selectedSplitType)
    }
    
    private func normalizeDayName(_ raw: String) -> String {
        raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
    
    private func customDayBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: { customDays.first(where: { $0.id == id })?.name ?? "" },
            set: { newValue in
                guard let idx = customDays.firstIndex(where: { $0.id == id }) else { return }
                customDays[idx].name = newValue
            }
        )
    }
    
    private func removeCustomDay(_ id: UUID) {
        customDays.removeAll { $0.id == id }
    }
    
    private func moveCustomDayUp(_ id: UUID) {
        guard let idx = customDays.firstIndex(where: { $0.id == id }), idx > 0 else { return }
        customDays.swapAt(idx, idx - 1)
        HapticManager.selection()
    }
    
    private func moveCustomDayDown(_ id: UUID) {
        guard let idx = customDays.firstIndex(where: { $0.id == id }), idx < customDays.count - 1 else { return }
        customDays.swapAt(idx, idx + 1)
        HapticManager.selection()
    }
}

