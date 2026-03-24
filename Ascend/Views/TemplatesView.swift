//
//  TemplatesView.swift
//  Ascend
//
//  Templates tab — `AppConstants.UI.mainColumnGutter`, shared main column with Studio/Habits, pill segments,
//  search + filter (sort in filter sheet), single-column bento on iPhone, 2-col + featured on iPad-regular.
//

import SwiftUI

// MARK: - Template hero imagery (colors: `Environment.kineticPalette`)

private enum KineticTemplateHeroAssets {
    static let bentoHeroURLs: [URL] = [
        URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuAyi-5GQkDrYKkqarxzqohNlvjKX04_fIQjltfj4qmx4hgIU5Z-yr_WW-q4snui9k4Jgq51TALvpTAWDk3EBgmfNJq1T-fMaDhl9k3tS8q4LkH4jVcUmbSqIxdwZ3-DxMAUOW5tiMr9x_BaA0gcavChWO3rXCalVikBSopaQYuhkNo9YSSe6uHFY9wMazgBwKOW7oZY_WSLBT5ePQR6DV7FIZZ4HJeCcSccuo9mQXYOmsSWAY7o1s-4FSk7op4hxkuNrPIxVIvdjWk")!,
        URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuBv1Ojoap9va9wu45AOT7XQOJ9vvF_hNfNLvvHx1OVi-5eaeUWzs92dqIOE9eRwVcoP79PiFa1B4m9jFWRwM-sOedr7NWPI8coq0LMKP7adAlGl0fpY2tso2l43sv_LHJ0Bm381jp7WxK3yd2LFwton1G1x_vtnKLK1PWnCEtjBL2SOgG_415dmHIBLjZxUrxUcgTXgXGmb2uBiJEJ8YsuEIV-PvbuyC6-9YBiiHtml-k93u85OTz3pJVvhUZKGaRZ_L8-69bfeFEU")!,
        URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuBUtkAsUm0i15Gyje-CgFcm0_Wihy72LhtPduUnNndKnSxPVuT8WfGHij5fP45KL6_iMVe7A2r0geK6doViAtHay5kJO60iabQkn8phroGZYyTzlB7iU5lME-cVUc3WqdyrytaTXTa8QyQJfJKFtYWA7hzSnDtZmnmeC1Df8dS9gqZjtMeAbLXebNKIH3J9LDat7_L43BnC-tFd0uylXGT4V6FxdQ6uiJYrVnGj8y1RtBe04fe6qFKi2oAnENfTDAD0c9fYmkrAdxw")!
    ]
}

private enum TemplateKineticFonts {
    static func extraBold(_ size: CGFloat) -> Font { Font.custom("Manrope-ExtraBold", size: size, relativeTo: .body) }
    static func bold(_ size: CGFloat) -> Font { Font.custom("Manrope-Bold", size: size, relativeTo: .body) }
    static func semiBold(_ size: CGFloat) -> Font { Font.custom("Manrope-SemiBold", size: size, relativeTo: .body) }
    static func medium(_ size: CGFloat) -> Font { Font.custom("Manrope-Medium", size: size, relativeTo: .body) }
}

private enum KineticTemplateLayout {
    static var contentColumnMaxWidth: CGFloat { AppConstants.UI.mainColumnMaxWidth }
    static var horizontalPadding: CGFloat { AppConstants.UI.mainColumnGutter }
    /// Segment strip: `max-w-md` (28rem ≈ 448pt).
    static let segmentStripMaxWidth: CGFloat = 448
}

/// Example program strip — full-bleed hero cards (hero + gradient + chips).
private enum ExampleProgramCardVisual {
    static let corner: CGFloat = 32
    static let height: CGFloat = 268
    static let cardWidth: CGFloat = 300
    static let secondaryContainer = Color(hex: "2a4c65")
    static let surfaceContainerHigh = Color(hex: "2a2a2a")
    static let surfaceContainerHighest = Color(hex: "353535")
    static let chipPrimary = Color(hex: "9cd0d3")
}

struct TemplatesView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.kineticPalette) private var kp
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    @ObservedObject var viewModel: TemplatesViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var progressViewModel: ProgressViewModel
    let onStartTemplate: () -> Void
    let onSettings: () -> Void
    
    // State
    @State private var showGenerateSheet = false
    @State private var showCalisthenicProgression = false
    @State private var searchText: String = ""
    @State private var debouncedSearchText: String = ""
    @State private var debounceTask: Task<Void, Never>?
    @State private var sortOption: TemplateLibrarySortOption = .name
    @State private var showFilterSheet = false
    @State private var filters = TemplateFilters()
    @State private var selectedSegment: ContentSegment = .templates
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var isMultiSelectMode = false
    @State private var selectedTemplates: Set<UUID> = []
    @State private var showCreateProgramFromCatalog = false
    @State private var selectedExampleProgram: WorkoutProgram?
    
    // Performance: Cache filtered templates
    @State private var cachedFilteredTemplates: [WorkoutTemplate] = []
    @State private var lastFilterCacheKey: String = ""
    
    enum ContentSegment: String, CaseIterable {
        case programs = "Programs"
        case skills = "Skills"
        case templates = "Templates"
    }
    
    private var filteredTemplates: [WorkoutTemplate] {
        // Create cache key based on inputs
        let filterKey = createFilterCacheKey(filters)
        let cacheKey = "\(debouncedSearchText)-\(filterKey)-\(sortOption.rawValue)-\(viewModel.templates.count)"
        
        // Return cached if key matches
        if cacheKey == lastFilterCacheKey && !cachedFilteredTemplates.isEmpty {
            return cachedFilteredTemplates
        }
        
        // Compute filtered templates
        let filtered = viewModel.templates.filter { template in
            if template.name.contains("Progression") { return false }
            
            // Apply search filter
            if !debouncedSearchText.isEmpty {
                let matchesSearch = template.name.localizedCaseInsensitiveContains(debouncedSearchText) ||
                       template.exercises.contains { $0.name.localizedCaseInsensitiveContains(debouncedSearchText) }
                if !matchesSearch { return false }
            }
            
            // Apply custom filters
            if filters.isActive {
                return filters.matches(template)
            }
            
            return true
        }
        let sorted = sortOption.sorted(filtered)
        
        // Cache the result
        cachedFilteredTemplates = sorted
        lastFilterCacheKey = cacheKey
        
        return sorted
    }
    
    private func detectMuscleGroup(_ exerciseName: String) -> String {
        let name = exerciseName.lowercased()
        if name.contains("chest") || name.contains("bench") || name.contains("press") { return "Chest" }
        if name.contains("back") || name.contains("row") || name.contains("pull") { return "Back" }
        if name.contains("leg") || name.contains("squat") || name.contains("deadlift") { return "Legs" }
        if name.contains("bicep") || name.contains("tricep") || name.contains("arm") { return "Arms" }
        if name.contains("core") || name.contains("ab") || name.contains("plank") { return "Core" }
        if name.contains("cardio") || name.contains("run") { return "Cardio" }
        return "General"
    }
    
    private func kineticIntensityLabel(for intensity: WorkoutIntensity?) -> String {
        switch intensity {
        case .some(.extreme), .some(.intense): return "High Intensity"
        case .some(.moderate): return "Technical"
        case .some(.light), .none: return "Foundation"
        }
    }
    
    /// Bundled `WorkoutProgramManager` cards — hero image, gradient, and chip row.
    private func kineticExampleProgramCard(_ program: WorkoutProgram, heroIndex: Int) -> some View {
        ZStack(alignment: .bottomLeading) {
            exampleProgramHeroImage(url: bentoHeroURL(at: heroIndex))
                .overlay {
                    LinearGradient(
                        colors: [
                            .black.opacity(0.92),
                            .black.opacity(0.55),
                            .clear
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 8) {
                    Text("\(program.days.count) \(program.days.count == 1 ? "DAY" : "DAYS")")
                        .font(TemplateKineticFonts.bold(10))
                        .tracking(1.6)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(ExampleProgramCardVisual.chipPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(ExampleProgramCardVisual.chipPrimary.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(ExampleProgramCardVisual.chipPrimary.opacity(0.25), lineWidth: 1)
                        )
                    Text(program.category.rawValue.uppercased())
                        .font(TemplateKineticFonts.bold(10))
                        .tracking(1.6)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                }
                Text(program.name)
                    .font(TemplateKineticFonts.extraBold(22))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .multilineTextAlignment(.leading)
                Text(program.description)
                    .font(TemplateKineticFonts.medium(14))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
        }
        .frame(width: ExampleProgramCardVisual.cardWidth, height: ExampleProgramCardVisual.height)
        .clipShape(RoundedRectangle(cornerRadius: ExampleProgramCardVisual.corner, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: ExampleProgramCardVisual.corner, style: .continuous))
    }
    
    private func exampleProgramHeroImage(url: URL) -> some View {
        SwiftUI.AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                LinearGradient(
                    colors: [ExampleProgramCardVisual.secondaryContainer, ExampleProgramCardVisual.surfaceContainerHigh],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .empty:
                ExampleProgramCardVisual.surfaceContainerHighest
            @unknown default:
                ExampleProgramCardVisual.surfaceContainerHighest
            }
        }
        .frame(height: ExampleProgramCardVisual.height)
        .frame(maxWidth: .infinity)
        .clipped()
    }
    
    private func bentoHeroURL(at index: Int) -> URL {
        KineticTemplateHeroAssets.bentoHeroURLs[index % KineticTemplateHeroAssets.bentoHeroURLs.count]
    }
    
    private var useWideTemplateGrid: Bool {
        horizontalSizeClass == .regular
    }
    
    @ViewBuilder
    private func kineticTemplateCard(
        _ template: WorkoutTemplate,
        index: Int,
        featured: Bool,
        showEditorialMetric: Bool
    ) -> some View {
        TemplateBentoCard(
            template: template,
            heroURL: bentoHeroURL(at: index),
            isFeatured: featured,
            showEditorialMetric: showEditorialMetric,
            muscleFocus: detectMuscleGroup(template.exercises.first?.name ?? "General"),
            intensityLabel: kineticIntensityLabel(for: template.intensity),
            isMultiSelectMode: isMultiSelectMode,
            isSelected: selectedTemplates.contains(template.id),
            onTapCard: {
                if isMultiSelectMode {
                    toggleSelection(template)
                } else {
                    selectedTemplate = template
                    HapticManager.impact(style: .light)
                }
            },
            onPlay: {
                viewModel.startTemplate(template, workoutViewModel: workoutViewModel)
                HapticManager.impact(style: .medium)
                onStartTemplate()
            },
            onEdit: { viewModel.editTemplate(template) },
            onDuplicate: { duplicateTemplate(template) },
            onDelete: template.isDefault ? nil : {
                viewModel.deleteTemplate(template, progressViewModel: progressViewModel)
            }
        )
    }
    
    /// Subtitle under the fixed “Templates” headline — varies slightly by segment.
    private var kineticTitleSubtitle: String {
        switch selectedSegment {
        case .programs:
            return "Curated protocols for strength, conditioning, and recovery."
        case .skills, .templates:
            return "Streamline your performance with engineered routines."
        }
    }

    private var kineticTitleBlock: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Templates")
                    .font(TemplateKineticFonts.extraBold(34))
                    .foregroundStyle(kp.onSurface)
                    .tracking(-0.8)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .accessibilityAddTraits(.isHeader)
                Text(kineticTitleSubtitle)
                    .font(TemplateKineticFonts.medium(14))
                    .foregroundStyle(kp.tertiary.opacity(0.7))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            HStack(spacing: 4) {
                HelpButton(pageType: .templates)
                if selectedSegment == .templates {
                    Menu {
                        Button {
                            showGenerateSheet = true
                        } label: {
                            Label("Generate workout", systemImage: "sparkles")
                        }
                        Button {
                            viewModel.showGenerationSettings = true
                        } label: {
                            Label("Generation settings", systemImage: "slider.horizontal.3")
                        }
                        if !filteredTemplates.isEmpty {
                            Button {
                                isMultiSelectMode = true
                                HapticManager.impact(style: .light)
                            } label: {
                                Label("Select templates", systemImage: "checkmark.circle")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 22))
                            .foregroundStyle(kp.mutedChrome.opacity(0.65))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Templates menu")
                }
                Button(action: onSettings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 22))
                        .foregroundStyle(kp.mutedChrome.opacity(0.65))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }
        }
    }
    
    /// Wireframe: `nav` — `p-1`, `gap-1`, `rounded-full`, `max-w-md mx-auto`, selected pill `rounded-full` + `bg-primary-container` + `text-on-primary-container`.
    private var kineticSegmentStrip: some View {
        HStack(spacing: 4) {
            ForEach(ContentSegment.allCases, id: \.self) { segment in
                let isSelected = selectedSegment == segment
                Button {
                    selectedSegment = segment
                    HapticManager.selection()
                } label: {
                    Text(segment.rawValue.uppercased())
                        .font(TemplateKineticFonts.bold(11))
                        .tracking(1.2)
                        .foregroundStyle(
                            isSelected
                                ? kp.onPrimaryContainer
                                : kp.onSurfaceVariant.opacity(0.85)
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Group {
                                if isSelected {
                                    Capsule()
                                        .fill(kp.primaryContainer)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(kp.surfaceContainerLow)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(kp.outlineVariant.opacity(0.12), lineWidth: 1)
        )
        .frame(maxWidth: KineticTemplateLayout.segmentStripMaxWidth)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Content segment")
    }
    
    /// AI generation — same chrome as Skills **Create custom skill** (capsule outline).
    private var kineticAutoGenerateCTA: some View {
        Button {
            showGenerateSheet = true
            HapticManager.impact(style: .medium)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                Text("AUTO-GENERATE")
                    .font(TemplateKineticFonts.bold(11))
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
        .accessibilityLabel("Auto-generate workout")
        .accessibilityHint("Opens workout generation")
    }
    
    private var kineticSearchRow: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 0) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(kp.outline)
                    .frame(width: 44)
                    .accessibilityHidden(true)
                TextField("Search precision routines...", text: $searchText)
                    .font(TemplateKineticFonts.medium(14))
                    .foregroundStyle(kp.onSurface)
                    .accessibilityLabel("Search templates")
                    .lineLimit(1)
                    .onChange(of: searchText) { _, newValue in
                        debounceTask?.cancel()
                        debounceTask = Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            if !Task.isCancelled {
                                debouncedSearchText = newValue
                            }
                        }
                    }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        debouncedSearchText = ""
                        HapticManager.selection()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(kp.onSurfaceVariant.opacity(0.6))
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.leading, 4)
            .padding(.trailing, 12)
            .padding(.vertical, 16)
            .background(kp.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            Button {
                showFilterSheet = true
                HapticManager.impact(style: .light)
            } label: {
                ZStack {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(kp.onSurfaceVariant)
                    if filters.isActive {
                        Circle()
                            .fill(Color.red.opacity(0.9))
                            .frame(width: 8, height: 8)
                            .offset(x: 11, y: -11)
                    }
                }
                .frame(width: 56, height: 56)
                .background(kp.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Filters and sort")
            .accessibilityHint("Opens filters and sort options")
        }
    }
    
    @ViewBuilder
    private var kineticTemplatesBentoSection: some View {
        let list = filteredTemplates
        if list.isEmpty {
            kineticEmptyState
        } else if useWideTemplateGrid {
            wideTemplatesBento(list)
        } else {
            compactTemplatesBento(list)
        }
    }
    
    @ViewBuilder
    private func compactTemplatesBento(_ list: [WorkoutTemplate]) -> some View {
        VStack(spacing: 24) {
            ForEach(Array(list.enumerated()), id: \.element.id) { index, template in
                let featured = index == 2 && list.count >= 3
                kineticTemplateCard(template, index: index, featured: featured, showEditorialMetric: false)
            }
        }
    }
    
    @ViewBuilder
    private func wideTemplatesBento(_ list: [WorkoutTemplate]) -> some View {
        VStack(spacing: 24) {
            if list.count >= 2 {
                HStack(alignment: .top, spacing: 24) {
                    kineticTemplateCard(list[0], index: 0, featured: false, showEditorialMetric: false)
                    kineticTemplateCard(list[1], index: 1, featured: false, showEditorialMetric: false)
                }
            } else if list.count == 1 {
                kineticTemplateCard(list[0], index: 0, featured: false, showEditorialMetric: false)
            }
            if list.count >= 3 {
                kineticTemplateCard(list[2], index: 2, featured: true, showEditorialMetric: true)
            }
            if list.count > 3 {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 24),
                        GridItem(.flexible(), spacing: 24)
                    ],
                    spacing: 24
                ) {
                    ForEach(Array(list.dropFirst(3).enumerated()), id: \.element.id) { offset, template in
                        kineticTemplateCard(template, index: offset + 3, featured: false, showEditorialMetric: false)
                    }
                }
            }
        }
    }
    
    private var kineticEmptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(kp.outline)
            Text("No templates found")
                .font(TemplateKineticFonts.bold(20))
                .foregroundStyle(kp.onSurface)
            Text("Refine your search parameters or construct a new protocol from scratch.")
                .font(TemplateKineticFonts.medium(14))
                .foregroundStyle(kp.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            Button {
                showGenerateSheet = true
                HapticManager.impact(style: .medium)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                    Text("AUTO-GENERATE")
                        .font(TemplateKineticFonts.bold(11))
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
            .accessibilityLabel("Auto-generate workout")
            Button {
                viewModel.createTemplate()
                HapticManager.impact(style: .medium)
            } label: {
                Text("Create Template")
                    .font(TemplateKineticFonts.bold(12))
                    .tracking(2)
                    .foregroundStyle(kp.primary)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(kp.secondaryContainer.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(kp.outlineVariant.opacity(0.25), lineWidth: 1)
                    )
            }
            .accessibilityLabel("Create template")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 24)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                .foregroundStyle(kp.outlineVariant.opacity(0.35))
        )
    }
    
    /// Same chrome as the template FAB — used for Templates (create template), Programs (create program), Skills (custom skill).
    private func kineticPlusFAB(action: @escaping () -> Void, accessibilityLabel: String) -> some View {
        Button {
            action()
            HapticManager.impact(style: .medium)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "284b63"), kp.primaryContainer],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: kp.primaryContainer.opacity(0.45), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
    
    @ViewBuilder
    private var kineticSegmentBody: some View {
        switch selectedSegment {
        case .programs:
            VStack(alignment: .leading, spacing: 32) {
                if !WorkoutProgramManager.shared.programs.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("EXAMPLE PROGRAMS")
                                .font(TemplateKineticFonts.bold(10))
                                .tracking(2)
                                .foregroundStyle(kp.primary)
                            Spacer(minLength: 0)
                        }
                        Text("Open full schedules and start workouts from bundled plans.")
                            .font(TemplateKineticFonts.medium(13))
                            .foregroundStyle(kp.onSurfaceVariant)
                            .fixedSize(horizontal: false, vertical: true)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 24) {
                                ForEach(Array(WorkoutProgramManager.shared.programs.enumerated()), id: \.element.id) { index, program in
                                    Button {
                                        selectedExampleProgram = program
                                        HapticManager.impact(style: .light)
                                    } label: {
                                        kineticExampleProgramCard(program, heroIndex: index)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Open \(program.name)")
                                }
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("YOUR PROGRAMS")
                            .font(TemplateKineticFonts.bold(10))
                            .tracking(2)
                            .foregroundStyle(kp.primary)
                        Spacer(minLength: 0)
                    }
                    WorkoutSplitsSection(
                        programViewModel: programViewModel,
                        templatesViewModel: viewModel,
                        workoutViewModel: workoutViewModel,
                        onStartWorkout: onStartTemplate,
                        sectionTitle: "Your programs",
                        hidesSectionTitle: true
                    )
                }
            }
            .padding(.top, 8)
        case .skills:
            CalisthenicsSkillsSection(
                workoutViewModel: workoutViewModel,
                templatesViewModel: viewModel,
                onStart: onStartTemplate
            )
            .padding(.top, 8)
        case .templates:
            kineticTemplatesBentoSection
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Fixed pixel width from the container (not maxWidth alone) so AsyncImage / bento rows can’t
            // widen the column after images resolve — same centered gutters as Studio/Habits intent.
            GeometryReader { geo in
                let gutter = KineticTemplateLayout.horizontalPadding
                let safeW = max(geo.size.width, 1)
                let columnWidth = min(
                    KineticTemplateLayout.contentColumnMaxWidth,
                    max(0, safeW - 2 * gutter)
                )
                HStack(alignment: .top, spacing: 0) {
                    Spacer(minLength: 0)
                    VStack(alignment: .leading, spacing: 0) {
                        kineticTitleBlock
                            .padding(.bottom, 32)
                        kineticSegmentStrip
                            .padding(.bottom, 40)
                        if selectedSegment == .templates {
                            kineticAutoGenerateCTA
                                .padding(.bottom, 20)
                        }
                        if selectedSegment == .templates {
                            kineticSearchRow
                                .padding(.bottom, 40)
                        }
                        ScrollView {
                            kineticSegmentBody
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 120)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                    .frame(width: columnWidth, alignment: .topLeading)
                    Spacer(minLength: 0)
                }
                .frame(width: safeW, height: geo.size.height, alignment: .top)
                .padding(.top, 16)
            }
            Group {
                if selectedSegment == .templates && !isMultiSelectMode {
                    kineticPlusFAB(action: { viewModel.createTemplate() }, accessibilityLabel: "Create template")
                } else if selectedSegment == .programs {
                    kineticPlusFAB(action: { showCreateProgramFromCatalog = true }, accessibilityLabel: "Create program")
                } else if selectedSegment == .skills {
                    kineticPlusFAB(action: { showCalisthenicProgression = true }, accessibilityLabel: "Create custom skill")
                }
            }
            .padding(.trailing, 24)
            .padding(.bottom, 100)
        }
        .background(kp.background.ignoresSafeArea())
        .kineticDynamicTypeClamp()
        .id(AppColors.themeID)
        .safeAreaInset(edge: .top, spacing: 0) {
            if isMultiSelectMode {
                ZStack {
                    kp.surfaceContainerLow
                        .frame(maxWidth: .infinity)
                    HStack {
                        Button("Cancel") {
                            isMultiSelectMode = false
                            selectedTemplates.removeAll()
                        }
                        .font(TemplateKineticFonts.semiBold(16))
                        .foregroundStyle(kp.primary)
                        Spacer()
                        Text("\(selectedTemplates.count) selected")
                            .font(TemplateKineticFonts.semiBold(15))
                            .foregroundStyle(kp.onSurface)
                        Spacer()
                        Button(role: .destructive) {
                            deleteSelectedTemplates()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .disabled(selectedTemplates.isEmpty)
                    }
                    .frame(maxWidth: KineticTemplateLayout.contentColumnMaxWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, KineticTemplateLayout.horizontalPadding)
                    .padding(.vertical, 12)
                }
            }
        }
        .sheet(isPresented: $viewModel.showEditTemplate) {
            if let template = viewModel.editingTemplate {
                TemplateEditView(
                    template: template,
                    onSave: { template in
                        viewModel.saveTemplate(template)
                    },
                    onCancel: {
                        viewModel.showEditTemplate = false
                        viewModel.editingTemplate = nil
                    },
                    onDelete: {
                        viewModel.deleteTemplate(template, progressViewModel: progressViewModel)
                        viewModel.showEditTemplate = false
                        viewModel.editingTemplate = nil
                    }
                )
            }
        }
        .sheet(isPresented: $viewModel.showCreateTemplate) {
            TemplateEditView(
                template: nil,
                onSave: { template in
                    viewModel.saveTemplate(template)
                },
                onCancel: {
                    viewModel.showCreateTemplate = false
                }
            )
        }
        .sheet(isPresented: $viewModel.showGenerationSettings) {
            WorkoutGenerationSettingsView(settings: $viewModel.generationSettings)
        }
        .sheet(isPresented: $showGenerateSheet) {
            WorkoutGenerationView(
                viewModel: viewModel,
                onStart: onStartTemplate,
                onRequestFullSettings: {
                    showGenerateSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        viewModel.showGenerationSettings = true
                    }
                }
            )
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCalisthenicProgression) {
            CreateCustomSkillView(skillManager: CalisthenicsSkillManager.shared)
        }
        .sheet(isPresented: $showFilterSheet) {
            TemplateFilterSheet(filters: $filters, sortOption: $sortOption)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showCreateProgramFromCatalog) {
            CreateWorkoutProgramView(
                programViewModel: programViewModel,
                templatesViewModel: viewModel,
                onDismiss: {
                    showCreateProgramFromCatalog = false
                }
            )
        }
        .sheet(item: $selectedExampleProgram) { program in
            NavigationView {
                WorkoutProgramView(
                    program: program,
                    workoutViewModel: workoutViewModel,
                    programViewModel: programViewModel,
                    templatesViewModel: viewModel
                )
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            selectedExampleProgram = nil
                        }
                        .foregroundColor(AppColors.primary)
                    }
                }
                .onChange(of: workoutViewModel.currentWorkout) { _, newValue in
                    if newValue != nil {
                        selectedExampleProgram = nil
                        onStartTemplate()
                    }
                }
            }
        }
        .sheet(item: $selectedTemplate) { template in
            TemplateDetailView(
                template: template,
                onStart: {
                    viewModel.startTemplate(template, workoutViewModel: workoutViewModel)
                    onStartTemplate()
                },
                onEdit: {
                    viewModel.editTemplate(template)
                },
                onDuplicate: {
                    duplicateTemplate(template)
                },
                onDelete: template.isDefault ? nil : {
                    viewModel.deleteTemplate(template, progressViewModel: progressViewModel)
                    CardDetailCacheManager.shared.invalidateTemplateCache(template.id)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
        .animation(KineticAccessibility.segmentAnimation(reduceMotion: accessibilityReduceMotion), value: selectedSegment)
        .onChange(of: debouncedSearchText) {
            invalidateTemplateCache()
        }
        .onChange(of: filters) {
            invalidateTemplateCache()
        }
        .onChange(of: sortOption) {
            invalidateTemplateCache()
        }
        .onChange(of: viewModel.templates.count) {
            invalidateTemplateCache()
        }
    }

    private func invalidateTemplateCache() {
        cachedFilteredTemplates = []
        lastFilterCacheKey = ""
    }
    
    private func createFilterCacheKey(_ filters: TemplateFilters) -> String {
        let intensities = filters.intensities.sorted(by: { $0.rawValue < $1.rawValue }).map { $0.rawValue }.joined(separator: ",")
        let muscleGroups = filters.muscleGroups.sorted().joined(separator: ",")
        return "\(intensities)-\(filters.showQuick)-\(filters.showMedium)-\(filters.showLong)-\(muscleGroups)-\(filters.showDefault)-\(filters.showCustom)"
    }
    
    // MARK: - Helper Functions
    
    private func duplicateTemplate(_ template: WorkoutTemplate) {
        let duplicated = WorkoutTemplate(
            name: "\(template.name) (Copy)",
            exercises: template.exercises,
            estimatedDuration: template.estimatedDuration,
            intensity: template.intensity,
            workoutType: template.workoutType,
            isDefault: false,
            colorHex: template.colorHex
        )
        viewModel.saveTemplate(duplicated)
        HapticManager.impact(style: .light)
    }
    
    private func toggleSelection(_ template: WorkoutTemplate) {
        if selectedTemplates.contains(template.id) {
            selectedTemplates.remove(template.id)
        } else {
            selectedTemplates.insert(template.id)
        }
        HapticManager.selection()
    }
    
    private func deleteSelectedTemplates() {
        for templateId in selectedTemplates {
            if let template = viewModel.templates.first(where: { $0.id == templateId }) {
                if !template.isDefault {
                    viewModel.deleteTemplate(template, progressViewModel: progressViewModel)
                }
            }
        }
        selectedTemplates.removeAll()
        isMultiSelectMode = false
        HapticManager.success()
    }
}

// MARK: - Template Bento Card (Kinetic wireframe)

private struct TemplateBentoCard: View {
    @Environment(\.kineticPalette) private var kp

    let template: WorkoutTemplate
    let heroURL: URL
    var isFeatured: Bool
    var showEditorialMetric: Bool
    let muscleFocus: String
    let intensityLabel: String
    let isMultiSelectMode: Bool
    let isSelected: Bool
    let onTapCard: () -> Void
    let onPlay: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: (() -> Void)?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: heroURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    LinearGradient(
                        colors: [kp.secondaryContainer, kp.surfaceContainerHigh],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                default:
                    kp.surfaceContainerHighest
                }
            }
            .frame(height: 268)
            .clipped()
            .overlay {
                LinearGradient(
                    colors: isFeatured
                        ? [.black.opacity(0.9), .black.opacity(0.4), .clear]
                        : [.black.opacity(0.92), .black.opacity(0.55), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
            }

            if isFeatured && showEditorialMetric {
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%02d", template.exercises.count))
                                .font(TemplateKineticFonts.extraBold(40))
                                .foregroundStyle(.white.opacity(0.22))
                                .tracking(-2)
                            Text("Exercises")
                                .font(TemplateKineticFonts.bold(10))
                                .tracking(2)
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                    Spacer()
                }
                .padding(20)
                .allowsHitTesting(false)
            }

            if isMultiSelectMode {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 28))
                            .foregroundStyle(isSelected ? kp.primary : .white.opacity(0.55))
                            .padding(12)
                    }
                    Spacer()
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 8) {
                    Text("\(template.estimatedDuration)m")
                        .font(TemplateKineticFonts.bold(10))
                        .tracking(1.6)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(isFeatured ? kp.secondary : kp.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            (isFeatured ? kp.secondaryContainer : kp.primary).opacity(isFeatured ? 0.4 : 0.2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(
                                    (isFeatured ? kp.secondary : kp.primary).opacity(0.25),
                                    lineWidth: 1
                                )
                        )
                    Text(intensityLabel)
                        .font(TemplateKineticFonts.bold(10))
                        .tracking(1.6)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                }
                Text(template.name)
                    .font(isFeatured ? TemplateKineticFonts.extraBold(26) : TemplateKineticFonts.extraBold(22))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.72)
                    .multilineTextAlignment(.leading)
                Text("\(template.exercises.count) Exercises • \(muscleFocus)")
                    .font(isFeatured ? TemplateKineticFonts.medium(15) : TemplateKineticFonts.medium(14))
                    .foregroundStyle(isFeatured ? .white.opacity(0.72) : .white.opacity(0.6))
                    .lineLimit(isFeatured ? 3 : 2)
                    .minimumScaleFactor(0.78)
                    .fixedSize(horizontal: false, vertical: true)
                if !isMultiSelectMode {
                    if isFeatured {
                        Button(action: onPlay) {
                            HStack(spacing: 10) {
                                Image(systemName: "play.fill")
                                Text("Start Session")
                            }
                            .font(TemplateKineticFonts.bold(12))
                            .tracking(2)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: onPlay) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(kp.onPrimary)
                                .frame(width: 48, height: 48)
                                .background(kp.primary)
                                .clipShape(Circle())
                                .shadow(color: kp.primary.opacity(0.45), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Start \(template.name)")
                    }
                }
            }
            .padding(20)
        }
        .frame(height: 268)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .contentShape(RoundedRectangle(cornerRadius: 32))
        .onTapGesture {
            onTapCard()
        }
        .contextMenu {
            Button("Edit", action: onEdit)
            Button("Duplicate", action: onDuplicate)
            if let onDelete {
                Button("Delete", role: .destructive, action: onDelete)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(template.name), \(template.exercises.count) exercises, \(template.estimatedDuration) minutes")
        .accessibilityHint("Double tap to open details. Actions menu includes start, edit, duplicate.")
        .accessibilityAction(named: Text("Start workout")) { onPlay() }
        .accessibilityAction(named: Text("Edit template")) { onEdit() }
        .accessibilityAction(named: Text("Duplicate template")) { onDuplicate() }
        .modifier(TemplateBentoCardDeleteAccessibility(onDelete: onDelete))
    }
}

/// VoiceOver: expose delete only for non-default templates (same as context menu).
private struct TemplateBentoCardDeleteAccessibility: ViewModifier {
    let onDelete: (() -> Void)?

    func body(content: Content) -> some View {
        if let onDelete {
            content.accessibilityAction(named: Text("Delete template")) { onDelete() }
        } else {
            content
        }
    }
}

// MARK: - Supporting Components

struct RedesignedTemplateCard: View {
    let template: WorkoutTemplate
    let isMultiSelectMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onStart: () -> Void
    
    private var gradient: LinearGradient {
        AppColors.templateGradient(for: template)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                // Selection indicator
                if isMultiSelectMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? AppColors.primary : AppColors.mutedForeground)
                        .accessibilityHidden(true)
                }
                
                // Icon
                ZStack {
                    Circle()
                        .fill(gradient.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(gradient)
                }
                
                // Template Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(AppTypography.heading3)
                        .foregroundColor(AppColors.foreground)
                        .lineLimit(1)
                        .accessibilityLabel(template.name)
                    
                    HStack(spacing: 8) {
                        Label("\(template.exercises.count)", systemImage: "figure.mixed.cardio")
                            .font(AppTypography.caption)
                        
                        if template.estimatedDuration > 0 {
                            Text("•")
                            Label("\(template.estimatedDuration) min", systemImage: "clock")
                                .font(AppTypography.caption)
                        }
                        
                        if let intensity = template.intensity {
                            Text("•")
                            Text(intensity.rawValue)
                                .font(AppTypography.caption)
                                .foregroundStyle(gradient)
                        }
                    }
                    .foregroundColor(AppColors.mutedForeground)
                }
                
                Spacer()
                
                // Quick Start button (not in multi-select)
                if !isMultiSelectMode {
                    Button(action: onStart) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(gradient)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityLabel("Start \(template.name)")
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedEmptyState: View {
    let hasSearchText: Bool
    let hasFilters: Bool
    let onClearSearch: () -> Void
    let onClearFilters: () -> Void
    let onCreateTemplate: () -> Void
    let onGenerateWorkout: () -> Void
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: hasSearchText ? "magnifyingglass" : "doc.text")
                    .font(.system(size: 48))
                    .foregroundColor(AppColors.primary.opacity(0.6))
            }
            
            // Title & Message
            VStack(spacing: 8) {
                Text(hasSearchText ? "No Templates Found" : "No Templates Yet")
                    .font(AppTypography.heading2)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(hasSearchText || hasFilters ?
                     "Try adjusting your search or filters" :
                     "Create your first workout template or generate one with AI")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Actions
            VStack(spacing: 12) {
                if hasSearchText {
                    Button(action: onClearSearch) {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Clear Search")
                        }
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                if hasFilters {
                    Button(action: onClearFilters) {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text("Clear Filters")
                        }
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                if !hasSearchText && !hasFilters {
                    Button(action: onCreateTemplate) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Template")
                        }
                        .font(AppTypography.bodyBold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    Button(action: onGenerateWorkout) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Generate with AI")
                        }
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct FloatingAddButton: View {
    let onCreateTemplate: () -> Void
    
    var body: some View {
        Button(action: onCreateTemplate) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(LinearGradient.primaryGradient)
                .clipShape(Circle())
                .shadow(color: AppColors.primary.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Create new template")
    }
}

struct GroupedTemplateSection: View {
    let groupName: String
    let templates: [WorkoutTemplate]
    let isMultiSelectMode: Bool
    @Binding var selectedTemplates: Set<UUID>
    let onTapTemplate: (WorkoutTemplate) -> Void
    let onStartTemplate: (WorkoutTemplate) -> Void
    let onDeleteTemplate: (WorkoutTemplate) -> Void
    let onDuplicateTemplate: (WorkoutTemplate) -> Void
    
    @State private var isExpanded = true
    
    // Note: Grouped sections use group-based gradients, individual templates use their own colors
    var gradient: LinearGradient {
        AppColors.categoryGradient(for: groupName)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Group Header
            Button(action: {
                isExpanded.toggle()
                HapticManager.selection()
            }) {
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(gradient)
                            .frame(width: 12, height: 12)
                        
                        Text(groupName)
                            .font(AppTypography.heading3)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("(\(templates.count))")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.mutedForeground)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.mutedForeground)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Templates in Group
            if isExpanded {
                ForEach(templates, id: \.id) { template in
                    RedesignedTemplateCard(
                        template: template,
                        isMultiSelectMode: isMultiSelectMode,
                        isSelected: selectedTemplates.contains(template.id),
                        onTap: { onTapTemplate(template) },
                        onStart: { onStartTemplate(template) }
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if !template.isDefault {
                            Button(role: .destructive) {
                                onDeleteTemplate(template)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            onDuplicateTemplate(template)
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                        .tint(AppColors.accent)
                    }
                }
            }
        }
    }
}
struct TemplateEditView: View {
    @State private var templateName: String
    @State private var exercises: [TemplateExercise]
    @State private var intensity: WorkoutIntensity?
    @State private var workoutType: WorkoutType
    @State private var templateColorHex: String?
    @State private var newExerciseName: String = ""
    @State private var newExerciseSets: Int = 3
    @State private var newExerciseReps: String = "8-10"
    @State private var newExerciseDropsets: Bool = false
    @State private var newExerciseType: ExerciseType = .weightReps
    @State private var newExerciseHoldDuration: Int = 30
    @State private var showAddCustomExercise = false
    @State private var showClearTemplateConfirmation = false
    @ObservedObject private var exerciseDataManager = ExerciseDataManager.shared
    
    private let originalTemplate: WorkoutTemplate?
    let onSave: (WorkoutTemplate) -> Void
    let onCancel: () -> Void
    let onDelete: (() -> Void)?
    
    init(template: WorkoutTemplate?, onSave: @escaping (WorkoutTemplate) -> Void, onCancel: @escaping () -> Void, onDelete: (() -> Void)? = nil) {
        self.originalTemplate = template
        if let template = template {
            _templateName = State(initialValue: template.name)
            _exercises = State(initialValue: template.exercises)
            _intensity = State(initialValue: template.intensity)
            _workoutType = State(initialValue: template.workoutType)
            _templateColorHex = State(initialValue: template.colorHex)
        } else {
            _templateName = State(initialValue: "")
            _exercises = State(initialValue: [])
            _intensity = State(initialValue: nil)
            _workoutType = State(initialValue: .standard)
            _templateColorHex = State(initialValue: nil)
        }
        self.onSave = onSave
        self.onCancel = onCancel
        self.onDelete = onDelete
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Template Name
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Template Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        TextField("e.g., Push Day", text: $templateName)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.foreground)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(AppColors.input)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.border, lineWidth: 2)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Workout Type Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Workout Type")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Picker("Workout Type", selection: $workoutType) {
                            ForEach(WorkoutType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(AppColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Intensity Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Intensity (Optional)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Picker("Intensity", selection: $intensity) {
                            Text("None").tag(WorkoutIntensity?.none)
                            ForEach(WorkoutIntensity.allCases, id: \.self) { intensityOption in
                                Text(intensityOption.rawValue).tag(WorkoutIntensity?.some(intensityOption))
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(AppColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Template Color Selection
                    TemplateColorPicker(selectedColorHex: $templateColorHex)
                    
                    // Exercises List
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Exercises")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                            
                            Spacer()
                            
                            // Clear Template Button (only show if there are exercises)
                            if !exercises.isEmpty {
                                Button(action: {
                                    showClearTemplateConfirmation = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 12))
                                        Text("Clear All")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(AppColors.destructive)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppColors.destructive.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        
                        ForEach(exercises) { exercise in
                            TemplateExerciseEditView(
                                exercise: Binding(
                                    get: { 
                                        exercises.first(where: { $0.id == exercise.id }) ?? exercise
                                    },
                                    set: { newValue in
                                        if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
                                            exercises[index] = newValue
                                        }
                                    }
                                ),
                                onDelete: {
                                    if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
                                        exercises.remove(at: index)
                                    }
                                }
                            )
                        }
                        
                        // Add Exercise Input
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Add Exercise")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.mutedForeground)
                                
                                Spacer()
                                
                                Button(action: {
                                    showAddCustomExercise = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 12))
                                        Text("Create Custom")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundColor(AppColors.primary)
                                }
                            }
                            
                            ExerciseAutocompleteField(
                                text: $newExerciseName,
                                placeholder: "Exercise name",
                                fontSize: 16
                            )
                            
                            HStack(spacing: 12) {
                                // Sets
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Sets")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.mutedForeground)
                                    Stepper(value: $newExerciseSets, in: 1...10) {
                                        Text("\(newExerciseSets)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.foreground)
                                    }
                                }
                                
                                // Reps
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Reps")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.mutedForeground)
                                    TextField("8-10", text: $newExerciseReps)
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.foreground)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(AppColors.input)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                
                                // Dropsets
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Dropsets")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.mutedForeground)
                                    Toggle("", isOn: $newExerciseDropsets)
                                        .toggleStyle(SwitchToggleStyle(tint: AppColors.accent))
                                }
                            }
                            
                            Button(action: {
                                if !newExerciseName.isEmpty {
                                    let newExercise = TemplateExercise(
                                        name: newExerciseName,
                                        sets: newExerciseSets,
                                        reps: newExerciseReps,
                                        dropsets: newExerciseDropsets,
                                        exerciseType: newExerciseType,
                                        targetHoldDuration: newExerciseType == .hold ? newExerciseHoldDuration : nil
                                    )
                                    exercises.append(newExercise)
                                    newExerciseName = ""
                                    newExerciseSets = 3
                                    newExerciseReps = "8-10"
                                    newExerciseDropsets = false
                                    newExerciseType = .weightReps
                                }
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Exercise")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.alabasterGrey)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(LinearGradient.primaryGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(newExerciseName.isEmpty)
                            .opacity(newExerciseName.isEmpty ? 0.6 : 1.0)
                        }
                        .padding(16)
                        .background(AppColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Delete Button (only for editing non-default templates)
                    if onDelete != nil && !(originalTemplate?.isDefault ?? false) {
                        Button(action: {
                            onDelete?()
                        }) {
                            Text("Delete Template")
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
                    }
                    
                    // Show message for default templates
                    if originalTemplate?.isDefault ?? false {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(AppColors.primary)
                            Text("This is a default template and cannot be deleted")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.mutedForeground)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(AppColors.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(24)
            }
            .background(AppColors.background)
            .navigationTitle(templateName.isEmpty ? "New Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .sheet(isPresented: $showAddCustomExercise) {
                AddCustomExerciseView { exercise in
                    exerciseDataManager.addCustomExercise(exercise)
                    // Pre-fill the exercise name if it was already typed
                    if newExerciseName.isEmpty {
                        newExerciseName = exercise.name
                    }
                }
            }
            .alert("Clear All Exercises?", isPresented: $showClearTemplateConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    exercises.removeAll()
                }
            } message: {
                Text("This will remove all exercises from the template. This action cannot be undone.")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let template: WorkoutTemplate
                        if let original = originalTemplate {
                            // Preserve ID when editing, keep existing estimatedDuration
                            template = WorkoutTemplate(
                                id: original.id,
                                name: templateName,
                                exercises: exercises,
                                estimatedDuration: original.estimatedDuration,
                                intensity: intensity,
                                workoutType: workoutType,
                                colorHex: templateColorHex
                            )
                        } else {
                            // New template gets new ID, use default estimatedDuration
                            template = WorkoutTemplate(
                                name: templateName,
                                exercises: exercises,
                                estimatedDuration: 60,
                                intensity: intensity,
                                workoutType: workoutType,
                                colorHex: templateColorHex
                            )
                        }
                        onSave(template)
                    }
                    .disabled(templateName.isEmpty || exercises.isEmpty)
                }
            }
        }
    }
}

struct AddExerciseView: View {
    @State private var exerciseName: String = ""
    @State private var targetSets: Int = 4
    // Local mode used to drive the UI. This maps down to ExerciseType for the model layer.
    private enum ExerciseMode {
        case weights      // Barbell/dumbbell style weight + reps
        case calisthenics // Bodyweight calisthenics: reps + optional additional weight
        case timeBased    // Time-based (cardio / stretching)
    }
    @State private var mode: ExerciseMode = .weights
    @State private var holdDuration: Int = 30
    @State private var showAddCustomExercise = false
    @ObservedObject private var exerciseDataManager = ExerciseDataManager.shared
    let onAdd: (String, Int, ExerciseType, Int) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Exercise Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                            
                            Spacer()
                            
                            Button(action: {
                                showAddCustomExercise = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 14))
                                    Text("Create Custom")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(AppColors.primary)
                            }
                        }
                        
                        ExerciseAutocompleteField(
                            text: $exerciseName,
                            placeholder: "e.g., Bench Press"
                        )
                    }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercise Type")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    HStack(spacing: 12) {
                        // Weights
                        Button(action: { mode = .weights }) {
                            HStack {
                                Image(systemName: "dumbbell.fill")
                                Text("Weights")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(mode == .weights ? AppColors.alabasterGrey : AppColors.foreground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(mode == .weights ? LinearGradient.primaryGradient : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Calisthenics (reps + additional weight)
                        Button(action: { mode = .calisthenics }) {
                            HStack {
                                Image(systemName: "figure.strengthtraining.traditional")
                                Text("Calisthenics")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(mode == .calisthenics ? AppColors.alabasterGrey : AppColors.foreground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(mode == .calisthenics ? LinearGradient.primaryGradient : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Time-based (cardio / stretch)
                        Button(action: { mode = .timeBased }) {
                            HStack {
                                Image(systemName: "timer")
                                Text("Time")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(mode == .timeBased ? AppColors.alabasterGrey : AppColors.foreground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(mode == .timeBased ? LinearGradient.primaryGradient : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                
                if mode == .timeBased {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Target Hold Duration (seconds)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Stepper(value: $holdDuration, in: 5...300, step: 5) {
                            Text("\(holdDuration) seconds")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppColors.foreground)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(AppColors.input)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.border, lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Target Sets")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Stepper(value: $targetSets, in: 1...10) {
                        Text("\(targetSets) sets")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.foreground)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(AppColors.input)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.border, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.foreground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.secondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.border, lineWidth: 2)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    Button(action: {
                        if !exerciseName.isEmpty {
                            let type: ExerciseType = (mode == .timeBased) ? .hold : .weightReps
                            onAdd(exerciseName, targetSets, type, holdDuration)
                        }
                    }) {
                        Text("Add Exercise")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppColors.alabasterGrey)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 14, x: 0, y: 4)
                    }
                    .disabled(exerciseName.isEmpty)
                    .opacity(exerciseName.isEmpty ? 0.6 : 1.0)
                }
                }
                .padding(24)
            }
            .background(AppColors.background)
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddCustomExercise) {
                AddCustomExerciseView { exercise in
                    exerciseDataManager.addCustomExercise(exercise)
                    // Pre-fill the exercise name if it was already typed
                    if exerciseName.isEmpty {
                        exerciseName = exercise.name
                    }
                }
            }
        }
    }
}
