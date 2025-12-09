import SwiftUI

struct ExerciseAutocompleteField: View {
    @Binding var text: String
    let placeholder: String
    var fontSize: CGFloat = 18
    @State private var showSuggestions = false
    @State private var filteredSuggestions: [String] = []
    @State private var favoriteSuggestions: [String] = []
    @FocusState private var isFocused: Bool
    @ObservedObject private var exerciseDataManager = ExerciseDataManager.shared
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var usageTracker = ExerciseUsageTracker.shared
    @State private var debounceTask: Task<Void, Never>?
    
    // Cache exercise list for better performance - computed once
    private static var cachedExercises: [String] = {
        var exercises: [String] = []
        
        // Get exercises from ExerciseDataManager database (hardcoded list)
        let exerciseDatabase = [
            "Bench Press", "Squat", "Deadlift", "Shoulder Press", "Barbell Row",
            "Pull-ups", "Plank", "Bicep Curl", "Tricep Extension", "Leg Press",
            "Planche", "Handstand Push-up", "Muscle Up", "Front Lever", "Back Lever",
            "Human Flag", "L-Sit", "Handstand"
        ]
        exercises.append(contentsOf: exerciseDatabase)
        
        // Get exercises from ExRx directory
        let exRxExercises = ExRxDirectoryManager.shared.getAllExerciseNames()
        exercises.append(contentsOf: exRxExercises)
        
        // Remove duplicates and sort
        return Array(Set(exercises)).sorted()
    }()
    
    private var allExercises: [String] {
        var exercises = Self.cachedExercises
        
        // Add custom exercises
        let customExercises = ExerciseDataManager.shared.customExercises.map { $0.name }
        exercises.append(contentsOf: customExercises)
        
        // Remove duplicates and sort
        return Array(Set(exercises)).sorted()
    }
    
    // Optimized filtering function - uses early exit and single pass where possible
    private func filterExercises(_ query: String) -> ([String], [String]) {
        // Separate favorites, recent, most used, and regular exercises
        // Use Set for O(1) lookup performance
        let favoritesSet = Set(favoritesManager.favoriteExercises)
        let recentSet = Set(usageTracker.recentExercises)
        let mostUsedSet = Set(usageTracker.getMostUsedExercises(limit: 10))
        
        let favorites = favoritesManager.favoriteExercises
        let recent = usageTracker.recentExercises
        let mostUsed = usageTracker.getMostUsedExercises(limit: 10)
        let regularExercises = allExercises.filter { 
            !favoritesSet.contains($0) && !recentSet.contains($0) && !mostUsedSet.contains($0)
        }
        
        guard !query.isEmpty else {
            // If no query, return: recent → most used → favorites → alphabetical
            // Use Set for O(1) lookup performance
            let recentSet = Set(recent)
            let mostUsedSet = Set(mostUsed)
            var ordered: [String] = []
            ordered.append(contentsOf: recent)
            ordered.append(contentsOf: mostUsed.filter { !recentSet.contains($0) })
            ordered.append(contentsOf: favorites.filter { !recentSet.contains($0) && !mostUsedSet.contains($0) })
            return (ordered, [])
        }
        
        let lowercasedQuery = query.lowercased()
        
        // Pre-allocate result arrays for better performance
        var recentMatches: [String] = []
        var mostUsedMatches: [String] = []
        var favoritePrefixMatches: [String] = []
        var favoriteContainsMatches: [String] = []
        var prefixMatches: [String] = []
        var containsMatches: [String] = []
        
        // Filter recent exercises first (optimized with early exit)
        for exercise in recent {
            let lowerExercise = exercise.lowercased()
            if lowerExercise.hasPrefix(lowercasedQuery) || lowerExercise.contains(lowercasedQuery) {
                recentMatches.append(exercise)
            }
        }
        
        // Filter most used exercises (skip if already in recent) - use Set for O(1) lookup
        let recentMatchesSet = Set(recentMatches)
        for exercise in mostUsed {
            if recentMatchesSet.contains(exercise) { continue }
            let lowerExercise = exercise.lowercased()
            if lowerExercise.hasPrefix(lowercasedQuery) || lowerExercise.contains(lowercasedQuery) {
                mostUsedMatches.append(exercise)
            }
        }
        
        // Filter favorites - use Set for O(1) lookup
        let mostUsedMatchesSet = Set(mostUsedMatches)
        for exercise in favorites {
            if recentMatchesSet.contains(exercise) || mostUsedMatchesSet.contains(exercise) { continue }
            let lowerExercise = exercise.lowercased()
            if lowerExercise.hasPrefix(lowercasedQuery) {
                favoritePrefixMatches.append(exercise)
            } else if lowerExercise.contains(lowercasedQuery) {
                favoriteContainsMatches.append(exercise)
            }
        }
        
        // Filter regular exercises
        for exercise in regularExercises {
            let lowerExercise = exercise.lowercased()
            if lowerExercise.hasPrefix(lowercasedQuery) {
                prefixMatches.append(exercise)
            } else if lowerExercise.contains(lowercasedQuery) {
                containsMatches.append(exercise)
            }
        }
        
        // Combine: recent → most used → favorites (prefix, then contains) → regular (prefix, then contains)
        var orderedResults = recentMatches
        orderedResults.append(contentsOf: mostUsedMatches)
        
        var favoriteResults = favoritePrefixMatches
        favoriteResults.append(contentsOf: favoriteContainsMatches)
        orderedResults.append(contentsOf: favoriteResults)
        
        var regularResults = prefixMatches
        regularResults.append(contentsOf: containsMatches)
        
        return (orderedResults, regularResults)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
            TextField(placeholder, text: $text)
                .font(.system(size: fontSize, weight: .medium))
                .foregroundColor(AppColors.foreground)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(AppColors.input)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .focused($isFocused)
                .onChange(of: text) { oldValue, newValue in
                    // Cancel previous debounce task
                    debounceTask?.cancel()
                    
                    // Debounce filtering for better performance
                    debounceTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 second debounce
                        
                        // Check if task was cancelled or text changed
                        guard !Task.isCancelled, text == newValue else { return }
                        
                        // Update filtered suggestions efficiently
                        let (favorites, regular) = filterExercises(newValue)
                        favoriteSuggestions = favorites
                        filteredSuggestions = regular
                        
                        let shouldShow = !newValue.isEmpty && (!favorites.isEmpty || !regular.isEmpty)
                        if shouldShow != showSuggestions {
                            withAnimation(AppAnimations.standard) {
                                showSuggestions = shouldShow
                            }
                        }
                    }
                }
                .onChange(of: isFocused) { oldValue, newValue in
                    let shouldShow = newValue && !text.isEmpty && (!favoriteSuggestions.isEmpty || !filteredSuggestions.isEmpty)
                    if shouldShow != showSuggestions {
                        withAnimation(AppAnimations.standard) {
                            showSuggestions = shouldShow
                        }
                    }
                }
            
            // Suggestions List
            if showSuggestions && (!favoriteSuggestions.isEmpty || !filteredSuggestions.isEmpty) {
                VStack(alignment: .leading, spacing: 0) {
                    // Favorites Section
                    if !favoriteSuggestions.isEmpty {
                        ForEach(favoriteSuggestions, id: \.self) { suggestion in
                            Button(action: {
                                withAnimation(AppAnimations.quick) {
                                    text = suggestion
                                    showSuggestions = false
                                    isFocused = false
                                }
                                // Track exercise usage
                                usageTracker.trackExerciseUsage(suggestion)
                            }) {
                                HStack {
                                    // Show icon based on type
                                    if usageTracker.recentExercises.contains(suggestion) {
                                        Image(systemName: "clock.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.accent)
                                    } else if usageTracker.getMostUsedExercises().contains(suggestion) {
                                        Image(systemName: "chart.bar.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.accent)
                                    } else {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.accent)
                                    }
                                    
                                    Text(suggestion)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppColors.foreground)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.left")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.mutedForeground)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(AppColors.accent.opacity(0.05))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .transition(.smoothSlide)
                            
                            if suggestion != favoriteSuggestions.last || !filteredSuggestions.isEmpty {
                                Divider()
                                    .background(AppColors.border.opacity(0.3))
                                    .padding(.horizontal, 16)
                                    .transition(.opacity)
                            }
                        }
                    }
                    
                    // Regular Suggestions Section
                    ForEach(filteredSuggestions, id: \.self) { suggestion in
                        Button(action: {
                            withAnimation(AppAnimations.quick) {
                                text = suggestion
                                showSuggestions = false
                                isFocused = false
                            }
                            // Track exercise usage
                            usageTracker.trackExerciseUsage(suggestion)
                        }) {
                            HStack {
                                Text(suggestion)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.foreground)
                                
                                Spacer()
                                
                                // Show usage count for most used exercises
                                if usageTracker.getUsageCount(for: suggestion) > 0 {
                                    Text("\(usageTracker.getUsageCount(for: suggestion))×")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(AppColors.mutedForeground)
                                }
                                
                                Image(systemName: "arrow.up.left")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColors.mutedForeground)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppColors.card)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .transition(.smoothSlide)
                        
                        if suggestion != filteredSuggestions.last {
                            Divider()
                                .background(AppColors.border.opacity(0.3))
                                .padding(.horizontal, 16)
                                .transition(.opacity)
                        }
                    }
                }
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .padding(.top, 8)
                .transition(.smoothScale)
            }
            }
        }
    }
}

