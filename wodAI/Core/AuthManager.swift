import Foundation
import SwiftUI
import WodAiAPI

// Create a helper class to manage authentication token
class AuthManager : ObservableObject {
    @Published var isAuthenticated: Bool
    
    private let tokenKey = "authToken"
    private let sessionExpiredKey = "sessionExpiredMessage"
    
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
    
    var isLoggedIn: Bool {
        print("evaluating login")
        return UserDefaults.standard.string(forKey: tokenKey) != nil
    }
    
    init() {
        // Set initial authentication state without triggering property observers
        self.isAuthenticated = UserDefaults.standard.string(forKey: tokenKey) != nil
    }
    
    var sessionExpiredMessage: String? {
        get {
            return UserDefaults.standard.string(forKey: sessionExpiredKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: sessionExpiredKey)
        }
    }
    
    func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        print("setting token to null")
        DispatchQueue.main.async { [weak self] in
            self?.isAuthenticated = false
        }
    }
    
    func clearSessionExpiredMessage() {
        UserDefaults.standard.removeObject(forKey: sessionExpiredKey)
        sessionExpiredMessage = nil
    }
    
    func handleSessionExpired() {
        sessionExpiredMessage = "Your session has expired. Please log in again."
        clearToken()
    }
}
