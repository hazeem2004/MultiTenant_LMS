# Deep Linking Setup Guide

The DevCohort LMS app is now configured to handle deep links like `devcohort://join?token=XYZ` or `https://devcohort-lms.firebaseapp.com/join?token=XYZ`.

## 1. Android Configuration

Edit `android/app/src/main/AndroidManifest.xml`. Add this `<intent-filter>` inside the `<activity>` tag:

```xml
<intent-filter android:label="DevCohort Join">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <!-- Custom Scheme -->
    <data android:scheme="devcohort" android:host="join" />
    <!-- Web Scheme (optional but recommended) -->
    <data android:scheme="https" android:host="devcohort-lms.firebaseapp.com" android:pathPrefix="/join" />
</intent-filter>
```

## 2. iOS Configuration

### Info.plist
Add the URL scheme to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>devcohort.join</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>devcohort</string>
        </array>
    </dict>
</array>
```

### Universal Links (Optional)
If using HTTPS links, you must:
1. Add the `Associated Domains` capability in Xcode (`applinks:devcohort-lms.firebaseapp.com`).
2. Host an `apple-app-site-association` file on your Firebase Hosting.

## 3. How to Test

### Manual
Paste a token in the "Have an Invite Token?" field on the Login screen and click "Sign in with GitHub".

### Deep Link (CLI)
**Android:**
```bash
adb shell am start -a android.intent.action.VIEW -d "devcohort://join?token=TEST123"
```

**iOS Simulator:**
```bash
xcrun simctl openurl booted "devcohort://join?token=TEST123"
```
