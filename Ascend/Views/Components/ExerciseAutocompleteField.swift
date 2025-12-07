import SwiftUI

struct ExerciseAutocompleteField: View {
    @Binding var text: String
    let placeholder: String
    var fontSize: CGFloat = 18
    @State private var showSuggestions = false
    @State private var filteredSuggestions: [String] = []
    @FocusState private var isFocused: Bool
    @ObservedObject private var exerciseDataManager = ExerciseDataManager.shared
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
    private func filterExercises(_ query: String) -> [String] {
        guard !query.isEmpty else { return [] }
        let lowercasedQuery = query.lowercased()
        
        // Pre-allocate result arrays for better performance
        var prefixMatches: [String] = []
        var containsMatches: [String] = []
        prefixMatches.reserveCapacity(10)
        containsMatches.reserveCapacity(10)
        
        // Single pass through exercises
        for exercise in allExercises {
            let lowerExercise = exercise.lowercased()
            
            // Check prefix first (most relevant)
            if lowerExercise.hasPrefix(lowercasedQuery) {
                prefixMatches.append(exercise)
                if prefixMatches.count >= 10 {
                    return prefixMatches
                }
            } else if lowerExercise.contains(lowercasedQuery) {
                containsMatches.append(exercise)
            }
        }
        
        // Combine results: prefix matches first, then contains matches
        var results = prefixMatches
        let remaining = 10 - results.count
        if remaining > 0 {
            results.append(contentsOf: containsMatches.prefix(remaining))
        }
        
        return results
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
                        let newFiltered = filterExercises(newValue)
                        filteredSuggestions = newFiltered
                        
                        let shouldShow = !newValue.isEmpty && !newFiltered.isEmpty
                        if shouldShow != showSuggestions {
                            withAnimation(AppAnimations.standard) {
                                showSuggestions = shouldShow
                            }
                        }
                    }
                }
                .onChange(of: isFocused) { oldValue, newValue in
                    let shouldShow = newValue && !text.isEmpty && !filteredSuggestions.isEmpty
                    if shouldShow != showSuggestions {
                        withAnimation(AppAnimations.standard) {
                            showSuggestions = shouldShow
                        }
                    }
                }
            
            // Suggestions List
            if showSuggestions && !filteredSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredSuggestions, id: \.self) { suggestion in
                        Button(action: {
                            withAnimation(AppAnimations.quick) {
                                text = suggestion
                                showSuggestions = false
                                isFocused = false
                            }
                        }) {
                            HStack {
                                Text(suggestion)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.foreground)
                                
                                Spacer()
                                
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

