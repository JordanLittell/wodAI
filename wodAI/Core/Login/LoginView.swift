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
                        // Logo Image
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .cornerRadius(30) // Makes it rounded
                            .shadow(color: Color("BrandPrimary").opacity(0.3), radius: 20, x: 0, y: 10)
                        
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
                    
                    // Apple Sign In Button - Using Official Apple Button
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let authResults):
                                if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                                    handleAppleSignInSuccess(credential: appleIDCredential)
                                }
                            case .failure(let error):
                                handleAppleSignInError(error: error)
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 54)
                    .padding(.horizontal)
                    .disabled(isAppleLoading || isLoading || isGoogleLoading)
                    .opacity(isAppleLoading || isLoading || isGoogleLoading ? 0.6 : 1.0)
                    
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
                    } else if let token = graphqlResult.data?.loginWithCredentials.token,
                              let userId = graphqlResult.data?.loginWithCredentials.user.id {
                        // Success - authenticate user which will trigger navigation
                        self.authManager.authenticate(token: token, userId: userId)
                        print("✅ Login successful, token set, user ID: \(userId)")
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
                            let userId = graphqlResult.data?.loginWithGoogle.user.id
                            self.authManager.authenticate(token: token, userId: userId)
                            print("✅ Google login successful, token set" + (userId != nil ? ", user ID: \(userId!)" : ""))
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
    
    private func handleAppleSignInSuccess(credential: ASAuthorizationAppleIDCredential) {
        isAppleLoading = true
        
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            self.errorMessage = "Failed to get Apple ID token"
            self.showError = true
            self.isAppleLoading = false
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
        
        // Create Apple Sign In result
        let result = AppleSignInResult(
            identityToken: tokenString,
            userId: userId,
            email: email,
            fullName: fullNameString,
            authorizationCode: credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
        )
        
        createAppleAccount(with: result)
    }
    
    private func handleAppleSignInError(error: Error) {
        isAppleLoading = false
        
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
    
    private func createAppleAccount(with result: AppleSignInResult) {
        print("identity token is: \(result.identityToken)")
        
        let mutation = AppleLoginMutation(
            identityToken: result.identityToken,
            fullName: result.fullName != nil ? .some(result.fullName!) : .none,
            email: result.email != nil ? .some(result.email!) : .none,
            user: result.userId
        )
        
        Network.shared.client.perform(mutation: mutation) { gqlResult in
            DispatchQueue.main.async {
                self.isAppleLoading = false
                
                switch gqlResult {
                case .success(let graphqlResult):
                    if let token = graphqlResult.data?.loginWithApple.token,
                       let userId = graphqlResult.data?.loginWithApple.user.id {
                        // Store the Apple user ID for future credential checks
                        UserDefaults.standard.set(result.userId, forKey: "currentAppleUserId")
                        
                        // Authenticate the user
                        self.authManager.authenticate(token: token, userId: userId)
                        print("✅ Apple account created/logged in successfully")
                        print("- User ID: \(result.userId)")
                        print("- Email: \(result.email ?? "Not provided")")
                        print("- Name: \(result.fullName ?? "Not provided")")
                        
                        // Schedule credential check on app launch
                        self.scheduleCredentialCheck()
                        
                    } else if let errors = graphqlResult.errors {
                        self.errorMessage = errors.first?.message ?? "Apple login failed"
                        self.showError = true
                    } else {
                        self.errorMessage = "Invalid response from server"
                        self.showError = true
                    }
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    print("❌ Apple login error: \(error.localizedDescription)")
                }
            }
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
