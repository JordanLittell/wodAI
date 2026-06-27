//
//  wodAIApp.swift
//  wodAI
//
//  Created by Jordan Littell on 4/16/25.
//

import SwiftUI

@main
struct wodAIApp: App {
    // Use the shared AuthState instance for consistency
    @StateObject private var authState = AuthState.shared
    @StateObject private var authManager = AuthManager() // Backwards compatibility

    init() {
        TelemetryService.initialize()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authState)
                .environmentObject(authManager)
                // Bring up WatchConnectivity so the phone can hand live workouts to the watch.
                .task { HIITSessionManager.shared.activate() }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthState.shared)
        .environmentObject(AuthManager())
}
