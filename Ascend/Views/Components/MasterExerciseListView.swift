import SwiftUI

// MARK: - Exercise database (HTML wireframe: Exercises screen)

struct MasterExerciseListView: View {
    @ObservedObject private var exRxManager = ExRxDirectoryManager.shared
    @ObservedObject private var exerciseDataManager = ExerciseDataManager.shared
    @ObservedObject var progressViewModel: ProgressViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.kineticPalette) private var kp

    @State private var searchText: String = ""
    @State private var selectedChip: ExerciseLibraryChip = .all
    @State private var selectedEquipmentFilter: String? = nil
    @State private var exerciseToEdit: ExRxExercise?
    @State private var showEditSheet = false
    @State private var exerciseToDelete: ExRxExercise?
    @State private var showDeleteConfirmation = false
    @State private var detailExercise: ExRxExercise?
    @State private var showAddCustomExercise = false

    private enum ExerciseLibraryChip: String, CaseIterable {
        case all = "All"
        case chest = "Chest"
        case back = "Back"
        case legs = "Legs"
        case shoulders = "Shoulders"
        case core = "Core"

        var category: ExRxCategory? {
            switch self {
            case .all: return nil
            case .chest: return .chest
            case .back: return .back
            case .legs: return .legs
            case .shoulders: return .shoulders
            case .core: return .core
            }
        }
    }

    private static let equipmentOptions: [String] = [
        "Barbell", "Dumbbell", "Cable", "Machine", "Bodyweight", "Kettlebell", "Band", "EZ Bar", "Smith Machine"
    ]

    private var filteredExercises: [ExRxExercise] {
        var exercises = exRxManager.getAllExercises()

        if !searchText.isEmpty {
            exercises = exercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                    exercise.category.localizedCaseInsensitiveContains(searchText) ||
                    exercise.muscleGroup.localizedCaseInsensitiveContains(searchText) ||
                    (exercise.equipment?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        if let cat = selectedChip.category {
            exercises = exercises.filter { $0.category == cat.rawValue }
        }

        if let equip = selectedEquipmentFilter {
            exercises = exercises.filter { ex in
                guard let e = ex.equipment, !e.isEmpty else { return false }
                return e.localizedCaseInsensitiveContains(equip) || e.caseInsensitiveCompare(equip) == .orderedSame
            }
        }

        return exercises.sorted { $0.name < $1.name }
    }

    var body: some View {
        ZStack(alignment: .top) {
            kp.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear.frame(height: 72)

                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        exerciseGridSection
                        bentoSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .scrollIndicators(.hidden)

            topBar
        }
        .sheet(isPresented: $showEditSheet) {
            if let exercise = exerciseToEdit {
                EditExerciseSheet(
                    exercise: exercise,
                    onSave: { updatedExercise in
                        exRxManager.updateImportedExercise(updatedExercise)
                        showEditSheet = false
                    },
                    onCancel: {
                        showEditSheet = false
                    }
                )
            }
        }
        .sheet(item: $detailExercise) { ex in
            ExerciseDatabaseDetailSheet(
                exercise: ex,
                isImported: exRxManager.isImportedExercise(ex),
                onEdit: {
                    detailExercise = nil
                    exerciseToEdit = ex
                    showEditSheet = true
                },
                onDelete: {
                    detailExercise = nil
                    exerciseToDelete = ex
                    showDeleteConfirmation = true
                }
            )
        }
        .sheet(isPresented: $showAddCustomExercise) {
            AddCustomExerciseView { exercise in
                exerciseDataManager.addCustomExercise(exercise)
            }
        }
        .alert("Delete Exercise", isPresented: $showDeleteConfirmation, presenting: exerciseToDelete) { exercise in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                exRxManager.deleteImportedExercise(exercise)
                HapticManager.success()
            }
        } message: { exercise in
            Text("Are you sure you want to delete '\(exercise.name)'? This action cannot be undone.")
        }
    }

    // MARK: - Top bar (HTML: profile + Performance + settings)

    private var topBar: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(kp.surfaceContainerHighest)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(Color.white.opacity(0.05), lineWidth: 1))
                Image(systemName: "person.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(kp.tertiary)
            }
            Text("Performance")
                .font(KineticWorkoutTypography.bold(18))
                .tracking(-0.5)
                .foregroundStyle(kp.primaryContainer)

            Spacer(minLength: 0)

            Button {
                HapticManager.selection()
                dismiss()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(kp.mutedChrome.opacity(0.85))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background {
            ZStack {
                kp.background.opacity(0.82)
                Rectangle().fill(.ultraThinMaterial)
            }
            .shadow(color: .white.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Search + filters + chips

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Exercises")
                .font(KineticWorkoutTypography.extraBold(34))
                .foregroundStyle(kp.onSurface)
                .tracking(-0.8)

            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    HStack(spacing: 0) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(kp.outline)
                            .padding(.leading, 16)
                        TextField("Search movements...", text: $searchText)
                            .font(KineticWorkoutTypography.medium(16))
                            .foregroundStyle(kp.onSurface)
                            .padding(.vertical, 16)
                            .padding(.trailing, 12)
                    }
                    .background(kp.surfaceContainerLow)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    HStack(spacing: 8) {
                        bodyPartMenuButton
                        equipmentMenuButton
                    }
                }

                chipRow
            }
        }
        .padding(.bottom, 8)
    }

    private var exerciseGridColumns: [GridItem] {
        if horizontalSizeClass == .regular {
            return [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
        }
        return [GridItem(.flexible(), spacing: 16)]
    }

    private var bodyPartMenuButton: some View {
        Menu {
            Button("All body parts") {
                selectedChip = .all
                HapticManager.selection()
            }
            ForEach(ExerciseLibraryChip.allCases.filter { $0 != .all }, id: \.self) { chip in
                Button(chip.rawValue) {
                    selectedChip = chip
                    HapticManager.selection()
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 16, weight: .medium))
                Text("Body Part")
                    .font(KineticWorkoutTypography.semiBold(13))
            }
            .foregroundStyle(kp.onSurface)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(kp.surfaceContainerHighest)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var equipmentMenuButton: some View {
        Menu {
            Button("All equipment") {
                selectedEquipmentFilter = nil
                HapticManager.selection()
            }
            ForEach(Self.equipmentOptions, id: \.self) { opt in
                Button(opt) {
                    selectedEquipmentFilter = opt
                    HapticManager.selection()
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Equipment")
                    .font(KineticWorkoutTypography.semiBold(13))
            }
            .foregroundStyle(kp.onSurface)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(kp.surfaceContainerHighest)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var chipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ExerciseLibraryChip.allCases, id: \.self) { chip in
                    let isOn = selectedChip == chip
                    Button {
                        selectedChip = chip
                        HapticManager.selection()
                    } label: {
                        Text(chip.rawValue.uppercased())
                            .font(KineticWorkoutTypography.bold(11))
                            .tracking(1.2)
                            .foregroundStyle(isOn ? kp.onPrimaryContainer : kp.tertiary.opacity(0.75))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isOn ? kp.primaryContainer : kp.surfaceContainerHighest)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Grid

    private var exerciseGridSection: some View {
        Group {
            if filteredExercises.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(kp.outline)
                    Text("No exercises found")
                        .font(KineticWorkoutTypography.semiBold(18))
                        .foregroundStyle(kp.onSurface)
                    Text("Try adjusting search or filters")
                        .font(KineticWorkoutTypography.medium(14))
                        .foregroundStyle(kp.outline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
            } else {
                LazyVGrid(
                    columns: exerciseGridColumns,
                    spacing: 16
                ) {
                    ForEach(Array(filteredExercises.enumerated()), id: \.element.id) { index, exercise in
                        ExerciseDatabaseKineticCard(
                            exercise: exercise,
                            exerciseIndex: index,
                            progressViewModel: progressViewModel,
                            onDetails: {
                                detailExercise = exercise
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Bento

    private var bentoSection: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 16) {
                knowledgeHubCard
                    .frame(maxWidth: .infinity)
                createCustomCard
                    .frame(maxWidth: .infinity)
                    .layoutPriority(0)
            }
            VStack(spacing: 16) {
                knowledgeHubCard
                createCustomCard
            }
        }
        .padding(.top, 8)
    }

    private var knowledgeHubCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Knowledge Hub")
                .font(KineticWorkoutTypography.bold(12))
                .tracking(3.2)
                .textCase(.uppercase)
                .foregroundStyle(kp.outline)
            Text("Optimizing the Eccentric Phase for Hypertrophy")
                .font(KineticWorkoutTypography.bold(18))
                .foregroundStyle(kp.onSurface)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 12)
            HStack {
                HStack(spacing: -8) {
                    Circle()
                        .fill(kp.primaryContainer.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 14))
                                .foregroundStyle(kp.onPrimaryContainer)
                        )
                        .overlay(Circle().stroke(kp.surfaceContainerLow, lineWidth: 2))
                    ZStack {
                        Circle()
                            .fill(kp.primaryContainer)
                            .frame(width: 32, height: 32)
                        Text("DR")
                            .font(KineticWorkoutTypography.bold(10))
                            .foregroundStyle(kp.onPrimaryContainer)
                    }
                    .overlay(Circle().stroke(kp.surfaceContainerLow, lineWidth: 2))
                }
                Spacer()
                Button {
                    HapticManager.selection()
                } label: {
                    HStack(spacing: 4) {
                        Text("Read Guide")
                            .font(KineticWorkoutTypography.bold(11))
                            .tracking(2)
                            .textCase(.uppercase)
                        Image(systemName: "arrow.forward")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(kp.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .background(kp.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    private var createCustomCard: some View {
        Button {
            HapticManager.impact(style: .light)
            showAddCustomExercise = true
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(kp.onPrimaryContainer)
                Text("Create Custom Exercise")
                    .font(KineticWorkoutTypography.bold(17))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(kp.onPrimaryContainer)
                Text("Add unique movements to your precision library")
                    .font(KineticWorkoutTypography.medium(12))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(kp.onPrimaryContainer.opacity(0.72))
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(
            LinearGradient(
                colors: [kp.primaryContainer, kp.secondaryContainer],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Card

private struct ExerciseDatabaseKineticCard: View {
    let exercise: ExRxExercise
    let exerciseIndex: Int
    @ObservedObject var progressViewModel: ProgressViewModel
    let onDetails: () -> Void
    @Environment(\.kineticPalette) private var kp

    private var prLabelColor: Color {
        exerciseIndex % 2 == 0 ? kp.primary : kp.secondary
    }

    private var prs: [PersonalRecord] {
        progressViewModel.prsForExercise(exercise.name)
    }

    private var currentPR: PersonalRecord? {
        prs.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                exerciseThumbnail
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(KineticWorkoutTypography.bold(17))
                        .foregroundStyle(kp.onSurface)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    Text(subtitleLine)
                        .font(KineticWorkoutTypography.bold(11))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundStyle(kp.outline)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                prColumn
            }

            HStack(alignment: .bottom) {
                trendPill
                Spacer(minLength: 8)
                Button {
                    HapticManager.impact(style: .light)
                    onDetails()
                } label: {
                    Text("Details")
                        .font(KineticWorkoutTypography.bold(12))
                        .foregroundStyle(kp.onPrimaryContainer)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(kp.primaryContainer)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 20)
        }
        .padding(16)
        .background(kp.surfaceContainerHighest)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(kp.primary.opacity(0.05))
                .frame(width: 96, height: 96)
                .blur(radius: 28)
                .offset(x: 16, y: 16)
                .allowsHitTesting(false)
        }
    }

    private var subtitleLine: String {
        let equip = exercise.equipment?.isEmpty == false ? exercise.equipment! : "Bodyweight"
        return "\(exercise.muscleGroup) • \(equip)"
    }

    private var prColumn: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("Current PR")
                .font(KineticWorkoutTypography.bold(10))
                .tracking(-0.5)
                .textCase(.uppercase)
                .foregroundStyle(prLabelColor)
            if let pr = currentPR {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(formatWeight(pr.weight))
                        .font(KineticWorkoutTypography.extraBold(26))
                        .foregroundStyle(kp.onSurface)
                        .tracking(-1)
                    Text("lbs")
                        .font(KineticWorkoutTypography.medium(14))
                        .foregroundStyle(kp.outline)
                }
            } else {
                Text("—")
                    .font(KineticWorkoutTypography.extraBold(22))
                    .foregroundStyle(kp.outline)
            }
        }
    }

    private func formatWeight(_ w: Double) -> String {
        let rounded = (w * 10).rounded() / 10
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", rounded)
        }
        return String(format: "%.1f", rounded)
    }

    private var trendPill: some View {
        HStack(spacing: 6) {
            Image(systemName: trendIconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(trendIconColor)
            (Text(trendMain)
                .font(KineticWorkoutTypography.bold(12))
                .foregroundStyle(kp.onSurface)
            + Text(" \(trendSub)")
                .font(KineticWorkoutTypography.medium(12))
                .foregroundStyle(kp.outline))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(kp.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var trendIconName: String {
        if prs.isEmpty { return "minus" }
        let trend = progressViewModel.calculateTrend(for: exercise.name, using: prs)
        switch trend {
        case .improving: return "chart.line.uptrend.xyaxis"
        case .stable: return "equal"
        case .declining: return "chart.line.downtrend.xyaxis"
        case .new: return "sparkles"
        }
    }

    private var trendIconColor: Color {
        if prs.isEmpty { return kp.outline }
        let trend = progressViewModel.calculateTrend(for: exercise.name, using: prs)
        switch trend {
        case .improving: return kp.primary
        case .stable: return kp.outline
        case .declining: return AppColors.destructive
        case .new: return kp.secondary
        }
    }

    private var trendMain: String {
        if prs.isEmpty { return "No PR" }
        if let pr = currentPR, let delta = progressViewModel.weightDeltaFromPreviousPR(for: pr), delta > 0 {
            return "+\(delta) lbs"
        }
        if let pct = monthPercentChange() {
            return String(format: "+%.1f%%", pct)
        }
        let trend = progressViewModel.calculateTrend(for: exercise.name, using: prs)
        switch trend {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Down"
        case .new: return "New"
        }
    }

    private var trendSub: String {
        if prs.isEmpty { return "yet" }
        if currentPR != nil, progressViewModel.weightDeltaFromPreviousPR(for: prs[0]) != nil {
            return "last session"
        }
        if monthPercentChange() != nil {
            return "this month"
        }
        return "volume"
    }

    private func monthPercentChange() -> Double? {
        guard prs.count >= 2 else { return nil }
        let cal = Calendar.current
        let now = Date()
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)),
              let prevMonthStart = cal.date(byAdding: .month, value: -1, to: monthStart) else { return nil }
        let thisMonth = prs.filter { $0.date >= monthStart }
        let lastMonth = prs.filter { $0.date >= prevMonthStart && $0.date < monthStart }
        guard let bestThis = thisMonth.map({ $0.weight * Double($0.reps) }).max(),
              let bestLast = lastMonth.map({ $0.weight * Double($0.reps) }).max(),
              bestLast > 0 else { return nil }
        let pct = ((bestThis - bestLast) / bestLast) * 100
        return pct > 0.5 ? pct : nil
    }

    private var exerciseThumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(kp.surfaceContainerLow)
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(kp.tertiary.opacity(0.6))
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Detail sheet

private struct ExerciseDatabaseDetailSheet: View {
    let exercise: ExRxExercise
    let isImported: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.kineticPalette) private var kp

    var body: some View {
        NavigationStack {
            ZStack {
                kp.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(exercise.name)
                            .font(KineticWorkoutTypography.extraBold(24))
                            .foregroundStyle(kp.onSurface)
                        detailRow("Category", exercise.category)
                        detailRow("Muscle group", exercise.muscleGroup)
                        if let equipment = exercise.equipment, !equipment.isEmpty {
                            detailRow("Equipment", equipment)
                        }
                        if let alts = exercise.alternatives, !alts.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Alternatives")
                                    .font(KineticWorkoutTypography.bold(12))
                                    .foregroundStyle(kp.outline)
                                Text(alts.joined(separator: ", "))
                                    .font(KineticWorkoutTypography.medium(15))
                                    .foregroundStyle(kp.onSurface)
                            }
                        }
                        if let url = exercise.url, let link = URL(string: url) {
                            Link("View on ExRx", destination: link)
                                .font(KineticWorkoutTypography.semiBold(15))
                                .foregroundStyle(kp.primary)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(kp.primary)
                }
                if isImported {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Edit") {
                            onEdit()
                        }
                        .foregroundStyle(kp.primary)
                    }
                }
            }
        }
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(KineticWorkoutTypography.bold(11))
                .tracking(1.6)
                .foregroundStyle(kp.outline)
            Text(value)
                .font(KineticWorkoutTypography.semiBold(16))
                .foregroundStyle(kp.onSurface)
        }
    }
}

struct EditExerciseSheet: View {
    let exercise: ExRxExercise
    let onSave: (ExRxExercise) -> Void
    let onCancel: () -> Void

    @State private var name: String
    @State private var category: String
    @State private var muscleGroup: String
    @State private var equipment: String
    @State private var alternatives: String

    init(exercise: ExRxExercise, onSave: @escaping (ExRxExercise) -> Void, onCancel: @escaping () -> Void) {
        self.exercise = exercise
        self.onSave = onSave
        self.onCancel = onCancel
        _name = State(initialValue: exercise.name)
        _category = State(initialValue: exercise.category)
        _muscleGroup = State(initialValue: exercise.muscleGroup)
        _equipment = State(initialValue: exercise.equipment ?? "")
        _alternatives = State(initialValue: (exercise.alternatives ?? []).joined(separator: ", "))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Exercise Details")) {
                    TextField("Exercise Name", text: $name)

                    Picker("Category", selection: $category) {
                        ForEach(ExRxCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat.rawValue)
                        }
                    }

                    Picker("Muscle Group", selection: $muscleGroup) {
                        ForEach(ExRxMuscleGroup.allCases, id: \.self) { mg in
                            Text(mg.rawValue).tag(mg.rawValue)
                        }
                    }

                    TextField("Equipment (optional)", text: $equipment)

                    TextField("Alternatives (comma-separated)", text: $alternatives)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let alternativesArray = alternatives
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }

                        let updatedExercise = ExRxExercise(
                            id: exercise.id,
                            name: name,
                            category: category,
                            muscleGroup: muscleGroup,
                            equipment: equipment.isEmpty ? nil : equipment,
                            url: exercise.url,
                            alternatives: alternativesArray.isEmpty ? nil : alternativesArray
                        )

                        onSave(updatedExercise)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    MasterExerciseListView(progressViewModel: ProgressViewModel())
}
