//
//  HabitEditView.swift
//  Ascend
//
//  Created on 2025
//

import SwiftUI

struct HabitEditView: View {
    let habit: Habit?
    let onSave: (Habit) -> Void
    let onCancel: () -> Void
    let onDelete: (() -> Void)?
    
    @State private var name: String = ""
    @State private var completionDuration: Int = 15
    @State private var targetStreakDays: Int? = nil
    @State private var isForever: Bool = true
    @State private var reminderTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var reminderEnabled: Bool = false
    @State private var selectedColorHex: String? = nil
    @State private var selectedIcon: String = "checkmark.circle.fill"
    @Environment(\.dismiss) private var dismiss
    
    // Common habit icons
    private let habitIcons = [
        "checkmark.circle.fill",
        "book.fill",
        "brain.head.profile",
        "figure.run",
        "drop.fill",
        "leaf.fill",
        "moon.stars.fill",
        "sun.max.fill",
        "heart.fill",
        "flame.fill",
        "star.fill",
        "pencil",
        "paintbrush.fill",
        "music.note",
        "gamecontroller.fill"
    ]
    
    init(
        habit: Habit? = nil,
        onSave: @escaping (Habit) -> Void,
        onCancel: @escaping () -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.habit = habit
        self.onSave = onSave
        self.onCancel = onCancel
        self.onDelete = onDelete
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                formContent
                    .padding(20)
            }
            .background(AppColors.background)
            .navigationTitle(habit == nil ? "New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .foregroundColor(AppColors.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        HapticManager.impact(style: .medium)
                        saveHabit()
                    }
                    .foregroundColor(AppColors.primary)
                    .disabled(name.isEmpty)
                }
            }
        }
        .onAppear {
            loadHabitData()
        }
    }
    
    private var formContent: some View {
        VStack(spacing: 20) {
            nameField
            iconPicker
            durationField
            targetStreakSection
            reminderSection
            colorPicker
            deleteButton
        }
    }
    
    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Habit Name")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.foreground)
            
            TextField("e.g., Morning Meditation", text: $name)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .padding(12)
                .background(AppColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Icon")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.foreground)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(habitIcons, id: \.self) { icon in
                        iconButton(icon: icon)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private func iconButton(icon: String) -> some View {
        Button(action: {
            HapticManager.selection()
            selectedIcon = icon
        }) {
            ZStack {
                if selectedIcon == icon {
                    Circle()
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: 50, height: 50)
                } else {
                    Circle()
                        .fill(AppColors.secondary)
                        .frame(width: 50, height: 50)
                }
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(selectedIcon == icon ? .white : AppColors.foreground)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var durationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Duration (minutes)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.foreground)
            
            Stepper(value: $completionDuration, in: 1...300, step: 5) {
                Text("\(completionDuration) min")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.foreground)
            }
            .padding(12)
            .background(AppColors.input)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var targetStreakSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $isForever) {
                Text("Forever Habit")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.foreground)
            }
            .tint(AppColors.primary)
            
            if !isForever {
                targetStreakField
            }
        }
    }
    
    private var targetStreakField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Target Streak (days)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.foreground)
            
            Stepper(value: Binding(
                get: { targetStreakDays ?? 30 },
                set: { targetStreakDays = $0 }
            ), in: 7...365, step: 7) {
                Text("\(targetStreakDays ?? 30) days")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.foreground)
            }
            .padding(12)
            .background(AppColors.input)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $reminderEnabled) {
                Text("Daily Reminder")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.foreground)
            }
            .tint(AppColors.primary)
            
            if reminderEnabled {
                DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .padding(12)
                    .background(AppColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.foreground)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    defaultColorButton
                    ForEach(AppColors.templateColorPalette, id: \.hex) { colorInfo in
                        colorButton(colorInfo: colorInfo)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var defaultColorButton: some View {
        Button(action: {
            HapticManager.selection()
            selectedColorHex = nil
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.primary)
                    .frame(width: 50, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedColorHex == nil ? AppColors.foreground : Color.clear, lineWidth: 3)
                    )
                
                if selectedColorHex == nil {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func colorButton(colorInfo: (name: String, hex: String)) -> some View {
        Button(action: {
            HapticManager.selection()
            selectedColorHex = colorInfo.hex
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: colorInfo.hex))
                    .frame(width: 50, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedColorHex == colorInfo.hex ? AppColors.foreground : Color.clear, lineWidth: 3)
                    )
                
                if selectedColorHex == colorInfo.hex {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var deleteButton: some View {
        if let _ = habit, let onDelete = onDelete {
            Button(action: {
                HapticManager.impact(style: .medium)
                onDelete()
                dismiss()
            }) {
                Text("Delete Habit")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.destructive)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.secondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.destructive, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.top, 8)
        }
    }
    
    private func loadHabitData() {
        if let habit = habit {
            name = habit.name
            completionDuration = habit.completionDuration
            targetStreakDays = habit.targetStreakDays
            isForever = habit.isForever
            reminderTime = habit.reminderTime ?? reminderTime
            reminderEnabled = habit.reminderEnabled
            selectedColorHex = habit.colorHex
            selectedIcon = habit.icon
        }
    }
    
    private func saveHabit() {
        let newHabit = Habit(
            id: habit?.id ?? UUID(),
            name: name,
            completionDuration: completionDuration,
            targetStreakDays: isForever ? nil : targetStreakDays,
            reminderTime: reminderEnabled ? reminderTime : nil,
            reminderEnabled: reminderEnabled,
            colorHex: selectedColorHex,
            icon: selectedIcon,
            createdDate: habit?.createdDate ?? Date()
        )
        onSave(newHabit)
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    HabitEditView(
        habit: nil,
        onSave: { _ in },
        onCancel: {}
    )
}

