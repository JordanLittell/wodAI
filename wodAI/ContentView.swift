//
//  ContentView.swift
//  wodAI
//
//  Created by Jordan Littell on 4/16/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                RootAppView()
                    .environmentObject(EnhancedWorkoutGeneratorViewModel())
                    .environmentObject(WODSessionManager.shared)
            } else {
                AuthenticationView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidLogout)) { _ in
            print("🔓 Received logout notification, forcing authentication state update")
            // Force UI update by triggering the published property
            DispatchQueue.main.async {
                authManager.isAuthenticated = false
            }
        }
    }
}

// MARK: - Root App View with WOD Session Overlay
struct RootAppView: View {
    @ObservedObject private var sessionManager = WODSessionManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content
            MainTabView()
            
            // Mini-player above tab bar when active
            if sessionManager.isActive {
                WODMiniPlayer()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: sessionManager.isActive)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
