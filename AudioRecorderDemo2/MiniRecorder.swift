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
import AVFoundation
#if canImport(UIKit)
import UIKit // For haptic feedback
#endif
import AudioToolbox // For lightweight system sounds

// MARK: - MiniRecorder
// This class handles audio recording, including requesting permission, starting/stopping recording,
// saving files under Application Support, and updating a live meter level for UI visualization.
final class MiniRecorder: ObservableObject {
    
    // Indicates whether the recorder is currently recording.
    @Published var isRecording = false
    
    // Normalized microphone input level (0...1), updated frequently for UI meters.
    @Published var meterLevel: Float = 0
    
    // History of recent meter levels to display a waveform-like visualization.
    @Published var meterHistory: [Float] = []
    
    // Metering configuration: tweak these for smoother animation or longer history.
    // Example: set `meterInterval = 0.02` for smoother meters; `maxHistoryCount = 200` for a longer scrolling waveform.
    var meterInterval: TimeInterval = 0.05
    var maxHistoryCount: Int = 80
    
    // Internal AVAudioRecorder instance controlling the recording session.
    private var recorder: AVAudioRecorder?
    
    // Timer publisher to periodically update the meter level using Combine.
    private var meterTimer: AnyCancellable?
    
    // URL of the current recording file.
    private(set) var fileURL: URL?
    
    // Requests permission to access the microphone. Calls the completion handler with true/false.
    func requestPermission(_ done: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { ok in
                DispatchQueue.main.async { done(ok) }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { ok in
                DispatchQueue.main.async { done(ok) }
            }
        }
    }
    
    // Starts a new recording session.
    func start() {
        do {
            // 1) Activate and configure the audio session for recording + playback.
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            
            // 2) Determine the directory to save recordings. Use Application Support/Recordings.
            // This folder is suitable for persistent app data that is not user-visible.
            let dir = try FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("Recordings", isDirectory: true)
            
            // --- Examples: Change save location ---
            // Save to Documents (visible in Files app):
            // let dir = try FileManager.default
            //     .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            //     .appendingPathComponent("Recordings", isDirectory: true)
            //
            // Save to iCloud Drive (requires iCloud capability + container; may return nil if unavailable):
            // if let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
            //     let dir = containerURL
            //         .appendingPathComponent("Documents/Recordings", isDirectory: true)
            //     // Use `dir` below instead of the Application Support path
            // }
            // --- End examples ---
            
            // Create the directory if it doesn't exist yet.
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            
            // 3) Create a timestamped filename to avoid collisions.
            // Replace ":" with "-" since ":" is not allowed in filenames on some platforms.
            let stamp = ISO8601DateFormatter().string(from: .now).replacingOccurrences(of: ":", with: "-")
            let url = dir.appendingPathComponent("\(stamp).m4a")
            fileURL = url
            
            // 4) Recorder settings: use AAC format, 44.1kHz sample rate, mono channel, high quality encoding.
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            // --- Examples: Adjust recording settings ---
            // Stereo at 48 kHz (AAC):
            // let settings: [String: Any] = [
            //     AVFormatIDKey: kAudioFormatMPEG4AAC,
            //     AVSampleRateKey: 48_000,
            //     AVNumberOfChannelsKey: 2,
            //     AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            // ]
            //
            // Lower sample rate + bitrate for smaller files:
            // let settings: [String: Any] = [
            //     AVFormatIDKey: kAudioFormatMPEG4AAC,
            //     AVSampleRateKey: 22_050,
            //     AVNumberOfChannelsKey: 1,
            //     AVEncoderBitRateKey: 64_000,
            //     AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            // ]
            //
            // Linear PCM (WAV-like) uncompressed:
            // let settings: [String: Any] = [
            //     AVFormatIDKey: kAudioFormatLinearPCM,
            //     AVSampleRateKey: 44_100,
            //     AVNumberOfChannelsKey: 1,
            //     AVLinearPCMBitDepthKey: 16,
            //     AVLinearPCMIsFloatKey: false,
            //     AVLinearPCMIsBigEndianKey: false
            // ]
            // --- End examples ---
            
            // 5) Initialize AVAudioRecorder with the URL and settings.
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.isMeteringEnabled = true  // Enable metering to get live audio levels.
            recorder?.record()                  // Start recording.
            playStartFeedback()            // Haptics/sound when recording starts (see helpers below)
            isRecording = true                 // Update published state.
            
            // 6) Start a Combine timer that updates the meterLevel and meterHistory every 0.05 seconds.
            startMetering()
        } catch {
            // If something fails (e.g., permission denied), print the error.
            print("Start failed:", error)
        }
    }
    
    // Stops the current recording session and cleans up.
    func stop() {
        stopMetering()      // Stop updating metering.
        recorder?.stop()    // Stop recording.
        playStopFeedback()     // Haptics/sound when recording stops
        isRecording = false // Update state.
        recorder = nil      // Release recorder resources.
    }
    
    // MARK: - Metering
    
    // Starts a Combine timer that periodically reads audio power levels for visualization.
    private func startMetering() {
        // Cancel any existing timer before starting a new one.
        meterTimer?.cancel()
        
        // Tweak `meterInterval` and `maxHistoryCount` to adjust smoothness and history length.
        meterTimer = Timer.publish(every: meterInterval, on: .main, in: .common)
            .autoconnect() // Automatically connect the timer publisher.
            .sink { [weak self] _ in
                guard let self, let rec = self.recorder, rec.isRecording else { return }
                rec.updateMeters() // Refresh meter data
                
                // averagePower(forChannel:) returns a dB value typically between -60 (silence) and 0 (max)
                let power = rec.averagePower(forChannel: 0)
                self.meterLevel = Self.normalize(power) // Convert dB to normalized 0...1
                
                // Keep a short history of recent meter levels for drawing waveform bars.
                self.meterHistory.append(self.meterLevel)
                
                // Limit history size to maxHistoryCount to avoid memory bloat.
                if self.meterHistory.count > self.maxHistoryCount {
                    self.meterHistory.removeFirst(self.meterHistory.count - self.maxHistoryCount)
                }
            }
    }
    
    // Stops the meter update timer and resets meter data.
    private func stopMetering() {
        meterTimer?.cancel()
        meterTimer = nil
        meterLevel = 0
        meterHistory.removeAll()
    }
    
    // Converts a decibel audio power value to a normalized 0...1 float for UI representation.
    private static func normalize(_ db: Float) -> Float {
        let floor: Float = -60 // Define bottom dB level as silence.
        if db <= floor { return 0 } // Anything quieter than floor is zero.
        let clamped = max(min(db, 0), floor) // Clamp dB between floor and 0.
        return (clamped - floor) / -floor // Normalize the range to 0...1.
    }
    
    // MARK: - UI Feedback (Haptics & Sounds)
    private func playStartFeedback() {
        // Light haptic + optional system sound to confirm start
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
        // System sounds are optional; choose IDs that exist on iOS.
        // Comment out if you prefer silence.
        AudioServicesPlaySystemSound(1113) // Begin recording-like tone
    }
    
    private func playStopFeedback() {
        // Light haptic + optional system sound to confirm stop
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        #endif
        AudioServicesPlaySystemSound(1114) // End recording-like tone
    }
}
