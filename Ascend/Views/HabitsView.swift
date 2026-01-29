//
//  HabitsView.swift
//  Ascend
//
//  Created on 2025
//

import SwiftUI

struct HabitsView: View {
    @StateObject private var viewModel: HabitViewModel
    @State private var selectedHabit: Habit?
    
    init(viewModel: HabitViewModel = HabitViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HabitsHeader(
                totalHabits: viewModel.totalHabits,
                todayCompletions: viewModel.todayCompletions,
                completionRate: viewModel.todayCompletionRate,
                onCreateHabit: {
                    viewModel.showCreateHabit = true
                }
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(AppColors.background)
            
            // Content
            if viewModel.totalHabits == 0 {
                // Empty state
                EmptyHabitsView(onCreateHabit: {
                    viewModel.showCreateHabit = true
                })
            } else {
                // Habit list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.activeHabits) { habit in
                            HabitCard(
                                habit: habit,
                                viewModel: viewModel,
                                onTap: {
                                    selectedHabit = habit
                                }
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 100) // Padding for tab bar
                }
            }
        }
        .background(AppColors.background)
        .sheet(isPresented: $viewModel.showCreateHabit) {
            HabitEditView(
                habit: nil,
                onSave: { habit in
                    viewModel.createHabit(habit)
                    viewModel.showCreateHabit = false
                },
                onCancel: {
                    viewModel.showCreateHabit = false
                }
            )
        }
        .sheet(isPresented: $viewModel.showEditHabit) {
            if let habit = viewModel.editingHabit {
                HabitEditView(
                    habit: habit,
                    onSave: { updatedHabit in
                        viewModel.updateHabit(updatedHabit)
                        viewModel.showEditHabit = false
                        viewModel.editingHabit = nil
                    },
                    onCancel: {
                        viewModel.showEditHabit = false
                        viewModel.editingHabit = nil
                    },
                    onDelete: {
                        viewModel.deleteHabit(habit)
                        viewModel.showEditHabit = false
                        viewModel.editingHabit = nil
                    }
                )
            }
        }
        .sheet(item: $selectedHabit) { habit in
            HabitDetailView(
                habit: habit,
                viewModel: viewModel
            )
        }
    }
}

// MARK: - Habits Header
struct HabitsHeader: View {
    let totalHabits: Int
    let todayCompletions: Int
    let completionRate: Double
    let onCreateHabit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Habits")
                    .font(AppTypography.largeTitleBold)
                    .foregroundStyle(LinearGradient.primaryGradient)
                
                Spacer()
                
                Button(action: {
                    HapticManager.impact(style: .light)
                    onCreateHabit()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient.primaryGradient)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Add Habit")
            }
            
            // Stats
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(totalHabits)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.foreground)
                    
                    Text("Total Habits")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(todayCompletions)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.foreground)
                    
                    Text("Today")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(completionRate * 100))%")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.foreground)
                    
                    Text("Complete")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Empty Habits View
struct EmptyHabitsView: View {
    let onCreateHabit: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64))
                .foregroundColor(AppColors.mutedForeground.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Habits Yet")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.foreground)
                
                Text("Create your first habit to start tracking your daily progress")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                HapticManager.impact(style: .medium)
                onCreateHabit()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    
                    Text("Create Habit")
                        .font(AppTypography.buttonBold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(LinearGradient.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
#Preview {
    HabitsView()
}


