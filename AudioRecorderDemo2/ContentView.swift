//
// Project: AudioRecorderDemo2
//  File: ContentView.swift
//  Created by Noah Carpenter
//  🐱 Follow me on YouTube! 🎥
//  https://www.youtube.com/@NoahDoesCoding97
//  Like and Subscribe for coding tutorials and fun! 💻✨
//  Fun Fact: Cats have five toes on their front paws, but only four on their back paws! 🐾
//  Dream Big, Code Bigger
//

import SwiftUI
import AVFoundation
import Combine
#if canImport(UIKit)
import UIKit // For haptic feedback and opening Settings
#endif

/*
 Overview:
 This is a minimal voice recording app demonstrating audio recording, playback, and live visual metering in SwiftUI.
 
 Components:
 - MiniRecorder: manages audio recording, file saving, and live microphone level metering.
 - MiniPlayer: plays audio files with progress tracking and playback controls.
 - MultiBarVisualizerView: a SwiftUI visualization showing recent meter levels as a horizontal bar graph.
 - ContentView: the main user interface combining recording, playing, and listing saved recordings.
 
 The app demonstrates key AVFoundation features, file management, and Combine timers for real-time UI updates.
*/

// MARK: - ContentView
// The main SwiftUI view that manages the entire UI layout including:
// - Title header
// - Live audio level visualization
// - Record and Play buttons
// - Displaying current file info
// - List of saved recordings with playback controls and delete option
struct ContentView: View {
    // State object to manage recording and audio levels.
    @StateObject private var rec = MiniRecorder()
    
    // State object to manage audio playback.
    @StateObject private var player = MiniPlayer()
    
    // List of saved recording file URLs.
    @State private var recordings: [URL] = []
    
    // Tracks whether microphone permission is denied to show an alert.
    @State private var micDenied = false
    
    var body: some View {
        VStack(spacing: 24) {
            
            // MARK: Title
            Text("Voice Recorder")
                .font(.title3).bold()
            
            // MARK: Waveform Visualizer - shows recent microphone level history bars.
            MultiBarVisualizerView(values: rec.meterHistory, barCount: 24)
                .frame(height: 54)
                .padding(.horizontal)
            
            // MARK: Simple live level bar - ProgressView version for less code.
            ProgressView(value: rec.meterLevel)
                .progressViewStyle(.linear)
                .tint(.blue.opacity(0.8))
                .frame(height: 8)
                .padding(.horizontal)
                .animation(.linear(duration: 0.05), value: rec.meterLevel)
            
            // MARK: Buttons - Record/Stop and Play current recording.
            HStack(spacing: 12) {
                
                // Record button toggles recording state.
                Button(rec.isRecording ? "Stop" : "Record") {
                    playTapHaptic()
                    if rec.isRecording {
                        // Stop recording; recordings list will refresh via onChange.
                        rec.stop()
                    } else {
                        // Stop playback if active, then start recording.
                        player.stop()
                        rec.start()
                    }
                }
                .buttonStyle(.borderedProminent)
                // Icon alternative:
                // .labelStyle(.iconOnly)
                // .font(.system(size: 22, weight: .bold))
                // .buttonStyle(.borderedProminent)
                // .overlay(Image(systemName: rec.isRecording ? "stop.fill" : "mic.fill").font(.system(size: 22)).foregroundStyle(.white))
                
                // Play button plays the current recording if available.
                Button("Play") {
                    playTapHaptic()
                    player.play(rec.fileURL)
                }
                .buttonStyle(.bordered)
                .disabled(rec.isRecording || rec.fileURL == nil) // Disable while recording or if no file.
                // Icon alternative:
                // .labelStyle(.iconOnly)
                // .font(.system(size: 20, weight: .semibold))
                // .overlay(Image(systemName: "play.fill").font(.system(size: 20)))
                // .disabled(rec.isRecording || rec.fileURL == nil)
            }
            
            // MARK: Current recording file info
            if let url = rec.fileURL {
                Text("File: \(url.lastPathComponent)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle) // Show start and end of filename for readability.
                
                // Alternative: show human-friendly date/time from file metadata
                // Text("Recorded: \(friendlyDate(for: url))")
                //     .font(.footnote)
                //     .foregroundStyle(.secondary)
                //     .lineLimit(1)
            }
            
            // MARK: List of saved recordings with playback and swipe-to-delete.
            List {
                Section("Recordings") {
                    ForEach(recordings, id: \.self) { url in
                        HStack(spacing: 8) {
                            Text(url.lastPathComponent)
                                .font(.footnote)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            
                            // Duration preview (computed via AVURLAsset):
                            // Text(audioDurationString(for: url))
                            //     .font(.caption2)
                            //     .foregroundStyle(.secondary)
                            //
                            // Waveform thumbnail placeholder (replace with real waveform rendering):
                            // Rectangle()
                            //     .fill(Color.secondary.opacity(0.25))
                            //     .frame(width: 40, height: 14)
                            //     .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                            
                            Button {
                                if player.playingURL == url && player.isPlaying {
                                    player.pause()
                                } else {
                                    player.play(url)
                                }
                            } label: {
                                Image(systemName: (player.playingURL == url && player.isPlaying) ? "pause.fill" : "play.fill")
                            }
                            .buttonStyle(.plain)
                            
                            ProgressView(value: player.playingURL == url ? player.progress : 0)
                                .frame(width: 60)
                            
                            // Share/export option (iOS 16+):
                            // if #available(iOS 16.0, *) {
                            //     ShareLink(item: url) {
                            //         Image(systemName: "square.and.arrow.up")
                            //     }
                            //     .buttonStyle(.plain)
                            // }
                        }
                    }
                    .onDelete { indexSet in
                        // Confirmation example: present a confirmation dialog before deleting.
                        // Consider storing the selected indexSet in @State and using .confirmationDialog.
                        // .confirmationDialog("Delete recording?", isPresented: $showDeleteConfirm) { ... }
                        
                        // Move to a "Trash" folder instead of permanent delete:
                        // if let dir = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
                        //     let trash = dir.appendingPathComponent("Recordings/Trash", isDirectory: true)
                        //     try? FileManager.default.createDirectory(at: trash, withIntermediateDirectories: true)
                        //     for index in indexSet {
                        //         let src = recordings[index]
                        //         let dst = trash.appendingPathComponent(src.lastPathComponent)
                        //         try? FileManager.default.moveItem(at: src, to: dst)
                        //         if player.playingURL == src { player.stop() }
                        //     }
                        //     recordings = recordingsList()
                        //     return
                        // }
                        
                        for index in indexSet {
                            let url = recordings[index]
                            try? FileManager.default.removeItem(at: url)
                            if player.playingURL == url {
                                player.stop()
                            }
                        }
                        recordings = recordingsList()
                    }
                }
            }
            
            Spacer() // Push content to top.
        }
        .padding()
        // --- UI Theme examples ---
        // Background gradient for the whole screen:
        // .background(
        //     LinearGradient(colors: [Color.blue.opacity(0.25), Color.purple.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
        // )
        // Rounded card style around content:
        // .background(.ultraThinMaterial)
        // .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        // .shadow(color: .black.opacity(0.1), radius: 12, y: 6)
        // Dark mode polish:
        // .preferredColorScheme(.dark)
        .task {
            // Request permission to record when view appears.
            rec.requestPermission { ok in
                // Show an alert if permission is denied.
                micDenied = (ok == false)
            }
            // Load existing recordings.
            recordings = recordingsList()
        }
        .onChange(of: rec.isRecording) { isRecording in
            // Keep player and recordings in sync with recording state.
            if isRecording {
                player.stop()
            } else {
                recordings = recordingsList()
            }
        }
        .alert("Microphone Access Needed", isPresented: $micDenied) {
            Button("OK", role: .cancel) {}
            #if canImport(UIKit)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            #endif
        } message: {
            Text("Please allow microphone access in Settings to record audio.")
        }
    }
    
    // Returns sorted list of recording files in the app's Recordings directory.
    func recordingsList() -> [URL] {
        // Locate the Recordings folder.
        let dir = try? FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Recordings", isDirectory: true)
        
        // List files in the folder, or return empty array if folder missing or error.
        guard let dir, let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return [] }
        
        // Filter for .m4a audio files and sort descending by filename (newest first).
        return files.filter { $0.pathExtension == "m4a" }.sorted { $0.lastPathComponent > $1.lastPathComponent }
    }
    
    // MARK: - Helpers
    private func playTapHaptic() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }
    
    // Format a friendly date/time for a file URL using its creation date.
    private func friendlyDate(for url: URL) -> String {
        if let values = try? url.resourceValues(forKeys: [.creationDateKey]), let date = values.creationDate {
            let df = DateFormatter()
            df.dateStyle = .medium
            df.timeStyle = .short
            return df.string(from: date)
        }
        // Fallback: derive from filename if it contains ISO8601 stamp
        let name = url.deletingPathExtension().lastPathComponent
        return name.replacingOccurrences(of: "T", with: " ")
    }
    
    // Compute a short duration string (e.g., 0:42) for an audio file.
    private func audioDurationString(for url: URL) -> String {
        let asset = AVURLAsset(url: url)
        let seconds = CMTimeGetSeconds(asset.duration)
        guard seconds.isFinite, seconds > 0 else { return "—" }
        let s = Int(seconds.rounded())
        let mPart = s / 60
        let sPart = s % 60
        return String(format: "%d:%02d", mPart, sPart)
    }
}
