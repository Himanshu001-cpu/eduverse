# Deep Link Setup Guide for Eduverse

This guide explains how to complete the deep link setup for the Eduverse app.

## 1. Server-Side Verification Files

For deep links to work seamlessly (without the "Open with" dialog), you need to host verification files on your domain.

### Android: Digital Asset Links

Create `public/.well-known/assetlinks.json`:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.eduverse.learning",
      "sha256_cert_fingerprints": [
        "YOUR_SHA256_FINGERPRINT_HERE"
      ]
    }
  }
]
```

**Get your SHA-256 fingerprint:**

```bash
# For debug keystore
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android

# For release keystore
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
```

### iOS: Apple App Site Association

Create `public/.well-known/apple-app-site-association` (no extension):

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.eduverse.learning",
        "paths": ["/app/*", "/delete-account"]
      }
    ]
  }
}
```

Replace `TEAM_ID` with your Apple Developer Team ID.

## 2. Deploy to Firebase Hosting

1. Create the `.well-known` folder in your `build/web` directory
2. Add the verification files
3. Update `firebase.json` to include the files:

```json
{
  "hosting": {
    "public": "build/web",
    "headers": [
      {
        "source": "/.well-known/assetlinks.json",
        "headers": [{"key": "Content-Type", "value": "application/json"}]
      },
      {
        "source": "/.well-known/apple-app-site-association",
        "headers": [{"key": "Content-Type", "value": "application/json"}]
      }
    ]
  }
}
```

4. Deploy: `firebase deploy --only hosting`

## 3. iOS Xcode Setup (Required)

Open the project in Xcode and:

1. Select **Runner** target → **Signing & Capabilities**
2. Click **+ Capability** → **Associated Domains**
3. Add: `applinks:eduverse-dad5e.web.app`

## 4. Supported Deep Link Routes

| Route | URL Example |
|-------|-------------|
| Course Detail | `https://eduverse-dad5e.web.app/app/course/COURSE_ID` |
| Batch Section | `https://eduverse-dad5e.web.app/app/batch/COURSE_ID/BATCH_ID` |
| Feed Item | `https://eduverse-dad5e.web.app/app/feed/FEED_ID` |
| Delete Account | `https://eduverse-dad5e.web.app/delete-account` |

## 5. Testing

**Android (adb):**
```bash
adb shell am start -a android.intent.action.VIEW -d "https://eduverse-dad5e.web.app/app/course/test123" com.eduverse.learning
```

**Custom scheme (both platforms):**
```
eduverse://app/course/test123
```
