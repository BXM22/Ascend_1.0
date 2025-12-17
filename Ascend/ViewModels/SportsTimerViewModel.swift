import Foundation
import SwiftUI
import Combine

/// Optimized Sports Timer ViewModel with efficient state management
class SportsTimerViewModel: ObservableObject {
    // Minimal published properties to reduce re-renders
    @Published private(set) var displayTime: String = "00:00"
    @Published private(set) var progress: Double = 0.0
    @Published private(set) var phaseLabel: String = "Round 1"
    @Published private(set) var currentRound: Int = 1
    @Published private(set) var totalRounds: Int = 12
    @Published private(set) var isActive: Bool = false
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var currentPhase: TimerPhase = .round
    @Published private(set) var timeRemainingSeconds: Int = 0
    
    // Config and sport (less frequently updated)
    @Published var config: SportsTimerConfig
    @Published var selectedSport: SportType
    @Published var selectedCustomSport: CustomSport?
    
    // Internal timer state (not published to avoid unnecessary updates)
    private var timer: Timer?
    private var phaseStartTime: Date?
    private var pausedTimeAccumulator: TimeInterval = 0
    private var lastPauseTime: Date?
    
    // Cached computed values
    private var cachedDisplayTime: String = "00:00"
    private var cachedProgress: Double = 0.0
    private var lastUpdateTime: Date = Date()
    private let updateInterval: TimeInterval = 0.1 // Update UI 10 times per second max
    
    // Haptic feedback tracking
    private var lastHapticTime: Int = -1
    
    // Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    
    init(sport: SportType = .boxing) {
        self.selectedSport = sport
        self.selectedCustomSport = nil
        self.config = sport.defaultConfig
        self.totalRounds = sport.defaultConfig.numberOfRounds
        self.phaseLabel = "\(sport.defaultConfig.roundLabel) 1"
        self.displayTime = formatTime(sport.defaultConfig.roundDuration)
    }
    
    init(customSport: CustomSport) {
        self.selectedSport = .boxing // Placeholder
        self.selectedCustomSport = customSport
        let customConfig = customSport.toSportsTimerConfig()
        self.config = customConfig
        self.totalRounds = customConfig.numberOfRounds
        self.phaseLabel = "\(customConfig.roundLabel) 1"
        self.displayTime = formatTime(customConfig.roundDuration)
    }
    
    // MARK: - Public Methods
    
    func selectSport(_ sport: SportType) {
        guard !isActive else { return }
        selectedSport = sport
        selectedCustomSport = nil
        config = sport.defaultConfig
        resetToInitialStateInternal()
    }
    
    func selectCustomSport(_ customSport: CustomSport) {
        guard !isActive else { return }
        selectedCustomSport = customSport
        selectedSport = .boxing // Placeholder
        let customConfig = customSport.toSportsTimerConfig()
        config = customConfig
        resetToInitialStateInternal()
    }
    
    func updateConfig(_ newConfig: SportsTimerConfig) {
        guard !isActive else { return }
        config = newConfig
        resetToInitialStateInternal()
    }
    
    func startTimer() {
        guard !isActive else { return }
        
        isActive = true
        isPaused = false
        currentRound = 1
        currentPhase = .round
        phaseStartTime = Date()
        pausedTimeAccumulator = 0
        lastPauseTime = nil
        lastHapticTime = -1
        
        startUpdateTimer()
        scheduleNotification()
        HapticManager.impact(style: .medium)
    }
    
    func pauseTimer() {
        guard isActive && !isPaused else { return }
        
        stopUpdateTimer()
        isPaused = true
        lastPauseTime = Date()
        
        if let phaseStart = phaseStartTime {
            pausedTimeAccumulator += Date().timeIntervalSince(phaseStart)
        }
        
        HapticManager.impact(style: .light)
    }
    
    func resumeTimer() {
        guard isActive && isPaused else { return }
        
        isPaused = false
        phaseStartTime = Date()
        lastPauseTime = nil
        
        startUpdateTimer()
        HapticManager.impact(style: .light)
    }
    
    func stopTimer() {
        stopUpdateTimer()
        isActive = false
        isPaused = false
        resetToInitialStateInternal()
        NotificationManager.shared.cancelAllNotifications()
        HapticManager.impact(style: .light)
    }
    
    // MARK: - Public Methods (continued)
    
    func resetToInitialState() {
        currentRound = 1
        currentPhase = .round
        phaseStartTime = nil
        pausedTimeAccumulator = 0
        lastPauseTime = nil
        lastHapticTime = -1
        
        updateDisplayValues()
    }
    
    // MARK: - Private Methods
    
    private func resetToInitialStateInternal() {
        currentRound = 1
        currentPhase = .round
        phaseStartTime = nil
        pausedTimeAccumulator = 0
        lastPauseTime = nil
        lastHapticTime = -1
        
        updateDisplayValues()
    }
    
    private func startUpdateTimer() {
        stopUpdateTimer()
        
        // Use a high-frequency timer for smooth updates
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
        
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopUpdateTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTimer() {
        guard isActive && !isPaused else { return }
        guard let phaseStart = phaseStartTime else { return }
        
        let now = Date()
        let elapsed = now.timeIntervalSince(phaseStart)
        
        // Calculate time remaining based on phase duration
        let phaseDuration = currentPhase == .round ? 
            Double(config.roundDuration) : Double(config.restDuration)
        
        let timeRemaining = max(0, phaseDuration - elapsed)
        let timeRemainingInt = Int(timeRemaining)
        
        // Update display values (throttled)
        if now.timeIntervalSince(lastUpdateTime) >= updateInterval {
            updateDisplayValues(timeRemaining: timeRemainingInt, phaseDuration: phaseDuration)
            lastUpdateTime = now
        }
        
        // Check for phase completion
        if timeRemainingInt <= 0 {
            completeCurrentPhase()
        }
        
        // Haptic feedback (only trigger once per second)
        if timeRemainingInt != lastHapticTime {
            handleHapticFeedback(timeRemaining: timeRemainingInt)
            lastHapticTime = timeRemainingInt
        }
    }
    
    private func updateDisplayValues(timeRemaining: Int? = nil, phaseDuration: Double? = nil) {
        let timeRemainingInt: Int
        let phaseDurationValue: Double
        
        if let timeRemaining = timeRemaining, let phaseDuration = phaseDuration {
            // Calculate from provided values
            timeRemainingInt = timeRemaining
            phaseDurationValue = phaseDuration
            displayTime = formatTime(timeRemaining)
            progress = max(0.0, min(1.0, 1.0 - (Double(timeRemaining) / phaseDuration)))
        } else if let phaseStart = phaseStartTime, !isPaused {
            // Calculate from current time
            let elapsed = Date().timeIntervalSince(phaseStart)
            phaseDurationValue = currentPhase == .round ? 
                Double(config.roundDuration) : Double(config.restDuration)
            let timeRemaining = max(0, phaseDurationValue - elapsed)
            timeRemainingInt = Int(timeRemaining)
            
            displayTime = formatTime(timeRemainingInt)
            progress = max(0.0, min(1.0, 1.0 - (timeRemaining / phaseDurationValue)))
        } else {
            // Paused or inactive - use cached or initial values
            phaseDurationValue = currentPhase == .round ? 
                Double(config.roundDuration) : Double(config.restDuration)
            let timeRemaining = phaseDurationValue - pausedTimeAccumulator
            timeRemainingInt = max(0, Int(timeRemaining))
            
            displayTime = formatTime(timeRemainingInt)
            progress = max(0.0, min(1.0, 1.0 - (Double(timeRemainingInt) / phaseDurationValue)))
        }
        
        // Update time remaining
        timeRemainingSeconds = timeRemainingInt
        
        // Update phase label
        updatePhaseLabel()
    }
    
    private func updatePhaseLabel() {
        switch currentPhase {
        case .round:
            phaseLabel = "\(config.roundLabel) \(currentRound)"
        case .rest:
            phaseLabel = config.restLabel
        case .completed:
            phaseLabel = "Completed"
        }
    }
    
    private func completeCurrentPhase() {
        if currentPhase == .round {
            // Round completed
            if currentRound < totalRounds {
                // Start rest period
                currentPhase = .rest
                phaseStartTime = Date()
                pausedTimeAccumulator = 0
                scheduleNotification()
                updateDisplayValues()
                HapticManager.success()
                AudioManager.shared.playPhaseTransition()
            } else {
                // All rounds completed
                completeTimer()
            }
        } else {
            // Rest completed, start next round
            currentRound += 1
            currentPhase = .round
            phaseStartTime = Date()
            pausedTimeAccumulator = 0
            scheduleNotification()
            updateDisplayValues()
            HapticManager.impact(style: .medium)
            AudioManager.shared.playPhaseTransition()
        }
    }
    
    private func completeTimer() {
        stopUpdateTimer()
        isActive = false
        currentPhase = .completed
        displayTime = "00:00"
        progress = 1.0
        updatePhaseLabel()
        
        NotificationManager.shared.cancelAllNotifications()
        HapticManager.success()
        AudioManager.shared.playCompletionSound()
    }
    
    private func scheduleNotification() {
        let phaseDuration = currentPhase == .round ? 
            config.roundDuration : config.restDuration
        let message = currentPhase == .round ?
            "\(config.roundLabel) \(currentRound) Complete!" :
            "Rest Complete - \(config.roundLabel) \(currentRound + 1) Starting!"
        
        let title = selectedCustomSport?.name ?? selectedSport.rawValue
        
        NotificationManager.shared.scheduleRestTimerNotification(
            duration: phaseDuration,
            title: title,
            body: message
        )
    }
    
    private func handleHapticFeedback(timeRemaining: Int) {
        switch timeRemaining {
        case 10:
            HapticManager.warning()
            AudioManager.shared.playWarningSound()
            // Play boxing claps at 10 seconds
            AudioManager.shared.playBoxingClaps()
        case 5:
            HapticManager.impact(style: .light)
            AudioManager.shared.playCountdownBeep()
        case 3, 2, 1:
            HapticManager.impact(style: .light)
            AudioManager.shared.playCountdownBeep()
        case 0:
            HapticManager.success()
            // Boxing bell plays automatically via playPhaseTransition/playCompletionSound
        default:
            break
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
    
    deinit {
        stopUpdateTimer()
    }
}
