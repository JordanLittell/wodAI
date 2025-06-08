import Foundation
import SwiftUI
import WodAiAPI

// Create a helper class to manage authentication token
class AuthManager : ObservableObject {
    
    private let tokenKey = "authToken"
    
    var token: String? {
        get {
            return UserDefaults.standard.string(forKey: tokenKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: tokenKey)
        }
    }
    
    var isLoggedIn: Bool {
        print("evaluating login")
        return UserDefaults.standard.string(forKey: tokenKey) != nil
    }
    
    func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        print("setting token to null")
        token = nil
    }
}
