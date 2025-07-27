# Fixing Sign in with Apple Error 1001

## The Issue
Error Domain=com.apple.AuthenticationServices.AuthorizationError Code=1001 indicates that Sign in with Apple is not properly configured.

## Solution Steps

### 1. Add Sign in with Apple Capability in Xcode

1. Open `wodAI.xcodeproj` in Xcode
2. Select the `wodAI` project in the navigator
3. Select the `wodAI` target
4. Go to the "Signing & Capabilities" tab
5. Click the "+" button to add a capability
6. Search for "Sign in with Apple" and add it
7. Make sure the entitlements file is properly linked

### 2. Verify Entitlements File

The entitlements file should now include:
```xml
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
```

I've already created/updated the entitlements files:
- `/wodAI/wodAI.entitlements` (Debug)
- `/wodAI/wodAIRelease.entitlements` (Release)

### 3. Configure in Apple Developer Portal

If you're testing on a real device:
1. Go to developer.apple.com
2. Navigate to "Certificates, Identifiers & Profiles"
3. Select your App ID (com.adapt.wodAI)
4. Enable "Sign in with Apple" capability
5. Save the changes

### 4. Clean and Rebuild

1. In Xcode: Product → Clean Build Folder (Cmd+Shift+K)
2. Close Xcode
3. Delete Derived Data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/wodAI-*
   ```
4. Reopen Xcode and rebuild

### 5. Testing Limitations

**Important**: Sign in with Apple has limitations in the simulator:
- The full authentication flow doesn't work in the simulator
- You'll see the authentication dialog but it may fail
- For proper testing, you need:
  - A real device
  - A paid Apple Developer account
  - Proper provisioning profiles

### 6. Simulator Workaround

For development in the simulator, you can:
1. Create a test Apple ID account
2. Sign into the device/simulator with that Apple ID (Settings → Sign in to your iPhone)
3. The Sign in with Apple flow will use the signed-in account

### 7. Alternative for Development

While developing, you might want to add a bypass for the simulator:

```swift
#if targetEnvironment(simulator)
    // Show a message that Sign in with Apple doesn't work in simulator
    // Or provide a mock authentication flow
#else
    // Real Sign in with Apple flow
#endif
```

## Next Steps

1. **In Xcode**: Add the Sign in with Apple capability through the UI
2. **Clean and rebuild** the project
3. **For real testing**: Use a physical device with a valid Apple Developer account
4. **For development**: Consider adding simulator detection to show an appropriate message

The entitlements files are now properly configured, but Xcode needs to recognize them through the project settings.
