import Foundation
import AuthenticationServices
import SwiftUI

struct AppleSignInResult {
    let identityToken: String
    let userId: String
    let email: String?
    let fullName: String?
    let authorizationCode: String?
}

// MARK: - Apple Sign In Coordinator
class AppleSignInCoordinator: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    private var completion: ((Result<AppleSignInResult, Error>) -> Void)?
    
    override init() {
        super.init()
    }
    
    func startSignInWithAppleFlow(completion: @escaping (Result<AppleSignInResult, Error>) -> Void) {
        self.completion = completion
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        // Also check for existing credentials
        let passwordProvider = ASAuthorizationPasswordProvider()
        let passwordRequest = passwordProvider.createRequest()
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request, passwordRequest])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func checkExistingAppleSignIn() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        
        // Check if we have a stored user ID
        guard let userId = UserDefaults.standard.string(forKey: "appleUserId") else {
            return
        }
        
        // Check the credential state
        appleIDProvider.getCredentialState(forUserID: userId) { [weak self] (credentialState, error) in
            switch credentialState {
            case .authorized:
                // The Apple ID credential is valid
                print("Apple ID Credential is valid")
                // You might want to refresh the user's session here
                
            case .revoked:
                // The Apple ID credential is revoked
                print("Apple ID Credential is revoked")
                self?.clearStoredAppleCredentials()
                
            case .notFound:
                // No credential was found
                print("No Apple ID Credential found")
                self?.clearStoredAppleCredentials()
                
            default:
                break
            }
        }
    }
    
    private func clearStoredAppleCredentials() {
        UserDefaults.standard.removeObject(forKey: "appleUserId")
        UserDefaults.standard.removeObject(forKey: "appleUserEmail")
        UserDefaults.standard.removeObject(forKey: "appleUserFullName")
    }
    
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
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            handleAppleIDCredential(appleIDCredential)
            
        case let passwordCredential as ASPasswordCredential:
            // Handle password-based sign in
            handlePasswordCredential(passwordCredential)
            
        default:
            break
        }
    }
    
    private func handleAppleIDCredential(_ credential: ASAuthorizationAppleIDCredential) {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            completion?(.failure(NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get Apple ID token"])))
            return
        }
        
        // Extract user information (only available on first sign-in)
        let userId = credential.user
        let email = credential.email
        let fullName = credential.fullName
        var fullNameString: String? = nil
        
        if let fullName = fullName {
            var nameComponents = [String]()
            if let givenName = fullName.givenName {
                nameComponents.append(givenName)
            }
            if let familyName = fullName.familyName {
                nameComponents.append(familyName)
            }
            if !nameComponents.isEmpty {
                fullNameString = nameComponents.joined(separator: " ")
            }
        }
        
        // Store credentials locally
        storeAppleCredentials(userId: userId, email: email, fullName: fullNameString)
        
        let authorizationCode = credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
        
        let result = AppleSignInResult(
            identityToken: tokenString,
            userId: userId,
            email: email ?? getStoredEmail(),
            fullName: fullNameString ?? getStoredFullName(),
            authorizationCode: authorizationCode
        )
        
        completion?(.success(result))
    }
    
    private func handlePasswordCredential(_ credential: ASPasswordCredential) {
        // For password-based sign in
        let username = credential.user
        _ = credential.password
        
        // You might want to use these credentials to sign in
        print("Password credential - User: \(username)")
    }
    
    private func storeAppleCredentials(userId: String, email: String?, fullName: String?) {
        UserDefaults.standard.set(userId, forKey: "appleUserId")
        
        // Only store email and name if they're provided (first sign-in)
        if let email = email {
            UserDefaults.standard.set(email, forKey: "appleUserEmail")
        }
        if let fullName = fullName {
            UserDefaults.standard.set(fullName, forKey: "appleUserFullName")
        }
    }
    
    private func getStoredEmail() -> String? {
        return UserDefaults.standard.string(forKey: "appleUserEmail")
    }
    
    private func getStoredFullName() -> String? {
        return UserDefaults.standard.string(forKey: "appleUserFullName")
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion?(.failure(error))
    }
}
