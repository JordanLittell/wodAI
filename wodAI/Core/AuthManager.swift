import Foundation
import SwiftUI
import WodAiAPI

// Create a helper class to manage authentication token
class AuthManager : ObservableObject {
    @Published var isAuthenticated: Bool
    @Published var isProvisioned: Bool = false
    @Published var needsProvisioning: Bool = false
    @Published var currentUserId: Int?
    
    private let tokenKey = "authToken"
    private let sessionExpiredKey = "sessionExpiredMessage"
    private let provisionedKey = "userProvisioned"
    private let userIdKey = "currentUserId"
    
    var token: String? {
        get {
            return UserDefaults.standard.string(forKey: tokenKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: tokenKey)
            // Update the published property when token changes
            DispatchQueue.main.async { [weak self] in
                self?.isAuthenticated = newValue != nil
            }
        }
    }
    
    
    init() {
        // Set initial authentication state without triggering property observers
        self.isAuthenticated = UserDefaults.standard.string(forKey: tokenKey) != nil
        self.isProvisioned = UserDefaults.standard.bool(forKey: provisionedKey)
        self.currentUserId = UserDefaults.standard.object(forKey: userIdKey) as? Int
        
        // Check if user needs provisioning on init
        checkProvisioningStatus()
    }
    
    var sessionExpiredMessage: String? {
        get {
            return UserDefaults.standard.string(forKey: sessionExpiredKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: sessionExpiredKey)
        }
    }
    
    func authenticate(token: String, userId: Int? = nil) {
        self.token = token
        // This automatically triggers isAuthenticated = true via the setter
        
        // Store user ID if provided
        if let userId = userId {
            self.currentUserId = userId
            UserDefaults.standard.set(userId, forKey: userIdKey)
        }
        
        // Check provisioning status after authentication
        checkProvisioningStatus()
    }
    
    func signOut() {
        clearToken()
        clearSessionExpiredMessage()
        clearUserId()
        isProvisioned = false
        needsProvisioning = false
    }
    
    private func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        print("setting token to null")
        DispatchQueue.main.async { [weak self] in
            self?.isAuthenticated = false
        }
    }
    
    private func clearUserId() {
        UserDefaults.standard.removeObject(forKey: userIdKey)
        currentUserId = nil
    }
    
    func clearSessionExpiredMessage() {
        UserDefaults.standard.removeObject(forKey: sessionExpiredKey)
        sessionExpiredMessage = nil
    }
    
    func handleSessionExpired() {
        print("🔓 Handling session expiration...")
        sessionExpiredMessage = "Your session has expired. Please log in again."
        signOut()
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .userDidLogout, object: nil)
        }
    }
    
    func checkProvisioningStatus() {
        guard isAuthenticated else {
            needsProvisioning = false
            return
        }
        
        // Use the stub service to check provisioning status
        ProvisioningService.shared.checkProvisioningStatus { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let isProvisioned):
                    self?.isProvisioned = isProvisioned
                    self?.needsProvisioning = !isProvisioned
                    UserDefaults.standard.set(isProvisioned, forKey: self?.provisionedKey ?? "")
                case .failure(_):
                    // In case of error, assume not provisioned
                    self?.isProvisioned = false
                    self?.needsProvisioning = true
                }
            }
        }
    }
    
    func completeProvisioning() {
        isProvisioned = true
        needsProvisioning = false
        UserDefaults.standard.set(true, forKey: provisionedKey)
    }
}
