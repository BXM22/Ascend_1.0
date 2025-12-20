import SwiftUI

struct ExerciseAutocompleteField: View {
    @Binding var text: String
    let placeholder: String
    var fontSize: CGFloat = 18
    @State private var showSuggestions = false
    @State private var filteredSuggestions: [String] = []
    @State private var favoriteSuggestions: [String] = []
    @State private var mergedExercises: [(original: String, lowercased: String)] = []
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
    
    private func updateMergedExercises() {
        var exercises = Self.cachedExercises
        
        // Add custom exercises
        let customExercises = ExerciseDataManager.shared.customExercises.map { $0.name }
        exercises.append(contentsOf: customExercises)
        
        // Remove duplicates, sort, and pre-lowercase for faster searching
        let sortedUnique = Array(Set(exercises)).sorted()
        mergedExercises = sortedUnique.map { ($0, $0.lowercased()) }
    }
    
    // Optimized filtering function - uses early exit and single pass where possible
    private func filterExercises(_ query: String) -> ([String], [String]) {
        let favorites = favoritesManager.favoriteExercises
        let recent = usageTracker.recentExercises
        let mostUsed = usageTracker.getMostUsedExercises(limit: 10)
        
        // Use Set for O(1) lookup performance
        let _ = Set(favorites) // favoritesSet not used in current implementation
        let recentSet = Set(recent)
        let mostUsedSet = Set(mostUsed)
        
        guard !query.isEmpty else {
            // If no query, return: recent → most used → favorites
            var ordered: [String] = []
            ordered.append(contentsOf: recent)
            ordered.append(contentsOf: mostUsed.filter { !recentSet.contains($0) })
            ordered.append(contentsOf: favorites.filter { !recentSet.contains($0) && !mostUsedSet.contains($0) })
            return (ordered, [])
        }
        
        let lowercasedQuery = query.lowercased()
        let resultLimit = 20
        
        // Matches from priority lists
        var orderedMatches: [String] = []
        var seenMatches = Set<String>()
        
        // 1. Check priority lists (recent, most used, favorites)
        let priorityLists = [recent, mostUsed, favorites]
        for list in priorityLists {
            for exercise in list {
                if seenMatches.contains(exercise) { continue }
                
                let lowerExercise = exercise.lowercased()
                if lowerExercise.hasPrefix(lowercasedQuery) || lowerExercise.contains(lowercasedQuery) {
                    orderedMatches.append(exercise)
                    seenMatches.insert(exercise)
                    
                    if orderedMatches.count >= resultLimit {
                        return (orderedMatches, [])
                    }
                }
            }
        }
        
        // 2. Check regular exercises (single pass)
        var prefixMatches: [String] = []
        var containsMatches: [String] = []
        
        for (original, lowercased) in mergedExercises {
            if seenMatches.contains(original) { continue }
            
            if lowercased.hasPrefix(lowercasedQuery) {
                prefixMatches.append(original)
                if orderedMatches.count + prefixMatches.count + containsMatches.count >= resultLimit { break }
            } else if lowercased.contains(lowercasedQuery) {
                containsMatches.append(original)
                if orderedMatches.count + prefixMatches.count + containsMatches.count >= resultLimit { break }
            }
        }
        
        return (orderedMatches, Array(prefixMatches + containsMatches).prefix(resultLimit - orderedMatches.count).map { String($0) })
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
                .onAppear {
                    updateMergedExercises()
                }
                .onChange(of: exerciseDataManager.customExercises) {
                    updateMergedExercises()
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
                .shadow(color: AppColors.foreground.opacity(0.1), radius: 8, x: 0, y: 4)
                .padding(.top, 8)
                .transition(.smoothScale)
            }
            }
        }
    }
}

