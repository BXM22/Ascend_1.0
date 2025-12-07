import Foundation
import SwiftUI
import Combine

class WorkoutSplitViewModel: ObservableObject {
    @Published var splits: [WorkoutSplit] = []
    @Published var showCreateSplit = false
    @Published var editingSplit: WorkoutSplit?
    
    init() {
        // Start with empty splits - users can create their own
        splits = []
    }
    
    func createSplit(name: String, splitType: WorkoutSplitType) {
        let split = WorkoutSplit(name: name, splitType: splitType)
        splits.append(split)
    }
    
    func updateSplit(_ split: WorkoutSplit) {
        if let index = splits.firstIndex(where: { $0.id == split.id }) {
            splits[index] = split
        }
    }
    
    func deleteSplit(_ split: WorkoutSplit) {
        splits.removeAll { $0.id == split.id }
    }
    
    func assignTemplate(_ templateId: UUID, toDay dayIndex: Int, inSplit splitId: UUID) {
        if let splitIndex = splits.firstIndex(where: { $0.id == splitId }) {
            var updatedSplit = splits[splitIndex]
            updatedSplit.setTemplate(templateId, for: dayIndex)
            splits[splitIndex] = updatedSplit
        }
    }
    
    func removeTemplate(fromDay dayIndex: Int, inSplit splitId: UUID) {
        if let splitIndex = splits.firstIndex(where: { $0.id == splitId }) {
            var updatedSplit = splits[splitIndex]
            updatedSplit.setTemplate(nil, for: dayIndex)
            splits[splitIndex] = updatedSplit
        }
    }
    
    func startSplit(_ split: WorkoutSplit, onDate: Date = Date()) {
        if let index = splits.firstIndex(where: { $0.id == split.id }) {
            var updatedSplit = splits[index]
            updatedSplit.startDate = onDate
            splits[index] = updatedSplit
        }
    }
}


