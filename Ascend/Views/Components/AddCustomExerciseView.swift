import SwiftUI

// MARK: - Kinetic typography (Add Custom Exercise wireframe)

private enum AddCustomExerciseFonts {
    static func extraBold(_ size: CGFloat) -> Font { Font.custom("Manrope-ExtraBold", size: size, relativeTo: .body) }
    static func bold(_ size: CGFloat) -> Font { Font.custom("Manrope-Bold", size: size, relativeTo: .body) }
    static func semiBold(_ size: CGFloat) -> Font { Font.custom("Manrope-SemiBold", size: size, relativeTo: .body) }
    static func medium(_ size: CGFloat) -> Font { Font.custom("Manrope-Medium", size: size, relativeTo: .body) }
}

private enum AddCustomExerciseEquipment {
    static let presets: [String] = [
        "Barbell", "Dumbbells", "Adjustable Bench", "Cable Machine",
        "Bodyweight", "Kettlebell", "Resistance Band", "Smith Machine"
    ]

    static func parseEquipmentString(_ raw: String?) -> (presets: Set<String>, freeText: String) {
        guard let raw, !raw.isEmpty else { return ([], "") }
        let parts = raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        var presetsFound = Set<String>()
        var other: [String] = []
        for p in parts {
            if Self.presets.contains(p) {
                presetsFound.insert(p)
            } else {
                other.append(p)
            }
        }
        return (presetsFound, other.joined(separator: ", "))
    }

    static func composeEquipment(presets: Set<String>, freeText: String) -> String? {
        var parts = presets.sorted()
        let trimmed = freeText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { parts.append(trimmed) }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: ", ")
    }
}

struct AddCustomExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.kineticPalette) private var kp

    @State private var exerciseName: String
    @State private var selectedPrimaryMuscles: Set<MuscleGroup>
    @State private var selectedSecondaryMuscles: Set<MuscleGroup>
    @State private var alternatives: [String]
    @State private var newAlternative: String
    @State private var videoURL: String
    @State private var performanceCues: String
    @State private var selectedCategory: ExerciseCategory
    @State private var selectedEquipmentPresets: Set<String>
    @State private var equipmentFreeText: String
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var videoURLValidated: Bool?

    private let sourceExercise: CustomExercise?
    let onSave: (CustomExercise) -> Void
    let isEditing: Bool

    init(exercise: CustomExercise? = nil, onSave: @escaping (CustomExercise) -> Void) {
        self.sourceExercise = exercise
        if let exercise {
            _exerciseName = State(initialValue: exercise.name)
            _selectedPrimaryMuscles = State(initialValue: Set(exercise.primaryMuscleGroups.compactMap { MuscleGroup(rawValue: $0) }))
            _selectedSecondaryMuscles = State(initialValue: Set(exercise.secondaryMuscleGroups.compactMap { MuscleGroup(rawValue: $0) }))
            _alternatives = State(initialValue: exercise.alternatives)
            _newAlternative = State(initialValue: "")
            _videoURL = State(initialValue: exercise.videoURL ?? "")
            _performanceCues = State(initialValue: exercise.performanceCues ?? "")
            _selectedCategory = State(initialValue: ExerciseCategory(rawValue: exercise.category) ?? .other)
            let parsed = AddCustomExerciseEquipment.parseEquipmentString(exercise.equipment)
            _selectedEquipmentPresets = State(initialValue: parsed.presets)
            _equipmentFreeText = State(initialValue: parsed.freeText)
            self.isEditing = true
        } else {
            _exerciseName = State(initialValue: "")
            _selectedPrimaryMuscles = State(initialValue: [])
            _selectedSecondaryMuscles = State(initialValue: [])
            _alternatives = State(initialValue: [])
            _newAlternative = State(initialValue: "")
            _videoURL = State(initialValue: "")
            _performanceCues = State(initialValue: "")
            _selectedCategory = State(initialValue: .other)
            _selectedEquipmentPresets = State(initialValue: [])
            _equipmentFreeText = State(initialValue: "")
            self.isEditing = false
        }
        _videoURLValidated = State(initialValue: nil)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.sectionGapXL) {
                    heroHeader
                    coreIdentitySection
                    technicalSpecsSection
                    mediaAndCuesSection
                    alternativesSection
                    actionArea
                }
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AppSpacing.contentPadLG)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(kp.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(AddCustomExerciseFonts.semiBold(14))
                        .foregroundStyle(kp.tertiary)
                }
            }
            .toolbarBackground(kp.background.opacity(0.92), for: .navigationBar)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Hero (wireframe — no global app header)

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isEditing ? "Refine Definition" : "New Definition")
                .font(AddCustomExerciseFonts.bold(11))
                .textCase(.uppercase)
                .tracking(2.2)
                .foregroundStyle(kp.primary)

            Text(isEditing ? "Edit Custom Exercise" : "Add Custom Exercise")
                .font(AddCustomExerciseFonts.extraBold(34))
                .foregroundStyle(kp.onSurface)
                .kineticDisplayTracking(for: 34)
                .fixedSize(horizontal: false, vertical: true)

            Text("Engineer your own movement patterns. Define specific parameters for precision tracking in your atelier.")
                .font(AddCustomExerciseFonts.medium(14))
                .foregroundStyle(kp.tertiary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 4)
    }

    // MARK: - Section 1: Core identity

    private var coreIdentitySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing8) {
            kineticFieldLabel("Exercise Name")

            TextField("e.g., Incline Spoto Press", text: $exerciseName)
                .font(AddCustomExerciseFonts.medium(17))
                .foregroundStyle(kp.onSurface)
                .padding(20)
                .background(kp.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusLG, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusLG, style: .continuous)
                        .stroke(Color.clear, lineWidth: 1)
                )

            Group {
                if horizontalSizeClass == .regular {
                    HStack(alignment: .top, spacing: 24) {
                        primaryMuscleBlock.frame(maxWidth: .infinity, alignment: .leading)
                        categoryBlock.frame(width: 200, alignment: .leading)
                    }
                } else {
                    VStack(alignment: .leading, spacing: AppSpacing.spacing8) {
                        primaryMuscleBlock
                        categoryBlock
                    }
                }
            }
        }
    }

    private var primaryMuscleBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            kineticFieldLabel("Primary Muscle Group")
            Text("Select at least one")
                .font(AddCustomExerciseFonts.medium(11))
                .foregroundStyle(kp.onSurfaceVariant.opacity(0.75))

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 88), spacing: 8)],
                alignment: .leading,
                spacing: 8
            ) {
                ForEach(MuscleGroup.allCases) { muscle in
                    primaryMuscleChip(muscle)
                }
            }
            .padding(8)
            .background(kp.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusLG, style: .continuous))
        }
    }

    private func primaryMuscleChip(_ muscle: MuscleGroup) -> some View {
        let selected = selectedPrimaryMuscles.contains(muscle)
        return Button {
            if selected {
                selectedPrimaryMuscles.remove(muscle)
            } else {
                selectedPrimaryMuscles.insert(muscle)
                selectedSecondaryMuscles.remove(muscle)
            }
        } label: {
            Text(muscle.rawValue)
                .font(AddCustomExerciseFonts.bold(12))
                .foregroundStyle(selected ? kp.onPrimaryContainer : kp.tertiary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(selected ? kp.primaryContainer : kp.surfaceContainerHighest)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var categoryBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            kineticFieldLabel("Category")

            Menu {
                ForEach(ExerciseCategory.allCases) { cat in
                    Button(cat.rawValue) { selectedCategory = cat }
                }
            } label: {
                HStack {
                    Text(selectedCategory.rawValue)
                        .font(AddCustomExerciseFonts.medium(16))
                        .foregroundStyle(kp.onSurface)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(kp.outline)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(kp.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusLG, style: .continuous))
            }
        }
    }

    // MARK: - Section 2: Bento — secondary + equipment

    private var technicalSpecsSection: some View {
        VStack(spacing: AppSpacing.spacing8) {
            secondaryFocusCard
            equipmentCard
        }
    }

    private var secondaryFocusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Secondary Focus")
                .font(AddCustomExerciseFonts.bold(10))
                .textCase(.uppercase)
                .tracking(1.8)
                .foregroundStyle(kp.secondary)

            HStack(alignment: .top, spacing: 10) {
                KineticChipPillStrip(
                    items: Array(selectedSecondaryMuscles).sorted { $0.rawValue < $1.rawValue }.map(\.rawValue),
                    kp: kp,
                    onRemove: { raw in
                        if let m = MuscleGroup(rawValue: raw) { selectedSecondaryMuscles.remove(m) }
                    }
                )

                secondaryAddMenu
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(kp.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMD, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(kp.secondary.opacity(0.35))
                .frame(width: 4)
                .padding(.vertical, 12)
        }
    }

    private var secondaryAddMenu: some View {
        Menu {
            ForEach(availableSecondaryMuscles, id: \.self) { muscle in
                Button(muscle.rawValue) {
                    selectedSecondaryMuscles.insert(muscle)
                }
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(kp.primary)
                .frame(width: 36, height: 36)
                .background(kp.primary.opacity(0.12))
                .clipShape(Circle())
        }
        .disabled(availableSecondaryMuscles.isEmpty)
        .opacity(availableSecondaryMuscles.isEmpty ? 0.4 : 1)
    }

    private var availableSecondaryMuscles: [MuscleGroup] {
        MuscleGroup.allCases.filter { !selectedPrimaryMuscles.contains($0) && !selectedSecondaryMuscles.contains($0) }
    }

    private var equipmentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Required Equipment")
                .font(AddCustomExerciseFonts.bold(10))
                .textCase(.uppercase)
                .tracking(1.8)
                .foregroundStyle(kp.tertiary)

            VStack(spacing: 12) {
                ForEach(AddCustomExerciseEquipment.presets, id: \.self) { item in
                    equipmentRow(title: item, systemImage: iconForEquipment(item), selected: selectedEquipmentPresets.contains(item)) {
                        if selectedEquipmentPresets.contains(item) {
                            selectedEquipmentPresets.remove(item)
                        } else {
                            selectedEquipmentPresets.insert(item)
                        }
                    }
                }
            }

            TextField("Other equipment (optional)", text: $equipmentFreeText)
                .font(AddCustomExerciseFonts.medium(14))
                .foregroundStyle(kp.onSurface)
                .padding(14)
                .background(kp.surfaceContainerLowest.opacity(colorScheme == .dark ? 1 : 0.85))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(kp.outlineVariant.opacity(0.12), lineWidth: 1)
                )
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(kp.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMD, style: .continuous))
    }

    private func iconForEquipment(_ title: String) -> String {
        switch title {
        case "Barbell": return "figure.strengthtraining.traditional"
        case "Dumbbells": return "dumbbell.fill"
        case "Adjustable Bench": return "bed.double.fill"
        case "Cable Machine": return "link"
        case "Bodyweight": return "figure.walk"
        case "Kettlebell": return "circle.fill"
        case "Resistance Band": return "bandage.fill"
        case "Smith Machine": return "line.horizontal.3"
        default: return "cube.fill"
        }
    }

    private func equipmentRow(title: String, systemImage: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(selected ? kp.primary : kp.tertiary)
                    .frame(width: 28, alignment: .center)

                Text(title)
                    .font(AddCustomExerciseFonts.semiBold(14))
                    .foregroundStyle(kp.onSurface)

                Spacer(minLength: 0)

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(selected ? kp.primary : kp.tertiary.opacity(0.55))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(kp.surfaceContainerLowest.opacity(selected ? 1 : (colorScheme == .dark ? 0.5 : 0.35)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(kp.outlineVariant.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section 3: Media & cues

    private var mediaAndCuesSection: some View {
        VStack(spacing: AppSpacing.spacing8) {
            referenceVideoCard
            performanceCuesCard
        }
    }

    private var referenceVideoCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reference Video")
                        .font(AddCustomExerciseFonts.bold(14))
                        .foregroundStyle(kp.onSurface)
                    Text("Paste a link to technical execution")
                        .font(AddCustomExerciseFonts.medium(12))
                        .foregroundStyle(kp.tertiary)
                }
                Spacer(minLength: 8)
                Image(systemName: "video.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(kp.primary)
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(kp.surfaceContainerHighest)

            VStack(alignment: .leading, spacing: 12) {
                ZStack(alignment: .trailing) {
                    TextField("https://youtube.com/v/...", text: $videoURL)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(kp.secondary)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .padding(.trailing, 88)
                        .background(kp.background)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMD, style: .continuous))

                    Button(action: validateVideoURL) {
                        Text("Validate")
                            .font(AddCustomExerciseFonts.bold(10))
                            .textCase(.uppercase)
                            .tracking(1.2)
                            .foregroundStyle(kp.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(kp.primary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .padding(.trailing, 10)
                }

                if let videoURLValidated {
                    HStack(spacing: 6) {
                        Image(systemName: videoURLValidated ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(videoURLValidated ? kp.primary : Color.red.opacity(0.85))
                        Text(videoURLValidated ? "Link looks valid" : "Enter a valid http(s) URL")
                            .font(AddCustomExerciseFonts.medium(12))
                            .foregroundStyle(kp.onSurfaceVariant)
                    }
                }
            }
            .padding(18)
        }
        .background(kp.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardRadiusXL, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardRadiusXL, style: .continuous)
                .stroke(kp.outlineVariant.opacity(0.08), lineWidth: 1)
        )
    }

    private var performanceCuesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            kineticFieldLabel("Performance Cues")

            ZStack(alignment: .topLeading) {
                TextEditor(text: $performanceCues)
                    .font(AddCustomExerciseFonts.medium(14))
                    .foregroundStyle(kp.onSurface)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100, alignment: .topLeading)
                    .padding(.top, 4)

                if performanceCues.isEmpty {
                    Text("e.g., Maintain 3-second eccentric phase. Keep elbows tucked 45 degrees.")
                        .font(AddCustomExerciseFonts.medium(14))
                        .foregroundStyle(kp.outlineVariant.opacity(0.55))
                        .allowsHitTesting(false)
                        .padding(.top, 12)
                        .padding(.leading, 4)
                }
            }
        }
        .padding(22)
        .background(kp.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardRadiusXL, style: .continuous))
    }

    // MARK: - Alternatives

    private var alternativesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Alternative movements")
                .font(AddCustomExerciseFonts.bold(10))
                .textCase(.uppercase)
                .tracking(1.8)
                .foregroundStyle(kp.primary)

            HStack(spacing: 12) {
                TextField("Add alternative", text: $newAlternative)
                    .font(AddCustomExerciseFonts.medium(15))
                    .foregroundStyle(kp.onSurface)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(kp.surfaceContainerLowest.opacity(colorScheme == .dark ? 0.55 : 0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(kp.outlineVariant.opacity(0.12), lineWidth: 1)
                    )

                Button {
                    let t = newAlternative.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !t.isEmpty else { return }
                    alternatives.append(t)
                    newAlternative = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(kp.primary)
                }
                .disabled(newAlternative.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if !alternatives.isEmpty {
                KineticChipPillStrip(
                    items: alternatives,
                    kp: kp,
                    onRemove: { alt in alternatives.removeAll { $0 == alt } }
                )
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            kp.surfaceContainerHigh.opacity(0.65)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMD, style: .continuous))
    }

    // MARK: - Actions

    private var actionArea: some View {
        VStack(spacing: 14) {
            Button(action: saveExercise) {
                Text("Save Exercise")
                    .font(AddCustomExerciseFonts.bold(13))
                    .textCase(.uppercase)
                    .tracking(2.4)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(saveGradient)
                    .clipShape(Capsule())
                    .shadow(color: kp.primaryContainer.opacity(0.28), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(!isValid)
            .opacity(isValid ? 1 : 0.45)

            Button("Discard Draft") {
                dismiss()
            }
            .font(AddCustomExerciseFonts.bold(12))
            .textCase(.uppercase)
            .tracking(2)
            .foregroundStyle(kp.tertiary)
        }
        .padding(.top, 8)
    }

    private var saveGradient: LinearGradient {
        if colorScheme == .light {
            LinearGradient(
                colors: [kp.primary, kp.secondary],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            LinearGradient(
                colors: [kp.primaryContainer, kp.secondaryContainer],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    private func kineticFieldLabel(_ title: String) -> some View {
        Text(title)
            .font(AddCustomExerciseFonts.bold(10))
            .textCase(.uppercase)
            .tracking(2)
            .foregroundStyle(kp.primary)
    }

    private var isValid: Bool {
        !exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedPrimaryMuscles.isEmpty
    }

    private func validateVideoURL() {
        let trimmed = videoURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            videoURLValidated = false
            return
        }
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            videoURLValidated = false
            return
        }
        videoURLValidated = true
    }

    private func saveExercise() {
        let name = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            errorMessage = "Exercise name is required"
            showError = true
            return
        }

        guard !selectedPrimaryMuscles.isEmpty else {
            errorMessage = "At least one primary muscle group is required"
            showError = true
            return
        }

        if !isEditing {
            if ExerciseDataManager.shared.getCustomExercise(name: name) != nil {
                errorMessage = "An exercise with this name already exists"
                showError = true
                return
            }
        } else if let source = sourceExercise, let conflict = ExerciseDataManager.shared.getCustomExercise(name: name),
                  conflict.id != source.id {
            errorMessage = "An exercise with this name already exists"
            showError = true
            return
        }

        let equipmentString = AddCustomExerciseEquipment.composeEquipment(
            presets: selectedEquipmentPresets,
            freeText: equipmentFreeText
        )
        let cues = performanceCues.trimmingCharacters(in: .whitespacesAndNewlines)
        let video = videoURL.trimmingCharacters(in: .whitespacesAndNewlines)

        let exercise: CustomExercise
        if isEditing, let existing = sourceExercise {
            exercise = CustomExercise(
                id: existing.id,
                name: name,
                primaryMuscleGroups: selectedPrimaryMuscles.map { $0.rawValue },
                secondaryMuscleGroups: selectedSecondaryMuscles.map { $0.rawValue },
                alternatives: alternatives,
                videoURL: video.isEmpty ? nil : video,
                category: selectedCategory.rawValue,
                equipment: equipmentString,
                performanceCues: cues.isEmpty ? nil : cues,
                dateCreated: existing.dateCreated
            )
        } else {
            exercise = CustomExercise(
                name: name,
                primaryMuscleGroups: selectedPrimaryMuscles.map { $0.rawValue },
                secondaryMuscleGroups: selectedSecondaryMuscles.map { $0.rawValue },
                alternatives: alternatives,
                videoURL: video.isEmpty ? nil : video,
                category: selectedCategory.rawValue,
                equipment: equipmentString,
                performanceCues: cues.isEmpty ? nil : cues
            )
        }

        onSave(exercise)
        dismiss()
    }
}

// MARK: - Pill strip (secondary muscles + alternatives)

private struct KineticChipPillStrip: View {
    let items: [String]
    let kp: KineticAdaptivePalette
    let onRemove: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(rows().enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { item in
                        HStack(spacing: 8) {
                            Text(item)
                                .font(AddCustomExerciseFonts.medium(12))
                                .foregroundStyle(kp.onSurface)
                            Button {
                                onRemove(item)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(kp.tertiary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(kp.background.opacity(0.45))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(kp.outlineVariant.opacity(0.12), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private func rows() -> [[String]] {
        guard !items.isEmpty else { return [] }
        var result: [[String]] = []
        var i = 0
        let perRow = 2
        while i < items.count {
            let end = min(i + perRow, items.count)
            result.append(Array(items[i..<end]))
            i = end
        }
        return result
    }
}
