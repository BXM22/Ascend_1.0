import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AlternativeExercisesView: View {
    let exerciseName: String
    let alternatives: [String]
    let onSelectAlternative: (String) -> Void
    @State private var showExRxDirectory = false
    
    private var exRxURL: String? {
        ExerciseDataManager.shared.getExRxURL(for: exerciseName)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.accent)
                
                Text("Alternative Exercises")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                // ExRx Directory Button
                if exRxURL != nil {
                    Button(action: {
                        openExRxURL()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "link")
                                .font(.system(size: 10))
                            Text("ExRx")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(AppColors.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(AppColors.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                }
            }
            
            if alternatives.isEmpty {
                VStack(spacing: AppSpacing.xs) {
                    Text("No Equipment? Try these bodyweight options!")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    // Show ExRx directory browse button if no alternatives
                    Button(action: {
                        showExRxDirectory = true
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 12))
                            Text("Browse ExRx Directory")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(AppColors.accent)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.top, AppSpacing.sm)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
            } else {
                VStack(spacing: AppSpacing.xs) {
                    // Limit to 3 alternatives
                    ForEach(Array(alternatives.prefix(3)), id: \.self) { alternative in
                        AlternativeExerciseCard(
                            name: alternative,
                            exRxURL: ExerciseDataManager.shared.getExRxURL(for: alternative),
                            onTap: {
                                onSelectAlternative(alternative)
                            }
                        )
                    }
                    
                    // Browse ExRx Directory Button
                    Button(action: {
                        showExRxDirectory = true
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 12))
                            Text("Browse More Exercises")
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(AppColors.accent)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.foreground.opacity(0.3), radius: 8, x: 0, y: 4)
        .sheet(isPresented: $showExRxDirectory) {
            ExRxDirectoryView(
                searchQuery: exerciseName,
                onSelectExercise: { exerciseName in
                    onSelectAlternative(exerciseName)
                    showExRxDirectory = false
                }
            )
        }
    }
    
    private func openExRxURL() {
        guard let urlString = exRxURL, let url = URL(string: urlString) else { return }
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #endif
    }
}

struct AlternativeExerciseCard: View {
    let name: String
    let exRxURL: String?
    let onTap: () -> Void
    @State private var showExRxInfo = false
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            HapticManager.selection()
            onTap()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.accent)
                
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                if exRxURL != nil {
                    Button(action: {
                        openExRxURL()
                    }) {
                        Image(systemName: "link")
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.accent)
                            .padding(4)
                            .background(AppColors.accent.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(SubtleButtonStyle())
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
                    .opacity(isHovered ? 0.7 : 1.0)
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs + 2)
            .background(AppColors.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .animation(AppAnimations.quick, value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private func openExRxURL() {
        guard let urlString = exRxURL, let url = URL(string: urlString) else { return }
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #endif
    }
}

struct VideoTutorialButton: View {
    let videoURL: String?
    let exerciseName: String
    
    var body: some View {
        if let urlString = videoURL, !urlString.isEmpty {
            Button(action: {
                openYouTubeVideo(urlString: urlString)
            }) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 20))
                    
                    Text("Watch Tutorial")
                        .font(AppTypography.bodyMedium)
                }
                .foregroundColor(AppColors.accentForeground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(LinearGradient.accentGradient)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    private func openYouTubeVideo(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        // Validate YouTube URL
        if urlString.contains("youtube.com") || urlString.contains("youtu.be") {
            // Open in Safari
            #if canImport(UIKit)
            UIApplication.shared.open(url)
            #endif
        } else {
            // Invalid URL - could show alert
            Logger.error("Invalid YouTube URL", category: .validation)
        }
    }
}

// MARK: - ExRx Directory View
struct ExRxDirectoryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText: String = ""
    @State private var selectedCategory: ExRxCategory? = nil
    @State private var selectedMuscleGroup: ExRxMuscleGroup? = nil
    
    let searchQuery: String
    let onSelectExercise: (String) -> Void
    
    private var filteredExercises: [ExRxExercise] {
        var exercises = ExRxDirectoryManager.shared.getAllExercises()
        
        // Apply search filter
        if !searchText.isEmpty {
            exercises = ExRxDirectoryManager.shared.searchExercises(query: searchText)
        }
        
        // Apply category filter
        if let category = selectedCategory {
            exercises = exercises.filter { $0.category == category.rawValue }
        }
        
        // Apply muscle group filter
        if let muscleGroup = selectedMuscleGroup {
            exercises = exercises.filter { $0.muscleGroup == muscleGroup.rawValue }
        }
        
        return exercises
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                VStack(spacing: AppSpacing.sm) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.textSecondary)
                        
                        TextField("Search exercises...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textPrimary)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Category and Muscle Group Filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.sm) {
                            // Category Filter
                            Menu {
                                Button("All Categories") {
                                    selectedCategory = nil
                                }
                                ForEach(ExRxCategory.allCases, id: \.self) { category in
                                    Button(category.rawValue) {
                                        selectedCategory = category
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedCategory?.rawValue ?? "All Categories")
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10))
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.sm)
                                .background(selectedCategory != nil ? AppColors.accent.opacity(0.2) : AppColors.secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            // Muscle Group Filter
                            Menu {
                                Button("All Muscle Groups") {
                                    selectedMuscleGroup = nil
                                }
                                ForEach(ExRxMuscleGroup.allCases, id: \.self) { muscleGroup in
                                    Button(muscleGroup.rawValue) {
                                        selectedMuscleGroup = muscleGroup
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedMuscleGroup?.rawValue ?? "All Muscles")
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10))
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.sm)
                                .background(selectedMuscleGroup != nil ? AppColors.accent.opacity(0.2) : AppColors.secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                    }
                }
                .padding(AppSpacing.md)
                .background(AppColors.card)
                
                // Exercise List
                ScrollView {
                    LazyVStack(spacing: AppSpacing.sm) {
                        ForEach(filteredExercises) { exercise in
                            ExRxExerciseCard(
                                exercise: exercise,
                                onSelect: {
                                    onSelectExercise(exercise.name)
                                }
                            )
                        }
                    }
                    .padding(AppSpacing.md)
                }
                .background(AppColors.background)
            }
            .navigationTitle("ExRx Directory")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
        }
        .onAppear {
            if !searchQuery.isEmpty {
                searchText = searchQuery
            }
        }
    }
}

// MARK: - ExRx Exercise Card
struct ExRxExerciseCard: View {
    let exercise: ExRxExercise
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text(exercise.name)
                        .font(AppTypography.heading4)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    if let url = exercise.url {
                        Button(action: {
                            openExRxURL(url)
                        }) {
                            Image(systemName: "link")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.accent)
                                .padding(6)
                                .background(AppColors.accent.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                HStack(spacing: AppSpacing.md) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                        Text(exercise.category)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "figure.strengthtraining.traditional")
                        Text(exercise.muscleGroup)
                    }
                    if let equipment = exercise.equipment {
                        HStack(spacing: 4) {
                            Image(systemName: "wrench.and.screwdriver")
                            Text(equipment)
                        }
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
            }
            .padding(AppSpacing.md)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppColors.foreground.opacity(0.06), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func openExRxURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #endif
    }
}

#Preview {
    VStack(spacing: 20) {
        AlternativeExercisesView(
            exerciseName: "Bench Press",
            alternatives: ["Push-ups", "Dumbbell Press", "Incline Push-ups"],
            onSelectAlternative: { _ in }
        )
        
        VideoTutorialButton(
            videoURL: "https://www.youtube.com/watch?v=rT7DgCr-3pg",
            exerciseName: "Bench Press"
        )
    }
    .padding()
    .background(AppColors.background)
}

