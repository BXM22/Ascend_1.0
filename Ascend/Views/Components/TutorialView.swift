import SwiftUI

struct TutorialView: View {
    @ObservedObject var onboardingManager: OnboardingManager
    let onComplete: () -> Void
    @State private var currentStepIndex: Int = 0
    
    private var currentStep: TutorialStep {
        TutorialStep.allCases[currentStepIndex]
    }
    
    private var isLastStep: Bool {
        currentStepIndex >= TutorialStep.allCases.count - 1
    }
    
    private var isFirstStep: Bool {
        currentStepIndex == 0
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    // Don't dismiss on background tap - require explicit action
                }
            
            VStack(spacing: 0) {
                Spacer()
                
                // Tutorial Card
                VStack(spacing: 24) {
                    // Icon
                    Image(systemName: currentStep.icon)
                        .font(.system(size: 60))
                        .foregroundStyle(LinearGradient.primaryGradient)
                        .padding(.top, 32)
                    
                    // Title
                    Text(currentStep.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    // Description
                    Text(currentStep.description)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                    
                    // Progress Indicator
                    HStack(spacing: 8) {
                        ForEach(0..<TutorialStep.allCases.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentStepIndex ? AppColors.primary : AppColors.secondary)
                                .frame(width: 8, height: 8)
                                .animation(AppAnimations.quick, value: currentStepIndex)
                        }
                    }
                    .padding(.vertical, 16)
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        // Skip button (only on first step)
                        if isFirstStep {
                            Button(action: {
                                HapticManager.impact(style: .light)
                                onboardingManager.skipTutorial()
                                onComplete()
                            }) {
                                Text("Skip")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppColors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(AppColors.secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        
                        // Previous button (not on first step)
                        if !isFirstStep {
                            Button(action: {
                                HapticManager.impact(style: .light)
                                withAnimation(AppAnimations.standard) {
                                    currentStepIndex -= 1
                                    onboardingManager.previousStep()
                                }
                            }) {
                                Text("Previous")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(AppColors.secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        
                        // Next/Complete button
                        Button(action: {
                            HapticManager.impact(style: .medium)
                            if isLastStep {
                                onboardingManager.completeTutorial()
                                onComplete()
                            } else {
                                withAnimation(AppAnimations.standard) {
                                    currentStepIndex += 1
                                    onboardingManager.nextStep()
                                }
                            }
                        }) {
                            HStack {
                                Text(isLastStep ? "Get Started" : "Next")
                                    .font(.system(size: 16, weight: .bold))
                                if !isLastStep {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .bold))
                                }
                            }
                            .foregroundColor(AppColors.alabasterGrey)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 14, x: 0, y: 4)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: AppColors.foreground.opacity(0.3), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
            .onAppear {
                currentStepIndex = onboardingManager.currentTutorialStep
            }
            .onChange(of: onboardingManager.currentTutorialStep) { _, newValue in
                withAnimation(AppAnimations.standard) {
                    currentStepIndex = newValue
                }
            }
    }
}

// MARK: - Tutorial Overlay Modifier

struct TutorialOverlayModifier: ViewModifier {
    @ObservedObject var onboardingManager: OnboardingManager
    let onComplete: () -> Void
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if onboardingManager.showTutorial {
                InteractiveTutorialView(
                    onboardingManager: onboardingManager,
                    onComplete: onComplete
                )
                .transition(.opacity)
                .zIndex(1000)
            }
        }
    }
}

extension View {
    func tutorialOverlay(onboardingManager: OnboardingManager, onComplete: @escaping () -> Void) -> some View {
        self.modifier(TutorialOverlayModifier(onboardingManager: onboardingManager, onComplete: onComplete))
    }
}
