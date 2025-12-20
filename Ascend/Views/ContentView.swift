//
//  ContentView.swift
//  WorkoutTracker
//
//  Created on 2024
//

import SwiftUI

struct ContentView: View {
    @StateObject private var progressViewModel: ProgressViewModel
    @StateObject private var templatesViewModel: TemplatesViewModel
    @StateObject private var programViewModel: WorkoutProgramViewModel
    @StateObject private var themeManager: ThemeManager
    @StateObject private var settingsManager: SettingsManager
    @StateObject private var workoutViewModel: WorkoutViewModel
    @StateObject private var onboardingManager = OnboardingManager.shared
    @State private var selectedTab: Tab = .dashboard
    @State private var showSettingsSheet = false
    @Environment(\.colorScheme) var systemColorScheme
    
    init() {
        // Create new ViewModel instances owned by this view
        // This ensures proper lifecycle management with @StateObject
        let progressVM = ProgressViewModel()
        let templatesVM = TemplatesViewModel()
        let programVM = WorkoutProgramViewModel()
        let themeMgr = ThemeManager()
        let settingsMgr = SettingsManager()
        
        // Initialize StateObjects with the new instances
        _progressViewModel = StateObject(wrappedValue: progressVM)
        _templatesViewModel = StateObject(wrappedValue: templatesVM)
        _programViewModel = StateObject(wrappedValue: programVM)
        _themeManager = StateObject(wrappedValue: themeMgr)
        _settingsManager = StateObject(wrappedValue: settingsMgr)
        
        // Create WorkoutViewModel with injected dependencies from the newly created instances
        let workoutVM = WorkoutViewModel(
            settingsManager: settingsMgr,
            progressViewModel: progressVM,
            programViewModel: programVM,
            templatesViewModel: templatesVM,
            themeManager: themeMgr
        )
        
        // Ensure progressViewModel connection is maintained
        // Since progressVM is owned by ContentView as @StateObject, it will persist
        _workoutViewModel = StateObject(wrappedValue: workoutVM)
        
        // Verify connection after initialization
        if workoutVM.progressViewModel == nil {
            workoutVM.reconnectProgressViewModel(progressVM)
        }
    }
    
    enum Tab {
        case dashboard, workout, progress, templates, sportsTimer
    }
    
    var effectiveColorScheme: ColorScheme {
        themeManager.colorScheme ?? systemColorScheme
    }
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
                .id(AppColors.themeID)
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            // Main Content
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView(
                        progressViewModel: progressViewModel,
                        workoutViewModel: workoutViewModel,
                        templatesViewModel: templatesViewModel,
                        programViewModel: programViewModel,
                        themeManager: themeManager,
                        onStartWorkout: {
                            withAnimation(AppAnimations.standard) {
                                selectedTab = .workout
                            }
                        },
                        onSettings: {
                            showSettingsSheet = true
                        },
                        onNavigateToProgress: {
                            withAnimation(AppAnimations.standard) {
                                selectedTab = .progress
                            }
                        }
                    )
                    .id(AppColors.themeID)
                    .transition(.slideFromBottom)
                case .workout:
                    WorkoutView(viewModel: workoutViewModel)
                        .id(AppColors.themeID)
                        .transition(.slideFromBottom)
                case .progress:
                    ProgressView(
                        viewModel: progressViewModel,
                        themeManager: themeManager,
                        onSettings: {
                            showSettingsSheet = true
                        }
                    )
                    .id(AppColors.themeID)
                    .transition(.slideFromBottom)
                case .templates:
                    TemplatesView(
                        viewModel: templatesViewModel,
                        workoutViewModel: workoutViewModel,
                        programViewModel: programViewModel,
                        themeManager: themeManager,
                        onStartTemplate: {
                            withAnimation(AppAnimations.standard) {
                                selectedTab = .workout
                            }
                        },
                        onSettings: {
                            showSettingsSheet = true
                        }
                    )
                    .id(AppColors.themeID)
                    .transition(.slideFromBottom)
                case .sportsTimer:
                    SportsTimerView()
                        .id(AppColors.themeID)
                        .transition(.slideFromBottom)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(AppAnimations.standard, value: selectedTab)
            .environmentObject(settingsManager)
            .environmentObject(ColorThemeProvider.shared)
            
            // Floating Bottom Navigation Bar
            VStack {
                Spacer()
                BottomNavigationBar(
                    selectedTab: $selectedTab,
                    themeManager: themeManager,
                    settingsManager: settingsManager
                )
                .id(AppColors.themeID)
            }
            .ignoresSafeArea(.keyboard)
            .tutorialOverlay(onboardingManager: onboardingManager) {
                // Handle tutorial completion - switch to highlighted tab if needed
                if let highlightTab = TutorialStep.allCases[onboardingManager.currentTutorialStep].highlightTab {
                    withAnimation(AppAnimations.standard) {
                        selectedTab = highlightTab
                    }
                }
            }
            .onChange(of: onboardingManager.currentTutorialStep) { _, newStep in
                // Switch to highlighted tab when tutorial step changes
                if let highlightTab = TutorialStep.allCases[newStep].highlightTab {
                    withAnimation(AppAnimations.standard) {
                        selectedTab = highlightTab
                    }
                }
            }
            
            // Completion Modal - at ZStack level so it appears above everything
            // Only show if workout came from template
            if workoutViewModel.showCompletionModal && workoutViewModel.isFromTemplate {
                if let stats = workoutViewModel.completionStats {
                    WorkoutCompletionModal(
                        stats: stats,
                        onDismiss: {
                            // Clear workout state when modal is dismissed
                            workoutViewModel.currentWorkout = nil
                            workoutViewModel.currentExerciseIndex = 0
                            workoutViewModel.elapsedTime = 0
                            workoutViewModel.showCompletionModal = false
                            workoutViewModel.completionStats = nil
                            workoutViewModel.isFromTemplate = false
                        }
                    )
                    .zIndex(1000) // Ensure modal appears on top of everything
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView(
                settingsManager: settingsManager,
                progressViewModel: progressViewModel,
                templatesViewModel: templatesViewModel,
                programViewModel: programViewModel,
                themeManager: themeManager
            )
        }
        .sheet(isPresented: $templatesViewModel.showCreateTemplate) {
            TemplateEditView(
                template: nil,
                onSave: { template in
                    templatesViewModel.saveTemplate(template)
                },
                onCancel: {
                    templatesViewModel.showCreateTemplate = false
                }
            )
        }
        .sheet(isPresented: $templatesViewModel.showEditTemplate) {
            if let template = templatesViewModel.editingTemplate {
                TemplateEditView(
                    template: template,
                    onSave: { updatedTemplate in
                        templatesViewModel.saveTemplate(updatedTemplate)
                    },
                    onCancel: {
                        templatesViewModel.showEditTemplate = false
                        templatesViewModel.editingTemplate = nil
                    },
                    onDelete: {
                        templatesViewModel.deleteTemplate(template)
                        templatesViewModel.showEditTemplate = false
                        templatesViewModel.editingTemplate = nil
                    }
                )
            }
        }
    }
}

struct BottomNavigationBar: View {
    @Binding var selectedTab: ContentView.Tab
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var settingsManager: SettingsManager
    
    var body: some View {
        // Connected circles design
        HStack(spacing: -8) {
            NavButton(
                icon: "house.fill",
                title: "Home",
                isSelected: selectedTab == .dashboard
            ) {
                HapticManager.selection()
                withAnimation(AppAnimations.quick) {
                    selectedTab = .dashboard
                }
            }
            
            NavButton(
                icon: "dumbbell.fill",
                title: "Workout",
                isSelected: selectedTab == .workout
            ) {
                HapticManager.selection()
                withAnimation(AppAnimations.quick) {
                    selectedTab = .workout
                }
            }
            
            NavButton(
                icon: "chart.line.uptrend.xyaxis",
                title: "Progress",
                isSelected: selectedTab == .progress
            ) {
                HapticManager.selection()
                withAnimation(AppAnimations.quick) {
                    selectedTab = .progress
                }
            }
            
            NavButton(
                icon: "list.bullet.rectangle",
                title: "Templates",
                isSelected: selectedTab == .templates
            ) {
                HapticManager.selection()
                withAnimation(AppAnimations.quick) {
                    selectedTab = .templates
                }
            }
            
            NavButton(
                icon: "timer",
                title: "Timer",
                isSelected: selectedTab == .sportsTimer
            ) {
                HapticManager.selection()
                withAnimation(AppAnimations.quick) {
                    selectedTab = .sportsTimer
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            // Connected circles background
            ConnectedCirclesBackground()
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct ThemePickerView: View {
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var settingsManager: SettingsManager
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Theme Mode Picker
            HStack(spacing: 12) {
                ForEach(ThemeManager.ThemeMode.allCases, id: \.self) { mode in
                    ThemeButton(mode: mode, themeManager: themeManager)
                }
            }
            
        }
    }
}

struct ThemeButton: View {
    let mode: ThemeManager.ThemeMode
    @ObservedObject var themeManager: ThemeManager
    @State private var isHovered = false
    
    private var iconName: String {
        switch mode {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
    
    private var isSelected: Bool {
        themeManager.themeMode == mode
    }
    
    private var foregroundColor: Color {
        isSelected ? AppColors.alabasterGrey : AppColors.foreground
    }
    
    private var background: some View {
        Group {
            if isSelected {
                LinearGradient.primaryGradient
            } else {
                AppColors.secondary
            }
        }
    }
    
    var body: some View {
        Button(action: {
            HapticManager.selection()
            themeManager.themeMode = mode
        }) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 16))
                
                Text(mode.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(isHovered && !isSelected ? 1.05 : 1.0)
            .opacity(isHovered && !isSelected ? 0.9 : 1.0)
            .animation(AppAnimations.quick, value: isHovered)
            .animation(AppAnimations.selection, value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct ThemeToggleButton: View {
    let isSelected: Bool
    let iconName: String
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Circular background when selected
                if isSelected {
                    Circle()
                        .fill(AppColors.secondary)
                        .frame(width: 44, height: 44)
                }
                
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                    .animation(AppAnimations.quick, value: isHovered)
            }
            .frame(width: 50, height: 50)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct NavButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    // Circular background - always visible but styled differently
                    Circle()
                        .fill(
                            isSelected
                                ? LinearGradient.primaryGradient
                                : LinearGradient(
                                    colors: [
                                        AppColors.card.opacity(0.8),
                                        AppColors.card.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isSelected
                                        ? Color.clear
                                        : AppColors.border.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: isSelected
                                ? AppColors.primary.opacity(0.4)
                                : AppColors.foreground.opacity(0.05),
                            radius: isSelected ? 8 : 4,
                            x: 0,
                            y: isSelected ? 2 : 1
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                        .scaleEffect(isSelected ? 1.0 : (isHovered ? 1.05 : 1.0))
                        .animation(AppAnimations.selection, value: isSelected)
                        .animation(AppAnimations.quick, value: isHovered)
                }
                .frame(width: 50, height: 50)
                
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
                    .opacity(isHovered && !isSelected ? 0.8 : 1.0)
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
            .animation(AppAnimations.quick, value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel(title)
        .accessibilityHint(isSelected ? "Currently selected \(title) tab" : "Switch to \(title) tab")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Connected Circles Background

struct ConnectedCirclesBackground: View {
    var body: some View {
        GeometryReader { geometry in
            let circleRadius: CGFloat = 25
            let circleDiameter = circleRadius * 2
            let totalWidth = geometry.size.width
            let totalHeight = geometry.size.height
            let circleCount: CGFloat = 5 // 5 nav buttons
            let spacing = (totalWidth - (circleCount * circleDiameter)) / (circleCount - 1)
            
            ZStack {
                // Background blur
                RoundedRectangle(cornerRadius: totalHeight / 2)
                    .fill(.ultraThinMaterial)
                    .frame(width: totalWidth, height: totalHeight)
                    .shadow(color: AppColors.foreground.opacity(0.08), radius: 20, x: 0, y: -2)
                
                // Connecting lines between circles
                ForEach(0..<Int(circleCount - 1), id: \.self) { index in
                    let startX = circleRadius + CGFloat(index) * (circleDiameter + spacing)
                    let endX = startX + spacing + circleDiameter
                    let centerY = totalHeight / 2
                    
                    Path { path in
                        path.move(to: CGPoint(x: startX + circleRadius, y: centerY))
                        path.addLine(to: CGPoint(x: endX - circleRadius, y: centerY))
                    }
                    .stroke(
                        AppColors.border.opacity(0.15),
                        style: StrokeStyle(lineWidth: 1, lineCap: .round)
                    )
                }
                
                // Border around the entire shape
                RoundedRectangle(cornerRadius: totalHeight / 2)
                    .strokeBorder(AppColors.border.opacity(0.15), lineWidth: 0.5)
            }
        }
    }
}

#Preview {
    ContentView()
}

