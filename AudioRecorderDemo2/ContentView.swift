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
// import Accelerate

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
                
                // Play button plays the current recording if available.
                Button("Play") {
                    player.play(rec.fileURL)
                }
                .buttonStyle(.bordered)
                .disabled(rec.isRecording || rec.fileURL == nil) // Disable while recording or if no file.
            }
            
            // MARK: Current recording file info
            if let url = rec.fileURL {
                Text("File: \(url.lastPathComponent)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle) // Show start and end of filename for readability.
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
                        }
                    }
                    .onDelete { indexSet in
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
        .task {
            // Request permission to record when view appears.
            rec.requestPermission { _ in }
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
}

