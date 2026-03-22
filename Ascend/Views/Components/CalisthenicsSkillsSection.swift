import SwiftUI

private enum SkillsKineticFonts {
    static func extraBold(_ size: CGFloat) -> Font { Font.custom("Manrope-ExtraBold", size: size, relativeTo: .body) }
    static func bold(_ size: CGFloat) -> Font { Font.custom("Manrope-Bold", size: size, relativeTo: .body) }
    static func semiBold(_ size: CGFloat) -> Font { Font.custom("Manrope-SemiBold", size: size, relativeTo: .body) }
    static func medium(_ size: CGFloat) -> Font { Font.custom("Manrope-Medium", size: size, relativeTo: .body) }
}

private struct SkillDisplayProgress {
    let levelDisplay: Int
    let totalLevels: Int
    var fraction: CGFloat { max(0, min(1, rawFraction)) }
    let phaseLabel: String
    private let rawFraction: CGFloat

    var percentInt: Int { Int((fraction * 100).rounded()) }

    init(skill: CalisthenicsSkill) {
        let levels = skill.progressionLevels.sorted { $0.level < $1.level }
        let total = max(levels.count, 1)
        let completed = levels.filter(\.isCompleted).count
        rawFraction = CGFloat(completed) / CGFloat(total)
        let next = levels.first { !$0.isCompleted }
        phaseLabel = (next?.name ?? levels.last?.name ?? "Progress").uppercased()
        levelDisplay = min(completed + 1, total)
        totalLevels = total
    }
}

private func skillWatermarkAbbreviation(_ name: String) -> String {
    let parts = name.split { !$0.isLetter && !$0.isNumber }.map { String($0) }.filter { !$0.isEmpty }
    if parts.count >= 2 {
        let letters = parts.prefix(4).compactMap { $0.first }.map { String($0) }
        return letters.joined().uppercased()
    }
    return String(name.prefix(4)).uppercased()
}

// MARK: - Section

struct CalisthenicsSkillsSection: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.kineticPalette) private var kp

    @ObservedObject var workoutViewModel: WorkoutViewModel
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var skillManager: CalisthenicsSkillManager = CalisthenicsSkillManager.shared
    let onStart: () -> Void
    @State private var selectedSkill: CalisthenicsSkill?
    @State private var showSkillDetail = false
    @State private var showCreateCustomSkill = false

    private var useTwoColumnGrid: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            kineticSectionIntro
                .padding(.bottom, 28)

            createCustomSkillButton
                .padding(.bottom, 28)

            if skillManager.skills.isEmpty {
                kineticSkillsEmptyState
            } else {
                kineticSkillsBento
            }
        }
        .padding(.bottom, 20)
        .sheet(isPresented: $showCreateCustomSkill) {
            CreateCustomSkillView(skillManager: skillManager)
        }
        .sheet(isPresented: $showSkillDetail) {
            NavigationView {
                if let skill = selectedSkill {
                    CalisthenicsSkillView(
                        skill: skill,
                        workoutViewModel: workoutViewModel,
                        templatesViewModel: templatesViewModel
                    )
                    .navigationTitle(skill.name)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showSkillDetail = false
                            }
                            .foregroundColor(AppColors.primary)
                        }
                    }
                    .onChange(of: workoutViewModel.currentWorkout) { _, newValue in
                        if newValue != nil {
                            showSkillDetail = false
                            onStart()
                        }
                    }
                }
            }
        }
    }

    private var kineticSectionIntro: some View {
        ZStack(alignment: .topLeading) {
            HStack(alignment: .top, spacing: 0) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(kp.primary)
                    .frame(width: 4, height: 48)
                    .padding(.trailing, 12)
                VStack(alignment: .leading, spacing: 8) {
                    Text(skillManager.activeSkill == nil ? "CURRENT OBJECTIVES" : "ACTIVE OBJECTIVE")
                        .font(SkillsKineticFonts.bold(10))
                        .tracking(2)
                        .foregroundStyle(kp.primary)
                    if let focus = skillManager.activeSkill {
                        Text(focus.name)
                            .font(SkillsKineticFonts.extraBold(30))
                            .tracking(-0.6)
                            .foregroundStyle(kp.onSurface)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Your focus skill is pinned to the top.")
                            .font(SkillsKineticFonts.medium(13))
                            .foregroundStyle(kp.tertiary.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("The Kinetic\nMastery")
                            .font(SkillsKineticFonts.extraBold(34))
                            .tracking(-0.8)
                            .foregroundStyle(kp.onSurface)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var createCustomSkillButton: some View {
        Button {
            showCreateCustomSkill = true
            HapticManager.impact(style: .medium)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("CREATE CUSTOM SKILL")
                    .font(SkillsKineticFonts.bold(11))
                    .tracking(1.6)
            }
            .foregroundStyle(kp.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(kp.surfaceContainerLow)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(kp.primaryContainer.opacity(0.55), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Create custom skill")
    }

    private var kineticSkillsEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 44))
                .foregroundStyle(kp.primary.opacity(0.5))
            Text("No skills yet")
                .font(SkillsKineticFonts.bold(18))
                .foregroundStyle(kp.onSurface)
            Text("Add a custom skill or check back after data loads.")
                .font(SkillsKineticFonts.medium(13))
                .foregroundStyle(kp.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private var kineticSkillsBento: some View {
        let skills = skillManager.displayOrderedSkills
        VStack(alignment: .leading, spacing: 24) {
            if let first = skills.first {
                KineticSkillHeroCard(
                    skill: first,
                    progress: SkillDisplayProgress(skill: first),
                    watermark: skillWatermarkAbbreviation(first.name),
                    isActiveObjective: skillManager.activeSkillId == first.id,
                    onPractice: { openSkill(first) },
                    onAnalytics: { openSkill(first) }
                )
                .contextMenu {
                    activeObjectiveContextMenu(for: first)
                    if first.isCustom {
                        Button(role: .destructive) {
                            skillManager.deleteCustomSkill(first)
                            HapticManager.success()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }

            let rest = Array(skills.dropFirst())
            if !rest.isEmpty {
                if useTwoColumnGrid {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ],
                        spacing: 16
                    ) {
                        ForEach(rest, id: \.id) { skill in
                            compactCard(for: skill)
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        ForEach(rest, id: \.id) { skill in
                            compactCard(for: skill)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func compactCard(for skill: CalisthenicsSkill) -> some View {
        KineticSkillCompactCard(
            skill: skill,
            progress: SkillDisplayProgress(skill: skill),
            isActiveObjective: skillManager.activeSkillId == skill.id,
            onPractice: { openSkill(skill) }
        )
        .contextMenu {
            activeObjectiveContextMenu(for: skill)
            if skill.isCustom {
                Button(role: .destructive) {
                    skillManager.deleteCustomSkill(skill)
                    HapticManager.success()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    @ViewBuilder
    private func activeObjectiveContextMenu(for skill: CalisthenicsSkill) -> some View {
        if skillManager.activeSkillId != skill.id {
            Button {
                skillManager.setActiveSkill(skill)
                HapticManager.success()
            } label: {
                Label("Set as active objective", systemImage: "target")
            }
        }
        if skillManager.activeSkillId == skill.id {
            Button {
                skillManager.setActiveSkill(nil)
                HapticManager.selection()
            } label: {
                Label("Clear active objective", systemImage: "circle.slash")
            }
        }
    }

    private func openSkill(_ skill: CalisthenicsSkill) {
        selectedSkill = skill
        showSkillDetail = true
        HapticManager.impact(style: .light)
    }
}

// MARK: - Hero card

private struct KineticSkillHeroCard: View {
    @Environment(\.kineticPalette) private var kp

    let skill: CalisthenicsSkill
    let progress: SkillDisplayProgress
    let watermark: String
    var isActiveObjective: Bool = false
    let onPractice: () -> Void
    let onAnalytics: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        if isActiveObjective {
                            Text("ACTIVE")
                                .font(SkillsKineticFonts.bold(9))
                                .tracking(1.4)
                                .foregroundStyle(kp.onPrimaryContainer)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(kp.primaryContainer.opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        Text("LEVEL \(progress.levelDisplay)/\(progress.totalLevels)")
                            .font(SkillsKineticFonts.bold(10))
                            .tracking(1.2)
                            .foregroundStyle(kp.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(kp.primaryContainer.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        Text(skill.name)
                            .font(SkillsKineticFonts.bold(24))
                            .foregroundStyle(kp.onSurface)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    ZStack {
                        Circle()
                            .fill(kp.surfaceContainerLow)
                            .frame(width: 64, height: 64)
                            .overlay(
                                Circle()
                                    .stroke(kp.outlineVariant.opacity(0.1), lineWidth: 1)
                            )
                        Image(systemName: skill.icon)
                            .font(.system(size: 28))
                            .foregroundStyle(kp.primary)
                    }
                }
                .padding(.bottom, 28)

                HStack(alignment: .bottom, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(progress.percentInt)")
                            .font(SkillsKineticFonts.extraBold(40))
                            .tracking(-1)
                            .foregroundStyle(kp.onSurface)
                        Text("%")
                            .font(SkillsKineticFonts.medium(18))
                            .foregroundStyle(kp.tertiary)
                    }
                    Spacer(minLength: 0)
                    Text(progress.phaseLabel)
                        .font(SkillsKineticFonts.bold(10))
                        .tracking(1)
                        .foregroundStyle(kp.tertiary)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.bottom, 12)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(kp.surfaceContainerLow)
                        Capsule()
                            .fill(kp.primaryContainer)
                            .frame(width: max(8, geo.size.width * progress.fraction))
                            .shadow(color: kp.primary.opacity(0.35), radius: 8, x: 0, y: 0)
                    }
                }
                .frame(height: 6)
                .padding(.bottom, 28)

                HStack(spacing: 12) {
                    Button(action: onPractice) {
                        Text("PRACTICE")
                            .font(SkillsKineticFonts.bold(11))
                            .tracking(1.8)
                            .foregroundStyle(kp.onPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(kp.primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button(action: onAnalytics) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(kp.onSurface)
                            .frame(width: 48, height: 48)
                            .background(kp.surfaceContainerLow)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(kp.outlineVariant.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("View skill details")
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(watermark)
                .font(SkillsKineticFonts.extraBold(56))
                .foregroundStyle(Color.white.opacity(0.05))
                .offset(x: 8, y: 18)
                .allowsHitTesting(false)
        }
        .background(kp.surfaceContainerHighest)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(skill.name), \(progress.percentInt) percent, \(progress.phaseLabel)")
    }
}

// MARK: - Compact card

private struct KineticSkillCompactCard: View {
    @Environment(\.kineticPalette) private var kp

    let skill: CalisthenicsSkill
    let progress: SkillDisplayProgress
    var isActiveObjective: Bool = false
    let onPractice: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("LEVEL \(progress.levelDisplay)/\(progress.totalLevels)")
                    .font(SkillsKineticFonts.bold(9))
                    .tracking(1.4)
                    .foregroundStyle(kp.tertiary)
                if isActiveObjective {
                    Text("ACTIVE")
                        .font(SkillsKineticFonts.bold(8))
                        .tracking(1)
                        .foregroundStyle(kp.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(kp.primaryContainer.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                Spacer()
                Image(systemName: skill.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(kp.primary)
            }
            .padding(.bottom, 20)

            Text(skill.name)
                .font(SkillsKineticFonts.bold(18))
                .foregroundStyle(kp.onSurface)
                .padding(.bottom, 4)

            Text(skill.description)
                .font(SkillsKineticFonts.medium(12))
                .foregroundStyle(kp.tertiary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 20)

            HStack {
                Text("\(progress.percentInt)%")
                    .font(SkillsKineticFonts.bold(10))
                    .foregroundStyle(kp.primary)
                Spacer()
                Text(progress.phaseLabel)
                    .font(SkillsKineticFonts.bold(10))
                    .tracking(0.8)
                    .foregroundStyle(kp.tertiary)
                    .lineLimit(1)
            }
            .padding(.bottom, 10)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(kp.surfaceContainerLow)
                    Capsule()
                        .fill(kp.primaryContainer)
                        .frame(width: max(6, geo.size.width * progress.fraction))
                }
            }
            .frame(height: 4)
            .padding(.bottom, 12)

            Button(action: onPractice) {
                Text("PRACTICE")
                    .font(SkillsKineticFonts.bold(10))
                    .tracking(1.8)
                    .foregroundStyle(kp.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(kp.primaryContainer, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(kp.surfaceContainerHighest)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(skill.name), \(progress.percentInt) percent")
    }
}

#Preview {
    CalisthenicsSkillsSection(
        workoutViewModel: WorkoutViewModel(settingsManager: SettingsManager()),
        templatesViewModel: TemplatesViewModel(),
        onStart: {}
    )
    .padding()
    .environment(\.kineticPalette, KineticAdaptivePalette.alignedWithAppColors(.dark))
    .background(KineticAdaptivePalette.dark.background)
}
