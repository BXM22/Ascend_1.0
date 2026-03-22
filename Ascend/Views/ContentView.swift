//
//  ContentView.swift
//  WorkoutTracker
//
//  Created on 2024
//

import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var colorThemeProvider: ColorThemeProvider
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
    
    enum Tab: CaseIterable, Hashable {
        case dashboard, workout, progress, templates, habits
    }
    
    var effectiveColorScheme: ColorScheme {
        themeManager.colorScheme ?? systemColorScheme
    }
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            // Main content + bottom tab bar — explicit `VStack` so chrome stays at the physical bottom (`safeAreaInset` can pin incorrectly inside some `ZStack` layouts).
            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case .dashboard:
                        DashboardView(
                            progressViewModel: progressViewModel,
                            workoutViewModel: workoutViewModel,
                            templatesViewModel: templatesViewModel,
                            programViewModel: programViewModel,
                            themeManager: themeManager,
                            settingsManager: settingsManager,
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
                            progressViewModel: progressViewModel,
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
                    case .habits:
                        HabitsView(onSettings: {
                            showSettingsSheet = true
                        })
                        .id(AppColors.themeID)
                        .transition(.slideFromBottom)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(AppAnimations.standard, value: selectedTab)

                BottomNavigationBar(selectedTab: $selectedTab, resolvedColorScheme: effectiveColorScheme)
                    .id(AppColors.themeID)
                    .animation(nil, value: selectedTab)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Extend into the home-indicator strip so the bar sits on the physical bottom (no extra gap under it).
            .ignoresSafeArea(edges: .bottom)
            .environmentObject(settingsManager)
            .environmentObject(ColorThemeProvider.shared)
            .environment(\.kineticPalette, KineticAdaptivePalette.alignedWithAppColors(effectiveColorScheme))
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

// MARK: - Kinetic tab bar (DESIGN.md: tonal chrome, primary accent, no hard rules)

private enum KineticTabBarFonts {
    static func label(_ size: CGFloat) -> Font {
        Font.custom("Manrope-Bold", size: size, relativeTo: .caption2)
    }
}

private extension ContentView.Tab {
    var tabIcon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .workout: return "dumbbell.fill"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .templates: return "rectangle.stack.fill"
        case .habits: return "checkmark.circle.fill"
        }
    }

    var tabShortLabel: String {
        switch self {
        case .dashboard: return "STUDIO"
        case .workout: return "SESSION"
        case .progress: return "STATS"
        case .templates: return "LIBRARY"
        case .habits: return "HABITS"
        }
    }

    var tabAccessibilityLabel: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .workout: return "Workout"
        case .progress: return "Progress"
        case .templates: return "Templates"
        case .habits: return "Habits"
        }
    }
}

struct BottomNavigationBar: View {
    @Binding var selectedTab: ContentView.Tab
    /// Must match `ContentView.effectiveColorScheme` — `safeAreaInset` can report the wrong `Environment.colorScheme` vs the canvas / `ThemeManager`.
    var resolvedColorScheme: ColorScheme

    private var homeIndicatorInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .safeAreaInsets.bottom ?? 0
    }

    var body: some View {
        // Intrinsic height only — never use `maxHeight: .infinity` here: inside a root `VStack` it steals
        // all remaining vertical space and pins controls to the top, leaving a blank band at the bottom.
        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    Color.black.opacity(resolvedColorScheme == .dark ? 0.22 : 0.06),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 12)
            .allowsHitTesting(false)

            HStack(spacing: 0) {
                ForEach(ContentView.Tab.allCases, id: \.self) { tab in
                    KineticTabBarItem(
                        icon: tab.tabIcon,
                        label: tab.tabShortLabel,
                        isSelected: selectedTab == tab,
                        accessibilityTitle: tab.tabAccessibilityLabel
                    ) {
                        select(tab)
                    }
                }
            }
            .padding(.top, 6)
            .padding(.bottom, max(4, homeIndicatorInset - 4))
        }
        .frame(maxWidth: .infinity)
        .background {
            AppColors.appBackground(for: resolvedColorScheme)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func select(_ tab: ContentView.Tab) {
        HapticManager.selection()
        selectedTab = tab
    }
}

private struct KineticTabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let accessibilityTitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                Text(label)
                    .font(KineticTabBarFonts.label(7.5))
                    .tracking(1.8)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                ZStack {
                    Capsule(style: .continuous)
                        .fill(AppColors.primary)
                        .frame(width: 22, height: 3)
                        .opacity(isSelected ? 1 : 0)
                    Color.clear
                        .frame(height: 3)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .foregroundStyle(isSelected ? AppColors.primary : AppColors.foreground.opacity(0.4))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityTitle)
        .accessibilityHint(isSelected ? "Currently selected" : "Switch to this tab")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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

#Preview {
    ContentView()
        .environmentObject(ColorThemeProvider.shared)
}

