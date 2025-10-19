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
            // Calculate sizes and spacing for bars.
            let width = geo.size.width
            let height = geo.size.height
            let barSpacing: CGFloat = 1
            let barWidth = (width - CGFloat(barCount - 1) * barSpacing) / CGFloat(barCount)
            
            // Group meter values into chunks to average for each bar.
            let chunkSize = max(1, values.count / barCount)
            
            // Compute average value per bar segment to smooth the waveform.
            let barValues: [Float] = (0..<barCount).map { i in
                let start = i * chunkSize
                let end = min(start + chunkSize, values.count)
                if start >= end { return 0 }
                let slice = values[start..<end]
                return slice.reduce(0, +) / Float(slice.count)
            }
            
            HStack(alignment: .center, spacing: barSpacing) {
                ForEach(barValues.indices, id: \.self) { i in
                    // Draw each bar with a minimum height for visibility.
                    let v = CGFloat(barValues[i])
                    let capped = max(0.07, min(v, 1)) // Ensure thin min bar to see quiet sections.
                    Rectangle()
                        .fill(Color.primary.opacity(0.85))
                        .frame(width: barWidth, height: capped * height)
                        .cornerRadius(barWidth / 2)
                        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                        // Vertically center the bar within the available height.
                        .offset(y: (height - capped * height) / 2)
                }
            }
        }
    }
}
