//
//  UIColorCustomizationManager.swift
//  Ascend
//
//  Manager for UI color customization persistence and updates
//

import Foundation
import SwiftUI
import Combine

class UIColorCustomizationManager: ObservableObject {
    static let shared = UIColorCustomizationManager()
    
    @Published var customization: UIColorCustomization {
        didSet {
            saveCustomization()
            // Notify AppColors to update
            NotificationCenter.default.post(name: AppConstants.Notification.colorThemeDidChange, object: nil)
        }
    }
    
    private let customizationKey = "uiColorCustomization"
    
    private init() {
        self.customization = UIColorCustomization()
        loadCustomization()
    }
    
    // MARK: - Public Methods
    
    /// Get custom color for a key, if it exists
    func getCustomColor(for key: UIColorCustomization.ColorKey) -> String? {
        return customization.customColors[key.rawValue]
    }
    
    /// Set custom color for a key
    func setCustomColor(_ hex: String, for key: UIColorCustomization.ColorKey) {
        customization.customColors[key.rawValue] = hex
    }
    
    /// Reset color to default (remove custom color)
    func resetColor(for key: UIColorCustomization.ColorKey) {
        customization.customColors.removeValue(forKey: key.rawValue)
    }
    
    /// Reset all custom colors
    func resetAll() {
        customization = UIColorCustomization()
    }
    
    /// Check if a color is customized
    func isCustomized(_ key: UIColorCustomization.ColorKey) -> Bool {
        return customization.customColors[key.rawValue] != nil
    }
    
    /// Check if any colors are customized
    var hasCustomizations: Bool {
        return !customization.customColors.isEmpty
    }
    
    // MARK: - Persistence
    
    private func loadCustomization() {
        guard let data = UserDefaults.standard.data(forKey: customizationKey) else {
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode(UIColorCustomization.self, from: data)
            customization = decoded
        } catch {
            Logger.error("Failed to load UI color customization", error: error, category: .persistence)
        }
    }
    
    private func saveCustomization() {
        do {
            let encoded = try JSONEncoder().encode(customization)
            UserDefaults.standard.set(encoded, forKey: customizationKey)
        } catch {
            Logger.error("Failed to save UI color customization", error: error, category: .persistence)
        }
    }
}







