//
//  ContentView.swift
//  wodAI
//
//  Created by Jordan Littell on 4/16/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authState = AuthState.shared
    @StateObject private var authManager = AuthManager() // Backwards compatibility
    @State private var hasCheckedAppleCredentials = false

    var body: some View {
        Group {
            if authState.isAuthenticated {
                if authState.needsProvisioning {
                    ProvisioningView()
                } else {
                    RootAppView()
                }
            } else {
                AuthenticationView()
            }
        }
        .environmentObject(authState)      // Inject new AuthState
        .environmentObject(authManager)    // Keep for backwards compatibility
        .onReceive(NotificationCenter.default.publisher(for: .userDidLogout)) { _ in
            print("🔓 Received logout notification, forcing authentication state update")
            // Force UI update by triggering the published property
            DispatchQueue.main.async {
                authState.signOut()
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
                print("Apple credentials are invalid or not found")
                // Clear any Apple-related session data if needed
            }
        }
    }
}

// MARK: - Root App View
struct RootAppView: View {
    var body: some View {
        AppNavigationView()
    }
}

#Preview {
    ContentView()
}
