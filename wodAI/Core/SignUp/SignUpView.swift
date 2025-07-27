import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import WodAiAPI
import AuthenticationServices

struct SignUpView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var viewModel = SignUpViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showError = false
    
    @State private var isGoogleLoading = false
    @State private var isAppleLoading = false
    @StateObject private var appleSignInCoordinator = AppleSignInCoordinator()
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("Background"),
                        Color("Surface")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color("BrandPrimary"),
                                                Color("BrandSecondary")
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .shadow(color: Color("BrandPrimary").opacity(0.3), radius: 20, x: 0, y: 10)
                                
                                Image(systemName: "dumbbell.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Create Account")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundColor(Color("PrimaryText"))
                            }
                        }
                        .padding(.top, 40)
                        
                        // Sign Up Form Card
                        VStack(spacing: 20) {
                            VStack(spacing: 16) {
                                // Email Field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Email")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("SecondaryText"))
                                    
                                    TextField("Enter your email", text: $viewModel.email)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .textContentType(.emailAddress)
                                        .padding()
                                        .background(Color("Surface2"))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color("Border"), lineWidth: 1)
                                        )
                                }
                                
                                // Password Field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Password")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("SecondaryText"))
                                    
                                    SecureField("Create a password", text: $viewModel.password)
                                        .textContentType(.newPassword)
                                        .padding()
                                        .background(Color("Surface2"))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color("Border"), lineWidth: 1)
                                        )
                                    
                                    // Password requirements
                                    VStack(alignment: .leading, spacing: 4) {
                                        Label("At least 8 characters", systemImage: viewModel.password.count >= 8 ? "checkmark.circle.fill" : "circle")
                                            .font(.caption2)
                                            .foregroundColor(viewModel.password.count >= 8 ? Color("Success") : Color("SecondaryText"))
                                    }
                                    .padding(.horizontal, 4)
                                }
                                
                                // Confirm Password Field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Confirm Password")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("SecondaryText"))
                                    
                                    SecureField("Confirm your password", text: $viewModel.confirmPassword)
                                        .textContentType(.newPassword)
                                        .padding()
                                        .background(Color("Surface2"))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    viewModel.confirmPassword.isEmpty ? Color("Border") : 
                                                    (viewModel.password == viewModel.confirmPassword ? Color("Success") : Color("Warning")),
                                                    lineWidth: 1
                                                )
                                        )
                                }
                            }
                            Button(action: {
                                Task {
                                    await viewModel.signUp()
                                }
                            }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Create Account")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 20)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color("BrandPrimary"),
                                        Color("BrandSecondary")
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color("BrandPrimary").opacity(0.3), radius: 8, x: 0, y: 4)
                            .disabled(!viewModel.isValid || viewModel.isLoading)
                            .opacity(viewModel.isValid ? 1.0 : 0.6)
                        }
                        .padding(24)
                        .background(Color("Surface"))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .padding(.horizontal)
                        
                        // Divider with "or" text
                        HStack(spacing: 16) {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color("Border"))
                            
                            Text("or")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color("SecondaryText"))
                            
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color("Border"))
                        }
                        .padding(.horizontal, 40)
                        
                        // Google Sign Up Button - Modern & Minimal
                        Button(action: handleGoogleSignUp) {
                            HStack(spacing: 12) {
                                if isGoogleLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color("PrimaryText")))
                                        .scaleEffect(0.8)
                                } else {
                                    // Custom Google "G" Logo with official colors
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 24, height: 24)
                                        
                                        Text("G")
                                            .font(.system(size: 16, weight: .bold, design: .default))
                                            .foregroundColor(Color(red: 66/255, green: 133/255, blue: 244/255)) // Google Blue
                                    }
                                    
                                    HStack(spacing: 3) {
                                        Text("Sign up with ")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(Color("PrimaryText"))
                                        
                                        // Google text with brand colors
                                        HStack(spacing: 0) {
                                            Text("Google")
                                        }
                                        .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color("Surface"))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("Border"), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .disabled(isGoogleLoading || viewModel.isLoading)
                        .opacity(isGoogleLoading || viewModel.isLoading ? 0.6 : 1.0)
                        
                        // Apple Sign Up Button - Modern & Minimal
                        Button(action: handleAppleSignUp) {
                            HStack(spacing: 12) {
                                if isAppleLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color("PrimaryText")))
                                        .scaleEffect(0.8)
                                } else {
                                    // Apple Logo
                                    Image(systemName: "apple.logo")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(Color("PrimaryText"))
                                    
                                    Text("Sign up with Apple")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color("PrimaryText"))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color("Surface"))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("Border"), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .disabled(isAppleLoading || viewModel.isLoading || isGoogleLoading)
                        .opacity(isAppleLoading || viewModel.isLoading || isGoogleLoading ? 0.6 : 1.0)
                        
                        Text("By creating an account, you agree to our\nTerms of Service and Privacy Policy")
                            .font(.caption)
                            .foregroundColor(Color("SecondaryText"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 16)
                        
                        VStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundColor(Color("SecondaryText"))
                                .font(.subheadline)
                            
                            Button(action: { dismiss() }) {
                                Text("Sign In")
                                    .foregroundColor(Color("BrandPrimary"))
                                    .fontWeight(.semibold)
                                    .font(.subheadline)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                viewModel.authManager = authManager
            }
        }
    }
    
    private func handleGoogleSignUp() {
        Task {
            do {
                let success = try await signInWithGoogle()
                if success {
                    // Google sign-in/sign-up successful
                }
            } catch {
                await MainActor.run {
                    viewModel.errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    func signInWithGoogle() async throws -> Bool {
        guard let presentingViewController = await MainActor.run(body: {
            (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController
        }) else {
            return false
        }
        
        let signInConfig = GIDConfiguration(clientID: "323431688528-e8s8oo9o1qtf6vrcu69uf0hnb9etvdg3.apps.googleusercontent.com")
        
        await MainActor.run {
            isGoogleLoading = true
        }
        
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
                DispatchQueue.main.async { [self] in
                    self.isGoogleLoading = false
                    
                    switch gqlResult {
                    case .success(let graphqlResult):
                        if let errors = graphqlResult.errors, !errors.isEmpty {
                            self.viewModel.errorMessage = errors.first?.message ?? "Google sign-up failed"
                            self.showError = true
                        } else if let token = graphqlResult.data?.loginWithGoogle.token {
                            // Success - authenticate user which will trigger navigation
                            self.authManager.authenticate(token: token)
                            print("✅ Google sign-up successful, token set")
                        } else {
                            self.viewModel.errorMessage = "Invalid response from server"
                            self.showError = true
                        }
                        
                    case .failure(let error):
                        self.viewModel.errorMessage = error.localizedDescription
                        self.showError = true
                        print("❌ Google sign-up error: \(error.localizedDescription)")
                    }
                }
            }
            
            return false
            
        } catch {
            await MainActor.run {
                self.viewModel.errorMessage = error.localizedDescription
                self.showError = true
                isGoogleLoading = false
            }
            throw error
        }
    }
    
    private func handleAppleSignUp() {
        #if targetEnvironment(simulator)
        // Show alert for simulator limitations
        self.viewModel.errorMessage = "Sign in with Apple requires configuration in Xcode.\n\nTo test:\n1. Add 'Sign in with Apple' capability in Xcode\n2. Use a real device for full testing\n\nFor now, you can use email/password registration."
        self.showError = true
        return
        #else
        
        isAppleLoading = true
        
        appleSignInCoordinator.startSignInWithAppleFlow { result in
            switch result {
            case .success(let appleSignInResult):
                // Create account immediately upon successful authentication
                self.createAppleAccount(with: appleSignInResult)
                
            case .failure(let error):
                self.isAppleLoading = false
                
                if case ASAuthorizationError.canceled = error {
                    // User canceled, don't show error
                    return
                }
                
                // Check for specific error codes
                if let authError = error as? ASAuthorizationError {
                    switch authError.code {
                    case .unknown:
                        self.viewModel.errorMessage = "Sign in with Apple is not configured. Please enable it in Xcode's Signing & Capabilities."
                    case .invalidResponse:
                        self.viewModel.errorMessage = "Invalid response from Apple. Please try again."
                    case .notHandled:
                        self.viewModel.errorMessage = "Sign in with Apple is not available."
                    case .failed:
                        self.viewModel.errorMessage = "Sign in with Apple failed. Please try again."
                    default:
                        self.viewModel.errorMessage = error.localizedDescription
                    }
                } else {
                    self.viewModel.errorMessage = error.localizedDescription
                }
                
                self.showError = true
            }
        }
        #endif
    }
    
    private func createAppleAccount(with result: AppleSignInResult) {
        // TODO: Replace with your actual mutation when available
        /*
        let mutation = AppleLoginMutation(
            identityToken: result.identityToken,
            fullName: result.fullName,
            email: result.email,
            user: result.userId
        )
        
        Network.shared.client.perform(mutation: mutation) { [weak self] gqlResult in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isAppleLoading = false
                
                switch gqlResult {
                case .success(let graphqlResult):
                    if let token = graphqlResult.data?.loginWithApple.token {
                        // Store the Apple user ID for future credential checks
                        UserDefaults.standard.set(result.userId, forKey: "currentAppleUserId")
                        
                        // Authenticate the user
                        self.authManager.authenticate(token: token)
                        print("✅ Apple account created successfully")
                        
                        // Schedule credential check on app launch
                        self.appleSignInCoordinator.checkExistingAppleSignIn()
                        
                    } else if let errors = graphqlResult.errors {
                        self.viewModel.errorMessage = errors.first?.message ?? "Apple sign-up failed"
                        self.showError = true
                    }
                    
                case .failure(let error):
                    self.viewModel.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
        */
        
        // Temporary implementation - simulate account creation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isAppleLoading = false
            
            // Store credentials
            UserDefaults.standard.set(result.userId, forKey: "currentAppleUserId")
            
            print("✅ Apple Sign-Up successful (simulation)")
            print("- User ID: \(result.userId)")
            print("- Email: \(result.email ?? "Not provided")")
            print("- Name: \(result.fullName ?? "Not provided")")
            
            self.viewModel.errorMessage = "Apple Sign-Up ready - Backend integration pending"
            self.showError = true
        }
    }
}

#Preview {
    let authManager = AuthManager()
    SignUpView()
        .environmentObject(authManager)
}
