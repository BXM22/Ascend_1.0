//
//  ExerciseDetailSheet.swift
//  Ascend
//
//  Sheet wrapper for ExerciseHistoryView with optimizations
//

import SwiftUI

struct ExerciseDetailSheet: View {
    let exercise: String
    let viewModel: ProgressViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ExerciseHistoryView(
                exerciseName: exercise,
                progressViewModel: viewModel
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                    dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}
