import Foundation
import SwiftUI
import Combine

class ProgressViewModel: ObservableObject {
    @Published var prs: [PersonalRecord] = []
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var workoutDates: [Date] = []
    @Published var restDays: [Date] = [] // Track rest days separately
    @Published var totalVolume: Int = AppConstants.Progress.defaultTotalVolume
    @Published var workoutCount: Int = AppConstants.Progress.defaultWorkoutCount
    @Published var selectedView: ProgressViewType = .week
    @Published var selectedExercise: String = ""
    
    enum ProgressViewType {
        case week, month
    }
    
    // Cache for available exercises
    private var cachedAvailableExercises: [String]?
    
    // Get all unique exercise names from PRs (cached and sorted by muscle group)
    var availableExercises: [String] {
        if let cached = cachedAvailableExercises {
            return cached
        }
        let uniqueExercises = Array(Set(prs.map { $0.exercise }))
        let exercises = sortExercisesByMuscleGroup(uniqueExercises)
        cachedAvailableExercises = exercises
        return exercises
    }
    
    // Get filtered exercises based on search text and body part, sorted by muscle group
    func getFilteredExercises(searchText: String, bodyPart: String?) -> [String] {
        var exercises = availableExercises
        
        // Filter by body part first (more specific)
        if let bodyPart = bodyPart, !bodyPart.isEmpty {
            exercises = exercises.filter { exerciseName in
                let (primary, secondary) = ExerciseDataManager.shared.getMuscleGroups(for: exerciseName)
                return primary.contains(bodyPart) || secondary.contains(bodyPart)
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            exercises = exercises.filter { exercise in
                exercise.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort filtered results by muscle group
        return sortExercisesByMuscleGroup(exercises)
    }
    
    // Sort exercises by muscle group, then alphabetically within each group
    private func sortExercisesByMuscleGroup(_ exercises: [String]) -> [String] {
        // Group exercises by their primary muscle group
        var muscleGroupMap: [String: [String]] = [:]
        
        for exercise in exercises {
            let (primary, _) = ExerciseDataManager.shared.getMuscleGroups(for: exercise)
            let primaryMuscle = primary.first ?? "Other"
            
            if muscleGroupMap[primaryMuscle] == nil {
                muscleGroupMap[primaryMuscle] = []
            }
            muscleGroupMap[primaryMuscle]?.append(exercise)
        }
        
        // Define muscle group order (matches app color scheme)
        let muscleGroupOrder = [
            "Chest", "Pectorals", "Push",
            "Back", "Lats", "Pull",
            "Legs", "Quadriceps", "Hamstrings", "Glutes", "Calves",
            "Arms", "Biceps", "Triceps", "Forearms",
            "Shoulders", "Deltoids",
            "Core", "Abdominals", "Abs",
            "Cardio",
            "Other"
        ]
        
        // Build sorted list
        var sortedExercises: [String] = []
        for muscleGroup in muscleGroupOrder {
            if let exercises = muscleGroupMap[muscleGroup] {
                // Sort alphabetically within each muscle group
                sortedExercises.append(contentsOf: exercises.sorted())
            }
        }
        
        // Add any remaining exercises not in the predefined order
        let addedExercises = Set(sortedExercises)
        let remaining = exercises.filter { !addedExercises.contains($0) }.sorted()
        sortedExercises.append(contentsOf: remaining)
        
        return sortedExercises
    }
    
    // Get all unique body parts from exercises with PRs
    func getAvailableBodyParts() -> [String] {
        var bodyParts: Set<String> = []
        
        for exerciseName in availableExercises {
            let (primary, secondary) = ExerciseDataManager.shared.getMuscleGroups(for: exerciseName)
            bodyParts.formUnion(primary)
            bodyParts.formUnion(secondary)
        }
        
        return Array(bodyParts).sorted()
    }
    
    // Invalidate exercise cache
    private func invalidateExerciseCache() {
        cachedAvailableExercises = nil
        cachedSelectedPRs = nil
        cachedSelectedExercise = nil
    }
    
    // Update selected exercise when PRs change
    func updateSelectedExerciseIfNeeded() {
        // If current selection is invalid or empty, select first available
        if selectedExercise.isEmpty || !availableExercises.contains(selectedExercise) {
            if !availableExercises.isEmpty {
                selectedExercise = availableExercises[0]
            }
        }
    }
    
    // Cache for selected exercise PRs
    private var cachedSelectedPRs: [PersonalRecord]?
    private var cachedSelectedExercise: String?
    
    // Get PRs for the selected exercise, sorted by date (newest first) - cached
    var selectedExercisePRs: [PersonalRecord] {
        guard !selectedExercise.isEmpty else { return [] }
        
        // Return cached if exercise hasn't changed
        if let cached = cachedSelectedPRs, cachedSelectedExercise == selectedExercise {
            return cached
        }
        
        // Filter and sort
        let filtered = prs.filter { $0.exercise == selectedExercise }
            .sorted { $0.date > $1.date }
        
        // Cache the result
        cachedSelectedPRs = filtered
        cachedSelectedExercise = selectedExercise
        
        return filtered
    }
    
    // Get current PR for selected exercise
    var currentPR: PersonalRecord? {
        selectedExercisePRs.first
    }
    
    private var cancellables = Set<AnyCancellable>()
    private let workoutHistoryManager = WorkoutHistoryManager.shared
    
    // Performance optimizations
    private var cachedSortedDates: [Date]?
    private var cachedStreakCalculation: (current: Int, longest: Int)?
    private var lastStreakCalculationDate: Date?
    private let streakCacheValidity: TimeInterval = 60 // 1 minute
    private let processingQueue = DispatchQueue(label: "com.ascend.streakProcessing", qos: .utility)
    
    // Flag to prevent saves during initial load
    private var isInitialLoad = true
    
    init() {
        // Set up observers first (they check isInitialLoad flag)
        setupObservers()
        
        // Load persisted data (won't trigger saves because isInitialLoad is true)
        loadPRs()
        loadWorkoutDates()
        loadRestDays()
        
        // Mark initial load as complete - now changes will save
        isInitialLoad = false
        
        calculateStreaks()
        updateVolumeAndCount()
        // Set initial selected exercise if available
        if !availableExercises.isEmpty {
            selectedExercise = availableExercises[0]
        }
        
        // Log initial state for debugging
        Logger.info("📊 ProgressViewModel initialized - PRs: \(prs.count), Workout dates: \(workoutDates.count), Streak: \(currentStreak)", category: .general)
    }
    
    private func setupObservers() {
        // Observe WorkoutHistoryManager for real-time updates
        workoutHistoryManager.$completedWorkouts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateVolumeAndCount()
            }
            .store(in: &cancellables)
        
        // Save PRs when they change (skip during initial load)
        $prs
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, !self.isInitialLoad else { return }
                self.savePRs()
            }
            .store(in: &cancellables)
        
        // Save workout dates when they change (skip during initial load)
        $workoutDates
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, !self.isInitialLoad else { return }
                self.invalidateStreakCache()
                self.saveWorkoutDates()
            }
            .store(in: &cancellables)
        
        // Save rest days when they change (skip during initial load)
        $restDays
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, !self.isInitialLoad else { return }
                self.invalidateStreakCache()
                self.saveRestDays()
            }
            .store(in: &cancellables)
    }
    
    private func invalidateStreakCache() {
        cachedSortedDates = nil
        cachedStreakCalculation = nil
        lastStreakCalculationDate = nil
    }
    
    func updateVolumeAndCount() {
        // Update count immediately
        workoutCount = workoutHistoryManager.completedWorkouts.count
        
        // For immediate updates after workout completion, calculate synchronously
        // This ensures dashboard updates in real-time
        if workoutCount <= 100 {
            // Small dataset - calculate synchronously for immediate update
            totalVolume = workoutHistoryManager.getAllTimeVolume()
        } else {
            // Large dataset - still calculate synchronously for immediate update
            // The cache will handle performance
            totalVolume = workoutHistoryManager.getAllTimeVolume()
        }
    }
    
    /// Calculates workout streaks from workout dates and rest days
    /// 
    /// Algorithm:
    /// 1. Current Streak: Counts consecutive days from today backwards
    ///    - Includes both workout days and rest days
    ///    - Starts from today and works backwards
    ///    - Breaks when a day is missing
    /// 2. Longest Streak: Finds the longest consecutive sequence in all dates
    ///    - Combines workout dates and rest days
    ///    - Iterates through sorted dates and counts consecutive sequences
    ///    - Tracks the maximum consecutive count found
    ///
    /// Time Complexity: O(n log n) for initial sort, O(n) for subsequent calls with cache
    func calculateStreaks() {
        // Check cache validity
        if let cacheDate = lastStreakCalculationDate,
           let cached = cachedStreakCalculation,
           Date().timeIntervalSince(cacheDate) < streakCacheValidity {
            currentStreak = cached.current
            longestStreak = cached.longest
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Use cached sorted dates if available, otherwise calculate
        let sortedDates: [Date]
        if let cached = cachedSortedDates {
            sortedDates = cached
        } else {
            // Combine workout dates and rest days
            let allDates = workoutDates + restDays
            let uniqueDates = Array(Set(allDates.map { calendar.startOfDay(for: $0) }))
            sortedDates = uniqueDates.sorted(by: >)
            cachedSortedDates = sortedDates
        }
        
        guard !sortedDates.isEmpty else {
            currentStreak = 0
            longestStreak = 0
            cachedStreakCalculation = (0, 0)
            lastStreakCalculationDate = Date()
            return
        }
        
        // For large datasets, calculate on background queue
        if sortedDates.count > 100 {
            processingQueue.async { [weak self] in
                guard let self = self else { return }
                let streaks = self.calculateStreaksSync(sortedDates: sortedDates, today: today, calendar: calendar)
                DispatchQueue.main.async {
                    self.currentStreak = streaks.current
                    self.longestStreak = streaks.longest
                    self.cachedStreakCalculation = streaks
                    self.lastStreakCalculationDate = Date()
                }
            }
            return
        }
        
        // For small datasets, calculate synchronously
        let streaks = calculateStreaksSync(sortedDates: sortedDates, today: today, calendar: calendar)
        currentStreak = streaks.current
        longestStreak = streaks.longest
        cachedStreakCalculation = streaks
        lastStreakCalculationDate = Date()
    }
    
    private func calculateStreaksSync(sortedDates: [Date], today: Date, calendar: Calendar) -> (current: Int, longest: Int) {
        // Calculate current streak (consecutive days from today backwards)
        var streak = 0
        var checkDate = today
        
        // Check if today is in the list
        if sortedDates.first == today {
            streak = 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        
        for date in sortedDates {
            let daysDiff = calendar.dateComponents([.day], from: date, to: checkDate).day ?? Int.max
            
            if daysDiff == 0 || daysDiff == 1 {
                if daysDiff == 1 {
                    streak += 1
                    checkDate = date
                } else if daysDiff == 0 && streak == 0 {
                    // Today is in the list but we haven't started counting
                    streak = 1
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                }
            } else if daysDiff > 1 {
                break
            }
        }
        
        // Calculate longest streak
        var longestStreakCount = 1
        var currentStreakCount = 1
        
        for i in 1..<sortedDates.count {
            let daysBetween = calendar.dateComponents([.day], from: sortedDates[i], to: sortedDates[i-1]).day ?? Int.max
            
            if daysBetween == 1 {
                currentStreakCount += 1
                longestStreakCount = max(longestStreakCount, currentStreakCount)
            } else {
                currentStreakCount = 1
            }
        }
        
        return (current: streak, longest: longestStreakCount)
    }
    
    func addWorkoutDate(_ date: Date = Date()) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        // Only add if not already in the list
        if !workoutDates.contains(where: { calendar.startOfDay(for: $0) == dayStart }) {
            workoutDates.append(date)
            // Invalidate streak cache to force recalculation
            invalidateStreakCache()
            // Calculate streaks immediately and synchronously
            calculateStreaks()
            Logger.info("✅ Workout date added - Total workout days: \(workoutDates.count)", category: .general)
        }
    }
    
    /// Marks a rest day, which increments the streak but doesn't count as a workout
    func markRestDay(_ date: Date = Date()) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        // Only add if not already in the list (either as workout or rest day)
        let isWorkoutDay = workoutDates.contains(where: { calendar.startOfDay(for: $0) == dayStart })
        let isRestDay = restDays.contains(where: { calendar.startOfDay(for: $0) == dayStart })
        
        if !isWorkoutDay && !isRestDay {
            restDays.append(date)
            calculateStreaks()
        }
    }
    
    /// Adds or updates a Personal Record (PR) for an exercise
    ///
    /// PR Detection Algorithm:
    /// - A new PR is detected when:
    ///   1. It's the first PR for the exercise, OR
    ///   2. The weight is higher than the current best PR, OR
    ///   3. The weight equals the current best PR but reps are higher
    ///
    /// PR Comparison Logic:
    /// - Primary: Compare by weight (higher is better)
    /// - Secondary: If weights are equal, compare by reps (higher is better)
    ///
    /// - Parameters:
    ///   - exercise: Name of the exercise
    ///   - weight: Weight lifted (in lbs)
    ///   - reps: Number of repetitions
    ///   - date: Date of the PR (defaults to now)
    /// - Returns: `true` if this is a new PR, `false` otherwise
    func addOrUpdatePR(exercise: String, weight: Double, reps: Int, date: Date = Date()) -> Bool {
        // Invalidate cache when PRs change
        invalidateExerciseCache()
        // Check if this is a new PR (better than existing)
        let existingPRs = prs.filter { $0.exercise == exercise }
        let isNewPR: Bool
        
        if existingPRs.isEmpty {
            // First PR for this exercise
            isNewPR = true
        } else {
            // Check if this beats the current PR
            let currentPR = existingPRs.max { pr1, pr2 in
                // Compare by weight first, then reps
                if pr1.weight != pr2.weight {
                    return pr1.weight < pr2.weight
                }
                return pr1.reps < pr2.reps
            }
            
            if let current = currentPR {
                // New PR if weight is higher, or same weight with more reps
                // Must be STRICTLY better (not equal)
                isNewPR = weight > current.weight || (weight == current.weight && reps > current.reps)
            } else {
                isNewPR = true
            }
        }
        
        // Only add the PR entry if it's actually a new PR
        if isNewPR {
            let newPR = PersonalRecord(exercise: exercise, weight: weight, reps: reps, date: date)
            prs.append(newPR)
            
            // Immediately save PR to ensure persistence
            savePRsImmediately()
            
            // Update selected exercise if needed
            updateSelectedExerciseIfNeeded()
            
            Logger.info("✅ PR ADDED to ProgressViewModel: \(exercise) - \(Int(weight)) lbs × \(reps) reps | Total PRs: \(prs.count)", category: .general)
        }
        
        return isNewPR
    }
    
    // Add initial PR entry for a new exercise (so it appears in dropdown)
    func addInitialExerciseEntry(exercise: String, weight: Double, reps: Int, date: Date = Date()) {
        // Check if exercise already exists
        if !availableExercises.contains(exercise) {
            invalidateExerciseCache() // Invalidate before adding
            let newPR = PersonalRecord(exercise: exercise, weight: weight, reps: reps, date: date)
            prs.append(newPR)
            updateSelectedExerciseIfNeeded()
        }
    }
    
    /// Deletes a Personal Record (PR)
    /// - Parameter pr: The PersonalRecord to delete
    func deletePR(_ pr: PersonalRecord) {
        // Remove PR from array
        prs.removeAll { $0.id == pr.id }
        
        // Invalidate caches to force recalculation
        invalidateExerciseCache()
        invalidateVolumeCache()
        
        // If the deleted PR was for the currently selected exercise, check if we need to update selection
        if selectedExercise == pr.exercise {
            // Check if there are any remaining PRs for this exercise
            let remainingPRs = prs.filter { $0.exercise == pr.exercise }
            if remainingPRs.isEmpty {
                // No more PRs for this exercise, clear selection
                selectedExercise = ""
            }
        }
        
        // Save PRs immediately after deletion
        savePRsImmediately()
        
        Logger.info("✅ PR deleted: \(pr.exercise) - \(Int(pr.weight)) lbs × \(pr.reps) reps | Remaining PRs: \(prs.count)", category: .general)
    }
    
    // MARK: - Trend Data for Graphs
    
    // Cache for volume data
    private var cachedVolumeData: [VolumeDataPoint] = []
    private var volumeDataCacheDate: Date?
    private let volumeCacheValidity: TimeInterval = AppConstants.Cache.volumeCacheValidity
    
    // Weekly volume data for the last 8 weeks
    var weeklyVolumeData: [VolumeDataPoint] {
        // Return cached data if valid
        if let cacheDate = volumeDataCacheDate,
           Date().timeIntervalSince(cacheDate) < volumeCacheValidity,
           !cachedVolumeData.isEmpty {
            return cachedVolumeData
        }
        
        // Calculate on background queue for better performance
        let calendar = Calendar.current
        let today = Date()
        let historyManager = WorkoutHistoryManager.shared
        
        // For large datasets, calculate asynchronously
        if historyManager.completedWorkouts.count > 50 {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                var data: [VolumeDataPoint] = []
                
                // Generate data for last N weeks
                for weekOffset in (0..<AppConstants.Progress.weeksToDisplay).reversed() {
                    let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today) ?? today
                    let weekStartOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart)) ?? weekStart
                    
                    // Calculate actual volume from completed workouts
                    let volume = historyManager.getWeeklyVolume(for: weekStartOfWeek)
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "M/d"
                    let weekLabel = formatter.string(from: weekStartOfWeek)
                    
                    data.append(VolumeDataPoint(week: weekOffset, weekLabel: weekLabel, volume: volume))
                }
                
                DispatchQueue.main.async {
                    self.cachedVolumeData = data
                    self.volumeDataCacheDate = Date()
                }
            }
            
            // Return empty array initially, will update when calculation completes
            return cachedVolumeData
        }
        
        // For small datasets, calculate synchronously
        var data: [VolumeDataPoint] = []
        
        // Generate data for last N weeks
        for weekOffset in (0..<AppConstants.Progress.weeksToDisplay).reversed() {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today) ?? today
            let weekStartOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart)) ?? weekStart
            
            // Calculate actual volume from completed workouts
            let volume = historyManager.getWeeklyVolume(for: weekStartOfWeek)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            let weekLabel = formatter.string(from: weekStartOfWeek)
            
            data.append(VolumeDataPoint(week: weekOffset, weekLabel: weekLabel, volume: volume))
        }
        
        // Update cache
        cachedVolumeData = data
        volumeDataCacheDate = Date()
        
        return data
    }
    
    // Invalidate volume cache when workouts change
    func invalidateVolumeCache() {
        cachedVolumeData = []
        volumeDataCacheDate = nil
    }
    
    // MARK: - Persistence
    
    private func savePRs() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            do {
                let encoded = try JSONEncoder().encode(self.prs)
                UserDefaults.standard.set(encoded, forKey: AppConstants.UserDefaultsKeys.personalRecords)
                Logger.debug("Saved \(self.prs.count) PRs", category: .persistence)
            } catch {
                Logger.error("Failed to save PRs", error: error, category: .persistence)
            }
        }
    }
    
    /// Immediately save PRs without debouncing (for critical updates like new PRs)
    private func savePRsImmediately() {
        do {
            let encoded = try JSONEncoder().encode(prs)
            UserDefaults.standard.set(encoded, forKey: AppConstants.UserDefaultsKeys.personalRecords)
            Logger.info("✅ PRs saved immediately - Total: \(prs.count)", category: .persistence)
        } catch {
            Logger.error("Failed to save PRs immediately", error: error, category: .persistence)
        }
    }
    
    private func loadPRs() {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.UserDefaultsKeys.personalRecords) else {
            Logger.info("No PR data found in UserDefaults - starting fresh", category: .persistence)
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([PersonalRecord].self, from: data)
            prs = decoded
            Logger.info("✅ Loaded \(decoded.count) PRs from UserDefaults", category: .persistence)
            if !decoded.isEmpty {
                Logger.debug("First 3 PRs: \(decoded.prefix(3).map { "\($0.exercise): \(Int($0.weight))lbs × \($0.reps)reps" }.joined(separator: ", "))", category: .persistence)
            }
        } catch {
            Logger.error("Failed to load PRs", error: error, category: .persistence)
            // Clear invalid data
            UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.personalRecords)
        }
    }
    
    private func saveWorkoutDates() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            do {
                let encoded = try JSONEncoder().encode(self.workoutDates)
                UserDefaults.standard.set(encoded, forKey: AppConstants.UserDefaultsKeys.workoutDates)
                Logger.debug("Saved \(self.workoutDates.count) workout dates", category: .persistence)
            } catch {
                Logger.error("Failed to save workout dates", error: error, category: .persistence)
            }
        }
    }
    
    private func loadWorkoutDates() {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.UserDefaultsKeys.workoutDates) else {
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([Date].self, from: data)
            workoutDates = decoded
            Logger.debug("Loaded \(decoded.count) workout dates", category: .persistence)
        } catch {
            Logger.error("Failed to load workout dates", error: error, category: .persistence)
            // Clear invalid data
            UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.workoutDates)
        }
    }
    
    private func saveRestDays() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            do {
                let encoded = try JSONEncoder().encode(self.restDays)
                UserDefaults.standard.set(encoded, forKey: AppConstants.UserDefaultsKeys.restDays)
                Logger.debug("Saved \(self.restDays.count) rest days", category: .persistence)
            } catch {
                Logger.error("Failed to save rest days", error: error, category: .persistence)
            }
        }
    }
    
    private func loadRestDays() {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.UserDefaultsKeys.restDays) else {
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([Date].self, from: data)
            restDays = decoded
            Logger.debug("Loaded \(decoded.count) rest days", category: .persistence)
        } catch {
            Logger.error("Failed to load rest days", error: error, category: .persistence)
            // Clear invalid data
            UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.restDays)
        }
    }
    
    // Weekly workout frequency for the last N weeks
    var weeklyWorkoutFrequency: [FrequencyDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        var data: [FrequencyDataPoint] = []
        
        // Generate data for last N weeks
        for weekOffset in (0..<AppConstants.Progress.weeksToDisplay).reversed() {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today) ?? today
            let weekStartOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart)) ?? weekStart
            
            // Count workouts in this week
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStartOfWeek) ?? weekStartOfWeek
            let workoutsInWeek = workoutDates.filter { date in
                let dayStart = calendar.startOfDay(for: date)
                return dayStart >= weekStartOfWeek && dayStart <= weekEnd
            }.count
            
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            let weekLabel = formatter.string(from: weekStartOfWeek)
            
            data.append(FrequencyDataPoint(week: weekOffset, weekLabel: weekLabel, count: workoutsInWeek))
        }
        
        return data
    }
}

// MARK: - Data Point Models for Graphs
struct VolumeDataPoint {
    let week: Int
    let weekLabel: String
    let volume: Int
}

struct FrequencyDataPoint {
    let week: Int
    let weekLabel: String
    let count: Int
}

