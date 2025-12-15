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
        // Get workouts from last 30 days
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        // Add logging
        Logger.info("📊 Calculating muscle groups - Total workouts: \(workoutHistoryManager.completedWorkouts.count)", category: .general)
        
        var recentWorkouts = workoutHistoryManager.completedWorkouts.filter { workout in
            workout.startDate >= thirtyDaysAgo
        }
        
        // Fallback: if no recent workouts, use all history so chart still shows data
        if recentWorkouts.isEmpty {
            Logger.info("📊 No recent workouts in 30 days, using all completed workouts (\(workoutHistoryManager.completedWorkouts.count))", category: .general)
            recentWorkouts = workoutHistoryManager.completedWorkouts
        } else {
            Logger.info("📊 Recent workouts (30 days): \(recentWorkouts.count)", category: .general)
        }
        
        var muscleGroupCounts: [String: Int] = [:]
        
        for workout in recentWorkouts {
            Logger.debug("📊 Processing workout: \(workout.name) with \(workout.exercises.count) exercises", category: .general)
            
            for exercise in workout.exercises {
                let (primary, _) = ExerciseDataManager.shared.getMuscleGroups(for: exercise.name)
                Logger.debug("📊 Exercise: \(exercise.name) → Muscle groups: \(primary)", category: .general)
                
                for muscleGroup in primary {
                    let normalized = normalizeMuscleGroup(muscleGroup)
                    let setCount = exercise.sets.count
                    muscleGroupCounts[normalized, default: 0] += setCount
                    Logger.debug("📊 Added \(setCount) sets to \(normalized)", category: .general)
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
        
        debugLog("calc complete", data: ["entries": result.count, "totalSets": result.reduce(0) { $0 + $1.count }])
        return result
    }
    
    private func refreshData() {
        let start = Date()
        let data = calculateMuscleGroupDistribution()
        cachedMuscleGroupData = data
        cachedTotalSets = data.reduce(0) { $0 + $1.count }
        debugLog("refreshData", data: ["durationMs": Int(Date().timeIntervalSince(start)*1000), "totalSets": cachedTotalSets])
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
                    
                    // Muscle group segments
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
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .padding(.top, 12)
            
            // Legend below (compact grid)
            if !cachedMuscleGroupData.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
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
        .onAppear {
            refreshData()
        }
        .onReceive(workoutHistoryManager.$completedWorkouts) { _ in
            refreshData()
        }
    }
    
    private func cumulativeFraction(for index: Int) -> Double {
        guard cachedTotalSets > 0 else { return 0 }
        let previousData = cachedMuscleGroupData.prefix(index)
        let previousPercentage = previousData.reduce(0.0) { total, data in
            total + (Double(data.count) / Double(cachedTotalSets))
        }
        return previousPercentage
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
        min(1.0, startFraction + percentage)
    }
    
    var body: some View {
        Circle()
            .trim(from: CGFloat(startFraction), to: CGFloat(endFraction))
            .stroke(data.gradient, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
            .frame(width: size, height: size)
            .rotationEffect(.degrees(-90))
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

