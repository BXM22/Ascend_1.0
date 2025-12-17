import SwiftUI

struct CustomSportEditView: View {
    let customSport: CustomSport?
    let onSave: (CustomSport) -> Void
    let onDelete: ((CustomSport) -> Void)?
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var roundMinutes: Int = 3
    @State private var roundSeconds: Int = 0
    @State private var restMinutes: Int = 1
    @State private var restSeconds: Int = 0
    @State private var numberOfRounds: Int = 12
    @State private var roundLabel: String = "Round"
    @State private var restLabel: String = "Rest"
    @State private var selectedIcon: String = "figure.martial.arts"
    @State private var isSaving: Bool = false
    
    // Available icons for custom sports
    private let availableIcons = [
        "figure.boxing", "figure.mixed.cardio", "figure.wrestling",
        "figure.martial.arts", "figure.yoga", "figure.kickboxing",
        "figure.run", "figure.strengthtraining.traditional",
        "figure.cross.training", "figure.core.training"
    ]
    
    init(customSport: CustomSport? = nil, onSave: @escaping (CustomSport) -> Void, onDelete: ((CustomSport) -> Void)? = nil) {
        self.customSport = customSport
        self.onSave = onSave
        self.onDelete = onDelete
        
        if let sport = customSport {
            _name = State(initialValue: sport.name)
            _roundMinutes = State(initialValue: sport.roundDuration / 60)
            _roundSeconds = State(initialValue: sport.roundDuration % 60)
            _restMinutes = State(initialValue: sport.restDuration / 60)
            _restSeconds = State(initialValue: sport.restDuration % 60)
            _numberOfRounds = State(initialValue: sport.numberOfRounds)
            _roundLabel = State(initialValue: sport.roundLabel)
            _restLabel = State(initialValue: sport.restLabel)
            _selectedIcon = State(initialValue: sport.icon)
        }
    }
    
    private func saveCustomSport() {
        guard !name.isEmpty, !isSaving else { return }
        isSaving = true
        
        let roundDuration = roundMinutes * 60 + roundSeconds
        let restDuration = restMinutes * 60 + restSeconds
        
        let sport = CustomSport(
            id: customSport?.id ?? UUID(),
            name: name,
            roundDuration: roundDuration,
            restDuration: restDuration,
            numberOfRounds: numberOfRounds,
            roundLabel: roundLabel,
            restLabel: restLabel,
            icon: selectedIcon
        )
        
        DispatchQueue.main.async {
            self.onSave(sport)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.dismiss()
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Sport Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sport Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, 20)
                        
                        TextField("Enter sport name", text: $name)
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppColors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    
                    // Icon Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Icon")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(availableIcons, id: \.self) { icon in
                                    Button(action: {
                                        selectedIcon = icon
                                        HapticManager.impact(style: .light)
                                    }) {
                                        ZStack {
                                            if selectedIcon == icon {
                                                LinearGradient.primaryGradient
                                            } else {
                                                AppColors.secondary
                                            }
                                            
                                            Image(systemName: icon)
                                                .font(.system(size: 24))
                                                .foregroundColor(selectedIcon == icon ? .white : AppColors.textSecondary)
                                        }
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Round Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Round Settings")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 16) {
                            // Round Duration
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Round Duration")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                                    .padding(.horizontal, 20)
                                
                                HStack(spacing: 12) {
                                    Spacer()
                                    
                                    Picker("Minutes", selection: $roundMinutes) {
                                        ForEach(0..<10) { minute in
                                            Text("\(minute) min").tag(minute)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 120)
                                    
                                    Text(":")
                                        .font(.title2)
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    Picker("Seconds", selection: $roundSeconds) {
                                        ForEach(0..<60) { second in
                                            Text("\(second) sec").tag(second)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 120)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .background(AppColors.card)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal, 20)
                            }
                            
                            // Number of Rounds
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Number of Rounds")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                                    .padding(.horizontal, 20)
                                
                                HStack {
                                    Button(action: {
                                        if numberOfRounds > 1 {
                                            numberOfRounds -= 1
                                            HapticManager.impact(style: .light)
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(numberOfRounds > 1 ? AppColors.primary : AppColors.mutedForeground)
                                    }
                                    .disabled(numberOfRounds <= 1)
                                    
                                    Spacer()
                                    
                                    Text("\(numberOfRounds)")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(AppColors.textPrimary)
                                        .frame(minWidth: 60)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        if numberOfRounds < 20 {
                                            numberOfRounds += 1
                                            HapticManager.impact(style: .light)
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(numberOfRounds < 20 ? AppColors.primary : AppColors.mutedForeground)
                                    }
                                    .disabled(numberOfRounds >= 20)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(AppColors.card)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    
                    // Rest Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Rest Settings")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 20)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rest Duration")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, 20)
                            
                            HStack(spacing: 12) {
                                Spacer()
                                
                                Picker("Minutes", selection: $restMinutes) {
                                    ForEach(0..<10) { minute in
                                        Text("\(minute) min").tag(minute)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 120)
                                
                                Text(":")
                                    .font(.title2)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Picker("Seconds", selection: $restSeconds) {
                                    ForEach(0..<60) { second in
                                        Text("\(second) sec").tag(second)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 120)
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .background(AppColors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Labels
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Labels")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Round Label")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                                    .padding(.horizontal, 20)
                                
                                TextField("Round", text: $roundLabel)
                                    .font(.system(size: 16))
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(AppColors.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(.horizontal, 20)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Rest Label")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                                    .padding(.horizontal, 20)
                                
                                TextField("Rest", text: $restLabel)
                                    .font(.system(size: 16))
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(AppColors.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .background(AppColors.background)
            .navigationTitle(customSport == nil ? "Create Custom Sport" : "Edit Custom Sport")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        if let sport = customSport, let onDelete = onDelete {
                            Button(action: {
                                onDelete(sport)
                                dismiss()
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(AppColors.destructive)
                            }
                        }
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(AppColors.textPrimary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        HapticManager.impact(style: .medium)
                        saveCustomSport()
                    }
                    .foregroundColor(AppColors.primary)
                    .disabled(name.isEmpty || isSaving)
                }
            }
        }
    }
}
