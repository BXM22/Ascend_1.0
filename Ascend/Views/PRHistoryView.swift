//
//  PRHistoryView.swift
//  Ascend
//
//  Created on 2024
//

import SwiftUI

struct PRHistoryView: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    @Environment(\.dismiss) var dismiss
    @State private var searchText: String = ""
    @State private var selectedExercise: String? = nil
    @State private var sortOption: SortOption = .dateDescending
    
    enum SortOption: String, CaseIterable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case exerciseName = "Exercise Name"
        case weightDescending = "Highest Weight"
    }
    
    private var filteredAndSortedPRs: [PersonalRecord] {
        var prs = progressViewModel.prs
        
        // Filter by search text
        if !searchText.isEmpty {
            prs = prs.filter { pr in
                pr.exercise.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by selected exercise
        if let exercise = selectedExercise {
            prs = prs.filter { $0.exercise == exercise }
        }
        
        // Sort
        switch sortOption {
        case .dateDescending:
            return prs.sorted { $0.date > $1.date }
        case .dateAscending:
            return prs.sorted { $0.date < $1.date }
        case .exerciseName:
            return prs.sorted { $0.exercise < $1.exercise }
        case .weightDescending:
            return prs.sorted { ($0.weight, $0.reps) > ($1.weight, $1.reps) }
        }
    }
    
    private var uniqueExercises: [String] {
        Array(Set(progressViewModel.prs.map { $0.exercise })).sorted()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                VStack(spacing: 12) {
                    // Search Bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.mutedForeground)
                        
                        TextField("Search exercises...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppColors.mutedForeground)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Filter and Sort
                    HStack(spacing: 12) {
                        // Exercise Filter
                        Menu {
                            Button("All Exercises") {
                                selectedExercise = nil
                            }
                            
                            ForEach(uniqueExercises, id: \.self) { exercise in
                                Button(exercise) {
                                    selectedExercise = exercise
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                Text(selectedExercise ?? "All Exercises")
                                    .lineLimit(1)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10))
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.foreground)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppColors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        // Sort Option
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(option.rawValue) {
                                    sortOption = option
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.up.arrow.down")
                                Text(sortOption.rawValue)
                                    .lineLimit(1)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10))
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.foreground)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppColors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(AppColors.background)
                
                // PR List
                if filteredAndSortedPRs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "trophy")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Text(searchText.isEmpty && selectedExercise == nil ? "No PRs yet" : "No PRs found")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.foreground)
                        
                        Text(searchText.isEmpty && selectedExercise == nil ? "Complete sets to earn your first PR!" : "Try adjusting your search or filter")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.mutedForeground)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredAndSortedPRs) { pr in
                                PRHistoryListItemView(pr: pr, viewModel: progressViewModel)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .background(AppColors.background)
            .navigationTitle("PR History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

struct PRHistoryListItemView: View {
    let pr: PersonalRecord
    @ObservedObject var viewModel: ProgressViewModel
    @State private var showDeleteConfirmation = false
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: pr.date)
    }
    
    private var relativeDateString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: pr.date, relativeTo: Date())
    }
    
    private var gradient: LinearGradient {
        AppColors.categoryGradient(for: pr.exercise)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Exercise Icon
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(gradient)
            }
            
            // PR Details
            VStack(alignment: .leading, spacing: 6) {
                Text(pr.exercise)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                
                HStack(spacing: 8) {
                    Text("\(Int(pr.weight)) lbs")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(gradient)
                    
                    Text("×")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Text("\(pr.reps) reps")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(gradient)
                }
                
                Text(relativeDateString)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            Spacer()
            
            // Delete Button
            Button(action: {
                HapticManager.impact(style: .light)
                showDeleteConfirmation = true
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.mutedForeground)
                    .frame(width: 36, height: 36)
                    .background(AppColors.secondary.opacity(0.5))
                    .clipShape(Circle())
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(gradient.opacity(0.3), lineWidth: 1.5)
        )
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 8, x: 0, y: 2)
        .alert("Delete Personal Record", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deletePR(pr)
                HapticManager.success()
            }
        } message: {
            Text("Are you sure you want to delete this personal record? This action cannot be undone.")
        }
    }
}




