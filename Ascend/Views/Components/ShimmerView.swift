//
//  ShimmerView.swift
//  Ascend
//
//  Shimmer loading placeholder for card details
//

import SwiftUI

struct ShimmerView: View {
    @State private var phase: CGFloat = -200
    private let duration: Double = 1.5
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base color
                AppColors.card
                
                // Shimmer overlay
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 200)
                .offset(x: phase)
            }
        }
        .onAppear {
            withAnimation(
                Animation.linear(duration: duration)
                    .repeatForever(autoreverses: false)
            ) {
                phase = 400
            }
        }
    }
}

struct CardDetailPlaceholder: View {
    let type: PlaceholderType
    
    enum PlaceholderType {
        case template
        case exercise
        case program
        case history
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Header placeholder
            VStack(spacing: AppSpacing.md) {
                ShimmerView()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                
                ShimmerView()
                    .frame(height: 24)
                    .frame(maxWidth: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                HStack(spacing: 12) {
                    ForEach(0..<3) { _ in
                        ShimmerView()
                            .frame(width: 80, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.top, AppSpacing.md)
            
            // Content placeholder
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                ShimmerView()
                    .frame(height: 20)
                    .frame(maxWidth: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, AppSpacing.lg)
                
                ForEach(Array(0..<(type == .template ? 5 : 3)), id: \.self) { _ in
                    ShimmerView()
                        .frame(height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, AppSpacing.lg)
                }
            }
        }
        .padding(.vertical, AppSpacing.lg)
    }
}

struct ExerciseHistoryPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                ShimmerView()
                    .frame(height: 32)
                    .frame(maxWidth: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                ShimmerView()
                    .frame(height: 16)
                    .frame(maxWidth: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Chart placeholder
            ShimmerView()
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
            
            // List items
            ForEach(0..<5) { _ in
                ShimmerView()
                    .frame(height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
            }
        }
    }
}

struct ErrorStateView: View {
    let message: String
    let error: String?
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColors.destructive)
            
            VStack(spacing: 8) {
                Text(message)
                    .font(AppTypography.heading3)
                    .foregroundColor(AppColors.textPrimary)
                
                if let error = error {
                    Text(error)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.mutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            
            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .font(AppTypography.bodyBold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(LinearGradient.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

