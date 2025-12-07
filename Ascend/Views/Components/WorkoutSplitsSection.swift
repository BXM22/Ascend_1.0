import SwiftUI

struct WorkoutSplitsSection: View {
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    let onStartWorkout: () -> Void
    @State private var expandedProgramId: UUID?
    @State private var showCreateProgram = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                Text("Workout Programs")
                    .font(AppTypography.heading2)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button(action: {
                    showCreateProgram = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.primary)
                        .frame(width: 36, height: 36)
                        .background(AppColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
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
                VStack(spacing: AppSpacing.sm) {
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
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
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
    
    var selectedTemplate: WorkoutTemplate? {
        guard let templateId = day.templateId else { return nil }
        return templatesViewModel.templates.first { $0.id == templateId }
    }
    
    var body: some View {
        HStack {
            // Completion Checkbox
            Button(action: onToggleCompletion) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isCompleted ? AppColors.accent : AppColors.textSecondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Day Name
            Text(day.name)
                .font(AppTypography.bodyMedium)
                .foregroundColor(day.isRestDay ? AppColors.textSecondary : (isCompleted ? AppColors.textSecondary : AppColors.textPrimary))
                .strikethrough(isCompleted && !day.isRestDay)
                .frame(width: 100, alignment: .leading)
            
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
            }
        }
        .padding(.vertical, AppSpacing.xs)
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
    let onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var programName: String = ""
    @State private var programDescription: String = ""
    @State private var selectedSplitType: WorkoutSplitType = .pushPullLegs
    @State private var customDayNames: [String] = ["Day 1", "Day 2", "Rest"]
    @State private var newDayName: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Program Name
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Program Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        TextField("e.g., My PPL Program", text: $programName)
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
                    
                    // Split Type Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Split Type")
                            .font(AppTypography.heading3)
                            .foregroundColor(AppColors.textPrimary)
                        
                        ForEach(WorkoutSplitType.allCases, id: \.self) { splitType in
                            Button(action: {
                                selectedSplitType = splitType
                            }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(splitType.rawValue)
                                            .font(AppTypography.bodyMedium)
                                            .foregroundColor(selectedSplitType == splitType ? AppColors.alabasterGrey : AppColors.textPrimary)
                                        
                                        Spacer()
                                        
                                        if selectedSplitType == splitType {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(AppColors.alabasterGrey)
                                        }
                                    }
                                    
                                    Text(splitType.description)
                                        .font(AppTypography.caption)
                                        .foregroundColor(selectedSplitType == splitType ? AppColors.alabasterGrey.opacity(0.8) : AppColors.textSecondary)
                                }
                                .padding(AppSpacing.md)
                                .background(selectedSplitType == splitType ? LinearGradient.primaryGradient : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // Custom Split Days Editor
                    if selectedSplitType == .custom {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Custom Days")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                            
                            ForEach(Array(customDayNames.enumerated()), id: \.offset) { index, dayName in
                                HStack {
                                    TextField("Day name", text: Binding(
                                        get: { customDayNames[index] },
                                        set: { customDayNames[index] = $0 }
                                    ))
                                    .font(.system(size: 16))
                                    .foregroundColor(AppColors.foreground)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(AppColors.input)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    Button(action: {
                                        customDayNames.remove(at: index)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(AppColors.destructive)
                                    }
                                }
                            }
                            
                            HStack {
                                TextField("New day name", text: $newDayName)
                                    .font(.system(size: 16))
                                    .foregroundColor(AppColors.foreground)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(AppColors.input)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                Button(action: {
                                    if !newDayName.isEmpty {
                                        customDayNames.append(newDayName)
                                        newDayName = ""
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(AppColors.primary)
                                }
                                .disabled(newDayName.isEmpty)
                            }
                        }
                        .padding(16)
                        .background(AppColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Create Button
                    Button(action: {
                        if !programName.isEmpty {
                            if selectedSplitType == .custom {
                                _ = programViewModel.createCustomProgram(
                                    name: programName,
                                    description: programDescription,
                                    dayNames: customDayNames
                                )
                            } else {
                                _ = programViewModel.createProgram(
                                    name: programName,
                                    description: programDescription,
                                    splitType: selectedSplitType
                                )
                            }
                            onDismiss()
                            dismiss()
                        }
                    }) {
                        Text("Create Program")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppColors.alabasterGrey)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(LinearGradient.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 14, x: 0, y: 4)
                    }
                    .disabled(programName.isEmpty)
                    .opacity(programName.isEmpty ? 0.6 : 1.0)
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle("Create Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onDismiss()
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
}

