//
    // Project: AudioRecorderDemo2
    //  File: handles.swift
    //  Created by Noah Carpenter
    //  🐱 Follow me on YouTube! 🎥
    //  https://www.youtube.com/@NoahDoesCoding97
    //  Like and Subscribe for coding tutorials and fun! 💻✨
    //  Fun Fact: Cats have five toes on their front paws, but only four on their back paws! 🐾
    //  Dream Big, Code Bigger
    
import Combine
import SwiftUI
import AVFoundation


// MARK: - MiniPlayer
// This class handles audio playback of recorded files, including play, pause, stop,
// playback progress tracking, and seeking.
final class MiniPlayer: ObservableObject {
    // Indicates if audio is currently playing.
    @Published var isPlaying = false
    
    // Playback progress normalized between 0 and 1.
    @Published var progress: Double = 0
    
    // Internal AVAudioPlayer instance for audio playback.
    private var player: AVAudioPlayer?
    
    // Timer publisher to frequently update playback progress in the UI.
    private var timer: AnyCancellable?
    
    // The current URL of the audio file being played.
    private var currentURL: URL?
    
    // Plays the audio at the given URL, toggling pause if already playing this URL.
    func play(_ url: URL?) {
        guard let url else { return }
        
        // If already playing this file, toggle pause.
        if isPlaying, currentURL == url {
            pause()
            return
        }
        
        stop() // Stop any existing playback before starting new one.
        
        do {
            // Create AVAudioPlayer with the file URL.
            player = try AVAudioPlayer(contentsOf: url)
            currentURL = url
            
            player?.prepareToPlay() // Prepare hardware buffers for smooth playback.
            player?.play()           // Start playing.
            isPlaying = true        // Update playback status.
            
            // Start periodic updates to the progress bar.
            startUpdatingProgress()
        } catch {
            print("Playback failed:", error)
            isPlaying = false
        }
    }
    
    // Pauses current playback.
    func pause() {
        player?.pause()
        isPlaying = false
        stopUpdatingProgress()
    }
    
    // Stops playback and resets progress.
    func stop() {
        player?.stop()
        isPlaying = false
        progress = 0
        stopUpdatingProgress()
        player = nil
        currentURL = nil
    }
    
    // Seeks playback to a specific normalized progress position (0...1).
    func seek(to prog: Double) {
        guard let player, player.duration > 0 else { return }
        player.currentTime = prog * player.duration
        progress = prog
    }
    
    // Starts a Combine timer that frequently updates the playback progress for UI.
    private func startUpdatingProgress() {
        stopUpdatingProgress() // Cancel existing timer if any.
        
        timer = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let player = self.player else { return }
                
                if player.isPlaying {
                    // Update progress normalized to duration.
                    self.progress = player.duration > 0 ? player.currentTime / player.duration : 0
                } else {
                    // Playback ended or paused, update state accordingly.
                    self.isPlaying = false
                    self.stopUpdatingProgress()
                }
            }
    }
    
    // Stops the playback progress timer.
    private func stopUpdatingProgress() {
        timer?.cancel()
        timer = nil
    }
    
    // Computed property indicating whether playback is paused but not finished.
    var isPaused: Bool {
        player != nil && !isPlaying && progress > 0 && progress < 1
    }
    
    // Returns URL of the currently playing audio file, if any.
    var playingURL: URL? { currentURL }
}
