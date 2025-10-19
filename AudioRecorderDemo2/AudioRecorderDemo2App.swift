/*
 Project: AudioRecorderDemo2
 Summary:
 A lightweight SwiftUI sample app demonstrating audio recording on iOS. The app launches into
 `ContentView`, where users can interact with the recording UI (start/stop, view status, etc.).

 Key Features:
 - Request and manage microphone permission
 - Configure audio session for recording
 - Start/stop recording and persist audio files
 - Basic error handling and user feedback (as implemented in the UI layer)

 Requirements & Setup:
 - Add NSMicrophoneUsageDescription to Info.plist with a user-facing reason.
 - Test on a real device for accurate microphone behavior (simulator has limitations).
 - Wear headphones when testing to avoid feedback loops.

 Architecture Notes:
 - Entry point: AudioRecorderDemo2App -> ContentView (SwiftUI lifecycle)
 - UI: SwiftUI views compose the recording interface
 - Audio: Recording logic is encapsulated in a dedicated model/manager type (see project files)
 - Persistence: Recordings are typically saved to the app's Documents directory

 Platform Targets:
 - iOS (update minimum deployment as needed in project settings)

 Maintenance Tips:
 - Handle audio session interruptions (phone calls, Siri) gracefully
 - Consider background recording behavior and entitlements if needed
 - Provide clear user feedback for permission denials and recording failures
*/

// 
    // Project: AudioRecorderDemo2
    //  File: AudioRecorderDemo2App.swift
    //  Created by Noah Carpenter
    //  🐱 Follow me on YouTube! 🎥
    //  https://www.youtube.com/@NoahDoesCoding97
    //  Like and Subscribe for coding tutorials and fun! 💻✨
    //  Fun Fact: Cats have five toes on their front paws, but only four on their back paws! 🐾
    //  Dream Big, Code Bigger
    

import SwiftUI

// MARK: - App Entry Point
@main
struct AudioRecorderDemo2App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
