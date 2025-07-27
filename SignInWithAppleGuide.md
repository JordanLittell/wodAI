# Sign in with Apple Configuration Guide

## Prerequisites

1. **Apple Developer Account**: You need a paid Apple Developer account
2. **App ID Configuration**: Your app must have Sign in with Apple capability enabled

## Step 1: Configure in Xcode

### Enable Capability
1. Open your project in Xcode
2. Select your project in the navigator
3. Select your app target (wodAI)
4. Go to "Signing & Capabilities" tab
5. Click "+ Capability" button
6. Search for and add "Sign in with Apple"

### Configure Entitlements
The capability will automatically add the necessary entitlements to your app.

## Step 2: Configure App ID (Apple Developer Portal)

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to "Certificates, Identifiers & Profiles"
3. Select "Identifiers" → Find your app
4. Enable "Sign in with Apple" capability
5. Configure as either:
   - **Enable as a primary App ID** (if this is your main app)
   - **Group with existing primary App ID** (if you have multiple apps)

## Step 3: Backend Implementation

### Option A: Direct Apple JWT Verification

Your backend needs to:
1. Receive the identity token from the app
2. Verify the JWT token with Apple's public keys
3. Create/update user account
4. Return your app's authentication token

### Option B: Using Firebase/Auth0

Many services provide Sign in with Apple integration:
- Firebase Auth
- Auth0
- AWS Cognito
- Supabase

## Step 4: Backend GraphQL Mutation

Create a mutation similar to Google Sign-In:

```graphql
mutation AppleLogin($identityToken: String!, $user: AppleUserInput) {
  loginWithApple(identityToken: $identityToken, user: $user) {
    token
    user {
      id
      email
      name
    }
  }
}
```

Where `AppleUserInput` might include:
```graphql
input AppleUserInput {
  email: String
  fullName: String
  userId: String!  # Apple's user identifier
}
```

## Step 5: Update iOS Code

The current implementation needs to be updated to call your backend:

```swift
// In LoginView.swift and SignUpView.swift
private func handleAppleSignIn() {
    isAppleLoading = true
    
    appleSignInCoordinator.startSignInWithAppleFlow { result in
        switch result {
        case .success(let tokenString):
            // Call your Apple sign-in mutation
            let mutation = AppleLoginMutation(identityToken: tokenString)
            
            Network.shared.client.perform(mutation: mutation) { gqlResult in
                DispatchQueue.main.async {
                    self.isAppleLoading = false
                    
                    switch gqlResult {
                    case .success(let graphqlResult):
                        if let token = graphqlResult.data?.loginWithApple.token {
                            self.authManager.authenticate(token: token)
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
            
        case .failure(let error):
            self.isAppleLoading = false
            // Handle error...
        }
    }
}
```

## Important Considerations

### 1. User Information
- Apple only provides user email and name on **first sign-in**
- Subsequent sign-ins only provide the user identifier
- Store user info in your backend on first sign-in

### 2. Testing
- Sign in with Apple works only on:
  - Real devices (not simulators) in development
  - TestFlight builds
  - App Store releases
- For simulator testing, use the "Sign in with Apple" option in Settings app

### 3. Privacy Requirements
- If you collect email, you must provide users option to hide their email
- Apple provides a private relay email option
- Handle both real and relay emails

### 4. App Store Review
- Apps that offer third-party login (Google) must also offer Sign in with Apple
- This is an App Store requirement as of 2020

## Backend Token Verification

### JWT Verification Steps:
1. Decode the identity token
2. Verify the signature using Apple's public keys
3. Validate claims:
   - `iss`: Must be "https://appleid.apple.com"
   - `aud`: Must match your app's bundle ID
   - `exp`: Token must not be expired

### Apple's Public Keys Endpoint:
```
https://appleid.apple.com/auth/keys
```

## Error Handling

Common errors and solutions:

1. **Invalid client**: Ensure bundle ID matches
2. **Invalid grant**: Token might be expired
3. **User cancelled**: Handle gracefully (no error shown)
4. **Network error**: Retry logic might be needed

## Additional Resources

- [Apple Documentation](https://developer.apple.com/sign-in-with-apple/)
- [JWT Verification](https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api/verifying_a_user)
- [Backend Implementation Guide](https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api)
