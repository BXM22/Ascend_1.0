//
//  ProgressInsightCard.swift
//  Ascend
//
//  Created on 2025
//

import SwiftUI

struct InsightCard: View {
    let insight: ProgressInsight
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(insight.gradient.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: insight.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(insight.gradient)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(insight.message)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 8)
    }
}

// MARK: - Enhanced Stat Card

struct EnhancedStatCard: View {
    let icon: String
    let gradient: LinearGradient
    let primaryValue: String
    let primaryLabel: String
    let secondaryValue: String
    let secondaryLabel: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(gradient)
                
                Text(primaryLabel)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.mutedForeground)
                    .textCase(.uppercase)
            }
            
            Text(primaryValue)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(gradient)
            
            Divider()
                .background(AppColors.border.opacity(0.3))
            
            HStack {
                Text(secondaryValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(secondaryLabel)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.mutedForeground)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(gradient.opacity(0.2), lineWidth: 2)
        )
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 8)
    }
}

// MARK: - Stat Pill (for stats grid)

struct StatPill: View {
    let value: String
    let label: String
    let gradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(gradient)
            
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let subtitle: String?
    
    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Top Exercise Card (for Overview tab)

struct TopExerciseCard: View {
    let exercise: String
    let prCount: Int
    let gradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(gradient)
            }
            
            VStack(spacing: 4) {
                Text(exercise)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text("\(prCount) PRs")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.mutedForeground)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 4)
    }
}

// MARK: - Recent PR Card (for Overview tab)

struct RecentPRCard: View {
    let pr: PersonalRecord
    
    var gradient: LinearGradient {
        AppColors.categoryGradient(for: pr.exercise)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(gradient)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pr.exercise)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                Text("\(Int(pr.weight)) lbs × \(pr.reps)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(gradient)
            }
            
            Spacer()
            
            Text(pr.date, style: .relative)
                .font(.system(size: 12))
                .foregroundColor(AppColors.mutedForeground)
        }
        .padding(12)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: AppColors.foreground.opacity(0.03), radius: 4)
    }
}

// MARK: - Manual PR Entry Sheet

struct ManualPREntrySheet: View {
    @Environment(\.dismiss) var dismiss
    let exercise: String
    @ObservedObject var viewModel: ProgressViewModel
    
    @State private var weight: Double = 0
    @State private var reps: Int = 1
    @State private var date: Date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Exercise") {
                    Text(exercise)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Section("Details") {
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("0", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                        Text("lbs")
                    }
                    
                    Stepper("Reps: \(reps)", value: $reps, in: 1...100)
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle("Add Manual PR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticManager.impact(style: .light)
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let isNewPR = viewModel.addOrUpdatePR(
                            exercise: exercise,
                            weight: weight,
                            reps: reps,
                            date: date
                        )
                        if isNewPR {
                            HapticManager.success()
                        } else {
                            HapticManager.impact(style: .medium)
                        }
                        dismiss()
                    }
                    .disabled(weight <= 0)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
