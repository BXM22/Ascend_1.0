import SwiftUI

// MARK: - Precision Habits (HTML reference — token-accurate)

private enum HabitsFonts {
    static func bold(_ size: CGFloat) -> Font {
        Font.custom("Manrope-Bold", size: size, relativeTo: .body)
    }

    static func semiBold(_ size: CGFloat) -> Font {
        Font.custom("Manrope-SemiBold", size: size, relativeTo: .body)
    }

    static func medium(_ size: CGFloat) -> Font {
        Font.custom("Manrope-Medium", size: size, relativeTo: .body)
    }

    static func extraBold(_ size: CGFloat) -> Font {
        Font.custom("Manrope-ExtraBold", size: size, relativeTo: .body)
    }
}

struct HabitsView: View {
    @EnvironmentObject private var colorThemeProvider: ColorThemeProvider
    @Environment(\.kineticPalette) private var kp
    @StateObject private var viewModel = HabitViewModel()
    @State private var selectedHabit: Habit?
    @State private var editingHabit: Habit?
    @State private var showCreateHabit = false

    let onSettings: () -> Void

    init(onSettings: @escaping () -> Void = {}) {
        self.onSettings = onSettings
    }

    private var completionPercent: Int {
        Int((viewModel.todayCompletionRate * 100).rounded())
    }

    private var bestCurrentStreak: Int {
        viewModel.activeHabits.map { viewModel.getStreak(habitId: $0.id) }.max() ?? 0
    }

    /// Share of habit–day slots filled over the last 14 days (0–100).
    private var consistencyPercent: Int {
        let habits = viewModel.activeHabits
        guard !habits.isEmpty else { return 0 }
        let calendar = Calendar.current
        let today = DateHelper.today
        var total = 0
        var done = 0
        for offset in 0..<14 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            for habit in habits {
                total += 1
                if viewModel.isCompleted(habitId: habit.id, date: day) {
                    done += 1
                }
            }
        }
        guard total > 0 else { return 0 }
        return Int((Double(done) / Double(total) * 100).rounded())
    }

    private var nextResetLabel: String {
        let calendar = Calendar.current
        var parts = calendar.dateComponents([.year, .month, .day], from: Date())
        parts.hour = 4
        parts.minute = 0
        parts.second = 0
        guard var reset = calendar.date(from: parts) else {
            return "Next Reset: 4:00 AM"
        }
        if reset <= Date() {
            reset = calendar.date(byAdding: .day, value: 1, to: reset) ?? reset
        }
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "Next Reset: \(f.string(from: reset))"
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 40) {
                    dailyProtocolSection
                    bentoStatsSection
                    todayExecutionSection
                    footerMeta
                }
                .frame(maxWidth: AppConstants.UI.mainColumnMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AppConstants.UI.mainColumnGutter)
                .padding(.top, 8)
                .padding(.bottom, 112)
            }
            .scrollIndicators(.hidden)

            fabButton
                .padding(.trailing, 24)
                .padding(.bottom, 20)
        }
        .background(kp.surface)
        .safeAreaInset(edge: .top, spacing: 0) {
            habitsSettingsBar
        }
        .id(colorThemeProvider.themeID)
        .sheet(item: $selectedHabit) { habit in
            HabitDetailView(habit: habit, viewModel: viewModel)
        }
        .sheet(item: $editingHabit) { habit in
            HabitEditView(
                habit: habit,
                onSave: { updatedHabit in
                    viewModel.updateHabit(updatedHabit)
                    editingHabit = nil
                },
                onCancel: {
                    editingHabit = nil
                },
                onDelete: {
                    viewModel.deleteHabit(habit)
                    editingHabit = nil
                }
            )
        }
        .sheet(isPresented: $showCreateHabit) {
            HabitEditView(
                habit: nil,
                onSave: { newHabit in
                    viewModel.createHabit(newHabit)
                    showCreateHabit = false
                },
                onCancel: {
                    showCreateHabit = false
                }
            )
        }
    }

    // MARK: - Settings (no full chrome header)

    private var habitsSettingsBar: some View {
        HStack {
            Spacer(minLength: 0)
            HelpButton(pageType: .habits)
            Button {
                HapticManager.impact(style: .light)
                onSettings()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(kp.mutedNav)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    // MARK: - Daily protocol

    private var dailyProtocolSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Protocol")
                        .font(HabitsFonts.bold(11))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundStyle(kp.tertiary)

                    Text("Precision Focus")
                        .font(HabitsFonts.extraBold(30))
                        .foregroundStyle(kp.onSurface)
                        .kineticDisplayTracking(for: 30)
                        .minimumScaleFactor(0.85)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text("\(completionPercent)%")
                    .font(HabitsFonts.extraBold(24))
                    .tracking(-0.5)
                    .foregroundStyle(kp.primary)
            }
            .padding(.bottom, 16)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(kp.surfaceContainerHighest)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [kp.primaryContainer, kp.primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * CGFloat(viewModel.todayCompletionRate)))
                        .shadow(color: kp.primary.opacity(0.3), radius: 12, x: 0, y: 0)
                }
            }
            .frame(height: 12)

            HStack {
                Text("\(viewModel.todayCompletions) of \(viewModel.totalHabits) Complete")
                    .font(HabitsFonts.bold(10))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(kp.tertiary.opacity(0.6))

                Spacer()

                if viewModel.todayCompletionRate >= 1, viewModel.totalHabits > 0 {
                    Text("Target reached")
                        .font(HabitsFonts.bold(10))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundStyle(kp.tertiary.opacity(0.6))
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Bento

    private var bentoStatsSection: some View {
        HStack(alignment: .top, spacing: 16) {
            bentoCard(
                icon: "flame.fill",
                iconColor: kp.primary,
                label: "Current Streak",
                value: "\(bestCurrentStreak) Days",
                watermark: "bolt.fill"
            )
            .frame(maxWidth: .infinity)
            bentoCard(
                icon: "medal.fill",
                iconColor: kp.secondary,
                label: "Consistency",
                value: "\(consistencyPercent)%",
                watermark: "chart.line.uptrend.xyaxis"
            )
            .frame(maxWidth: .infinity)
        }
    }

    private func bentoCard(
        icon: String,
        iconColor: Color,
        label: String,
        value: String,
        watermark: String
    ) -> some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(iconColor)
                    .padding(.bottom, 8)

                Text(label)
                    .font(HabitsFonts.bold(10))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(kp.tertiary)

                Text(value)
                    .font(HabitsFonts.extraBold(24))
                    .foregroundStyle(kp.onSurface)
                    .kineticDisplayTracking(for: 24)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: watermark)
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(kp.onSurface.opacity(0.05))
                .offset(x: 12, y: 12)
        }
        .padding(20)
        .background(kp.surfaceContainerHighest)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    // MARK: - Today's execution

    private var todayExecutionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                Text("Today's Execution")
                    .font(HabitsFonts.bold(12))
                    .tracking(3.2)
                    .textCase(.uppercase)
                    .foregroundStyle(kp.tertiary.opacity(0.6))

                Rectangle()
                    .fill(kp.surfaceContainerHighest)
                    .frame(height: 1)
            }
            .padding(.bottom, 24)

            if viewModel.activeHabits.isEmpty {
                emptyHabitsPlaceholder
            } else {
                VStack(spacing: 16) {
                    ForEach(viewModel.activeHabits) { habit in
                        KineticHabitRow(
                            habit: habit,
                            viewModel: viewModel,
                            onTap: { selectedHabit = habit },
                            onComplete: {
                                viewModel.toggleCompletion(habitId: habit.id)
                            },
                            onEdit: { editingHabit = $0 },
                            onDelete: { viewModel.deleteHabit($0) }
                        )
                    }
                }
            }
        }
    }

    private var emptyHabitsPlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(kp.primary)
            Text("No habits yet")
                .font(HabitsFonts.bold(18))
                .foregroundStyle(kp.onSurface)
            Text("Add a habit to start your daily protocol.")
                .font(HabitsFonts.medium(13))
                .foregroundStyle(kp.onSurfaceVariant)
                .multilineTextAlignment(.center)
            Button {
                showCreateHabit = true
            } label: {
                Text("Add habit")
                    .font(HabitsFonts.semiBold(12))
                    .foregroundStyle(kp.primary)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(kp.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var footerMeta: some View {
        Text(nextResetLabel)
            .font(HabitsFonts.bold(10))
            .tracking(2)
            .textCase(.uppercase)
            .foregroundStyle(kp.tertiary.opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .padding(.vertical, 24)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(kp.outlineVariant.opacity(0.1))
                    .frame(height: 1)
            }
    }

    // MARK: - FAB

    private var fabButton: some View {
        Button {
            HapticManager.impact(style: .medium)
            showCreateHabit = true
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [kp.primaryContainer, kp.primary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: kp.primary.opacity(0.2), radius: 16, x: 0, y: 6)

                Image(systemName: "plus")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(kp.onPrimaryContainer)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add habit")
    }
}

// MARK: - Habit row

private struct KineticHabitRow: View {
    @Environment(\.kineticPalette) private var kp
    let habit: Habit
    @ObservedObject var viewModel: HabitViewModel
    let onTap: () -> Void
    let onComplete: () -> Void
    let onEdit: (Habit) -> Void
    let onDelete: (Habit) -> Void

    private var streak: Int {
        viewModel.getStreak(habitId: habit.id)
    }

    private var completedToday: Bool {
        viewModel.isCompleted(habitId: habit.id)
    }

    private var subtitle: String {
        "\(habit.completionDuration) min · daily focus"
    }

    var body: some View {
        HStack(spacing: 16) {
            Button {
                HapticManager.selection()
                onTap()
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(kp.surfaceContainerHighest)
                            .frame(width: 48, height: 48)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(kp.outlineVariant.opacity(0.1), lineWidth: 1)
                            )

                        Image(systemName: habit.icon)
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(completedToday ? kp.primary : kp.tertiary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.name)
                            .font(HabitsFonts.bold(17))
                            .foregroundStyle(kp.onSurface)
                            .lineLimit(1)

                        Text(subtitle)
                            .font(HabitsFonts.medium(12))
                            .foregroundStyle(kp.tertiary.opacity(0.8))
                    }

                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)
            .opacity(completedToday ? 1 : 0.7)

            HStack(spacing: 16) {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("\(streak)")
                        .font(HabitsFonts.bold(10))
                }
                .foregroundStyle(completedToday ? kp.primary : kp.tertiary)

                Button {
                    onComplete()
                } label: {
                    if completedToday {
                        ZStack {
                            Circle()
                                .fill(kp.primaryContainer)
                                .frame(width: 40, height: 40)
                                .shadow(color: kp.primary.opacity(0.2), radius: 8, x: 0, y: 4)

                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(kp.onPrimaryContainer)
                        }
                    } else {
                        Circle()
                            .strokeBorder(kp.primary.opacity(0.4), lineWidth: 2)
                            .frame(width: 40, height: 40)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(
            Group {
                if completedToday {
                    kp.surfaceContainerLow
                } else {
                    kp.surfaceContainerHighest.opacity(0.5)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    completedToday ? Color.clear : kp.outlineVariant.opacity(0.3),
                    style: StrokeStyle(
                        lineWidth: 1,
                        dash: completedToday ? [] : [6, 4]
                    )
                )
        )
        .contextMenu {
            Button("View") { onTap() }
            Button("Edit") { onEdit(habit) }
            Button("Delete", role: .destructive) { onDelete(habit) }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete(habit)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                onEdit(habit)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(kp.primaryContainer)
        }
    }
}

#Preview {
    HabitsView()
        .environmentObject(ColorThemeProvider.shared)
}
