import Foundation
import AuthenticationServices

class AppleSignInService: NSObject {
    static let shared = AppleSignInService()
    
    private override init() {
        super.init()
    }
    
    /// Check the validity of stored Apple credentials on app launch
    func checkCredentialState(completion: @escaping (Bool) -> Void) {
        guard let userId = UserDefaults.standard.string(forKey: "currentAppleUserId") else {
            completion(false)
            return
        }
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: userId) { (credentialState, error) in
            switch credentialState {
            case .authorized:
                // The Apple ID credential is valid
                print("✅ Apple ID credential is valid for user: \(userId)")
                completion(true)
                
            case .revoked:
                // The Apple ID credential is revoked, remove stored data
                print("❌ Apple ID credential is revoked")
                self.clearStoredCredentials()
                completion(false)
                
            case .notFound:
                // No credential was found, remove stored data
                print("❌ Apple ID credential not found")
                self.clearStoredCredentials()
                completion(false)
                
            case .transferred:
                // The app was transferred to another team
                print("⚠️ Apple ID credential transferred")
                completion(false)
                
            @unknown default:
                print("⚠️ Unknown Apple ID credential state")
                completion(false)
            }
        }
    }
    
    /// Perform fast re-authentication if credentials are valid
    func performExistingAccountSetup(completion: @escaping () -> Void) {
        guard let _ = UserDefaults.standard.string(forKey: "currentAppleUserId") else {
            completion()
            return
        }
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [
            ASAuthorizationAppleIDProvider().createRequest()
        ])
        
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    private func clearStoredCredentials() {
        UserDefaults.standard.removeObject(forKey: "currentAppleUserId")
        UserDefaults.standard.removeObject(forKey: "appleUserId")
        UserDefaults.standard.removeObject(forKey: "appleUserEmail")
        UserDefaults.standard.removeObject(forKey: "appleUserFullName")
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleSignInService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case _ as ASAuthorizationAppleIDCredential:
            print("✅ Re-authenticated with Apple ID")
            // You can refresh your session here if needed
            
        default:
            break
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Apple re-authentication failed: \(error.localizedDescription)")
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleSignInService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let window = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive })
            .flatMap({ $0 as? UIWindowScene })?
            .windows
            .first(where: { $0.isKeyWindow }) else {
            return UIWindow()
        }
        return window
    }
}
