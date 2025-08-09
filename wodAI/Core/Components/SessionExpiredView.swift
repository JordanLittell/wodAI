//
//  SessionExpiredView.swift
//  wodAI
//
//  Graceful session expiration handling
//

import SwiftUI

struct SessionExpiredView: View {
    @Binding var isPresented: Bool
    var onReauthenticate: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.warning)
                .padding(.top, 40)
            
            // Title
            Text("Session Expired")
                .font(.title)
                .fontWeight(.bold)
            
            // Message
            Text("Your session has expired for security reasons. Please log in again to continue.")
                .font(.body)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Actions
            VStack(spacing: 12) {
                Button(action: onReauthenticate) {
                    Text("Log In Again")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brandPrimary)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.brandPrimary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: 350)
        .background(Color(.surface))
        .cornerRadius(20)
        .shadow(radius: 20)
    }
}

// MARK: - Session Manager
class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    @Published var showSessionExpired = false
    @Published var pendingAction: (() -> Void)?
    
    // MARK: - Dependencies
    private let authProvider: AuthenticationProvider
    
    init(authProvider: AuthenticationProvider = AuthState.shared) {
        self.authProvider = authProvider
    }
    
    func handleUnauthorized(retry: @escaping () -> Void) {
        // Store the action to retry after re-authentication
        pendingAction = retry
        showSessionExpired = true
    }
    
    func handleReauthentication() {
        showSessionExpired = false
        authProvider.logout()
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }
    
    func retryPendingAction() {
        if let action = pendingAction {
            action()
            pendingAction = nil
        }
    }
}

// MARK: - View Modifier for Session Handling
struct SessionExpiredModifier: ViewModifier {
    @ObservedObject private var sessionManager = SessionManager.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if sessionManager.showSessionExpired {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                SessionExpiredView(
                    isPresented: $sessionManager.showSessionExpired,
                    onReauthenticate: {
                        sessionManager.handleReauthentication()
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: sessionManager.showSessionExpired)
    }
}

extension View {
    func handleSessionExpiration() -> some View {
        modifier(SessionExpiredModifier())
    }
}
