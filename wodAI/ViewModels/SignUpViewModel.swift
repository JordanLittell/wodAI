import Foundation
import SwiftUI
import WodAiAPI

@MainActor
class SignUpViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var errorMessage = ""
    @Published var isLoading = false
    @Published var isSignedUp = false
    
    weak var authManager: AuthManager?
    
    var isValid: Bool {
        !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword
    }
    
    func signUp() async {
        guard isValid else {
            errorMessage = "Please fill in all fields and ensure passwords match"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        Network.shared.client.perform(mutation: RegisterUserMutation(email: email, password: password)) { [weak self] result in
            switch result {
            case .success(let graphqlResult):
                print(graphqlResult)
                if let error = graphqlResult.errors?.first {
                    self?.errorMessage = error.description
                    return
                }
                
                guard let token = graphqlResult.data?.register.token else {
                    self?.errorMessage = "Failed to get authentication token"
                    return
                }
                
                // Authenticate user and update UI state
                DispatchQueue.main.async {
                    self?.authManager?.authenticate(token: token)
                    self?.isSignedUp = true
                    self?.errorMessage = ""
                }
                
            case .failure(let error):
                print(error)
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
