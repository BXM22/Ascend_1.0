import SwiftUI

struct SportsTimerView: View {
    @StateObject private var viewModel: SportsTimerViewModel
    @StateObject private var customSportsManager = CustomSportsManager.shared
    @State private var showConfigSheet = false
    @State private var showCustomSportSheet = false
    @State private var editingCustomSport: CustomSport?
    @Environment(\.dismiss) var dismiss
    
    // Long press tracking
    @State private var longPressStartTime: Date?
    @State private var longPressProgress: Double = 0.0
    @State private var longPressTimer: Timer?
    @State private var showStopConfirmation: Bool = false
    @State private var isHolding: Bool = false
    
    // Animation states
    @State private var showCompletionScreen: Bool = false
    @State private var sessionStartTime: Date?
    @State private var soundEnabled: Bool = AudioManager.shared.soundEnabled
    
    init(sport: SportType = .boxing, customSport: CustomSport? = nil) {
        if let custom = customSport {
            _viewModel = StateObject(wrappedValue: SportsTimerViewModel(customSport: custom))
        } else {
            _viewModel = StateObject(wrappedValue: SportsTimerViewModel(sport: sport))
        }
    }
    
    // Background color based on phase
    private var backgroundColor: Color {
        guard viewModel.isActive else {
            return AppColors.background
        }
        switch viewModel.currentPhase {
        case .round:
            return Color.green
        case .rest:
            return Color.red
        case .completed:
            return AppColors.background
        }
    }
    
    // Handle tap to pause/resume
    private func handleTap() {
        guard viewModel.isActive else { return }
        
        if viewModel.isPaused {
            viewModel.resumeTimer()
        } else {
            viewModel.pauseTimer()
        }
        HapticManager.impact(style: .light)
    }
    
    // Handle long press start
    private func startHoldToStop() {
        guard viewModel.isActive, !isHolding else { return }
        
        isHolding = true
        longPressStartTime = Date()
        longPressProgress = 0.0
        
        // Start progress timer
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            guard self.isHolding, let startTime = self.longPressStartTime else {
                timer.invalidate()
                return
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(1.0, elapsed / 3.0) // 3 seconds total
            
            self.longPressProgress = progress
            
            if elapsed >= 3.0 {
                timer.invalidate()
                self.completeHoldToStop()
            }
        }
        
        if let timer = longPressTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
        
        HapticManager.impact(style: .medium)
    }
    
    // Handle long press end (cancelled)
    private func cancelHoldToStop() {
        guard isHolding else { return }
        
        isHolding = false
        longPressTimer?.invalidate()
        longPressTimer = nil
        longPressStartTime = nil
        longPressProgress = 0.0
    }
    
    // Complete the hold to stop
    private func completeHoldToStop() {
        isHolding = false
        longPressTimer?.invalidate()
        longPressTimer = nil
        longPressStartTime = nil
        longPressProgress = 0.0
        
        HapticManager.success()
        viewModel.stopTimer()
    }
    
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic background color
                backgroundColor
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentPhase)
                
                VStack(spacing: 0) {
                    // Sport Selection (only when not active)
                    if !viewModel.isActive {
                        SportSelectorDropdownView(
                            selectedSport: $viewModel.selectedSport,
                            selectedCustomSport: $viewModel.selectedCustomSport,
                            customSports: customSportsManager.customSports,
                            onSelectSport: { sport in
                                viewModel.selectSport(sport)
                            },
                            onSelectCustomSport: { customSport in
                                viewModel.selectCustomSport(customSport)
                            },
                            onCreateCustom: {
                                editingCustomSport = nil
                                showCustomSportSheet = true
                            },
                            onEditCustom: { customSport in
                                editingCustomSport = customSport
                                showCustomSportSheet = true
                            },
                            onDeleteCustom: { customSport in
                                customSportsManager.deleteCustomSport(customSport)
                                // If this was the selected sport, switch to default
                                if viewModel.selectedCustomSport?.id == customSport.id {
                                    viewModel.selectSport(.boxing)
                                }
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 60)
                    }
                    
                    Spacer()
                    
                    // Timer Display - Takes up majority of screen
                    VStack(spacing: 40) {
                        // Phase Label
                        Text(viewModel.phaseLabel)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                            .id(viewModel.phaseLabel)
                            .opacity(viewModel.isActive ? 1.0 : 0.7)
                        
                        // Large Timer Display - Made even bigger
                        VStack(spacing: 32) {
                            ZStack {
                                // Warning glow when time is low (static, no pulsing)
                                if viewModel.isActive && !viewModel.isPaused && viewModel.timeRemainingSeconds <= 10 && viewModel.timeRemainingSeconds > 0 {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 300, height: 300)
                                        .blur(radius: 30)
                                }
                                
                                Text(viewModel.displayTime)
                                    .font(.system(size: 200, weight: .bold, design: .rounded))
                                    .foregroundColor(
                                        viewModel.isActive && !viewModel.isPaused && viewModel.timeRemainingSeconds <= 10 && viewModel.timeRemainingSeconds > 0 ?
                                        Color.yellow : .white
                                    )
                                    .contentTransition(.numericText())
                                    .monospacedDigit()
                                    .minimumScaleFactor(0.3)
                                    .lineLimit(1)
                                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            
                            // Status text
                            if viewModel.isActive {
                                Text(viewModel.isPaused ? "Paused - Tap to Resume" : "Active - Tap to Pause")
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                    .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .contentShape(Rectangle()) // Make timer area tappable for pause/resume ONLY
                        .onTapGesture {
                            handleTap()
                        }
                        .onChange(of: viewModel.isActive) {
                            if viewModel.isActive {
                                sessionStartTime = Date()
                            } else {
                                if viewModel.currentPhase == .completed {
                                    showCompletionScreen = true
                                }
                            }
                        }
                        
                        // Round Progress
                        if viewModel.isActive {
                            RoundProgressView(
                                currentRound: viewModel.currentRound,
                                totalRounds: viewModel.totalRounds
                            )
                            .padding(.top, 20)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Control Buttons
                    VStack(spacing: 16) {
                        if !viewModel.isActive {
                            // Quick Presets
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Quick Presets")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 24)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        QuickPresetButton(
                                            title: "3 min",
                                            subtitle: "12 rounds",
                                            action: {
                                                viewModel.updateConfig(SportsTimerConfig(
                                                    sport: viewModel.selectedSport,
                                                    roundDuration: 180,
                                                    restDuration: 60,
                                                    numberOfRounds: 12,
                                                    roundLabel: "Round",
                                                    restLabel: "Rest"
                                                ))
                                                HapticManager.selection()
                                            }
                                        )
                                        
                                        QuickPresetButton(
                                            title: "5 min",
                                            subtitle: "5 rounds",
                                            action: {
                                                viewModel.updateConfig(SportsTimerConfig(
                                                    sport: viewModel.selectedSport,
                                                    roundDuration: 300,
                                                    restDuration: 60,
                                                    numberOfRounds: 5,
                                                    roundLabel: "Round",
                                                    restLabel: "Rest"
                                                ))
                                                HapticManager.selection()
                                            }
                                        )
                                        
                                        QuickPresetButton(
                                            title: "2 min",
                                            subtitle: "3 rounds",
                                            action: {
                                                viewModel.updateConfig(SportsTimerConfig(
                                                    sport: viewModel.selectedSport,
                                                    roundDuration: 120,
                                                    restDuration: 30,
                                                    numberOfRounds: 3,
                                                    roundLabel: "Round",
                                                    restLabel: "Rest"
                                                ))
                                                HapticManager.selection()
                                            }
                                        )
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                            .padding(.bottom, 8)
                            
                            // Start button
                            Button(action: {
                                HapticManager.impact(style: .medium)
                                viewModel.startTimer()
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 20))
                                    Text("Start Timer")
                                        .font(.system(size: 20, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(
                                    LinearGradient(
                                        colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            // Configure button
                            Button(action: {
                                HapticManager.selection()
                                showConfigSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 18))
                                    Text("Configure Timer")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(Color.black.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(ScaleButtonStyle())
                        } else {
                            // Hold to Stop area - Completely separate from tap gesture
                            VStack(spacing: 12) {
                                if !isHolding {
                                    Text("Hold here to stop timer")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                        .padding(.top, 8)
                                } else {
                                    Text("Stopping... \(Int(longPressProgress * 3))s")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.top, 8)
                                }
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        // Background
                                        Rectangle()
                                            .fill(isHolding ? Color.white.opacity(0.3) : Color.white.opacity(0.15))
                                        
                                        // Progress overlay
                                        if isHolding {
                                            Rectangle()
                                                .fill(Color.white)
                                                .frame(width: geometry.size.width * CGFloat(longPressProgress))
                                                .animation(.linear(duration: 0.1), value: longPressProgress)
                                        }
                                        
                                        // Content
                                        if !isHolding {
                                            VStack(spacing: 8) {
                                                Image(systemName: "hand.tap.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.white.opacity(0.7))
                                                Text("Hold 3 seconds")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.7))
                                            }
                                            .frame(maxWidth: .infinity)
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .simultaneousGesture(
                                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                            .onChanged { value in
                                                // Start holding if not already holding and finger hasn't moved much
                                                if !isHolding && abs(value.translation.width) < 30 && abs(value.translation.height) < 30 {
                                                    startHoldToStop()
                                                } else if isHolding && (abs(value.translation.width) > 100 || abs(value.translation.height) > 100) {
                                                    // Cancel if user moves finger too far
                                                    cancelHoldToStop()
                                                }
                                            }
                                            .onEnded { _ in
                                                // Only cancel if we're still holding (didn't complete)
                                                if isHolding {
                                                    cancelHoldToStop()
                                                }
                                            }
                                    )
                                }
                                .frame(height: 80)
                            }
                            .padding(.top, 12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle(viewModel.selectedCustomSport?.name ?? viewModel.selectedSport.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Sound Toggle
                    Button(action: {
                        soundEnabled.toggle()
                        AudioManager.shared.soundEnabled = soundEnabled
                        HapticManager.selection()
                    }) {
                        Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.system(size: 18))
                            .foregroundColor(viewModel.isActive ? .white : AppColors.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if viewModel.isActive {
                            viewModel.stopTimer()
                        }
                        dismiss()
                    }
                    .foregroundColor(viewModel.isActive ? .white : AppColors.primary)
                }
            }
            .onAppear {
                soundEnabled = AudioManager.shared.soundEnabled
            }
            .sheet(isPresented: $showConfigSheet) {
                SportsTimerConfigView(
                    config: viewModel.config,
                    onSave: { newConfig in
                        // Update config - this is already on main thread
                        viewModel.updateConfig(newConfig)
                    }
                )
            }
            .sheet(isPresented: $showCustomSportSheet) {
                CustomSportEditView(
                    customSport: editingCustomSport,
                    onSave: { customSport in
                        if editingCustomSport != nil {
                            customSportsManager.updateCustomSport(customSport)
                        } else {
                            customSportsManager.addCustomSport(customSport)
                        }
                        // Select the newly created/edited sport
                        viewModel.selectCustomSport(customSport)
                    },
                    onDelete: { customSport in
                        customSportsManager.deleteCustomSport(customSport)
                        // If this was the selected sport, switch to default
                        if viewModel.selectedCustomSport?.id == customSport.id {
                            viewModel.selectSport(.boxing)
                        }
                    }
                )
            }
            .onDisappear {
                // Clean up long press timer
                cancelHoldToStop()
            }
            .sheet(isPresented: $showCompletionScreen) {
                TimerCompletionView(
                    totalRounds: viewModel.totalRounds,
                    roundDuration: viewModel.config.roundDuration,
                    restDuration: viewModel.config.restDuration,
                    sessionStartTime: sessionStartTime,
                    onDismiss: {
                        showCompletionScreen = false
                        viewModel.resetToInitialState()
                    },
                    onRestart: {
                        showCompletionScreen = false
                        viewModel.resetToInitialState()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            viewModel.startTimer()
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Timer Completion View

struct TimerCompletionView: View {
    let totalRounds: Int
    let roundDuration: Int
    let restDuration: Int
    let sessionStartTime: Date?
    let onDismiss: () -> Void
    let onRestart: () -> Void
    @Environment(\.dismiss) var dismiss
    
    private var totalTime: TimeInterval {
        guard let start = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(start)
    }
    
    private var formattedTotalTime: String {
        let hours = Int(totalTime) / 3600
        let minutes = (Int(totalTime) % 3600) / 60
        let seconds = Int(totalTime) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.primaryGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Success Icon
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 40)
                        
                        // Title
                        Text("Session Complete!")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Statistics
                        VStack(spacing: 20) {
                            TimerStatCard(
                                icon: "number.circle.fill",
                                title: "Rounds Completed",
                                value: "\(totalRounds)",
                                color: .white
                            )
                            
                            TimerStatCard(
                                icon: "clock.fill",
                                title: "Total Time",
                                value: formattedTotalTime,
                                color: .white
                            )
                            
                            TimerStatCard(
                                icon: "timer",
                                title: "Round Duration",
                                value: formatDuration(roundDuration),
                                color: .white
                            )
                            
                            TimerStatCard(
                                icon: "pause.circle.fill",
                                title: "Rest Duration",
                                value: formatDuration(restDuration),
                                color: .white
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Action Buttons
                        VStack(spacing: 16) {
                            Button(action: {
                                HapticManager.impact(style: .medium)
                                onRestart()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 18))
                                    Text("Start New Session")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(Color.white.opacity(0.25))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            Button(action: {
                                HapticManager.impact(style: .light)
                                onDismiss()
                            }) {
                                Text("Done")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if minutes > 0 {
            return "\(minutes)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }
}

struct TimerStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color.opacity(0.8))
                
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}


// MARK: - Round Progress View

struct RoundProgressView: View {
    let currentRound: Int
    let totalRounds: Int
    @State private var animatedRound: Int = 1
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(1...totalRounds, id: \.self) { round in
                ZStack {
                    Circle()
                        .fill(round <= animatedRound ? 
                              Color.white : Color.white.opacity(0.3))
                        .frame(width: 18, height: 18)
                    
                    if round == animatedRound && round <= currentRound {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 24, height: 24)
                            .opacity(0.6)
                            .scaleEffect(1.2)
                            .animation(
                                Animation.easeOut(duration: 1.0)
                                    .repeatForever(autoreverses: false),
                                value: animatedRound
                            )
                    }
                }
            }
        }
        .onChange(of: currentRound) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animatedRound = currentRound
            }
        }
        .onAppear {
            animatedRound = currentRound
        }
    }
}

struct QuickPresetButton: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sport Selector Dropdown

struct SportSelectorDropdownView: View {
    @Binding var selectedSport: SportType
    @Binding var selectedCustomSport: CustomSport?
    let customSports: [CustomSport]
    let onSelectSport: (SportType) -> Void
    let onSelectCustomSport: (CustomSport) -> Void
    let onCreateCustom: () -> Void
    let onEditCustom: (CustomSport) -> Void
    let onDeleteCustom: ((CustomSport) -> Void)?
    
    @State private var isExpanded = false
    
    private var currentDisplayName: String {
        if let custom = selectedCustomSport {
            return custom.name
        }
        return selectedSport.rawValue
    }
    
    private var currentIcon: String {
        if let custom = selectedCustomSport {
            return custom.icon
        }
        return selectedSport.icon
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Dropdown Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                HapticManager.impact(style: .light)
            }) {
                HStack(spacing: 12) {
                    Image(systemName: currentIcon)
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.primary)
                        .frame(width: 24)
                    
                    Text(currentDisplayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.mutedForeground)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(AppColors.border.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Dropdown Menu
            if isExpanded {
                VStack(spacing: 0) {
                    // Built-in Sports
                    ForEach(SportType.allCases) { sport in
                        SportMenuItem(
                            name: sport.rawValue,
                            icon: sport.icon,
                            isSelected: selectedSport == sport && selectedCustomSport == nil,
                            onSelect: {
                                onSelectSport(sport)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isExpanded = false
                                }
                            }
                        )
                    }
                    
                    // Divider
                    if !customSports.isEmpty {
                        Divider()
                            .padding(.vertical, 4)
                    }
                    
                    // Custom Sports
                    ForEach(customSports) { customSport in
                        SportMenuItem(
                            name: customSport.name,
                            icon: customSport.icon,
                            isSelected: selectedCustomSport?.id == customSport.id,
                            isCustom: true,
                            onSelect: {
                                onSelectCustomSport(customSport)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isExpanded = false
                                }
                            },
                            onEdit: {
                                onEditCustom(customSport)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isExpanded = false
                                }
                            },
                            onDelete: onDeleteCustom != nil ? {
                                onDeleteCustom?(customSport)
                            } : nil
                        )
                    }
                    
                    // Add Custom Sport Button
                    Button(action: {
                        onCreateCustom()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isExpanded = false
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(AppColors.primary)
                            
                            Text("Create Custom Sport")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppColors.primary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppColors.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 8)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(AppColors.border.opacity(0.5), lineWidth: 1)
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
}

struct SportMenuItem: View {
    let name: String
    let icon: String
    let isSelected: Bool
    var isCustom: Bool = false
    let onSelect: () -> Void
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? AppColors.primary : AppColors.mutedForeground)
                        .frame(width: 24)
                    
                    Text(name)
                        .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                    
                    if isCustom {
                        Text("Custom")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppColors.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Edit and Delete buttons for custom sports
            if isCustom {
                HStack(spacing: 4) {
                    if let onEdit = onEdit {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.mutedForeground)
                                .padding(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if let onDelete = onDelete {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.destructive)
                                .padding(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .confirmationDialog("Delete Custom Sport", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                            Button("Delete", role: .destructive) {
                                onDelete()
                            }
                            Button("Cancel", role: .cancel) { }
                        } message: {
                            Text("Are you sure you want to delete \"\(name)\"? This action cannot be undone.")
                        }
                    }
                }
            }
        }
        .background(isSelected ? AppColors.secondary.opacity(0.5) : Color.clear)
    }
}

// MARK: - Timer Configuration View

struct SportsTimerConfigView: View {
    let initialConfig: SportsTimerConfig
    let onSave: (SportsTimerConfig) -> Void
    @Environment(\.dismiss) var dismiss
    
    // Local state - initialized from initialConfig
    @State private var roundMinutes: Int
    @State private var roundSeconds: Int
    @State private var restMinutes: Int
    @State private var restSeconds: Int
    @State private var numberOfRounds: Int
    @State private var roundLabel: String
    @State private var restLabel: String
    @State private var isSaving: Bool = false
    @State private var soundEnabled: Bool = AudioManager.shared.soundEnabled
    
    init(config: SportsTimerConfig, onSave: @escaping (SportsTimerConfig) -> Void) {
        self.initialConfig = config
        self.onSave = onSave
        
        // Initialize state from config
        _roundMinutes = State(initialValue: config.roundDuration / 60)
        _roundSeconds = State(initialValue: config.roundDuration % 60)
        _restMinutes = State(initialValue: config.restDuration / 60)
        _restSeconds = State(initialValue: config.restDuration % 60)
        _numberOfRounds = State(initialValue: config.numberOfRounds)
        _roundLabel = State(initialValue: config.roundLabel)
        _restLabel = State(initialValue: config.restLabel)
    }
    
    private func saveConfiguration() {
        guard !isSaving else { return }
        isSaving = true
        
        // Create new config from current state
        let newConfig = SportsTimerConfig(
            sport: initialConfig.sport,
            roundDuration: roundMinutes * 60 + roundSeconds,
            restDuration: restMinutes * 60 + restSeconds,
            numberOfRounds: numberOfRounds,
            roundLabel: roundLabel,
            restLabel: restLabel
        )
        
        // Call save callback on next run loop to avoid blocking
        DispatchQueue.main.async {
            self.onSave(newConfig)
            // Dismiss after a tiny delay to ensure save completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.dismiss()
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Sound Toggle
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .font(.system(size: 18))
                                .foregroundColor(AppColors.primary)
                                .frame(width: 24)
                            
                            Text("Timer Sounds")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                            
                            Spacer()
                            
                            Toggle("", isOn: $soundEnabled)
                                .labelsHidden()
                                .onChange(of: soundEnabled) {
                                    AudioManager.shared.soundEnabled = soundEnabled
                                    HapticManager.selection()
                                }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    
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
                    .padding(.top, 20)
                    
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
            .navigationTitle("Configure Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        HapticManager.impact(style: .medium)
                        saveConfiguration()
                    }
                    .foregroundColor(AppColors.primary)
                    .disabled(isSaving)
                }
            }
        }
    }
}
