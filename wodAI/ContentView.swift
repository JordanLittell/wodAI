//
//  ContentView.swift
//  wodAI
//
//  Created by Jordan Littell on 4/16/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var hasCheckedAppleCredentials = false

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if authManager.needsProvisioning {
                    ProvisioningView()
                } else {
                    RootAppView()
                        .environmentObject(EnhancedWorkoutGeneratorViewModel())
                        .environmentObject(WODSessionManager.shared)
                }
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
        .onAppear {
            checkAppleSignInCredentials()
        }
    }
    
    private func checkAppleSignInCredentials() {
        guard !hasCheckedAppleCredentials else { return }
        hasCheckedAppleCredentials = true
        
        // Check Apple Sign-In credential state on app launch
        AppleSignInService.shared.checkCredentialState { isValid in
            if isValid {
                print("✅ Apple credentials are valid")
                // You might want to refresh the session here
            } else {
                print("❌ Apple credentials are invalid or not found")
                // Clear any Apple-related session data if needed
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
