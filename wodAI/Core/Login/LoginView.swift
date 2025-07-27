import SwiftUI
import WodAiAPI
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices

struct LoginView: View {
    
    @EnvironmentObject var authManager: AuthManager;
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isGoogleLoading = false
    @State private var isAppleLoading = false
    @StateObject private var appleSignInCoordinator = AppleSignInCoordinator()
    
    var body: some View {
        ZStack {
            // Background gradient
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
                    // Session Expired Message
                    if let sessionMessage = authManager.sessionExpiredMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.white)
                            Text(sessionMessage)
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("Warning"))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            // Clear the message after 5 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                withAnimation {
                                    authManager.clearSessionExpiredMessage()
                                }
                            }
                        }
                    }
                    
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
                                .frame(width: 120, height: 120)
                                .shadow(color: Color("BrandPrimary").opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            Image(systemName: "dumbbell.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text("WOD.ai")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(Color("PrimaryText"))
                        }
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color("SecondaryText"))
                                
                                TextField("Enter your email", text: $email)
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
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color("SecondaryText"))
                                
                                SecureField("Enter your password", text: $password)
                                    .textContentType(.password)
                                    .padding()
                                    .background(Color("Surface2"))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color("Border"), lineWidth: 1)
                                    )
                            }
                        }
                        
                        Button(action: signIn) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Sign In")
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
                        .disabled(email.isEmpty || password.isEmpty || isLoading)
                        .opacity((email.isEmpty || password.isEmpty || isLoading) ? 0.6 : 1.0)
                        .scaleEffect(email.isEmpty || password.isEmpty || isLoading ? 1.0 : 1.0)
                    }
                    .padding(24)
                    .background(Color("Surface"))
                    .cornerRadius(20)
                    
                    // Divider with "or" text
                    HStack(spacing: 10) {
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
                    
                    // Google Sign In Button - Modern & Minimal
                    Button(action: noOp) {
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
                                    Text("Continue with ")
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
                    .disabled(isGoogleLoading || isLoading)
                    .opacity(isGoogleLoading || isLoading ? 0.6 : 1.0)
                    
                    // Apple Sign In Button - Modern & Minimal
                    Button(action: handleAppleSignIn) {
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
                                
                                Text("Continue with Apple")
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
                    .disabled(isAppleLoading || isLoading || isGoogleLoading)
                    .opacity(isAppleLoading || isLoading || isGoogleLoading ? 0.6 : 1.0)
                    
                    // Sign Up Link
                    VStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(Color("SecondaryText"))
                            .font(.subheadline)
                        
                        Text("Sign Up")
                            .foregroundColor(Color("BrandPrimary"))
                            .fontWeight(.semibold)
                            .font(.subheadline)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
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
            DispatchQueue.main.async { [self] in
                self.isLoading = false
                
                switch gqlResult {
                case .success(let graphqlResult):
                    if let errors = graphqlResult.errors, !errors.isEmpty {
                        self.errorMessage = errors.first?.message ?? "Login failed"
                        self.showError = true
                    } else if let token = graphqlResult.data?.loginWithCredentials.token {
                        // Success - authenticate user which will trigger navigation
                        self.authManager.authenticate(token: token)
                        print("✅ Login successful, token set")
                    } else {
                        self.errorMessage = "Invalid response from server"
                        self.showError = true
                    }
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    print("❌ Login error: \(error.localizedDescription)")
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
                            self.errorMessage = errors.first?.message ?? "Google login failed"
                            self.showError = true
                        } else if let token = graphqlResult.data?.loginWithGoogle.token {
                            // Success - authenticate user which will trigger navigation
                            self.authManager.authenticate(token: token)
                            print("✅ Google login successful, token set")
                        } else {
                            self.errorMessage = "Invalid response from server"
                            self.showError = true
                        }
                        
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                        print("❌ Google login error: \(error.localizedDescription)")
                    }
                }
            }
            
            return false
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
                isGoogleLoading = false
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
    
    private func handleAppleSignIn() {
        #if targetEnvironment(simulator)
        // Show alert for simulator limitations
        self.errorMessage = "Sign in with Apple requires configuration in Xcode.\n\nTo test:\n1. Add 'Sign in with Apple' capability in Xcode\n2. Use a real device for full testing\n\nFor now, you can use email/password login."
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
                        self.errorMessage = "Sign in with Apple is not configured. Please enable it in Xcode's Signing & Capabilities."
                    case .invalidResponse:
                        self.errorMessage = "Invalid response from Apple. Please try again."
                    case .notHandled:
                        self.errorMessage = "Sign in with Apple is not available."
                    case .failed:
                        self.errorMessage = "Sign in with Apple failed. Please try again."
                    default:
                        self.errorMessage = error.localizedDescription
                    }
                } else {
                    self.errorMessage = error.localizedDescription
                }
                
                self.showError = true
            }
        }
        #endif
    }
    
    private func createAppleAccount(with result: AppleSignInResult) {
        print("identity token is: \(result.identityToken)")
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
                        print("✅ Apple account created/logged in successfully")
                        
                        // Schedule credential check on app launch
                        self.scheduleCredentialCheck()
                        
                    } else if let errors = graphqlResult.errors {
                        self.errorMessage = errors.first?.message ?? "Apple login failed"
                        self.showError = true
                    }
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
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
            
            print("✅ Apple Sign-In successful (simulation)")
            print("- User ID: \(result.userId)")
            print("- Email: \(result.email ?? "Not provided")")
            print("- Name: \(result.fullName ?? "Not provided")")
            
            self.errorMessage = "Apple Sign-In ready - Backend integration pending"
            self.showError = true
        }
    }
    
    private func scheduleCredentialCheck() {
        // This should be called on app launch to verify Apple credentials are still valid
        appleSignInCoordinator.checkExistingAppleSignIn()
    }
}

#Preview {
    let authManager = AuthManager()
    LoginView()
        .environmentObject(authManager)
    
}
