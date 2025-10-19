//
    // Project: AudioRecorderDemo2
    //  File: MultiBarVisualizerView.swift
    //  Created by Noah Carpenter
    //  🐱 Follow me on YouTube! 🎥
    //  https://www.youtube.com/@NoahDoesCoding97
    //  Like and Subscribe for coding tutorials and fun! 💻✨
    //  Fun Fact: Cats have five toes on their front paws, but only four on their back paws! 🐾
    //  Dream Big, Code Bigger
    
import SwiftUI
import Combine
import AVFoundation

// MARK: - MultiBarVisualizerView
// A SwiftUI view that displays an array of audio level values as a horizontal bar graph.
// It averages meter data into a fixed number of bars for a smooth waveform effect.
struct MultiBarVisualizerView: View {
    // Array of normalized meter values (0...1) to visualize.
    let values: [Float]
    
    // Number of bars to display across the view.
    let barCount: Int
    
    var body: some View {
        GeometryReader { geo in
            // Calculate sizes and spacing for bars with safe clamping.
            let rawWidth = geo.size.width
            let rawHeight = geo.size.height
            let width = rawWidth.isFinite ? max(0, rawWidth) : 0
            let height = rawHeight.isFinite ? max(0, rawHeight) : 0

            // Ensure we never divide by zero and spacing doesn't make width negative.
            let safeBarCount = max(1, barCount)
            let barSpacing: CGFloat = 1 // Increase for chunky retro look, decrease for tighter/smoother detail.
            // Example tweaks:
            // let barSpacing: CGFloat = 0.5   // tighter spacing
            // let barSpacing: CGFloat = 2.0   // chunkier spacing
            // Tip: increase `barCount` at call site for more detail, reduce for a retro look.

            let totalSpacing = CGFloat(safeBarCount - 1) * barSpacing
            let availableWidth = max(0, width - totalSpacing)
            let barWidth = availableWidth / CGFloat(safeBarCount)

            // Group meter values into chunks to average for each bar.
            let chunkSize = max(1, values.count / safeBarCount)

            // Compute average value per bar segment to smooth the waveform.
            let barValues: [Float] = (0..<safeBarCount).map { i in
                let start = i * chunkSize
                let end = min(start + chunkSize, values.count)
                if start >= end { return 0 }
                let slice = values[start..<end]
                return slice.reduce(0, +) / Float(slice.count)
            }
            // Add animation by attaching .animation(_, value: values) to HStack or Rectangle (see examples below).

            HStack(alignment: .center, spacing: barSpacing) {
                ForEach(0..<safeBarCount, id: \.self) { i in
                    // Draw each bar with a minimum height for visibility.
                    let base = CGFloat(barValues[i])
                    let v = base.isFinite ? base : 0
                    let capped = max(0.07, min(v, 1)) // Ensure thin min bar to see quiet sections.
                    let barHeight = max(0, min(height, capped * height))
                    let safeBarWidth = max(0, barWidth)
                    let yOffset = (height - barHeight) / 2

                    Rectangle()
                    // --- Bar styling examples ---
                    // 1) Linear gradient (top-to-bottom):
                    // .fill(
                    //     LinearGradient(
                    //         colors: [Color.accentColor.opacity(0.95), Color.accentColor.opacity(0.4)],
                    //         startPoint: .top,
                    //         endPoint: .bottom
                    //     )
                    // )
                    //
                    // 2) Rainbow gradient across bars (apply to container instead for continuous effect):
                    // .fill(
                    //     AngularGradient(
                    //         gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .indigo, .purple, .red]),
                    //         center: .center
                    //     )
                    // )
                    //
                    // 3) Dynamic per-bar color based on level (uncomment helper at bottom):
                    // .fill(levelColor(Double(capped)))
                    // --- End styling examples ---
                        .fill(Color.primary.opacity(0.85))
                        .frame(width: safeBarWidth, height: barHeight)
                        .cornerRadius(safeBarWidth / 2)
                        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                        // Vertically center the bar within the available height.
                        .offset(y: yOffset)
                        // --- Animation example ---
                        // .animation(.easeOut(duration: 0.12), value: values)
                        // Try .linear(duration: 0.05) for a snappier feel, or increase duration for smoother motion.
                        
                        // --- Mirror display example ("stereo" look) ---
                        // Replace this single Rectangle with a VStack of two mirrored bars:
                        // VStack(spacing: 0) {
                        //     Rectangle()
                        //         .fill(Color.primary.opacity(0.85))
                        //         .frame(width: safeBarWidth, height: barHeight / 2)
                        //     Rectangle()
                        //         .fill(Color.primary.opacity(0.6)) // slightly dimmer bottom half
                        //         .frame(width: safeBarWidth, height: barHeight / 2)
                        // }
                        // .frame(height: barHeight)
                        // .offset(y: yOffset)
                        // Note: For gradient or dynamic colors, apply the same fill logic as above to each half.
                }
            }
        }
    }

    // --- Helper: Map level (0...1) to a color using hue ---
    // Uncomment to use with `.fill(levelColor(Double(capped)))` above.
    // private func levelColor(_ level: Double) -> Color {
    //     // Map 0...1 to hue 0.0 (red) -> 0.4 (green-ish)
    //     let hue = max(0, min(0.4, 0.4 * level))
    //     return Color(hue: hue, saturation: 0.9, brightness: 0.95)
    // }
}
