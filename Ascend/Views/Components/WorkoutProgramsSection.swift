import SwiftUI

struct WorkoutProgramsSection: View {
    @ObservedObject var workoutViewModel: WorkoutViewModel
    let onStart: () -> Void
    @State private var selectedProgram: WorkoutProgram?
    @State private var showProgramDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("📋")
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Workout Programs")
                        .font(AppTypography.heading2)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Structured multi-day training plans")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(WorkoutProgramManager.shared.programs) { program in
                        SimpleWorkoutProgramCard(
                            program: program,
                            onTap: {
                                selectedProgram = program
                                showProgramDetail = true
                            }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
        .sheet(isPresented: $showProgramDetail) {
            NavigationView {
                if let program = selectedProgram {
                    WorkoutProgramView(
                        program: program,
                        workoutViewModel: workoutViewModel,
                        programViewModel: workoutViewModel.programViewModel,
                        templatesViewModel: workoutViewModel.templatesViewModel
                    )
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showProgramDetail = false
                            }
                            .foregroundColor(AppColors.primary)
                        }
                    }
                    .onChange(of: workoutViewModel.currentWorkout) { _, newValue in
                        if newValue != nil {
                            showProgramDetail = false
                            onStart()
                        }
                    }
                }
            }
        }
    }
}

struct SimpleWorkoutProgramCard: View {
    let program: WorkoutProgram
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text(program.category.rawValue)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.secondary)
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    Text("\(program.days.count) days")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Text(program.name)
                    .font(AppTypography.heading3)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Text(program.description)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.accent)
                    Text(program.frequency)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(AppSpacing.md)
            .frame(width: 280)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .shadow(color: AppColors.foreground.opacity(0.06), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    WorkoutProgramsSection(
        workoutViewModel: WorkoutViewModel(settingsManager: SettingsManager()),
        onStart: {}
    )
    .padding()
    .background(AppColors.background)
}



