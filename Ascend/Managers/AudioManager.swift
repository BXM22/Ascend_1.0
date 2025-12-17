import Foundation
import AVFoundation
import AudioToolbox

/// Audio feedback manager for timer sounds
class AudioManager {
    static let shared = AudioManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private let soundEnabledKey = "sportsTimerSoundEnabled"
    
    // Sound file names (should be added to the app bundle)
    private let boxingBellSound = "Boxing Bell Sound FX"
    private let boxingClapSound = "boxing_clap"
    
    /// Sound enabled state (persisted to UserDefaults)
    var soundEnabled: Bool {
        get {
            UserDefaults.standard.object(forKey: soundEnabledKey) as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: soundEnabledKey)
        }
    }
    
    private init() {
        setupAudioSession()
        preloadSounds()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            Logger.error("Failed to setup audio session", error: error, category: .general)
        }
    }
    
    /// Preload sound files for better performance
    private func preloadSounds() {
        _ = loadSound(named: boxingBellSound)
        _ = loadSound(named: boxingClapSound)
    }
    
    /// Load a sound file from the app bundle
    private func loadSound(named filename: String) -> AVAudioPlayer? {
        // Check if already loaded
        if let player = audioPlayers[filename] {
            return player
        }
        
        // Try different file extensions
        let extensions = ["mp3", "wav", "m4a", "caf", "aiff"]
        
        for ext in extensions {
            guard let url = Bundle.main.url(forResource: filename, withExtension: ext) else {
                continue
            }
            
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                audioPlayers[filename] = player
                return player
            } catch {
                Logger.error("Failed to load sound file: \(filename).\(ext)", error: error, category: .general)
            }
        }
        
        return nil
    }
    
    /// Play a sound file by name
    private func playSound(named filename: String, volume: Float = 1.0) {
        guard soundEnabled else { return }
        
        // Check if sound file exists
        if loadSound(named: filename) != nil {
            // Create a new player instance for each play to allow overlapping sounds
            if let url = Bundle.main.url(forResource: filename, withExtension: "mp3") ??
                         Bundle.main.url(forResource: filename, withExtension: "wav") ??
                         Bundle.main.url(forResource: filename, withExtension: "m4a") ??
                         Bundle.main.url(forResource: filename, withExtension: "caf") ??
                         Bundle.main.url(forResource: filename, withExtension: "aiff") {
                do {
                    let newPlayer = try AVAudioPlayer(contentsOf: url)
                    newPlayer.volume = volume
                    newPlayer.play()
                } catch {
                    Logger.error("Failed to play sound: \(filename)", error: error, category: .general)
                }
            }
        } else {
            // Fallback to system sounds if custom sound file not found
            Logger.debug("Sound file not found: \(filename), using fallback", category: .general)
        }
    }
    
    /// Play boxing clap sounds (10-second countdown pattern)
    /// Uses real boxing clap sound file if available, otherwise falls back to system sounds
    func playBoxingClaps() {
        guard soundEnabled else { return }
        
        // Try to play real boxing clap sound file
        if loadSound(named: boxingClapSound) != nil {
            // Play clap sound multiple times in a pattern
            let clapPattern: [TimeInterval] = [0.0, 0.15, 0.3, 0.5, 0.65, 0.8]
            
            for delay in clapPattern {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.playSound(named: self.boxingClapSound, volume: 0.8)
                }
            }
        } else {
            // Fallback to system sounds if file not found
            let clapPattern: [(SystemSoundID, TimeInterval)] = [
                (1103, 0.0),    // First clap
                (1104, 0.15),   // Second clap (quick)
                (1105, 0.3),    // Third clap (quick)
                (1103, 0.5),    // Fourth clap (slight pause)
                (1104, 0.65),   // Fifth clap
                (1105, 0.8),    // Sixth clap
            ]
            
            for (soundID, delay) in clapPattern {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    AudioServicesPlaySystemSound(soundID)
                }
            }
        }
    }
    
    /// Play boxing bell sound (for round/phase transitions)
    /// Uses real boxing bell sound file if available, otherwise falls back to system sound
    func playBoxingBell() {
        guard soundEnabled else { return }
        
        if loadSound(named: boxingBellSound) != nil {
            playSound(named: boxingBellSound, volume: 1.0)
        } else {
            // Fallback to a bell-like system sound
            AudioServicesPlaySystemSound(1056) // Phase transition sound as fallback
        }
    }
    
    /// Play a system sound for countdown/transitions
    func playCountdownBeep() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1057) // System beep sound
    }
    
    /// Play a success sound
    func playSuccessSound() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1054) // Success sound
    }
    
    /// Play a warning sound
    func playWarningSound() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1053) // Warning sound
    }
    
    /// Play a completion sound (uses boxing bell)
    func playCompletionSound() {
        playBoxingBell()
    }
    
    /// Play a phase transition sound (uses boxing bell)
    func playPhaseTransition() {
        playBoxingBell()
    }
}
