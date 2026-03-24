import SwiftUI

// MARK: - Generate sheet (Kinetic Atelier)

private enum WorkoutGenFonts {
    static func extraBold(_ size: CGFloat) -> Font { Font.custom("Manrope-ExtraBold", size: size, relativeTo: .body) }
    static func bold(_ size: CGFloat) -> Font { Font.custom("Manrope-Bold", size: size, relativeTo: .body) }
    static func semiBold(_ size: CGFloat) -> Font { Font.custom("Manrope-SemiBold", size: size, relativeTo: .body) }
    static func medium(_ size: CGFloat) -> Font { Font.custom("Manrope-Medium", size: size, relativeTo: .body) }
}

struct WorkoutGenerationView: View {
    @ObservedObject var viewModel: TemplatesViewModel
    let onStart: () -> Void
    /// Dismisses the generate sheet, then parent can present full settings (optional).
    var onRequestFullSettings: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.kineticPalette) private var kp
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @AppStorage(AppConstants.UserDefaultsKeys.lastGeneratedTemplateLabel) private var lastGeneratedLabel: String = ""

    @State private var selectedWorkoutType: WorkoutType = .fullBody
    @State private var showSuccessAlert = false
    @State private var generatedWorkoutName = ""
    /// 0 → 1 variation, 1 → 3, 2 → 5 (quick batch & slider).
    @State private var variationBatchIndex: Double = 1

    init(
        viewModel: TemplatesViewModel,
        onStart: @escaping () -> Void,
        onRequestFullSettings: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onStart = onStart
        self.onRequestFullSettings = onRequestFullSettings
    }

    enum WorkoutType: String, CaseIterable {
        case custom = "Custom"
        case push = "Push Day"
        case pull = "Pull Day"
        case legs = "Leg Day"
        case upper = "Upper Day"
        case lower = "Lower Day"
        case fullBody = "Full Body"

        var icon: String {
            switch self {
            case .custom: return "square.grid.3x3.fill"
            case .push: return "arrow.up.circle.fill"
            case .pull: return "arrow.down.circle.fill"
            case .legs: return "figure.walk"
            case .upper: return "dumbbell.fill"
            case .lower: return "arrow.down.to.line.compact"
            case .fullBody: return "figure.strengthtraining.traditional"
            }
        }

        var architectureSubtitle: String {
            switch self {
            case .custom: return "Manual Input"
            case .push: return "Anterior Focus"
            case .pull: return "Posterior Chain"
            case .legs: return "Lower Core"
            case .upper: return "Torso Split"
            case .lower: return "Lower Torso"
            case .fullBody: return "Total Kinetic"
            }
        }

        var architectureTitle: String {
            switch self {
            case .custom: return "CUSTOM"
            case .push: return "PUSH"
            case .pull: return "PULL"
            case .legs: return "LEGS"
            case .upper: return "UPPER"
            case .lower: return "LOWER"
            case .fullBody: return "FULL BODY"
            }
        }
    }

    private var currentPhase: TrainingPhase {
        viewModel.generationSettings.resolvedTrainingPhase
    }

    private var variationBatchValues: [Int] { [1, 3, 5] }
    private var selectedBatchCount: Int {
        variationBatchValues[max(0, min(variationBatchValues.count - 1, Int(variationBatchIndex.rounded())))]
    }

    private var architectureColumns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    private var appVersionLabel: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return b.isEmpty ? v : "\(v) (\(b))"
    }

    var body: some View {
        ZStack {
            kp.background.ignoresSafeArea()

            VStack(spacing: 0) {
                kineticHeader

                ScrollView {
                    VStack(spacing: 32) {
                        metadataBadges

                        architectureSection

                        trainingIntentSection

                        variationBatchingSection

                        PhasePreviewCard(phase: currentPhase, settings: viewModel.generationSettings)

                        KineticCoreRulesSection()

                        generateCTA

                        quickBatchRow

                        if onRequestFullSettings != nil {
                            Button {
                                HapticManager.impact(style: .light)
                                onRequestFullSettings?()
                            } label: {
                                Text("Fine-tune protocol & equipment")
                                    .font(WorkoutGenFonts.semiBold(13))
                                    .foregroundStyle(kp.primary)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)

                kineticFooter
            }
        }
        .alert("Workout Generated", isPresented: $showSuccessAlert) {
            Button("OK") { showSuccessAlert = false }
        } message: {
            Text("Successfully generated: \(generatedWorkoutName)")
        }
        .kineticDynamicTypeClamp()
    }

    // MARK: - Header

    private var kineticHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Engineered Logic")
                    .font(WorkoutGenFonts.bold(10))
                    .tracking(2)
                    .foregroundStyle(kp.primary)
                Text("Workout Generation")
                    .font(WorkoutGenFonts.extraBold(20))
                    .tracking(-0.5)
                    .foregroundStyle(kp.onSurface)
                    .textCase(.uppercase)
            }
            Spacer()
            Button {
                HapticManager.impact(style: .light)
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(kp.onSurfaceVariant)
                    .frame(width: 40, height: 40)
                    .background(kp.surfaceContainerHighest)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 24)
        .frame(height: 72)
        .background(kp.surfaceContainerLow.opacity(0.85))
    }

    // MARK: - Metadata

    private var metadataBadges: some View {
        HStack(spacing: 12) {
            metadataChip(icon: "gearshape.2", title: "Ascend Gen", subtitle: appVersionLabel)
            metadataChip(icon: "clock.arrow.circlepath", title: "Last", subtitle: lastGeneratedLabel.isEmpty ? "—" : lastGeneratedLabel)
        }
        .padding(.top, 8)
    }

    private func metadataChip(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(kp.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(WorkoutGenFonts.bold(9))
                    .tracking(1.2)
                    .foregroundStyle(kp.tertiary)
                Text(subtitle)
                    .font(WorkoutGenFonts.semiBold(12))
                    .foregroundStyle(kp.onSurfaceVariant)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(kp.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(kp.outlineVariant.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Architecture grid

    private var architectureSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                Text("Select Architecture")
                    .font(WorkoutGenFonts.bold(12))
                    .tracking(3)
                    .foregroundStyle(kp.onSurfaceVariant)
                    .textCase(.uppercase)
                Spacer()
                Text("Required")
                    .font(WorkoutGenFonts.bold(10))
                    .foregroundStyle(kp.primary)
            }

            LazyVGrid(columns: architectureColumns, spacing: 12) {
                ForEach(WorkoutType.allCases, id: \.self) { type in
                    KineticArchitectureCard(
                        type: type,
                        isSelected: selectedWorkoutType == type,
                        palette: kp
                    ) {
                        HapticManager.impact(style: .light)
                        selectedWorkoutType = type
                    }
                }
            }
        }
    }

    // MARK: - Training intent

    private var trainingIntentSection: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 24) {
                trainingPillColumn(
                    title: "Training Intent",
                    options: TrainingType.allCases,
                    selection: $viewModel.generationSettings.trainingType,
                    label: { $0.rawValue.uppercased() },
                    isPrimary: true
                ) {
                    viewModel.generationSettings.applyPhasePreset()
                }
                trainingPillColumn(
                    title: "Caloric Logic",
                    options: TrainingGoal.allCases,
                    selection: $viewModel.generationSettings.trainingGoal,
                    label: { $0.rawValue.uppercased() },
                    isPrimary: false
                ) {
                    viewModel.generationSettings.applyPhasePreset()
                }
            }
        }
    }

    private func trainingPillColumn<T: Hashable>(
        title: String,
        options: [T],
        selection: Binding<T>,
        label: @escaping (T) -> String,
        isPrimary: Bool,
        onChange: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(WorkoutGenFonts.bold(12))
                .tracking(3)
                .foregroundStyle(kp.onSurfaceVariant)
                .textCase(.uppercase)

            HStack(spacing: 0) {
                ForEach(options, id: \.self) { option in
                    let isOn = selection.wrappedValue == option
                    Button {
                        HapticManager.impact(style: .light)
                        selection.wrappedValue = option
                        onChange()
                    } label: {
                        Text(label(option))
                            .font(WorkoutGenFonts.bold(11))
                            .tracking(2)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(
                                isOn
                                    ? (isPrimary ? kp.onPrimary : Color(hex: "0c344a"))
                                    : kp.onSurfaceVariant
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                Group {
                                    if isOn {
                                        if isPrimary {
                                            kp.primary
                                        } else {
                                            kp.secondary
                                        }
                                    } else {
                                        Color.clear
                                    }
                                }
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(kp.surfaceContainerLow)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(kp.outlineVariant.opacity(0.12), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Variation batching

    private var variationBatchingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Variation Batching")
                    .font(WorkoutGenFonts.bold(12))
                    .tracking(3)
                    .foregroundStyle(kp.onSurfaceVariant)
                    .textCase(.uppercase)
                Spacer()
                Text("\(selectedBatchCount)×")
                    .font(WorkoutGenFonts.extraBold(28))
                    .foregroundStyle(kp.primary)
            }

            Slider(value: $variationBatchIndex, in: 0 ... Double(variationBatchValues.count - 1), step: 1)
                .tint(kp.primary)

            HStack {
                Text("Single Concept")
                Spacer()
                Text("Standard Set")
                Spacer()
                Text("High Variance")
            }
            .font(WorkoutGenFonts.bold(9))
            .tracking(0.5)
            .foregroundStyle(kp.tertiary)
            .textCase(.uppercase)
        }
    }

    // MARK: - Primary CTA

    private var generateCTA: some View {
        Button {
            HapticManager.impact(style: .medium)
            generateAndSaveWorkout()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .bold))
                Text("Generate Workout Architecture")
                    .font(WorkoutGenFonts.bold(14))
                    .tracking(2)
            }
            .foregroundStyle(kp.onPrimaryContainer)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(
                LinearGradient(
                    colors: [kp.primaryContainer, kp.primary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: kp.primary.opacity(0.25), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Generate workout architecture")
    }

    private var quickBatchRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Draft")
                .font(WorkoutGenFonts.bold(10))
                .tracking(2)
                .foregroundStyle(kp.onSurfaceVariant)
                .textCase(.uppercase)

            HStack(spacing: 10) {
                ForEach(Array(variationBatchValues.enumerated()), id: \.offset) { idx, count in
                    let isSelected = Int(variationBatchIndex.rounded()) == idx
                    Button {
                        HapticManager.impact(style: .light)
                        variationBatchIndex = Double(idx)
                        generateMultipleWorkouts(count: count)
                    } label: {
                        VStack(spacing: 4) {
                            Text("V\(count)")
                                .font(WorkoutGenFonts.extraBold(16))
                                .foregroundStyle(isSelected ? kp.primary : kp.onSurfaceVariant)
                            Text(batchSubtitle(for: count))
                                .font(WorkoutGenFonts.bold(9))
                                .tracking(1.5)
                                .foregroundStyle(kp.onSurfaceVariant)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(kp.surfaceContainerHigh)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(isSelected ? kp.primary.opacity(0.45) : kp.outlineVariant.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func batchSubtitle(for count: Int) -> String {
        switch count {
        case 1: return "Quick Draft"
        case 3: return "Standard"
        default: return "Deep Suite"
        }
    }

    private var kineticFooter: some View {
        VStack(spacing: 0) {
            Divider()
                .background(kp.outlineVariant.opacity(0.2))
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: "34d399"))
                        .frame(width: 8, height: 8)
                        .shadow(color: Color(hex: "34d399").opacity(0.5), radius: 4)
                    Text("System Ready · Protocol \(appVersionLabel)")
                        .font(WorkoutGenFonts.bold(10))
                        .tracking(2)
                        .foregroundStyle(kp.tertiary)
                }
                Spacer()
                Text("Kinetic Atelier")
                    .font(WorkoutGenFonts.medium(10))
                    .italic()
                    .foregroundStyle(kp.onSurfaceVariant.opacity(0.45))
            }
            .padding(20)
            .background(kp.surfaceContainerLow)
        }
    }

    // MARK: - Generation

    private func recordLastGenerated(name: String) {
        lastGeneratedLabel = name
    }

    private func generateAndSaveWorkout() {
        let workout: WorkoutTemplate

        switch selectedWorkoutType {
        case .custom:
            workout = viewModel.generateWorkout()
        case .push:
            workout = viewModel.generatePushWorkout()
        case .pull:
            workout = viewModel.generatePullWorkout()
        case .legs:
            workout = viewModel.generateLegWorkout()
        case .upper:
            workout = viewModel.generateUpperWorkout()
        case .lower:
            workout = viewModel.generateLowerWorkout()
        case .fullBody:
            workout = viewModel.generateFullBodyWorkout()
        }

        viewModel.saveTemplate(workout)
        generatedWorkoutName = workout.name
        recordLastGenerated(name: workout.name)
        showSuccessAlert = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }

    private func generateMultipleWorkouts(count: Int) {
        let workouts = viewModel.generateWorkoutVariations(count: count)
        for workout in workouts {
            viewModel.saveTemplate(workout)
        }
        if let last = workouts.last {
            recordLastGenerated(name: last.name)
        }
        generatedWorkoutName = "\(count) workout\(count > 1 ? "s" : "")"
        showSuccessAlert = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

// MARK: - Architecture card

private struct KineticArchitectureCard: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let type: WorkoutGenerationView.WorkoutType
    let isSelected: Bool
    let palette: KineticAdaptivePalette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer(minLength: 0)
                    Image(systemName: type.icon)
                        .font(.system(size: 26))
                        .foregroundStyle(type == .custom ? palette.onSurfaceVariant : palette.primary)
                    Spacer(minLength: 8)
                    Text(type.architectureSubtitle)
                        .font(WorkoutGenFonts.medium(10))
                        .foregroundStyle(palette.onSurfaceVariant)
                        .textCase(.uppercase)
                        .lineLimit(1)
                    Text(type.architectureTitle)
                        .font(WorkoutGenFonts.extraBold(18))
                        .foregroundStyle(palette.onSurface)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: horizontalSizeClass == .regular ? 120 : 112)
                .padding(18)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(borderColor, lineWidth: type == .custom && !isSelected ? 1.5 : 1)
                )
                .shadow(color: palette.onSurface.opacity(0.04), radius: 6, x: 0, y: 3)

                if isSelected {
                    Circle()
                        .fill(palette.primary)
                        .frame(width: 8, height: 8)
                        .shadow(color: palette.primary.opacity(0.55), radius: 6)
                        .padding(12)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityLabel("\(type.architectureTitle) architecture")
    }

    private var cardBackground: some View {
        Group {
            if type == .custom {
                palette.surfaceContainerLow
            } else if isSelected {
                LinearGradient(
                    colors: [palette.primaryContainer.opacity(0.35), palette.surfaceContainerHighest],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
            } else {
                palette.surfaceContainerHighest
            }
        }
    }

    private var borderColor: Color {
        if type == .custom {
            return isSelected ? palette.primary.opacity(0.55) : palette.outlineVariant.opacity(0.35)
        }
        return isSelected ? palette.primary.opacity(0.55) : palette.outlineVariant.opacity(0.12)
    }
}

// MARK: - Core rules (Kinetic)

private struct KineticCoreRulesSection: View {
    @Environment(\.kineticPalette) private var kp

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Text("Full-Body")
                    .font(WorkoutGenFonts.bold(16))
                    .foregroundStyle(kp.primary)
                Text("— Core Rules")
                    .font(WorkoutGenFonts.bold(16))
                    .foregroundStyle(kp.onSurface)
            }

            VStack(alignment: .leading, spacing: 10) {
                KineticRuleRow(icon: "calendar", text: "Train 3–4× per week")
                KineticRuleRow(icon: "target", text: "Hit every major muscle each session")
                KineticRuleRow(icon: "arrow.triangle.2.circlepath", text: "Fewer exercises per muscle per workout, higher weekly frequency")
            }
            .padding(14)
            .background(kp.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(16)
        .background(kp.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(kp.outlineVariant.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct KineticRuleRow: View {
    @Environment(\.kineticPalette) private var kp
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(kp.primary)
                .frame(width: 20, alignment: .center)
            Text(text)
                .font(WorkoutGenFonts.medium(13))
                .foregroundStyle(kp.onSurface)
        }
    }
}

// MARK: - Phase Preview Card

struct PhasePreviewCard: View {
    @Environment(\.kineticPalette) private var kp

    let phase: TrainingPhase
    let settings: WorkoutGenerationSettings

    private var phaseColor: LinearGradient {
        switch phase {
        case .bulking:
            return LinearGradient(
                colors: [Color(hex: "16a34a"), Color(hex: "10b981")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .cutting:
            return LinearGradient(
                colors: [Color(hex: "ea580c"), Color(hex: "f59e0b")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .endurance:
            return LinearGradient(
                colors: [Color(hex: "0891b2"), Color(hex: "0ea5e9")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var totalExerciseCount: String {
        switch phase {
        case .bulking: return "5–7"
        case .cutting: return "4–6"
        case .endurance: return "4–6"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Protocol Preview")
                .font(WorkoutGenFonts.bold(12))
                .tracking(3)
                .foregroundStyle(kp.onSurfaceVariant)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 10) {
                Text(phase.rawValue.uppercased())
                    .font(WorkoutGenFonts.extraBold(18))
                    .foregroundStyle(phaseColor)

                VStack(alignment: .leading, spacing: 8) {
                    PhaseInfoRow(label: "Goal", value: phaseGoal)
                    PhaseInfoRow(label: "Weekly sets/muscle", value: weeklySetsRange)
                    PhaseInfoRow(label: "Exercises per workout", value: totalExerciseCount)
                    PhaseInfoRow(label: "Sets/Reps", value: setsRepsGuideline)
                }
                .padding(12)
                .background(kp.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(16)
        .background(kp.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(kp.outlineVariant.opacity(0.12), lineWidth: 1)
        )
    }

    private var phaseGoal: String {
        switch phase {
        case .bulking: return "Grow muscle"
        case .cutting: return "Maintain muscle"
        case .endurance: return "Fatigue resistance"
        }
    }

    private var weeklySetsRange: String {
        switch phase {
        case .bulking: return "12–18"
        case .cutting: return "8–12"
        case .endurance: return "8–15"
        }
    }

    private var setsRepsGuideline: String {
        switch phase {
        case .bulking: return "3–4 sets × 6–12 reps"
        case .cutting: return "2–3 sets × 5–10 reps"
        case .endurance: return "2–3 sets × 12–20 reps"
        }
    }
}

struct PhaseInfoRow: View {
    @Environment(\.kineticPalette) private var kp
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(WorkoutGenFonts.medium(12))
                .foregroundStyle(kp.onSurfaceVariant)
            Spacer()
            Text(value)
                .font(WorkoutGenFonts.semiBold(13))
                .foregroundStyle(kp.onSurface)
        }
    }
}

// MARK: - Goal Selection (shared with WorkoutGenerationSettingsView)

struct GoalSelectionSection: View {
    @Environment(\.kineticPalette) private var kp
    @Binding var trainingType: TrainingType
    @Binding var trainingGoal: TrainingGoal

    let onTypeChange: () -> Void
    let onGoalChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Select Your Goal")
                .font(WorkoutGenFonts.bold(22))
                .foregroundStyle(kp.onSurface)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Training Type")
                    .font(WorkoutGenFonts.medium(15))
                    .foregroundStyle(kp.onSurfaceVariant)

                HStack(spacing: AppSpacing.sm) {
                    ForEach(TrainingType.allCases, id: \.self) { type in
                        Button(action: {
                            HapticManager.impact(style: .light)
                            trainingType = type
                            onTypeChange()
                        }) {
                            VStack(spacing: AppSpacing.xs) {
                                Image(systemName: type == .strength ? "bolt.fill" : "flame.fill")
                                    .font(.system(size: 20))
                                Text(type.rawValue)
                                    .font(WorkoutGenFonts.medium(15))
                            }
                            .foregroundStyle(trainingType == type ? kp.onPrimary : kp.onSurface)
                            .frame(maxWidth: .infinity)
                            .padding(AppSpacing.md)
                            .background {
                                if trainingType == type {
                                    LinearGradient(
                                        colors: [kp.primaryContainer, kp.primary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                } else {
                                    kp.surfaceContainerHighest
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        trainingType == type ? Color.clear : kp.outlineVariant.opacity(0.35),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Goal")
                    .font(WorkoutGenFonts.medium(15))
                    .foregroundStyle(kp.onSurfaceVariant)

                HStack(spacing: AppSpacing.sm) {
                    ForEach(TrainingGoal.allCases, id: \.self) { goal in
                        Button(action: {
                            HapticManager.impact(style: .light)
                            trainingGoal = goal
                            onGoalChange()
                        }) {
                            VStack(spacing: AppSpacing.xs) {
                                Image(systemName: goal == .bulk ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                    .font(.system(size: 20))
                                Text(goal.rawValue)
                                    .font(WorkoutGenFonts.medium(15))
                            }
                            .foregroundStyle(trainingGoal == goal ? kp.onPrimary : kp.onSurface)
                            .frame(maxWidth: .infinity)
                            .padding(AppSpacing.md)
                            .background {
                                if trainingGoal == goal {
                                    LinearGradient(
                                        colors: [kp.primaryContainer, kp.primary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                } else {
                                    kp.surfaceContainerHighest
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        trainingGoal == goal ? Color.clear : kp.outlineVariant.opacity(0.35),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(kp.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(kp.outlineVariant.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: kp.onSurface.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}
