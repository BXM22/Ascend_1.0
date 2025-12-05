//
//  ContentView.swift
//  WorkoutTracker
//
//  Created on 2024
//

import SwiftUI

struct ContentView: View {
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var progressViewModel = ProgressViewModel()
    @StateObject private var templatesViewModel = TemplatesViewModel()
    @StateObject private var programViewModel = WorkoutProgramViewModel()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var settingsManager = SettingsManager()
    @State private var selectedTab: Tab = .dashboard
    @Environment(\.colorScheme) var systemColorScheme
    
    enum Tab {
        case dashboard, workout, progress, templates
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
            
            VStack(spacing: 0) {
                // Main Content
                Group {
                    switch selectedTab {
                    case .dashboard:
                        DashboardView(
                            progressViewModel: progressViewModel,
                            workoutViewModel: workoutViewModel,
                            templatesViewModel: templatesViewModel,
                            programViewModel: programViewModel,
                            onStartWorkout: {
                                withAnimation(AppAnimations.standard) {
                                    selectedTab = .workout
                                }
                            }
                        )
                        .id(AppColors.themeID)
                        .transition(.smoothFade)
                    case .workout:
                        WorkoutView(viewModel: workoutViewModel)
                        .onAppear {
                            workoutViewModel.progressViewModel = progressViewModel
                            workoutViewModel.programViewModel = programViewModel
                            workoutViewModel.templatesViewModel = templatesViewModel
                            workoutViewModel.themeManager = themeManager
                        }
                            .id(AppColors.themeID)
                            .transition(.smoothFade)
                    case .progress:
                        ProgressView(viewModel: progressViewModel)
                            .id(AppColors.themeID)
                            .transition(.smoothFade)
                    case .templates:
                        TemplatesView(
                            viewModel: templatesViewModel,
                            workoutViewModel: workoutViewModel,
                            programViewModel: programViewModel,
                            onStartTemplate: {
                                withAnimation(AppAnimations.standard) {
                                    selectedTab = .workout
                                }
                            }
                        )
                        .id(AppColors.themeID)
                        .transition(.smoothFade)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(AppAnimations.standard, value: selectedTab)
                .onAppear {
                    // Connect ViewModels
                    workoutViewModel.progressViewModel = progressViewModel
                    workoutViewModel.settingsManager = settingsManager
                    workoutViewModel.programViewModel = programViewModel
                    workoutViewModel.templatesViewModel = templatesViewModel
                    workoutViewModel.themeManager = themeManager
                }
                .environmentObject(settingsManager)
                .environmentObject(ColorThemeProvider.shared)
                
                // Bottom Navigation
                BottomNavigationBar(
                    selectedTab: $selectedTab,
                    themeManager: themeManager,
                    settingsManager: settingsManager
                )
                .id(AppColors.themeID)
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
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
    @State private var showThemePicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Theme Picker (when shown)
            if showThemePicker {
                ThemePickerView(
                    themeManager: themeManager,
                    settingsManager: settingsManager
                )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 0)
                    )
            }
            
            HStack(spacing: 0) {
                NavButton(
                    icon: "house.fill",
                    title: "Home",
                    isSelected: selectedTab == .dashboard
                ) {
                    withAnimation(AppAnimations.quick) {
                        selectedTab = .dashboard
                    }
                }
                
                Spacer()
                
                NavButton(
                    icon: "dumbbell.fill",
                    title: "Workout",
                    isSelected: selectedTab == .workout
                ) {
                    withAnimation(AppAnimations.quick) {
                        selectedTab = .workout
                    }
                }
                
                Spacer()
                
                NavButton(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progress",
                    isSelected: selectedTab == .progress
                ) {
                    withAnimation(AppAnimations.quick) {
                        selectedTab = .progress
                    }
                }
                
                Spacer()
                
                NavButton(
                    icon: "list.bullet.rectangle",
                    title: "Templates",
                    isSelected: selectedTab == .templates
                ) {
                    withAnimation(AppAnimations.quick) {
                        selectedTab = .templates
                    }
                }
                
                Spacer()
                
                // Theme Toggle Button
                Button(action: {
                    withAnimation(AppAnimations.standard) {
                        showThemePicker.toggle()
                    }
                }) {
                    Image(systemName: showThemePicker ? "paintbrush.fill" : "paintbrush")
                        .font(AppTypography.heading3)
                        .foregroundColor(selectedTab == .templates ? AppColors.primary : AppColors.textSecondary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.card)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppColors.border),
                alignment: .top
            )
        }
    }
}

struct ThemePickerView: View {
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var settingsManager: SettingsManager
    @State private var showColorImport = false
    @State private var colorURLText = ""
    @State private var importError: String?
    @State private var importSuccess = false
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Theme Mode Picker
            HStack(spacing: 12) {
                ForEach(ThemeManager.ThemeMode.allCases, id: \.self) { mode in
                    ThemeButton(mode: mode, themeManager: themeManager)
                }
            }
            
            Divider()
                .background(AppColors.border)
            
            // Color Theme Import Section
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("Custom Color Theme")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    if settingsManager.customTheme != nil {
                        Button(action: {
                            settingsManager.resetToDefaultTheme()
                            importSuccess = false
                        }) {
                            Text("Reset")
                                .font(AppTypography.captionMedium)
                                .foregroundColor(AppColors.destructive)
                        }
                    }
                }
                
                if !showColorImport {
                    Button(action: {
                        withAnimation(AppAnimations.standard) {
                            showColorImport = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "link")
                                .font(AppTypography.body)
                            Text("Import from Coolors.co")
                                .font(AppTypography.bodyMedium)
                        }
                        .foregroundColor(AppColors.accentForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                } else {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        TextField("Paste Coolors.co URL", text: $colorURLText)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(AppSpacing.sm)
                            .background(AppColors.input)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        
                        if let error = importError {
                            Text(error)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.destructive)
                        }
                        
                        if importSuccess {
                            Text("Theme imported successfully!")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.success)
                        }
                        
                        HStack(spacing: AppSpacing.sm) {
                            Button(action: {
                                importTheme()
                            }) {
                                Text("Import")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.accentForeground)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppSpacing.sm)
                                    .background(AppColors.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            Button(action: {
                                withAnimation(AppAnimations.standard) {
                                    showColorImport = false
                                    colorURLText = ""
                                    importError = nil
                                    importSuccess = false
                                }
                            }) {
                                Text("Cancel")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppSpacing.sm)
                                    .background(AppColors.secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .colorThemeDidChange)) { _ in
            // Refresh view when theme changes
        }
    }
    
    private func importTheme() {
        importError = nil
        importSuccess = false
        
        guard !colorURLText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            importError = "Please enter a URL"
            return
        }
        
        let result = settingsManager.importTheme(from: colorURLText)
        
        switch result {
        case .success:
            importSuccess = true
            // Clear text after successful import
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(AppAnimations.standard) {
                    showColorImport = false
                    colorURLText = ""
                    importSuccess = false
                }
            }
        case .failure(let error):
            importError = error.localizedDescription
        }
    }
}

struct ThemeButton: View {
    let mode: ThemeManager.ThemeMode
    @ObservedObject var themeManager: ThemeManager
    
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
        }
    }
}

struct NavButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(AppTypography.heading3)
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
                    .scaleEffect(isSelected ? 1.08 : 1.0)
                    .animation(AppAnimations.selection, value: isSelected)
                
                Text(title)
                    .font(AppTypography.captionMedium)
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContentView()
}

