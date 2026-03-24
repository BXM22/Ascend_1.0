import SwiftUI

// MARK: - Generation Settings (Kinetic Atelier)

private enum GenSettingsFonts {
    static func extraBold(_ size: CGFloat) -> Font { Font.custom("Manrope-ExtraBold", size: size, relativeTo: .body) }
    static func bold(_ size: CGFloat) -> Font { Font.custom("Manrope-Bold", size: size, relativeTo: .body) }
    static func semiBold(_ size: CGFloat) -> Font { Font.custom("Manrope-SemiBold", size: size, relativeTo: .body) }
    static func medium(_ size: CGFloat) -> Font { Font.custom("Manrope-Medium", size: size, relativeTo: .body) }
    static func regular(_ size: CGFloat) -> Font { Font.custom("Manrope-Regular", size: size, relativeTo: .body) }
}

struct WorkoutGenerationSettingsView: View {
    @Binding var settings: WorkoutGenerationSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.kineticPalette) private var kp
    
    private let exerciseTotalBounds = 3...15
    private let restBounds = 30...300
    private let rirBounds = 0...5
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.sectionGapXL) {
                    headerIntro
                    
                    GenerationSettingsPhaseHero(settings: $settings)
                    
                    if horizontalSizeClass == .regular {
                        HStack(alignment: .top, spacing: AppSpacing.lg) {
                            leftColumn
                            rightColumn
                        }
                    } else {
                        VStack(alignment: .leading, spacing: AppSpacing.spacing8) {
                            leftColumn
                            rightColumn
                        }
                    }
                    
                    applyPresetCTA
                    
                    referenceDisclosure
                }
                .padding(.horizontal, AppSpacing.contentPadLG)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(kp.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("GENERATION SETTINGS")
                        .font(GenSettingsFonts.semiBold(11))
                        .tracking(1.6)
                        .foregroundStyle(kp.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(kp.primary)
                }
            }
            .toolbarBackground(kp.surface.opacity(0.78), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .kineticDynamicTypeClamp()
    }
    
    private var headerIntro: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Training guidelines")
                .font(GenSettingsFonts.regular(17))
                .foregroundStyle(kp.onSurfaceVariant)
        }
    }
    
    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing8) {
            GenerationVolumeSection(
                settings: $settings,
                exerciseTotalBounds: exerciseTotalBounds
            )
            GenerationContentLogicSection(settings: $settings)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing8) {
            GenerationEquipmentSection(settings: $settings)
            GenerationPerformanceSection(
                settings: $settings,
                restBounds: restBounds,
                rirBounds: rirBounds
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var applyPresetCTA: some View {
        VStack(spacing: AppSpacing.md) {
            Button {
                HapticManager.impact(style: .medium)
                settings.applyPhasePreset()
            } label: {
                Text("Apply recommended defaults")
                    .font(GenSettingsFonts.bold(22))
                    .foregroundStyle(kp.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        LinearGradient(
                            colors: [kp.primaryContainer, kp.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: kp.primary.opacity(0.12), radius: 24, x: 0, y: 8)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Text("Applying Kinetic Atelier generation logic")
                .font(GenSettingsFonts.regular(13))
                .foregroundStyle(kp.onSurfaceVariant)
                .tracking(0.15)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity)
        }
    }
    
    private var referenceDisclosure: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                CoreRulesSection()
                PhaseGuidelinesSection(
                    phase: settings.resolvedTrainingPhase,
                    settings: settings
                )
            }
            .padding(.top, AppSpacing.sm)
        } label: {
            Text("Phase & training reference")
                .font(GenSettingsFonts.bold(22))
                .foregroundStyle(kp.onSurface)
        }
        .tint(kp.primary)
    }
}

// MARK: - Hero

private struct GenerationSettingsPhaseHero: View {
    @Environment(\.kineticPalette) private var kp
    @Binding var settings: WorkoutGenerationSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Current phase")
                .font(GenSettingsFonts.regular(13))
                .fontWeight(.bold)
                .tracking(2)
                .foregroundStyle(kp.primary)
                .textCase(.uppercase)
            
            Text(settings.phaseDisplayTitle)
                .font(GenSettingsFonts.extraBold(36))
                .foregroundStyle(kp.onSurface)
            
            HStack(spacing: AppSpacing.sm) {
                phasePill(icon: "dial.high", text: settings.phaseFocusLabel)
                phasePill(icon: "timer", text: restSummary)
                phasePill(icon: "waveform.path.ecg", text: rirSummary)
            }
            .fixedSize(horizontal: false, vertical: true)
            
            GoalSelectionSection(
                trainingType: $settings.trainingType,
                trainingGoal: $settings.trainingGoal,
                onTypeChange: {
                    HapticManager.impact(style: .light)
                    settings.applyPhasePreset()
                },
                onGoalChange: {
                    HapticManager.impact(style: .light)
                    settings.applyPhasePreset()
                }
            )
            .padding(.top, AppSpacing.sm)
        }
        .padding(AppSpacing.cardPadding)
        .background(
            LinearGradient(
                colors: [kp.secondaryContainer.opacity(0.45), kp.surfaceContainerHighest.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusXL, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: AppSpacing.radiusXL, style: .continuous)
                .fill(kp.primary)
                .frame(width: 4)
        }
        .overlay(alignment: .topTrailing) {
            Image(systemName: "square.grid.3x3.topleft.filled")
                .font(.system(size: 72))
                .foregroundStyle(kp.primary.opacity(0.08))
                .padding()
        }
    }
    
    private var restSummary: String {
        let a = settings.restTimeMin
        let b = settings.restTimeMax
        if a == b { return "\(a)s" + " Rest" }
        return "\(a)s–\(b)s" + " Rest"
    }
    
    private var rirSummary: String {
        "\(settings.rirMin)–\(settings.rirMax)" + " RIR"
    }
    
    private func phasePill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(kp.primary)
            Text(text)
                .font(GenSettingsFonts.regular(13))
                .foregroundStyle(kp.onSurfaceVariant)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(kp.surfaceContainerHigh.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMD, style: .continuous))
    }
}

// MARK: - Volume

private struct GenerationVolumeSection: View {
    @Environment(\.kineticPalette) private var kp
    @Binding var settings: WorkoutGenerationSettings
    let exerciseTotalBounds: ClosedRange<Int>
    
    private var averageMuscle: Int {
        let vals = settings.exercisesPerMuscleGroup.values.filter { $0 > 0 }
        guard !vals.isEmpty else { return 2 }
        return vals.reduce(0, +) / vals.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Volume tuning")
                    .font(GenSettingsFonts.bold(26))
                    .foregroundStyle(kp.onSurface)
                Spacer()
                Image(systemName: "chart.bar.xaxis")
                    .foregroundStyle(kp.onSurfaceVariant)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                volumeRow(
                    title: "Total exercises",
                    value: "\(settings.minExercises) — \(settings.maxExercises)"
                ) {
                    ExerciseCountRangeBar(
                        min: settings.minExercises,
                        max: settings.maxExercises,
                        in: exerciseTotalBounds
                    )
                }
                dualIntSliders(
                    low: $settings.minExercises,
                    high: $settings.maxExercises,
                    range: exerciseTotalBounds,
                    onChange: {
                        if settings.minExercises > settings.maxExercises {
                            settings.maxExercises = settings.minExercises
                        }
                        HapticManager.selection()
                    }
                )
                
                volumeRow(
                    title: "Exercises per muscle",
                    value: "\(averageMuscle) (uniform target)"
                ) {
                    ExerciseCountRangeBar(
                        min: averageMuscle,
                        max: averageMuscle,
                        in: 1...4
                    )
                }
                Slider(
                    value: Binding(
                        get: { Double(averageMuscle) },
                        set: { new in
                            HapticManager.selection()
                            settings.setUniformMuscleExerciseCount(Int(new.rounded()))
                        }
                    ),
                    in: 1...4,
                    step: 1
                )
                .tint(kp.primary)
                
                Text("Scales every muscle group to the same count. Combine with presets below.")
                    .font(GenSettingsFonts.regular(13))
                    .foregroundStyle(kp.onSurfaceVariant)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(kp.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusLG, style: .continuous))
    }
    
    private func volumeRow<Bar: View>(title: String, value: String, @ViewBuilder bar: () -> Bar) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .bottom) {
                Text(title)
                    .font(GenSettingsFonts.medium(17))
                    .foregroundStyle(kp.onSurfaceVariant)
                Spacer()
                Text(value)
                    .font(GenSettingsFonts.bold(24))
                    .foregroundStyle(kp.primary)
            }
            bar()
        }
    }
    
    private func dualIntSliders(
        low: Binding<Int>,
        high: Binding<Int>,
        range: ClosedRange<Int>,
        onChange: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Min")
                    .font(GenSettingsFonts.regular(13))
                    .foregroundStyle(kp.onSurfaceVariant)
                Spacer()
                Text("\(low.wrappedValue)")
                    .font(GenSettingsFonts.bold(17))
                    .foregroundStyle(kp.onSurface)
            }
            Slider(
                value: Binding(
                    get: { Double(low.wrappedValue) },
                    set: {
                        low.wrappedValue = Int($0.rounded())
                        onChange()
                    }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .tint(kp.primary)
            
            HStack {
                Text("Max")
                    .font(GenSettingsFonts.regular(13))
                    .foregroundStyle(kp.onSurfaceVariant)
                Spacer()
                Text("\(high.wrappedValue)")
                    .font(GenSettingsFonts.bold(17))
                    .foregroundStyle(kp.onSurface)
            }
            Slider(
                value: Binding(
                    get: { Double(high.wrappedValue) },
                    set: {
                        high.wrappedValue = Int($0.rounded())
                        onChange()
                    }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .tint(kp.primary)
        }
    }
}

struct ExerciseCountRangeBar: View {
    @Environment(\.kineticPalette) private var kp
    let min: Int
    let max: Int
    let `in`: ClosedRange<Int>
    
    var body: some View {
        GeometryReader { geo in
            let span = CGFloat(`in`.upperBound - `in`.lowerBound)
            let start = CGFloat(min - `in`.lowerBound) / span
            let end = CGFloat(max - `in`.lowerBound) / span
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(kp.surfaceContainerHighest)
                Capsule()
                    .fill(kp.primary)
                    .shadow(color: kp.primary.opacity(0.35), radius: 8, x: 0, y: 0)
                    .frame(width: Swift.max(6, (end - start) * w))
                    .offset(x: start * w)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Content toggles

private struct GenerationContentLogicSection: View {
    @Environment(\.kineticPalette) private var kp
    @Binding var settings: WorkoutGenerationSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Content logic")
                .font(GenSettingsFonts.bold(26))
                .foregroundStyle(kp.onSurface)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.spacing3) {
                kineticToggle("Include cardio", isOn: $settings.includeCardio)
                kineticToggle("Calisthenics", isOn: $settings.includeCalisthenics)
                kineticToggle("Warmup routine", isOn: $settings.includeWarmup)
                kineticToggle("Cool down / stretch", isOn: $settings.includeStretch)
            }
            
            VStack(spacing: AppSpacing.spacing3) {
                stepperRow(
                    title: "Warmup & stretch cap",
                    subtitle: "Max per workout (0–5)",
                    value: $settings.maxWarmupStretchExercises,
                    range: 0...5
                )
                stepperRow(
                    title: "Cardio cap",
                    subtitle: "Max per workout (0–3)",
                    value: $settings.maxCardioExercises,
                    range: 0...3
                )
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(kp.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusLG, style: .continuous))
    }
    
    private func kineticToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(GenSettingsFonts.medium(17))
                .foregroundStyle(kp.onSurface)
            Spacer()
            Toggle("", isOn: Binding(
                get: { isOn.wrappedValue },
                set: {
                    HapticManager.impact(style: .light)
                    isOn.wrappedValue = $0
                }
            ))
            .labelsHidden()
            .tint(kp.primaryContainer)
        }
        .padding(AppSpacing.md)
        .background(kp.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMD, style: .continuous))
    }
    
    private func stepperRow(title: String, subtitle: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(GenSettingsFonts.medium(17))
                    .foregroundStyle(kp.onSurface)
                Text(subtitle)
                    .font(GenSettingsFonts.regular(13))
                    .foregroundStyle(kp.onSurfaceVariant)
            }
            Spacer()
            Stepper(
                value: Binding(
                    get: { value.wrappedValue },
                    set: {
                        HapticManager.selection()
                        value.wrappedValue = $0
                    }
                ),
                in: range
            ) {
                Text("\(value.wrappedValue)")
                    .font(GenSettingsFonts.bold(17))
                    .foregroundStyle(kp.onSurface)
                    .frame(minWidth: 24)
            }
        }
        .padding(AppSpacing.md)
        .background(kp.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMD, style: .continuous))
    }
}

// MARK: - Equipment

private struct GenerationEquipmentSection: View {
    @Environment(\.kineticPalette) private var kp
    @Binding var settings: WorkoutGenerationSettings
    
    private let options: [(id: String, label: String)] = [
        ("Barbell", "Barbell"),
        ("Dumbbells", "Dumbbell"),
        ("Machine", "Machine"),
        ("Cable", "Cable"),
        ("Bodyweight", "Bodyweight")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Equipment inventory")
                .font(GenSettingsFonts.bold(26))
                .foregroundStyle(kp.onSurface)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: AppSpacing.sm)], spacing: AppSpacing.sm) {
                ForEach(options, id: \.id) { item in
                    let isOn = settings.preferredEquipment.contains(item.id)
                    Button {
                        HapticManager.impact(style: .light)
                        if isOn {
                            settings.preferredEquipment.removeAll { $0 == item.id }
                        } else {
                            if !settings.preferredEquipment.contains(item.id) {
                                settings.preferredEquipment.append(item.id)
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if isOn {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                            }
                            Text(item.label)
                                .font(GenSettingsFonts.medium(17))
                        }
                        .foregroundStyle(isOn ? kp.primary : kp.onSurfaceVariant)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .frame(maxWidth: .infinity)
                        .background(isOn ? kp.primary.opacity(0.12) : kp.surfaceContainerHighest)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(isOn ? kp.primary : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(kp.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusLG, style: .continuous))
    }
}

// MARK: - Performance

private struct GenerationPerformanceSection: View {
    @Environment(\.kineticPalette) private var kp
    @Binding var settings: WorkoutGenerationSettings
    let restBounds: ClosedRange<Int>
    let rirBounds: ClosedRange<Int>
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Performance thresholds")
                .font(GenSettingsFonts.bold(26))
                .foregroundStyle(kp.onSurface)
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("Rest duration")
                        .font(GenSettingsFonts.medium(17))
                        .foregroundStyle(kp.onSurfaceVariant)
                    Spacer()
                    Text("\(settings.restTimeMin)s – \(settings.restTimeMax)s")
                        .font(GenSettingsFonts.bold(17))
                        .foregroundStyle(kp.primary)
                }
                Slider(
                    value: Binding(
                        get: { Double(settings.restTimeMin) },
                        set: { new in
                            HapticManager.selection()
                            settings.restTimeMin = Int(new.rounded())
                            if settings.restTimeMin > settings.restTimeMax {
                                settings.restTimeMax = settings.restTimeMin
                            }
                        }
                    ),
                    in: Double(restBounds.lowerBound)...Double(restBounds.upperBound),
                    step: 5
                )
                .tint(kp.primary)
                Slider(
                    value: Binding(
                        get: { Double(settings.restTimeMax) },
                        set: { new in
                            HapticManager.selection()
                            settings.restTimeMax = Int(new.rounded())
                            if settings.restTimeMax < settings.restTimeMin {
                                settings.restTimeMin = settings.restTimeMax
                            }
                        }
                    ),
                    in: Double(restBounds.lowerBound)...Double(restBounds.upperBound),
                    step: 5
                )
                .tint(kp.primary)
                HStack {
                    Text("30s")
                    Spacer()
                    Text("300s")
                }
                .font(GenSettingsFonts.regular(13))
                .foregroundStyle(kp.onSurfaceVariant)
                .textCase(.uppercase)
                .tracking(1)
            }
            
            Divider()
                .background(kp.surfaceContainerHighest.opacity(0.5))
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("RIR range (effort)")
                        .font(GenSettingsFonts.medium(17))
                        .foregroundStyle(kp.onSurfaceVariant)
                    Spacer()
                    Text("\(settings.rirMin) – \(settings.rirMax) RIR")
                        .font(GenSettingsFonts.bold(17))
                        .foregroundStyle(kp.primary)
                }
                Slider(
                    value: Binding(
                        get: { Double(settings.rirMin) },
                        set: { new in
                            HapticManager.selection()
                            settings.rirMin = Int(new.rounded())
                            if settings.rirMin > settings.rirMax {
                                settings.rirMax = settings.rirMin
                            }
                        }
                    ),
                    in: Double(rirBounds.lowerBound)...Double(rirBounds.upperBound),
                    step: 1
                )
                .tint(kp.primary)
                Slider(
                    value: Binding(
                        get: { Double(settings.rirMax) },
                        set: { new in
                            HapticManager.selection()
                            settings.rirMax = Int(new.rounded())
                            if settings.rirMax < settings.rirMin {
                                settings.rirMin = settings.rirMax
                            }
                        }
                    ),
                    in: Double(rirBounds.lowerBound)...Double(rirBounds.upperBound),
                    step: 1
                )
                .tint(kp.primary)
                HStack {
                    Text("Max intensity")
                    Spacer()
                    Text("Recovery focus")
                }
                .font(GenSettingsFonts.regular(13))
                .foregroundStyle(kp.onSurfaceVariant)
                .textCase(.uppercase)
                .tracking(1)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(kp.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusLG, style: .continuous))
    }
}

// MARK: - Reference sections (Kinetic)

struct CoreRulesSection: View {
    @Environment(\.kineticPalette) private var kp

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("FULL-BODY")
                    .font(GenSettingsFonts.bold(26))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [kp.primary, kp.primaryContainer],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("— CORE RULES")
                    .font(GenSettingsFonts.bold(26))
                    .foregroundStyle(kp.onSurface)
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                RuleItem(icon: "calendar", text: "Train 3–4× per week")
                RuleItem(icon: "target", text: "Hit every major muscle each session")
                RuleItem(icon: "arrow.triangle.2.circlepath", text: "Fewer exercises per muscle per workout, but higher weekly frequency")
            }
            .padding(AppSpacing.md)
            .background(kp.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(AppSpacing.md)
        .background(kp.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(kp.outlineVariant.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: kp.onSurface.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

struct RuleItem: View {
    @Environment(\.kineticPalette) private var kp
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(kp.primary)
                .frame(width: 20)

            Text(text)
                .font(GenSettingsFonts.regular(17))
                .foregroundStyle(kp.onSurface)
        }
    }
}

struct PhaseGuidelinesSection: View {
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
    
    private var exerciseCounts: [String: Int] {
        TrainingPhase.getExerciseCounts(for: phase, splitType: "full body", dayType: "")
    }
    
    private var totalExerciseCount: String {
        switch phase {
        case .bulking:
            return "5–7"
        case .cutting:
            return "4–6"
        case .endurance:
            return "4–6"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Phase Header
            HStack {
                Text(phase.rawValue.uppercased())
                    .font(GenSettingsFonts.bold(26))
                    .foregroundStyle(phaseColor)

                Text("(Full-Body)")
                    .font(GenSettingsFonts.bold(26))
                    .foregroundStyle(kp.onSurface)
            }

            // Goal and Recovery Info
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                InfoRow(label: "Goal", value: phaseGoal)
                InfoRow(label: "Recovery", value: phaseRecovery)
                InfoRow(label: "Weekly sets/muscle", value: weeklySetsRange)
            }
            .padding(AppSpacing.md)
            .background(kp.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Per Workout Exercise Count
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Per Workout Exercise Count")
                    .font(GenSettingsFonts.bold(17))
                    .foregroundStyle(kp.onSurface)

                Text("\(totalExerciseCount) total exercises")
                    .font(GenSettingsFonts.regular(17))
                    .foregroundStyle(kp.onSurfaceVariant)

                // Muscle Group Table
                VStack(spacing: AppSpacing.xs) {
                    ForEach(muscleGroupRows, id: \.muscle) { row in
                        HStack {
                            Text(row.muscle)
                                .font(GenSettingsFonts.medium(17))
                                .foregroundStyle(kp.onSurface)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(row.count)
                                .font(GenSettingsFonts.bold(17))
                                .foregroundStyle(kp.primary)
                        }
                        .padding(.vertical, AppSpacing.xs)

                        if row.muscle != muscleGroupRows.last?.muscle {
                            Divider()
                                .background(kp.outlineVariant.opacity(0.35))
                        }
                    }
                }
                .padding(AppSpacing.sm)
                .background(kp.surfaceContainerHigh)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(AppSpacing.md)
            .background(kp.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Sets/Reps Guidelines
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Sets/Reps:")
                    .font(GenSettingsFonts.bold(17))
                    .foregroundStyle(kp.onSurface)

                Text(setsRepsGuideline)
                    .font(GenSettingsFonts.regular(17))
                    .foregroundStyle(kp.onSurfaceVariant)
            }
            .padding(AppSpacing.md)
            .background(kp.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(AppSpacing.md)
        .background(kp.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(kp.outlineVariant.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: kp.onSurface.opacity(0.06), radius: 4, x: 0, y: 2)
    }
    
    private var phaseGoal: String {
        switch phase {
        case .bulking:
            return "Grow muscle"
        case .cutting:
            return "Maintain muscle"
        case .endurance:
            return "Fatigue resistance"
        }
    }
    
    private var phaseRecovery: String {
        switch phase {
        case .bulking:
            return "High"
        case .cutting:
            return "Lower"
        case .endurance:
            return "Moderate"
        }
    }
    
    private var weeklySetsRange: String {
        switch phase {
        case .bulking:
            return "12–18"
        case .cutting:
            return "8–12"
        case .endurance:
            return "8–15"
        }
    }
    
    private var muscleGroupRows: [(muscle: String, count: String)] {
        let counts = exerciseCounts
        var rows: [(muscle: String, count: String)] = []
        
        // Build rows based on phase
        switch phase {
        case .bulking:
            rows = [
                ("Quads", counts["Quads"] != nil && counts["Quads"]! > 0 ? "\(counts["Quads"]!)" : "1"),
                ("Hams/Glutes", (counts["Hamstrings"] ?? 0) + (counts["Glutes"] ?? 0) > 0 ? "1" : "1"),
                ("Chest", counts["Chest"] != nil && counts["Chest"]! > 0 ? "\(counts["Chest"]!)" : "1"),
                ("Back", counts["Lats"] != nil ? "\(counts["Lats"]!)" : "1–2"),
                ("Shoulders", counts["Shoulders"] != nil && counts["Shoulders"]! > 0 ? "\(counts["Shoulders"]!)" : "0–1"),
                ("Arms", ((counts["Biceps"] ?? 0) + (counts["Triceps"] ?? 0)) > 0 ? "0–1" : "0–1")
            ]
        case .cutting:
            rows = [
                ("Quads", counts["Quads"] != nil && counts["Quads"]! > 0 ? "\(counts["Quads"]!)" : "1"),
                ("Hams/Glutes", (counts["Hamstrings"] ?? 0) + (counts["Glutes"] ?? 0) > 0 ? "1" : "1"),
                ("Chest", counts["Chest"] != nil && counts["Chest"]! > 0 ? "\(counts["Chest"]!)" : "1"),
                ("Back", counts["Lats"] != nil && counts["Lats"]! > 0 ? "\(counts["Lats"]!)" : "1"),
                ("Shoulders/Arms", ((counts["Shoulders"] ?? 0) + (counts["Biceps"] ?? 0) + (counts["Triceps"] ?? 0)) > 0 ? "0–1 total" : "0–1 total")
            ]
        case .endurance:
            rows = [
                ("Legs", ((counts["Quads"] ?? 0) + (counts["Hamstrings"] ?? 0) + (counts["Glutes"] ?? 0)) > 0 ? "2" : "2"),
                ("Push", counts["Chest"] != nil && counts["Chest"]! > 0 ? "\(counts["Chest"]!)" : "1"),
                ("Pull", counts["Lats"] != nil && counts["Lats"]! > 0 ? "\(counts["Lats"]!)" : "1–2"),
                ("Core/Arms", ((counts["Abs"] ?? 0) + (counts["Biceps"] ?? 0) + (counts["Triceps"] ?? 0)) > 0 ? "0–1" : "0–1")
            ]
        }
        
        return rows
    }
    
    private var setsRepsGuideline: String {
        switch phase {
        case .bulking:
            return "3–4 sets × 6–12 reps"
        case .cutting:
            return "2–3 sets × 5–10 reps\nKeep loads heavy"
        case .endurance:
            return "2–3 sets × 12–20 reps\nFormat: Circuits or short rest"
        }
    }
}

struct InfoRow: View {
    @Environment(\.kineticPalette) private var kp
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(GenSettingsFonts.medium(17))
                .foregroundStyle(kp.onSurfaceVariant)

            Spacer()

            Text(value)
                .font(GenSettingsFonts.bold(17))
                .foregroundStyle(kp.onSurface)
        }
    }
}
