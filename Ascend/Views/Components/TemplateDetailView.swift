//
//  TemplateDetailView.swift
//  Ascend
//
//  Kinetic template detail — wireframe parity (no duplicate top shell header; nav toolbar only).
//

import SwiftUI

// MARK: - Typography (Manrope — matches Templates kinetic)

private enum DetailFonts {
    static func extraBold(_ size: CGFloat) -> Font {
        Font.custom("Manrope-ExtraBold", size: size, relativeTo: .body)
    }
    static func bold(_ size: CGFloat) -> Font {
        Font.custom("Manrope-Bold", size: size, relativeTo: .body)
    }
    static func semiBold(_ size: CGFloat) -> Font {
        Font.custom("Manrope-SemiBold", size: size, relativeTo: .body)
    }
    static func medium(_ size: CGFloat) -> Font {
        Font.custom("Manrope-Medium", size: size, relativeTo: .body)
    }
}

/// Rotating hero thumbnails when no direct image URL is available (same family as Library bento).
private enum TemplateDetailHeroImagery {
    static let exerciseThumbnails: [URL] = [
        URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuAyi-5GQkDrYKkqarxzqohNlvjKX04_fIQjltfj4qmx4hgIU5Z-yr_WW-q4snui9k4Jgq51TALvpTAWDk3EBgmfNJq1T-fMaDhl9k3tS8q4LkH4jVcUmbSqIxdwZ3-DxMAUOW5tiMr9x_BaA0gcavChWO3rXCalVikBSopaQYuhkNo9YSSe6uHFY9wMazgBwKOW7oZY_WSLBT5ePQR6DV7FIZZ4HJeCcSccuo9mQXYOmsSWAY7o1s-4FSk7op4hxkuNrPIxVIvdjWk")!,
        URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuBv1Ojoap9va9wu45AOT7XQOJ9vvF_hNfNLvvHx1OVi-5eaeUWzs92dqIOE9eRwVcoP79PiFa1B4m9jFWRwM-sOedr7NWPI8coq0LMKP7adAlGl0fpY2tso2l43sv_LHJ0Bm381jp7WxK3yd2LFwton1G1x_vtnKLK1PWnCEtjBL2SOgG_415dmHIBLjZxUrxUcgTXgXGmb2uBiJEJ8YsuEIV-PvbuyC6-9YBiiHtml-k93u85OTz3pJVvhUZKGaRZ_L8-69bfeFEU")!,
        URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuBUtkAsUm0i15Gyje-CgFcm0_Wihy2LhtPduUnNndKnSxPVuT8WfGHij5fP45KL6_iMVe7A2r0geK6doViAtHay5kJO60iabQkn8phroGZYyTzlB7iU5lME-cVUc3WqdyrytaTXTa8QyQJfJKFtYWA7hzSnDtZmnmeC1Df8dS9gqZjtMeAbLXebNKIH3J9LDat7_L43BnC-tFd0uylXGT4V6FxdQ6uiJYrVnGj8y1RtBe04fe6qFKi2oAnENfTDAD0c9fYmkrAdxw")!
    ]

    static func thumbnailURL(for exerciseIndex: Int) -> URL {
        exerciseThumbnails[exerciseIndex % exerciseThumbnails.count]
    }
}

struct TemplateDetailView: View {
    let template: WorkoutTemplate
    let onStart: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.kineticPalette) private var kp
    @State private var showDeleteConfirmation = false

    private var totalSets: Int {
        template.exercises.reduce(0) { $0 + $1.sets }
    }

    private var eyebrowLine: String {
        let kind = template.intensity?.rawValue ?? template.workoutType.rawValue
        return "Templates / \(kind)"
    }

    private var heroDescription: String {
        if let d = template.intensity?.description { return d }
        return template.workoutType.description
    }

    /// Volume bar fill — scales with share of a nominal “full” week block (visual only).
    private var volumeBarFraction: CGFloat {
        let t = CGFloat(totalSets)
        let cap: CGFloat = 40
        return min(1, max(0.15, t / cap))
    }

    private var lastSessionText: String {
        let workouts = WorkoutHistoryManager.shared.completedWorkouts
            .filter { $0.name == template.name }
            .sorted { $0.startDate > $1.startDate }
        guard let last = workouts.first?.startDate else {
            return "No sessions yet"
        }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: last, relativeTo: Date())
    }

    private var lastSessionTrend: String {
        let workouts = WorkoutHistoryManager.shared.completedWorkouts
            .filter { $0.name == template.name }
            .sorted { $0.startDate > $1.startDate }
        guard workouts.count >= 2 else {
            return workouts.isEmpty ? "Start logging" : "Baseline set"
        }
        let recent = volume(for: workouts[0])
        let older = volume(for: workouts[1])
        guard older > 0 else { return "New data" }
        let delta = (recent - older) / older * 100
        if abs(delta) < 0.5 { return "Stable volume" }
        let sign = delta > 0 ? "+" : ""
        return "\(sign)\(Int(delta.rounded()))% volume"
    }

    private func volume(for workout: Workout) -> Double {
        workout.exercises.reduce(0.0) { acc, ex in
            acc + ex.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
        }
    }

    private var avgIntensityPercent: Int {
        guard let i = template.intensity else { return 75 }
        switch i {
        case .light: return 65
        case .moderate: return 75
        case .intense: return 84
        case .extreme: return 92
        }
    }

    private var avgIntensityCaption: String {
        template.intensity.map { "\($0.rawValue) focus" } ?? "Balanced load"
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                kp.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        heroSection
                        bentoStats
                        routineSection
                        insightsSection
                    }
                    .frame(maxWidth: KineticTemplateDetailLayout.contentMaxWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, KineticTemplateDetailLayout.horizontalPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)

                startWorkoutFloatingBar
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(kp.tertiary)
                    }
                    .accessibilityLabel("Close")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            HapticManager.impact(style: .light)
                            onEdit()
                            dismiss()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button {
                            HapticManager.impact(style: .light)
                            onDuplicate()
                            dismiss()
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                        if onDelete != nil {
                            Divider()
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(kp.onSurface)
                    }
                    .accessibilityLabel("More actions")
                }
            }
            .alert("Delete Template?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete '\(template.name)'? This action cannot be undone.")
            }
            .onAppear {
                CardDetailCacheManager.shared.cacheTemplate(template)
            }
        }
    }

    // MARK: - Hero (no outer HTML shell header)

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrowLine)
                .font(DetailFonts.bold(10))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(kp.primary)

            Text(template.name)
                .font(DetailFonts.extraBold(34))
                .foregroundStyle(kp.onSurface)
                .tracking(-0.8)
                .fixedSize(horizontal: false, vertical: true)

            Text(heroDescription)
                .font(DetailFonts.medium(14))
                .foregroundStyle(kp.tertiary)
                .lineSpacing(3)
                .frame(maxWidth: 420, alignment: .leading)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Bento stats

    private var bentoStats: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 12),
                GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 12)
            ],
            spacing: 12
        ) {
            estimatedTimeCard
            volumeCard
        }
        .padding(.bottom, 28)
    }

    private var estimatedTimeCard: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Estimated Time")
                    .font(DetailFonts.bold(10))
                    .tracking(1.2)
                    .foregroundStyle(kp.primary.opacity(0.6))
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(max(template.estimatedDuration, 1))")
                        .font(DetailFonts.extraBold(40))
                        .foregroundStyle(kp.onSurface)
                    Text("m")
                        .font(DetailFonts.bold(18))
                        .foregroundStyle(kp.tertiary)
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            Image(systemName: "timer")
                .font(.system(size: 72))
                .foregroundStyle(Color.white.opacity(0.05))
                .offset(x: 8, y: 8)
        }
        .padding(20)
        .frame(height: 128)
        .frame(maxWidth: .infinity)
        .background(kp.surfaceContainerHighest)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var volumeCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Volume")
                .font(DetailFonts.bold(10))
                .tracking(1.2)
                .foregroundStyle(kp.primary.opacity(0.6))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(totalSets)")
                    .font(DetailFonts.extraBold(32))
                    .foregroundStyle(kp.onSurface)
                Text("SETS")
                    .font(DetailFonts.bold(11))
                    .foregroundStyle(kp.tertiary)
            }
            .padding(.top, 4)

            Spacer(minLength: 8)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(kp.surfaceContainerHighest)
                        .frame(height: 4)
                    Capsule()
                        .fill(kp.primary)
                        .frame(width: max(4, geo.size.width * volumeBarFraction), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(20)
        .frame(height: 128)
        .frame(maxWidth: .infinity)
        .background(kp.surfaceContainerLow)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(kp.outlineVariant.opacity(0.15), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Routine list

    private var routineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Workout Routine")
                    .font(DetailFonts.bold(13))
                    .tracking(2.4)
                    .foregroundStyle(kp.tertiary)
                    .textCase(.uppercase)
                Spacer()
                Text("\(template.exercises.count) Exercises")
                    .font(DetailFonts.medium(12))
                    .foregroundStyle(kp.primary)
            }

            VStack(spacing: 12) {
                ForEach(Array(template.exercises.enumerated()), id: \.element.id) { index, exercise in
                    KineticTemplateExerciseRow(
                        exercise: exercise,
                        exerciseIndex: index,
                        kp: kp
                    )
                }
            }
        }
        .padding(.bottom, 28)
    }

    // MARK: - Insights

    private var insightsSection: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            insightTile(
                title: "Last Session",
                value: lastSessionText,
                foot: lastSessionTrend,
                footIcon: "trending.up",
                footTint: kp.primary
            )
            insightTile(
                title: "Avg. Intensity",
                value: "\(avgIntensityPercent)%",
                foot: avgIntensityCaption,
                footIcon: "chart.bar.xaxis",
                footTint: kp.secondary
            )
        }
    }

    private func insightTile(title: String, value: String, foot: String, footIcon: String, footTint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(DetailFonts.bold(10))
                .tracking(1.2)
                .foregroundStyle(kp.tertiary.opacity(0.6))
            Text(value)
                .font(DetailFonts.bold(18))
                .foregroundStyle(kp.onSurface)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            HStack(spacing: 4) {
                Image(systemName: footIcon)
                    .font(.system(size: 11))
                Text(foot)
                    .font(DetailFonts.medium(10))
            }
            .foregroundStyle(footTint)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(kp.surfaceContainerLow)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(kp.outlineVariant.opacity(0.15), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Fixed CTA

    private var startWorkoutFloatingBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [kp.background, kp.background.opacity(0.9), kp.background.opacity(0)],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 24)
            .allowsHitTesting(false)

            Button {
                HapticManager.impact(style: .medium)
                onStart()
                dismiss()
            } label: {
                HStack(spacing: 10) {
                    Text("Start Workout")
                        .font(DetailFonts.bold(13))
                        .tracking(2.4)
                        .textCase(.uppercase)
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundStyle(kp.onSecondaryContainer)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(kp.secondaryContainer)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.35), radius: 20, x: 0, y: 10)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, KineticTemplateDetailLayout.horizontalPadding)
            .padding(.bottom, 12)
            .accessibilityLabel("Start workout with \(template.name)")
        }
        .frame(maxWidth: KineticTemplateDetailLayout.contentMaxWidth + KineticTemplateDetailLayout.horizontalPadding * 2)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [kp.background.opacity(0), kp.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Layout

private enum KineticTemplateDetailLayout {
    static var contentMaxWidth: CGFloat { min(672, AppConstants.UI.mainColumnMaxWidth) }
    static var horizontalPadding: CGFloat { AppConstants.UI.mainColumnGutter }
}

// MARK: - Exercise row

private struct KineticTemplateExerciseRow: View {
    let exercise: TemplateExercise
    let exerciseIndex: Int
    let kp: KineticAdaptivePalette

    private var movementTag: String {
        TemplateDetailMovementClassifier.tag(for: exercise.name)
    }

    private var displayRPE: String {
        TemplateDetailMovementClassifier.rpeLine(for: exerciseIndex)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            exerciseThumbnail

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(exercise.name)
                        .font(DetailFonts.bold(16))
                        .foregroundStyle(kp.onSurface)
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    Text(movementTag)
                        .font(DetailFonts.bold(10))
                        .tracking(0.5)
                        .foregroundStyle(tagForeground)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(tagBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }

                HStack(spacing: 20) {
                    metricColumn(label: "Sets", value: "\(exercise.sets)")
                    metricColumn(label: "Reps", value: exercise.reps)
                    metricColumn(label: "RPE", value: displayRPE, valueColor: kp.secondary)
                }
            }
        }
        .padding(14)
        .background(kp.surfaceContainerHighest)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var tagForeground: Color {
        movementTag == "Isolation" ? kp.secondary : kp.primary
    }

    private var tagBackground: Color {
        movementTag == "Isolation"
            ? kp.secondaryContainer.opacity(0.35)
            : kp.primaryContainer.opacity(0.35)
    }

    private func metricColumn(label: String, value: String, valueColor: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(DetailFonts.bold(9))
                .tracking(2)
                .foregroundStyle(kp.tertiary)
                .textCase(.uppercase)
            Text(value)
                .font(DetailFonts.extraBold(14))
                .foregroundStyle(valueColor ?? kp.onSurface)
        }
    }

    @ViewBuilder
    private var exerciseThumbnail: some View {
        let url = TemplateDetailHeroImagery.thumbnailURL(for: exerciseIndex)
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                ZStack {
                    Color(hex: "131313")
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 28))
                        .foregroundStyle(kp.tertiary.opacity(0.4))
                }
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Movement heuristics (no RPE in model — display-only)

private enum TemplateDetailMovementClassifier {
    static func tag(for name: String) -> String {
        let n = name.lowercased()
        let isolationHints = ["curl", "fly", "raise", "extension", "pushdown", "kickback", "face pull", "lateral", "shrug"]
        if isolationHints.contains(where: { n.contains($0) }) { return "Isolation" }
        return "Compound"
    }

    static func rpeLine(for index: Int) -> String {
        let values = ["8.5", "8", "9", "7.5", "8.5", "9"]
        return values[index % values.count]
    }
}

#Preview {
    TemplateDetailView(
        template: WorkoutTemplate(
            name: "Push Volume A",
            exercises: [
                TemplateExercise(name: "Barbell Bench Press", sets: 4, reps: "8-10", dropsets: false, exerciseType: .weightReps),
                TemplateExercise(name: "Dumbbell Shoulder Press", sets: 3, reps: "10-12", dropsets: false, exerciseType: .weightReps),
                TemplateExercise(name: "Incline Cable Fly", sets: 3, reps: "12-15", dropsets: false, exerciseType: .weightReps)
            ],
            estimatedDuration: 75,
            intensity: .intense
        ),
        onStart: {},
        onEdit: {},
        onDuplicate: {},
        onDelete: {}
    )
}
