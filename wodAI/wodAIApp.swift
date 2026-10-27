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
        #if DEBUG
        if UITestMode.isActive {
            UITestMode.configure()
            return
        }
        #endif
        // Unit tests run inside the app: keep their deliberate failures and
        // fixtures out of Sentry and PostHog.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return
        }
        TelemetryService.initialize()
        AnalyticsService.initialize()
        // A restored sign-in never goes through authenticate(), which is
        // where athletes are otherwise identified.
        if AuthState.shared.isAuthenticated, let userId = AuthState.shared.currentUserId {
            TelemetryService.identify(userId: String(userId))
            AnalyticsService.identify(userId: String(userId))
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authState)
                .environmentObject(authManager)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthState.shared)
        .environmentObject(AuthManager())
}
