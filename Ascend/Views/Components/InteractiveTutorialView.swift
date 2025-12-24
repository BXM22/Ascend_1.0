import SwiftUI

// MARK: - Interactive Tutorial System

struct InteractiveTutorialView: View {
    @ObservedObject var onboardingManager: OnboardingManager
    let onComplete: () -> Void
    @State private var currentStepIndex: Int = 0
    @State private var highlightPulse: Bool = false
    
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
            // Main tutorial content
            VStack(spacing: 0) {
                // Top skip button (only on first step)
                if isFirstStep {
                    HStack {
                        Spacer()
                        Button(action: {
                            HapticManager.impact(style: .light)
                            onboardingManager.skipTutorial()
                            onComplete()
                        }) {
                            Text("Skip Tutorial")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(AppColors.card.opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        .padding(.top, 50)
                        .padding(.trailing, 20)
                    }
                }
                
                Spacer()
                
                // Interactive callout card
                if let callout = currentStep.callout {
                    InteractiveCalloutCard(
                        callout: callout,
                        currentStep: currentStepIndex,
                        totalSteps: TutorialStep.allCases.count,
                        highlightedElement: currentStep.highlightedElement,
                        onNext: {
                            if isLastStep {
                                onboardingManager.completeTutorial()
                                onComplete()
                            } else {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    currentStepIndex += 1
                                    onboardingManager.nextStep()
                                }
                            }
                        },
                        onPrevious: {
                            if !isFirstStep {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    currentStepIndex -= 1
                                    onboardingManager.previousStep()
                                }
                            }
                        },
                        showPrevious: !isFirstStep,
                        isLastStep: isLastStep
                    )
                    .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
                
                // Bottom navigation buttons are now integrated into the callout card
                // No need for separate bottom navigation buttons
            }
        }
        .onAppear {
            currentStepIndex = onboardingManager.currentTutorialStep
        }
        .onChange(of: onboardingManager.currentTutorialStep) { _, newValue in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStepIndex = newValue
            }
        }
    }
}

// MARK: - Spotlight Background

struct SpotlightBackground: View {
    let highlightedElement: TutorialElement?
    @State private var pulseAnimation = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full dark overlay
                Color.black.opacity(0.85)
                    .ignoresSafeArea()
                
                // Spotlight cutout for highlighted element
                if let element = highlightedElement {
                    let frame = frameForElement(element, in: geometry.size)
                    
                    // Main cutout - makes the button visible
                    RoundedRectangle(cornerRadius: 16)
                        .frame(width: frame.width + 20, height: frame.height + 20)
                        .position(x: frame.midX, y: frame.midY)
                        .blendMode(.destinationOut)
                }
            }
            .compositingGroup()
        }
    }
    
    private func frameForElement(_ element: TutorialElement, in size: CGSize) -> CGRect {
        return calculateButtonFrame(element: element, size: size)
    }
}

// MARK: - Button Frame Calculation Helper

private func calculateButtonFrame(element: TutorialElement, size: CGSize) -> CGRect {
    switch element {
    case .dashboardTab, .workoutTab, .progressTab, .templatesTab, .sportsTimerTab:
        // Navigation bar layout: HStack with 5 NavButtons
        // Each NavButton uses .frame(maxWidth: .infinity), so they share space equally
        let horizontalPadding: CGFloat = 24 // AppSpacing.lg
        let verticalPadding: CGFloat = 16 // AppSpacing.md
        
        // Calculate available width for navigation buttons
        let totalAvailableWidth = size.width - (2 * horizontalPadding)
        // Each of the 5 NavButtons gets equal space
        let buttonAreaWidth = totalAvailableWidth / 5
        
        // Button dimensions - NavButton uses VStack with icon, text, and indicator
        let buttonHeight: CGFloat = 60 // Approximate height of NavButton content
        let buttonWidth: CGFloat = buttonAreaWidth // NavButton expands to fill its area
        
        // Button index (0-4)
        let buttonIndex: Int
        switch element {
        case .dashboardTab: buttonIndex = 0
        case .workoutTab: buttonIndex = 1
        case .progressTab: buttonIndex = 2
        case .templatesTab: buttonIndex = 3
        case .sportsTimerTab: buttonIndex = 4
        default: buttonIndex = 0
        }
        
        // Calculate X position - each button starts at its allocated area
        let buttonX = horizontalPadding + (CGFloat(buttonIndex) * buttonAreaWidth)
        
        // Calculate Y position - nav bar is at bottom with padding
        // The nav bar background includes vertical padding, so buttons are inset
        let navBarContentHeight = buttonHeight + (verticalPadding * 2)
        let buttonY = size.height - navBarContentHeight + verticalPadding
        
        return CGRect(
            x: buttonX,
            y: buttonY,
            width: buttonWidth,
            height: buttonHeight
        )
        
    case .quickStartTemplates:
        return CGRect(
            x: size.width / 2,
            y: size.height * 0.4,
            width: size.width * 0.9,
            height: 120
        )
        
    case .generateButton, .settingsButton:
        return CGRect(
            x: size.width - 60,
            y: 50,
            width: 80,
            height: 40
        )
    }
}

// MARK: - Interactive Callout Card

struct InteractiveCalloutCard: View {
    let callout: TutorialCallout
    let currentStep: Int
    let totalSteps: Int
    let highlightedElement: TutorialElement?
    let onNext: () -> Void
    let onPrevious: () -> Void
    let showPrevious: Bool
    let isLastStep: Bool
    
    @State private var pulseAnimation = false
    
    var body: some View {
        GeometryReader { geometry in
            let isBottomNav = highlightedElement == .dashboardTab || 
                            highlightedElement == .workoutTab || 
                            highlightedElement == .progressTab || 
                            highlightedElement == .templatesTab ||
                            highlightedElement == .sportsTimerTab
            
            // Position callout based on element type
            let calloutY: CGFloat = isBottomNav ? geometry.size.height * 0.3 : geometry.size.height * 0.4
            let calloutWidth: CGFloat = min(340, geometry.size.width * 0.9)
            let calloutFrame = CGRect(
                x: geometry.size.width / 2 - calloutWidth / 2,
                y: calloutY - 150, // Approximate callout height / 2
                width: calloutWidth,
                height: 300
            )
            
            ZStack {
                // Short arrow pointing to button
                if let element = highlightedElement {
                    let buttonFrame = calculateButtonFrame(element: element, size: geometry.size)
                    ShortArrowShape(
                        from: calloutFrame,
                        to: buttonFrame,
                        maxLength: 80 // Short arrow - max 80 points
                    )
                    .stroke(AppColors.primary, lineWidth: 3)
                    .shadow(color: AppColors.primary.opacity(0.5), radius: 4)
                }
                
                VStack(spacing: 0) {
                // Icon with animation
                ZStack {
                    Circle()
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .opacity(pulseAnimation ? 0.8 : 1.0)
                    
                    Image(systemName: stepIcon)
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 20)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        pulseAnimation = true
                    }
                }
                
                // Title
                Text(callout.title)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)
                
                // Description
                Text(callout.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 24)
                
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<totalSteps, id: \.self) { index in
                        Capsule()
                            .fill(index == currentStep ? AppColors.primary : AppColors.secondary)
                            .frame(width: index == currentStep ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
                    }
                }
                .padding(.bottom, 24)
                
                // Action buttons
                HStack(spacing: 12) {
                    if showPrevious {
                        Button(action: {
                            HapticManager.impact(style: .light)
                            onPrevious()
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
                    
                    Button(action: {
                        HapticManager.impact(style: .medium)
                        onNext()
                    }) {
                        HStack(spacing: 8) {
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
                }
                .padding(28)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: AppColors.foreground.opacity(0.4), radius: 30, x: 0, y: 15)
                .frame(width: calloutWidth)
                .position(x: geometry.size.width / 2, y: calloutY)
            }
        }
    }
    
    private var stepIcon: String {
        TutorialStep.allCases[currentStep].icon
    }
    
    private func frameForElement(_ element: TutorialElement, in size: CGSize) -> CGRect {
        switch element {
        case .dashboardTab, .workoutTab, .progressTab, .templatesTab, .sportsTimerTab:
            let buttonWidth: CGFloat = size.width / 5
            let buttonHeight: CGFloat = 60
            let yPosition = size.height - buttonHeight / 2 - 20
            
            let index: CGFloat
            switch element {
            case .dashboardTab: index = 0.5
            case .workoutTab: index = 1.5
            case .progressTab: index = 2.5
            case .templatesTab: index = 3.5
            case .sportsTimerTab: index = 4.5
            default: index = 0.5
            }
            
            return CGRect(
                x: buttonWidth * index,
                y: yPosition,
                width: buttonWidth * 0.8,
                height: buttonHeight
            )
            
        default:
            return CGRect(x: size.width / 2, y: size.height / 2, width: 100, height: 100)
        }
    }
}


// MARK: - Short Arrow Shape

struct ShortArrowShape: Shape {
    let from: CGRect
    let to: CGRect
    let maxLength: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Calculate direction from callout to button
        let calloutBottomCenter = CGPoint(x: from.midX, y: from.maxY) // Bottom center of callout
        let buttonTopCenter = CGPoint(x: to.midX, y: to.minY) // Top center of button
        
        // Calculate the actual distance
        let dx = buttonTopCenter.x - calloutBottomCenter.x
        let dy = buttonTopCenter.y - calloutBottomCenter.y
        let distance = sqrt(dx * dx + dy * dy)
        let angle = atan2(dy, dx)
        
        // Start arrow from a point closer to the button (80% of the way from callout to button)
        // This makes the arrow appear closer to the button
        let startDistance = distance * 0.8
        let fromPoint = CGPoint(
            x: calloutBottomCenter.x + cos(angle) * startDistance,
            y: calloutBottomCenter.y + sin(angle) * startDistance
        )
        
        // End point is at the button
        let toPoint = buttonTopCenter
        
        // Calculate the remaining distance
        let remainingDx = toPoint.x - fromPoint.x
        let remainingDy = toPoint.y - fromPoint.y
        let remainingDistance = sqrt(remainingDx * remainingDx + remainingDy * remainingDy)
        
        // Limit arrow length to maxLength, but ensure it reaches close to button
        let arrowLength = min(remainingDistance, maxLength)
        
        // Calculate end point of arrow (limited length)
        let arrowEndPoint = CGPoint(
            x: fromPoint.x + cos(angle) * arrowLength,
            y: fromPoint.y + sin(angle) * arrowLength
        )
        
        // Draw arrow line
        path.move(to: fromPoint)
        path.addLine(to: arrowEndPoint)
        
        // Arrowhead
        let arrowheadLength: CGFloat = 8
        let arrowheadAngle: CGFloat = .pi / 6
        
        let arrowPoint1 = CGPoint(
            x: arrowEndPoint.x - arrowheadLength * cos(angle - arrowheadAngle),
            y: arrowEndPoint.y - arrowheadLength * sin(angle - arrowheadAngle)
        )
        let arrowPoint2 = CGPoint(
            x: arrowEndPoint.x - arrowheadLength * cos(angle + arrowheadAngle),
            y: arrowEndPoint.y - arrowheadLength * sin(angle + arrowheadAngle)
        )
        
        path.addLine(to: arrowPoint1)
        path.move(to: arrowEndPoint)
        path.addLine(to: arrowPoint2)
        
        return path
    }
}

// MARK: - Tutorial Navigation Buttons

struct TutorialNavigationButtons: View {
    let onPrevious: () -> Void
    let onNext: () -> Void
    let showPrevious: Bool
    let isLastStep: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if showPrevious {
                Button(action: {
                    HapticManager.impact(style: .light)
                    onPrevious()
                }) {
                    Text("Previous")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: AppColors.foreground.opacity(0.2), radius: 10, x: 0, y: 4)
                }
            }
            
            Button(action: {
                HapticManager.impact(style: .medium)
                onNext()
            }) {
                HStack(spacing: 8) {
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
    }
}

