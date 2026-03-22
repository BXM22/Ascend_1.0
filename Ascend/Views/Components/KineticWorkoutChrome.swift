//
//  KineticWorkoutChrome.swift
//  Ascend
//
//  Wireframe parity: Tailwind kinetic session (Manrope, M3-ish tokens from HTML spec).
//

import SwiftUI

// MARK: - Typography

enum KineticWorkoutTypography {
    static func extraBold(_ size: CGFloat) -> Font { Font.custom("Manrope-ExtraBold", size: size, relativeTo: .body) }
    static func bold(_ size: CGFloat) -> Font { Font.custom("Manrope-Bold", size: size, relativeTo: .body) }
    static func semiBold(_ size: CGFloat) -> Font { Font.custom("Manrope-SemiBold", size: size, relativeTo: .body) }
    static func medium(_ size: CGFloat) -> Font { Font.custom("Manrope-Medium", size: size, relativeTo: .body) }
}

// MARK: - Top bar (fixed blur)

struct KineticWorkoutTopBar: View {
    let elapsedTime: TimeInterval
    let timerPaused: Bool
    let onTogglePause: () -> Void
    let onSettings: () -> Void

    @Environment(\.kineticPalette) private var kp

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(kp.surfaceContainerHighest)
                            .frame(width: 32, height: 32)
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(kp.tertiary)
                    }
                    Text(formatElapsed(elapsedTime))
                        .font(KineticWorkoutTypography.bold(18))
                        .foregroundStyle(kp.primaryContainer)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Button(action: {
                        onTogglePause()
                        HapticManager.impact(style: .medium)
                    }) {
                        Image(systemName: timerPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(kp.mutedChrome)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(timerPaused ? "Resume workout" : "Pause workout")
                }
                Spacer(minLength: 0)
                Text("Performance")
                    .font(KineticWorkoutTypography.semiBold(15))
                    .foregroundStyle(kp.mutedChrome)
                Spacer(minLength: 0)
                Button(action: {
                    onSettings()
                    HapticManager.selection()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(kp.mutedChrome)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background {
                ZStack {
                    kp.background.opacity(0.82)
                    Rectangle().fill(.ultraThinMaterial)
                }
            }
            Rectangle()
                .fill(kp.surfaceContainerHighest.opacity(0.2))
                .frame(height: 1)
        }
    }

    private func formatElapsed(_ t: TimeInterval) -> String {
        let s = Int(t)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%d:%02d", m, sec)
    }
}

// MARK: - Session header (title + Active + started time)

struct KineticWorkoutSessionHeader: View {
    let workoutName: String
    let sessionStart: Date?

    @Environment(\.kineticPalette) private var kp

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(workoutName)
                    .font(KineticWorkoutTypography.extraBold(28))
                    .foregroundStyle(kp.onSurface)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 8)
                Text("Active")
                    .font(KineticWorkoutTypography.bold(10))
                    .tracking(2.4)
                    .textCase(.uppercase)
                    .foregroundStyle(kp.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(kp.primaryContainer.opacity(0.2))
                    .clipShape(Capsule())
            }
            if let start = sessionStart {
                Text("Session started \(start.formatted(date: .omitted, time: .shortened))")
                    .font(KineticWorkoutTypography.medium(14))
                    .foregroundStyle(kp.tertiary)
            } else {
                Text("Session in progress")
                    .font(KineticWorkoutTypography.medium(14))
                    .foregroundStyle(kp.tertiary)
            }
        }
    }
}

// MARK: - Rest timer bento

struct KineticRestTimerBento: View {
    let timeRemaining: Int
    let totalDuration: Int
    let upNextExerciseName: String
    let onAdd15: () -> Void
    let onSkip: () -> Void

    @Environment(\.kineticPalette) private var kp

    private var progress: CGFloat {
        guard totalDuration > 0 else { return 0 }
        return CGFloat(1 - Double(timeRemaining) / Double(totalDuration))
    }

    var body: some View {
        ZStack {
            kp.surfaceContainerHighest
            Image(systemName: "timer")
                .font(.system(size: 100))
                .foregroundStyle(kp.onSurface.opacity(0.05))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(16)
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .stroke(kp.surfaceContainerLow, lineWidth: 4)
                        .frame(width: 160, height: 160)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            kp.primaryContainer,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: kp.primary.opacity(0.4), radius: 8)
                    VStack(spacing: 4) {
                        Text(formatClock(timeRemaining))
                            .font(KineticWorkoutTypography.bold(36))
                            .foregroundStyle(kp.onSurface)
                            .monospacedDigit()
                        Text("Resting")
                            .font(KineticWorkoutTypography.bold(10))
                            .tracking(2.4)
                            .textCase(.uppercase)
                            .foregroundStyle(kp.tertiary)
                    }
                }
                .padding(.bottom, 20)
                VStack(spacing: 4) {
                    Text("Up Next")
                        .font(KineticWorkoutTypography.bold(10))
                        .tracking(2.4)
                        .textCase(.uppercase)
                        .foregroundStyle(kp.primary)
                    Text(upNextExerciseName)
                        .font(KineticWorkoutTypography.bold(20))
                        .foregroundStyle(kp.onSurface)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(.bottom, 20)
                HStack(spacing: 12) {
                    Button(action: {
                        onAdd15()
                        HapticManager.impact(style: .light)
                    }) {
                        Text("+15s")
                            .font(KineticWorkoutTypography.bold(14))
                            .foregroundStyle(kp.onSurface)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(kp.surfaceContainerLow)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(kp.outlineVariant.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    Button(action: {
                        onSkip()
                        HapticManager.impact(style: .medium)
                    }) {
                        Text("Skip")
                            .font(KineticWorkoutTypography.bold(14))
                            .foregroundStyle(kp.onPrimaryContainer)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(kp.primaryContainer)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: kp.primaryContainer.opacity(0.2), radius: 12, y: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func formatClock(_ sec: Int) -> String {
        let s = max(0, sec)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

// MARK: - Bottom bar

struct KineticWorkoutBottomBar: View {
    let onCancel: () -> Void
    let onFinish: () -> Void

    @Environment(\.kineticPalette) private var kp

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(kp.surfaceContainerHighest.opacity(0.3))
                .frame(height: 1)
            HStack(spacing: 16) {
                Button(action: {
                    onCancel()
                    HapticManager.impact(style: .medium)
                }) {
                    Text("Cancel")
                        .font(KineticWorkoutTypography.bold(14))
                        .foregroundStyle(kp.onSurface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(kp.surfaceContainerHighest, in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(kp.outlineVariant.opacity(0.55), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.32), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                Button(action: {
                    onFinish()
                    HapticManager.impact(style: .medium)
                }) {
                    Text("Finish Workout")
                        .font(KineticWorkoutTypography.bold(14))
                        .foregroundStyle(kp.onPrimaryContainer)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(kp.primaryContainer)
                        .clipShape(Capsule())
                        .shadow(color: kp.primaryContainer.opacity(0.3), radius: 12, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
    }
}

// MARK: - Exercise title row (tags from ExRx when available)

struct KineticExerciseTitleRow: View {
    let exerciseName: String
    let tag1: String?
    let tag2: String?
    let onInfo: () -> Void

    @Environment(\.kineticPalette) private var kp

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(exerciseName)
                    .font(KineticWorkoutTypography.bold(22))
                    .foregroundStyle(kp.onSurface)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    if let tag1 {
                        tagChip(tag1)
                    }
                    if let tag2 {
                        tagChip(tag2)
                    }
                }
            }
            Spacer(minLength: 8)
            Button(action: {
                onInfo()
                HapticManager.selection()
            }) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(kp.tertiary)
                    .frame(width: 40, height: 40)
                    .background(kp.surfaceContainerHighest)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Exercise info and history")
        }
    }

    private func tagChip(_ text: String) -> some View {
        Text(text.uppercased())
            .font(KineticWorkoutTypography.bold(10))
            .tracking(1.2)
            .foregroundStyle(kp.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(kp.secondaryContainer.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

enum KineticExerciseTags {
    static func tags(for exerciseName: String) -> (String?, String?) {
        guard let ex = ExRxDirectoryManager.shared.findExercise(name: exerciseName) else {
            return (nil, nil)
        }
        return (ex.muscleGroup, ex.category)
    }
}
