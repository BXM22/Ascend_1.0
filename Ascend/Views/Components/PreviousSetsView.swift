import SwiftUI

struct PreviousSetsView: View {
    let sets: [ExerciseSet]
    
    // Separate warm-up sets and working sets
    private var warmupSets: [ExerciseSet] {
        sets.filter { $0.isWarmup }
    }
    
    private var workingSets: [ExerciseSet] {
        sets.filter { !$0.isWarmup }
    }
    
    // Group sets by set number, including dropsets (only for working sets)
    private var groupedSets: [(setNumber: Int, mainSet: ExerciseSet, dropsets: [ExerciseSet])] {
        var grouped: [Int: (mainSet: ExerciseSet?, dropsets: [ExerciseSet])] = [:]
        
        for set in workingSets {
            if set.isDropset {
                // For dropsets, they share the same set number as their main set
                let mainSetNumber = set.setNumber
                if grouped[mainSetNumber] == nil {
                    grouped[mainSetNumber] = (mainSet: nil, dropsets: [])
                }
                grouped[mainSetNumber]?.dropsets.append(set)
            } else {
                // Main set
                if grouped[set.setNumber] == nil {
                    grouped[set.setNumber] = (mainSet: nil, dropsets: [])
                }
                grouped[set.setNumber]?.mainSet = set
            }
        }
        
        // Sort dropsets by dropsetNumber within each group
        for key in grouped.keys {
            grouped[key]?.dropsets.sort { ($0.dropsetNumber ?? 0) < ($1.dropsetNumber ?? 0) }
        }
        
        return grouped
            .sorted { $0.key < $1.key }
            .compactMap { setNumber, data in
                guard let mainSet = data.mainSet else { return nil }
                return (setNumber: setNumber, mainSet: mainSet, dropsets: data.dropsets)
            }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Previous Sets")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.foreground)
            
            // Warm-up sets section
            if !warmupSets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Warm-up")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                        .textCase(.uppercase)
                    
                    ForEach(warmupSets.sorted(by: { $0.setNumber < $1.setNumber }), id: \.id) { set in
                        WarmupSetRow(set: set)
                    }
                }
                .padding(.bottom, 8)
            }
            
            // Working sets section
            if !groupedSets.isEmpty {
                ForEach(groupedSets, id: \.setNumber) { group in
                    SetRowGroup(mainSet: group.mainSet, dropsets: group.dropsets)
                        .id("\(group.setNumber)-\(group.mainSet.id)-\(group.dropsets.count)")
                }
            }
        }
        .padding(20)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

struct SetRowGroup: View {
    let mainSet: ExerciseSet
    let dropsets: [ExerciseSet]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main set
            HStack {
                HStack(spacing: 12) {
                    Text("Set \(mainSet.setNumber)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    if let holdDuration = mainSet.holdDuration {
                        Text("\(holdDuration) seconds")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.foreground)
                    } else {
                        Text("\(Int(mainSet.weight)) lbs × \(mainSet.reps) reps")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.foreground)
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(AppColors.accent.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.accent)
                }
            }
            
            // Dropsets
            if !dropsets.isEmpty {
                ForEach(dropsets.sorted(by: { ($0.dropsetNumber ?? 0) < ($1.dropsetNumber ?? 0) }), id: \.id) { dropset in
                    HStack {
                        HStack(spacing: 12) {
                            if let dropsetNum = dropset.dropsetNumber {
                                Text("DS\(dropsetNum)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AppColors.accent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(AppColors.accent.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                            
                            if let holdDuration = dropset.holdDuration {
                                Text("\(holdDuration) seconds")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.mutedForeground)
                            } else {
                                Text("\(Int(dropset.weight)) lbs × \(dropset.reps) reps")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.mutedForeground)
                            }
                        }
                        
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(AppColors.accent.opacity(0.08))
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppColors.accent.opacity(0.7))
                        }
                    }
                    .padding(.leading, 24)
                }
            }
        }
        .padding(.vertical, 12)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.border.opacity(0.3)),
            alignment: .bottom
        )
    }
}

struct SetRow: View {
    let set: ExerciseSet
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Text("Set \(set.setNumber)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
                
                if let holdDuration = set.holdDuration {
                    Text("\(holdDuration) seconds")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.foreground)
                } else {
                    Text("\(Int(set.weight)) lbs × \(set.reps) reps")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.foreground)
                }
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(AppColors.accent.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.accent)
            }
        }
        .padding(.vertical, 12)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.border.opacity(0.3)),
            alignment: .bottom
        )
    }
}

struct WarmupSetRow: View {
    let set: ExerciseSet
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                // Show warm-up indicator instead of set number
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.accent)
                    Text("Warm-up")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                if let holdDuration = set.holdDuration {
                    Text("\(holdDuration) seconds")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.foreground.opacity(0.7))
                } else {
                    Text("\(Int(set.weight)) lbs × \(set.reps) reps")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.foreground.opacity(0.7))
                }
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(AppColors.accent.opacity(0.08))
                    .frame(width: 28, height: 28)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.accent.opacity(0.6))
            }
        }
        .padding(.vertical, 8)
        .padding(.leading, 8)
        .background(AppColors.secondary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    PreviousSetsView(sets: [
        ExerciseSet(setNumber: 1, weight: 185, reps: 8),
        ExerciseSet(setNumber: 2, weight: 185, reps: 8),
        ExerciseSet(setNumber: 3, weight: 185, reps: 7)
    ])
    .padding()
    .background(AppColors.background)
}

