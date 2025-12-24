import SwiftUI

// MARK: - Tutorial Element Identifier

enum TutorialElement: String, Identifiable {
    case dashboardTab
    case workoutTab
    case progressTab
    case templatesTab
    case sportsTimerTab
    case quickStartTemplates
    case generateButton
    case settingsButton
    
    var id: String { rawValue }
}

// MARK: - Spotlight Overlay

struct SpotlightOverlay: View {
    let highlightedElement: TutorialElement?
    let callout: TutorialCallout?
    let showFullOverlay: Bool
    
    init(highlightedElement: TutorialElement?, callout: TutorialCallout?, showFullOverlay: Bool = false) {
        self.highlightedElement = highlightedElement
        self.callout = callout
        self.showFullOverlay = showFullOverlay
    }
    
    var body: some View {
        ZStack {
            // Dark overlay with cutout (or full overlay for welcome/complete)
            if showFullOverlay {
                Color.black.opacity(0.75)
                    .ignoresSafeArea()
            } else {
                Color.black.opacity(0.75)
                    .ignoresSafeArea()
                    .mask(
                        SpotlightMask(highlightedElement: highlightedElement)
                    )
            }
            
            // Callout
            if let callout = callout {
                if let element = highlightedElement {
                    // Callout pointing to specific element
                    TutorialCalloutView(callout: callout, element: element)
                } else {
                    // Centered callout for welcome/complete steps
                    CenteredCalloutView(callout: callout)
                }
            }
        }
    }
}

// MARK: - Spotlight Mask

struct SpotlightMask: View {
    let highlightedElement: TutorialElement?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full dark overlay
                Rectangle()
                    .fill(Color.black)
                
                // Cutout for highlighted element
                if let element = highlightedElement {
                    let frame = frameForElement(element, in: geometry.size)
                    RoundedRectangle(cornerRadius: 12)
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)
                        .blendMode(.destinationOut)
                }
            }
            .compositingGroup()
        }
    }
    
    private func frameForElement(_ element: TutorialElement, in size: CGSize) -> CGRect {
        switch element {
        case .dashboardTab, .workoutTab, .progressTab, .templatesTab, .sportsTimerTab:
            // Bottom navigation bar buttons
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
            
        case .quickStartTemplates:
            // Quick start section in dashboard
            return CGRect(
                x: size.width / 2,
                y: size.height * 0.4,
                width: size.width * 0.9,
                height: 120
            )
            
        case .generateButton, .settingsButton:
            // Buttons in templates header
            return CGRect(
                x: size.width - 60,
                y: 50,
                width: 80,
                height: 40
            )
        }
    }
}

// MARK: - Tutorial Callout

struct TutorialCallout: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let position: CalloutPosition
}

enum CalloutPosition {
    case top
    case bottom
    case left
    case right
}

struct TutorialCalloutView: View {
    let callout: TutorialCallout
    let element: TutorialElement
    
    var body: some View {
        GeometryReader { geometry in
            let elementFrame = frameForElement(element, in: geometry.size)
            let isBottomNav = elementFrame.minY > geometry.size.height * 0.75
            let calloutFrame = calloutFrame(for: callout.position, elementFrame: elementFrame, screenSize: geometry.size, isBottomNav: isBottomNav)
            
            VStack(alignment: .leading, spacing: 12) {
                Text(callout.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(callout.description)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Progress indicator
                HStack(spacing: 6) {
                    ForEach(0..<TutorialStep.allCases.count, id: \.self) { index in
                        Circle()
                            .fill(index == OnboardingManager.shared.currentTutorialStep ? AppColors.primary : AppColors.secondary)
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.top, 4)
            }
            .padding(20)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppColors.foreground.opacity(0.3), radius: 20, x: 0, y: 10)
            .frame(width: min(280, geometry.size.width * 0.85))
            .position(x: calloutFrame.midX, y: calloutFrame.midY)
            
            // Arrow pointing to element - adjust position for bottom nav
            let adjustedPosition = isBottomNav ? CalloutPosition.bottom : callout.position
            ArrowShape(from: calloutFrame, to: elementFrame, position: adjustedPosition)
                .stroke(AppColors.primary, lineWidth: 3)
                .fill(AppColors.primary)
        }
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
    
    private func calloutFrame(for position: CalloutPosition, elementFrame: CGRect, screenSize: CGSize, isBottomNav: Bool) -> CGRect {
        let calloutWidth: CGFloat = min(280, screenSize.width * 0.85)
        let calloutHeight: CGFloat = 180
        
        // For bottom navigation tabs, position callout in upper-middle area to avoid overlap
        if isBottomNav {
            return CGRect(
                x: screenSize.width / 2,
                y: screenSize.height * 0.35, // Upper-middle area, well above nav bar
                width: calloutWidth,
                height: calloutHeight
            )
        }
        
        // For other elements, use standard positioning
        switch position {
        case .top:
            return CGRect(
                x: elementFrame.midX,
                y: elementFrame.minY - calloutHeight / 2 - 30,
                width: calloutWidth,
                height: calloutHeight
            )
        case .bottom:
            return CGRect(
                x: elementFrame.midX,
                y: elementFrame.maxY + calloutHeight / 2 + 30,
                width: calloutWidth,
                height: calloutHeight
            )
        case .left:
            return CGRect(
                x: elementFrame.minX - calloutWidth / 2 - 20,
                y: elementFrame.midY,
                width: calloutWidth,
                height: calloutHeight
            )
        case .right:
            return CGRect(
                x: elementFrame.maxX + calloutWidth / 2 + 20,
                y: elementFrame.midY,
                width: calloutWidth,
                height: calloutHeight
            )
        }
    }
}

// MARK: - Arrow Shape

struct ArrowShape: Shape {
    let from: CGRect
    let to: CGRect
    let position: CalloutPosition
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let fromPoint: CGPoint
        let toPoint: CGPoint
        
        switch position {
        case .top:
            fromPoint = CGPoint(x: from.midX, y: from.maxY)
            toPoint = CGPoint(x: to.midX, y: to.minY)
        case .bottom:
            fromPoint = CGPoint(x: from.midX, y: from.minY)
            toPoint = CGPoint(x: to.midX, y: to.maxY)
        case .left:
            fromPoint = CGPoint(x: from.maxX, y: from.midY)
            toPoint = CGPoint(x: to.minX, y: to.midY)
        case .right:
            fromPoint = CGPoint(x: from.minX, y: from.midY)
            toPoint = CGPoint(x: to.maxX, y: to.midY)
        }
        
        path.move(to: fromPoint)
        path.addLine(to: toPoint)
        
        // Arrowhead
        let angle = atan2(toPoint.y - fromPoint.y, toPoint.x - fromPoint.x)
        let arrowLength: CGFloat = 10
        let arrowAngle: CGFloat = .pi / 6
        
        let arrowPoint1 = CGPoint(
            x: toPoint.x - arrowLength * cos(angle - arrowAngle),
            y: toPoint.y - arrowLength * sin(angle - arrowAngle)
        )
        let arrowPoint2 = CGPoint(
            x: toPoint.x - arrowLength * cos(angle + arrowAngle),
            y: toPoint.y - arrowLength * sin(angle + arrowAngle)
        )
        
        path.addLine(to: arrowPoint1)
        path.move(to: toPoint)
        path.addLine(to: arrowPoint2)
        
        return path
    }
}

// MARK: - Centered Callout View

struct CenteredCalloutView: View {
    let callout: TutorialCallout
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 12) {
                Text(callout.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(callout.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Progress indicator
                HStack(spacing: 6) {
                    ForEach(0..<TutorialStep.allCases.count, id: \.self) { index in
                        Circle()
                            .fill(index == OnboardingManager.shared.currentTutorialStep ? AppColors.primary : AppColors.secondary)
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.top, 8)
            }
            .padding(24)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: AppColors.foreground.opacity(0.3), radius: 20, x: 0, y: 10)
            .frame(width: min(320, geometry.size.width * 0.9))
            .position(x: geometry.size.width / 2, y: geometry.size.height * 0.4)
        }
    }
}

// MARK: - Tutorial Overlay View

struct TutorialOverlayView: View {
    @ObservedObject var onboardingManager: OnboardingManager
    let onComplete: () -> Void
    @State private var currentStepIndex: Int = 0
    
    private var currentStep: TutorialStep {
        TutorialStep.allCases[currentStepIndex]
    }
    
    private var highlightedElement: TutorialElement? {
        currentStep.highlightedElement
    }
    
    private var callout: TutorialCallout? {
        currentStep.callout
    }
    
    private var isLastStep: Bool {
        currentStepIndex >= TutorialStep.allCases.count - 1
    }
    
    private var isFirstStep: Bool {
        currentStepIndex == 0
    }
    
    var body: some View {
        ZStack {
            // Spotlight overlay
            SpotlightOverlay(
                highlightedElement: highlightedElement,
                callout: callout,
                showFullOverlay: highlightedElement == nil
            )
            
            // Navigation buttons - positioned at top to avoid blocking bottom nav
            VStack {
                HStack {
                    Spacer()
                    
                    // Skip button (only on first step) - top right
                    if isFirstStep {
                        Button(action: {
                            HapticManager.impact(style: .light)
                            onboardingManager.skipTutorial()
                            onComplete()
                        }) {
                            Text("Skip")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(AppColors.card.opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        .padding(.top, 60)
                        .padding(.trailing, 20)
                    }
                }
                
                Spacer()
                
                // Navigation buttons - positioned above navigation bar to avoid blocking
                VStack {
                    Spacer()
                    
                    // Check if we're highlighting a bottom navigation tab
                    let isBottomNavTab = highlightedElement == .dashboardTab || 
                                        highlightedElement == .workoutTab || 
                                        highlightedElement == .progressTab || 
                                        highlightedElement == .templatesTab ||
                                        highlightedElement == .sportsTimerTab
                    
                    HStack(spacing: 12) {
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
                                    .padding(.vertical, 14)
                                    .background(AppColors.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: AppColors.foreground.opacity(0.2), radius: 10, x: 0, y: 4)
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
                            .padding(.vertical, 14)
                            .background(LinearGradient.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 14, x: 0, y: 4)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, isBottomNavTab ? 120 : 100) // Higher for bottom nav tabs
                }
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
