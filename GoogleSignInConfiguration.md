# Google Sign-In Configuration for WodAI

## Steps to Configure Google Sign-In URL Schemes

### Method 1: Using Xcode Project Settings (Recommended)

1. Open your project in Xcode
2. Select your project in the navigator
3. Select your app target
4. Go to the "Info" tab
5. Look for "URL Types" section (you may need to expand it)
6. Click the "+" button to add a new URL Type
7. Set the following values:
   - **Identifier**: com.googleusercontent.apps.323431688528-e8s8oo9o1qtf6vrcu69uf0hnb9etvdg3
   - **URL Schemes**: com.googleusercontent.apps.323431688528-e8s8oo9o1qtf6vrcu69uf0hnb9etvdg3
   - **Role**: Editor

### Method 2: Create/Edit Info.plist

If your project uses an Info.plist file, add the following configuration:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.323431688528-e8s8oo9o1qtf6vrcu69uf0hnb9etvdg3</string>
        </array>
    </dict>
</array>
```

### Method 3: Using a Property List Configuration File

If your project uses a .xcconfig or custom plist file, you can add:

```
CFBundleURLTypes = (
    {
        CFBundleURLSchemes = (
            "com.googleusercontent.apps.323431688528-e8s8oo9o1qtf6vrcu69uf0hnb9etvdg3"
        );
    }
);
```

## Additional Google Sign-In Configuration

Make sure you have also:

1. **Google Service Configuration File**: 
   - Download `GoogleService-Info.plist` from Firebase Console or Google Cloud Console
   - Add it to your Xcode project (drag and drop into the project navigator)
   - Make sure it's added to your app target

2. **OAuth Client ID Configuration**:
   - The client ID in your code (323431688528-e8s8oo9o1qtf6vrcu69uf0hnb9etvdg3.apps.googleusercontent.com) should match the one in GoogleService-Info.plist

3. **Bundle ID**:
   - Ensure your app's bundle ID matches what's configured in Google Cloud Console

## Troubleshooting

If you continue to see the error after adding the URL scheme:

1. Clean your build folder (Cmd+Shift+K)
2. Delete derived data
3. Restart Xcode
4. Rebuild the project

The URL scheme is required for Google Sign-In to handle the OAuth redirect back to your app after authentication.
