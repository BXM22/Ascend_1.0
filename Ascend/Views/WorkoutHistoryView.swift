import SwiftUI

struct WorkoutHistoryView: View {
    @ObservedObject private var workoutHistoryManager = WorkoutHistoryManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var workoutToDelete: Workout?
    @State private var showDeleteConfirmation = false
    
    @State private var workoutToSaveAsTemplate: Workout?
    @State private var showSaveTemplateModal = false
    @State private var templateName = ""
    
    private var sortedWorkouts: [Workout] {
        workoutHistoryManager.completedWorkouts.sorted { $0.startDate > $1.startDate }
    }
    
    private func groupedWorkouts() -> [(date: Date, workouts: [Workout])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sortedWorkouts) { workout in
            calendar.startOfDay(for: workout.startDate)
        }
        
        return grouped.map { (date: $0.key, workouts: $0.value) }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if sortedWorkouts.isEmpty {
                    emptyStateView
                } else {
                    workoutListView
                }
            }
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
            .alert("Delete Workout", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    workoutToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let workout = workoutToDelete {
                        workoutHistoryManager.deleteWorkout(workout)
                        HapticManager.success()
                        workoutToDelete = nil
                    }
                }
            } message: {
                if let workout = workoutToDelete {
                    Text("Are you sure you want to delete '\(workout.name)'? This action cannot be undone.")
                }
            }
            .alert("Save as Template", isPresented: $showSaveTemplateModal) {
                TextField("Template Name", text: $templateName)
                Button("Cancel", role: .cancel) {
                    workoutToSaveAsTemplate = nil
                    templateName = ""
                }
                Button("Save") {
                    saveWorkoutAsTemplate()
                }
                .disabled(templateName.isEmpty)
            } message: {
                Text("Enter a name for this workout template.")
            }
        }
    }
    
    private func saveWorkoutAsTemplate() {
        guard let workout = workoutToSaveAsTemplate, !templateName.isEmpty else { return }
        
        // Convert Exercise to TemplateExercise
        let templateExercises = workout.exercises.map { exercise in
            // For reps, we try to find a representative value or use a default
            let repsString: String
            if let firstSet = exercise.sets.first {
                repsString = "\(firstSet.reps)"
            } else {
                repsString = "8-12"
            }
            
            return TemplateExercise(
                name: exercise.name,
                sets: exercise.sets.count > 0 ? exercise.sets.count : 3,
                reps: repsString,
                dropsets: exercise.hasDropsets,
                exerciseType: exercise.exerciseType,
                targetHoldDuration: exercise.targetHoldDuration
            )
        }
        
        let newTemplate = WorkoutTemplate(
            name: templateName,
            exercises: templateExercises,
            estimatedDuration: workout.exercises.count * 10 // Estimate 10 mins per exercise
        )
        
        TemplatesViewModel.shared.saveTemplate(newTemplate)
        HapticManager.success()
        
        // Reset state
        workoutToSaveAsTemplate = nil
        templateName = ""
        showSaveTemplateModal = false
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell")
                .font(.system(size: 64))
                .foregroundColor(AppColors.mutedForeground)
            
            Text("No Workouts Yet")
                .font(AppTypography.heading2)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Complete a workout to see it here")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
    
    private var workoutListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(groupedWorkouts(), id: \.date) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        // Date header
                        Text(formatDate(group.date))
                            .font(AppTypography.heading3)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        // Workouts for this date
                        ForEach(group.workouts, id: \.id) { workout in
                            WorkoutHistoryCard(
                                workout: workout,
                                onDelete: {
                                    workoutToDelete = workout
                                    showDeleteConfirmation = true
                                },
                                onSaveAsTemplate: {
                                    workoutToSaveAsTemplate = workout
                                    templateName = workout.name
                                    showSaveTemplateModal = true
                                }
                            )
                        }
                    }
                }
            }
            .padding(.vertical, 20)
        }
        .background(AppColors.background)
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}

struct WorkoutHistoryCard: View {
    let workout: Workout
    let onDelete: () -> Void
    let onSaveAsTemplate: () -> Void
    @State private var isHovered = false
    @State private var isExpanded = false
    
    private var exerciseCount: Int {
        workout.exercises.count
    }
    
    private var totalSets: Int {
        workout.exercises.reduce(0) { $0 + $1.sets.count }
    }
    
    private var duration: String {
        // Calculate approximate duration (could be enhanced with actual duration tracking)
        let estimatedMinutes = exerciseCount * 5 // Rough estimate: 5 min per exercise
        if estimatedMinutes < 60 {
            return "\(estimatedMinutes) min"
        } else {
            let hours = estimatedMinutes / 60
            let minutes = estimatedMinutes % 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: workout.startDate)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 16) {
                    // Time indicator
                    VStack(spacing: 4) {
                        Text(timeString)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                        
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 4, height: 4)
                    }
                    .frame(width: 50)
                    
                    // Workout details
                    VStack(alignment: .leading, spacing: 8) {
                        Text(workout.name)
                            .font(AppTypography.heading4)
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(2)
                        
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "dumbbell.fill")
                                    .font(.system(size: 11))
                                Text("\(exerciseCount)")
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(AppColors.textSecondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 11))
                                Text("\(totalSets)")
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(AppColors.textSecondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 11))
                                Text(duration)
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.mutedForeground)
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(AppColors.border.opacity(0.1))
                        .padding(.horizontal, 16)
                    
                    // Exercises list
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(workout.exercises) { exercise in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                
                                HStack(spacing: 12) {
                                    ForEach(exercise.sets) { set in
                                        Text("\(Int(set.weight))x\(set.reps)")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppColors.textSecondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(AppColors.secondary.opacity(0.5))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    
                    Divider()
                        .background(AppColors.border.opacity(0.1))
                        .padding(.horizontal, 16)
                    
                    // Actions
                    HStack(spacing: 12) {
                        Button(action: {
                            HapticManager.impact(style: .medium)
                            onSaveAsTemplate()
                        }) {
                            HStack {
                                Image(systemName: "plus.square.on.square")
                                Text("Save as Template")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(AppColors.primary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            HapticManager.impact(style: .medium)
                            onDelete()
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.destructive)
                                .padding(10)
                                .background(AppColors.destructive.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.border.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    WorkoutHistoryView()
}

