import SwiftUI

struct MuscleGroupChart: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    @ObservedObject private var workoutHistoryManager = WorkoutHistoryManager.shared
    
    @State private var cachedMuscleGroupData: [MuscleGroupData] = []
    @State private var cachedTotalSets: Int = 0
    
    // Simple file-based debug log (appends NDJSON)
    private func debugLog(_ message: String, data: [String: Any] = [:], hypothesisId: String = "perf") {
        let logPath = "/Users/brennenmeregillano/Desktop/Ascend/.cursor/debug.log"
        let payload: [String: Any] = [
            "sessionId": "debug-session",
            "runId": "perf-tuning",
            "hypothesisId": hypothesisId,
            "location": "MuscleGroupChart.swift",
            "message": message,
            "data": data,
            "timestamp": Date().timeIntervalSince1970 * 1000
        ]
        guard let json = try? JSONSerialization.data(withJSONObject: payload),
              let line = String(data: json, encoding: .utf8) else { return }
        let url = URL(fileURLWithPath: logPath)
        let entry = (line + "\n").data(using: .utf8) ?? Data()
        if FileManager.default.fileExists(atPath: logPath),
           let handle = try? FileHandle(forWritingTo: url) {
            try? handle.write(contentsOf: entry)
            try? handle.close()
        } else {
            try? entry.write(to: url)
        }
    }
    
    private func calculateMuscleGroupDistribution() -> [MuscleGroupData] {
        // Track all completed workouts for muscle distribution
        let allWorkouts = workoutHistoryManager.completedWorkouts
        
        // Add logging
        Logger.info("📊 Calculating muscle groups - Total workouts: \(allWorkouts.count)", category: .general)
        
        var muscleGroupCounts: [String: Int] = [:]
        
        // Process all completed workouts
        for workout in allWorkouts {
            Logger.debug("📊 Processing workout: \(workout.name) with \(workout.exercises.count) exercises", category: .general)
            
            for exercise in workout.exercises {
                // Get both primary and secondary muscle groups
                let (primary, secondary) = ExerciseDataManager.shared.getMuscleGroups(for: exercise.name)
                
                // Count completed sets (only count sets that have been completed)
                let completedSets = exercise.sets.filter { set in
                    // A set is considered completed if it has reps > 0 or weight > 0
                    set.reps > 0 || set.weight > 0 || set.holdDuration != nil
                }
                let setCount = completedSets.count
                
                if setCount > 0 {
                    Logger.debug("📊 Exercise: \(exercise.name) → Primary: \(primary), Secondary: \(secondary), Sets: \(setCount)", category: .general)
                    
                    // Count primary muscle groups (full weight)
                    for muscleGroup in primary {
                        let normalized = normalizeMuscleGroup(muscleGroup)
                        muscleGroupCounts[normalized, default: 0] += setCount
                        Logger.debug("📊 Added \(setCount) sets to \(normalized) (primary)", category: .general)
                    }
                    
                    // Count secondary muscle groups (half weight)
                    for muscleGroup in secondary {
                        let normalized = normalizeMuscleGroup(muscleGroup)
                        // Secondary muscles get half credit
                        muscleGroupCounts[normalized, default: 0] += max(1, setCount / 2)
                        Logger.debug("📊 Added \(setCount / 2) sets to \(normalized) (secondary)", category: .general)
                    }
                }
            }
        }
        
        // Convert to MuscleGroupData array
        let result = muscleGroupCounts.map { key, value in
            MuscleGroupData(
                name: key,
                count: value,
                gradient: gradientForMuscleGroup(key)
            )
        }
        .sorted { $0.count > $1.count }
        
        let totalSets = result.reduce(0) { $0 + $1.count }
        Logger.info("📊 Chart calculation complete - Muscle groups: \(result.count), Total sets: \(totalSets)", category: .general)
        debugLog("calc complete", data: ["entries": result.count, "totalSets": totalSets, "workouts": allWorkouts.count])
        return result
    }
    
    private func refreshData() {
        let start = Date()
        // Process on background queue for large datasets
        let allWorkouts = workoutHistoryManager.completedWorkouts
        if allWorkouts.count > 50 {
            PerformanceOptimizer.performOnBackground(
                {
                    return self.calculateMuscleGroupDistribution()
                },
                completion: { (data: [MuscleGroupData]) in
                    self.cachedMuscleGroupData = data
                    self.cachedTotalSets = data.reduce(0) { $0 + $1.count }
                    self.debugLog("refreshData", data: ["durationMs": Int(Date().timeIntervalSince(start)*1000), "totalSets": self.cachedTotalSets])
                }
            )
        } else {
            let data = calculateMuscleGroupDistribution()
            cachedMuscleGroupData = data
            cachedTotalSets = data.reduce(0) { $0 + $1.count }
            debugLog("refreshData", data: ["durationMs": Int(Date().timeIntervalSince(start)*1000), "totalSets": cachedTotalSets])
        }
    }
    
    private func normalizeMuscleGroup(_ group: String) -> String {
        let lowercased = group.lowercased()
        if lowercased.contains("chest") || lowercased.contains("push") || lowercased.contains("shoulder") {
            return "Chest"
        } else if lowercased.contains("back") || lowercased.contains("pull") || lowercased.contains("lat") {
            return "Back"
        } else if lowercased.contains("leg") || lowercased.contains("quad") || lowercased.contains("hamstring") || lowercased.contains("calf") || lowercased.contains("glute") {
            return "Legs"
        } else if lowercased.contains("arm") || lowercased.contains("bicep") || lowercased.contains("tricep") {
            return "Arms"
        } else if lowercased.contains("core") || lowercased.contains("ab") {
            return "Core"
        } else if lowercased.contains("cardio") {
            return "Cardio"
        } else {
            return "Other"
        }
    }
    
    private func gradientForMuscleGroup(_ group: String) -> LinearGradient {
        switch group {
        case "Chest":
            return LinearGradient.chestGradient
        case "Back":
            return LinearGradient.backGradient
        case "Legs":
            return LinearGradient.legsGradient
        case "Arms":
            return LinearGradient.armsGradient
        case "Core":
            return LinearGradient.coreGradient
        case "Cardio":
            return LinearGradient.cardioGradient
        default:
            return LinearGradient.primaryGradient
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Centered circular chart
            ZStack {
                if cachedTotalSets == 0 {
                    // Empty state
                    Circle()
                        .stroke(AppColors.border.opacity(0.3), lineWidth: 22)
                        .frame(width: 160, height: 160)
                    
                    VStack(spacing: 4) {
                        Text("No Data")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Text("Start tracking")
                            .font(.system(size: 9))
                            .foregroundColor(AppColors.mutedForeground)
                    }
                } else {
                    // Background circle
                    Circle()
                        .stroke(AppColors.border.opacity(0.1), lineWidth: 22)
                        .frame(width: 160, height: 160)
                    
                    // Muscle group segments - draw in order
                    ForEach(Array(cachedMuscleGroupData.enumerated()), id: \.element.id) { index, data in
                        MuscleGroupSegment(
                            data: data,
                            totalSets: cachedTotalSets,
                            startFraction: cumulativeFraction(for: index),
                            size: 160,
                            strokeWidth: 22
                        )
                    }
                    
                    // Center text
                    VStack(spacing: 2) {
                        Text("\(cachedTotalSets)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(LinearGradient.primaryGradient)
                        
                        Text("Total Sets")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Text("All Workouts")
                            .font(.system(size: 8, weight: .regular))
                            .foregroundColor(AppColors.mutedForeground.opacity(0.7))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .padding(.top, 12)
            
            // Legend below (compact grid)
            if !cachedMuscleGroupData.isEmpty {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ],
                    alignment: .leading,
                    spacing: 8
                ) {
                    ForEach(cachedMuscleGroupData) { data in
                        CompactMuscleGroupLegendItem(data: data, total: cachedTotalSets)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.foreground.opacity(0.08), radius: 20, x: 0, y: 4)
        .drawingGroup() // Optimize complex chart rendering
        .onAppear {
            // Force refresh on appear to ensure data is loaded
            refreshData()
        }
        .onChange(of: workoutHistoryManager.completedWorkouts.count) { _, _ in
            // Refresh when workout count changes
            refreshData()
        }
        .onReceive(workoutHistoryManager.$completedWorkouts) { _ in
            // Debounce refresh to avoid excessive recalculations
            PerformanceOptimizer.shared.debouncedSave(delay: 0.3) {
                self.refreshData()
            }
        }
        .drawingGroup() // Optimize rendering for complex chart
    }
    
    private func cumulativeFraction(for index: Int) -> Double {
        guard cachedTotalSets > 0, index < cachedMuscleGroupData.count, index >= 0 else { return 0 }
        
        if index == 0 {
            return 0.0
        }
        
        let previousData = cachedMuscleGroupData.prefix(index)
        let previousPercentage = previousData.reduce(0.0) { total, data in
            total + (Double(data.count) / Double(cachedTotalSets))
        }
        // Ensure we don't exceed 1.0 and handle floating point precision
        return min(1.0, max(0.0, previousPercentage))
    }
}

struct MuscleGroupData: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let gradient: LinearGradient
    
    var percentage: Double {
        return 0.0 // Will be calculated relative to total
    }
}

struct MuscleGroupSegment: View {
    let data: MuscleGroupData
    let totalSets: Int
    let startFraction: Double
    let size: CGFloat
    let strokeWidth: CGFloat
    
    private var percentage: Double {
        guard totalSets > 0 else { return 0.0 }
        return Double(data.count) / Double(totalSets)
    }
    
    private var endFraction: Double {
        let calculatedEnd = startFraction + percentage
        // Ensure we don't exceed 1.0 and handle floating point precision
        return min(1.0, max(startFraction, calculatedEnd))
    }
    
    var body: some View {
        Circle()
            .trim(from: max(0, min(1, CGFloat(startFraction))), to: max(0, min(1, CGFloat(endFraction))))
            .stroke(
                data.gradient,
                style: StrokeStyle(
                    lineWidth: strokeWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(-90))
            .animation(.easeInOut(duration: 0.3), value: startFraction)
            .animation(.easeInOut(duration: 0.3), value: endFraction)
    }
}

struct MuscleGroupLegendItem: View {
    let data: MuscleGroupData
    let total: Int
    
    private var percentage: Int {
        guard total > 0 else { return 0 }
        return Int(round(Double(data.count) / Double(total) * 100))
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Colored dot
            Circle()
                .fill(data.gradient)
                .frame(width: 12, height: 12)
            
            Text(data.name)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("\(data.count) sets")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
                    .lineLimit(1)
                
                Text("(\(percentage)%)")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.mutedForeground)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
    }
}

struct CompactMuscleGroupLegendItem: View {
    let data: MuscleGroupData
    let total: Int
    
    private var percentage: Int {
        guard total > 0 else { return 0 }
        return Int(round(Double(data.count) / Double(total) * 100))
    }
    
    var body: some View {
        HStack(spacing: 6) {
            // Colored dot
            Circle()
                .fill(data.gradient)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(data.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text("\(data.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Text("(\(percentage)%)")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(AppColors.secondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    MuscleGroupChart(progressViewModel: ProgressViewModel())
        .padding()
        .background(AppColors.background)
}

