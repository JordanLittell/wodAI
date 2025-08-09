import Foundation
import SwiftUI
import WodAiAPI
import Combine

// Backwards-compatible AuthManager that wraps the new AuthState
class AuthManager: ObservableObject {
    // MARK: - Dependency
    private let authState: AuthState
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties (for backwards compatibility)
    @Published var isAuthenticated: Bool = false
    @Published var isProvisioned: Bool = false
    @Published var needsProvisioning: Bool = false
    @Published var currentUserId: Int?
    
    // MARK: - Computed Properties
    var token: String? {
        get { authState.currentToken }
        set { 
            if let newValue = newValue {
                authState.currentToken = newValue
            } else {
                authState.signOut()
            }
        }
    }
    
    var sessionExpiredMessage: String? {
        get { authState.sessionExpiredMessage }
        set { authState.sessionExpiredMessage = newValue }
    }
    
    // MARK: - Initialization
    init(authState: AuthState = AuthState.shared) {
        self.authState = authState
        setupBindings()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Bind AuthState properties to local @Published properties for backwards compatibility
        authState.$isAuthenticated
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
        
        authState.$isProvisioned
            .assign(to: \.isProvisioned, on: self)
            .store(in: &cancellables)
        
        authState.$needsProvisioning
            .assign(to: \.needsProvisioning, on: self)
            .store(in: &cancellables)
        
        authState.$currentUserId
            .assign(to: \.currentUserId, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func authenticate(token: String, userId: Int? = nil) {
        authState.authenticate(token: token, userId: userId)
    }
    
    func signOut() {
        authState.signOut()
    }
    
    func clearSessionExpiredMessage() {
        authState.clearSessionExpiredMessage()
    }
    
    func handleSessionExpired() {
        authState.handleSessionExpired()
    }
    
    func checkProvisioningStatus() {
        Task {
            await authState.checkProvisioningStatus()
        }
    }
    
    func completeProvisioning() {
        authState.completeProvisioning()
    }
}

// MARK: - Shared Instance
extension AuthState {
    static let shared = AuthState()
}
