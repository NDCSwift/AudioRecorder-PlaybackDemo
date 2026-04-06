# 🎙️ Audio Recorder & Playback Demo

A SwiftUI app that lets you record audio from the microphone, save clips locally, and play them back — complete with a live multi-bar waveform visualizer during recording and playback.

---

## 🤔 What this is

This project demonstrates how to build a full audio recorder and player in SwiftUI using `AVAudioRecorder` and `AVAudioPlayer`. It includes a live animated visualizer that reacts to audio levels in real time, split across a clean `MiniRecorder` and `MiniPlayer` component architecture.

## ✅ Why you'd use it

- **MiniRecorder** — handles mic permissions, recording state, and live audio metering
- **MiniPlayer** — manages playback, scrubbing, and playback progress
- **MultiBarVisualizerView** — animated bar chart that responds to real-time audio amplitude
- **Self-contained** — no third-party audio libraries; pure AVFoundation

## 📺 Watch on YouTube

[![Watch on YouTube](https://img.shields.io/badge/YouTube-Watch%20the%20Tutorial-red?style=for-the-badge&logo=youtube)](https://youtu.be/vNy3qZi46p4)

> This project was built for the [NoahDoesCoding YouTube channel](https://www.youtube.com/@NoahDoesCoding97).

---

## 🚀 Getting Started

### 1. Clone the Repo
```bash
git clone https://github.com/NDCSwift/AudioRecorder-PlaybackDemo.git
cd AudioRecorder-PlaybackDemo
```

### 2. Open in Xcode
- Double-click `AudioRecorderDemo2.xcodeproj`

### 3. Set Your Development Team
In Xcode: **TARGET → Signing & Capabilities → Team**

### 4. Update the Bundle Identifier
Change `com.example.MyApp` to a unique identifier (e.g., `com.yourname.AudioRecorderDemo`).

---

## 🛠️ Notes

- Microphone permission (`NSMicrophoneUsageDescription`) must be set in Info.plist.
- Recordings are saved to the app's documents directory.
- If you see a code signing error, check that Team and Bundle ID are set.

## 📦 Requirements

- iOS 16+
- Xcode 15+
- Swift 5.9+

---

📺 [Watch the guide on YouTube](https://youtu.be/vNy3qZi46p4)
