import SwiftUI
import WodAiAPI
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    
    @EnvironmentObject var authManager: AuthManager;
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo and Title
                Image(systemName: "dumbbell.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                
                Text("wodAI")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Login Form
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: signIn) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Divider with "or" text
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                    
                    Text("or")
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                }
                .padding(.horizontal)
                
                // Google Sign In Button
                GoogleSignInButton(action: noOp)
                    .frame(height: 50)
                    .padding(.horizontal)
                
                Spacer()
                
                // Sign Up Link
                NavigationLink(destination: SignUpView()) {
                    Text("Don't have an account? Sign Up")
                        .foregroundColor(.blue)
                }
                .padding(.bottom)
            }
            .padding()
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func noOp() {
        Task {
            do {
                let success = try await signInWithGoogle()
                if success {
                    // Navigate to main app or handle successful login
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
    
    private func signIn() {
        isLoading = true
        let mutation = LoginWithCredentialsMutation(email: email, password: password)
        Network.shared.client.perform(mutation: mutation) { gqlResult in
            switch gqlResult {
            case .success(let graphqlResult):
                guard
                    let token = graphqlResult.data?.loginWithCredentials.token else {return}
                authManager.token = token
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        isLoading = false
    }
    
    func signInWithGoogle() async throws -> Bool {
        guard let presentingViewController = await (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {
            return false
        }
        
        let signInConfig = GIDConfiguration(clientID: "323431688528-e8s8oo9o1qtf6vrcu69uf0hnb9etvdg3.apps.googleusercontent.com")
        
        await MainActor.run { isLoading = true }
        
        do {
            GIDSignIn.sharedInstance.configuration = signInConfig
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: presentingViewController
            )
            
            guard let idToken: String = result.user.idToken?.tokenString else {
                return false
            }
            
            let mutation = GoogleLoginMutation(idToken: idToken)
            
            Network.shared.client.perform(mutation: mutation) { gqlResult in
                switch gqlResult {
                case .success(let graphqlResult):
                    guard
                        let token = graphqlResult.data?.loginWithGoogle.token,
                        let user = graphqlResult.data?.loginWithGoogle.user else {return}
                    
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
            
            return false
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
                isLoading = false
            }
            throw error
        }
    }
    
    private func getRootViewController() -> UIViewController {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = screen.windows.first?.rootViewController else {
            return .init()
        }
        return root
    }
}

#Preview {
    LoginView()
}
