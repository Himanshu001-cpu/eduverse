# Eduverse — Environment Setup & Development Guide

---

## 1. Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| Flutter SDK | `^3.12.0` | App framework |
| Dart SDK | Bundled with Flutter | Language |
| Node.js | 20+ | Cloud Functions |
| npm | 10+ | Node package manager |
| Firebase CLI | Latest | Firebase deployment |
| Android Studio / VS Code | Latest | IDE |
| Git | Latest | Version control |

---

## 2. Environment Variables

**File**: `.env` (copy from `.env.example`)

### Firebase Production
```env
FIREBASE_PROD_PROJECT_ID=eduverse-dad5e
FIREBASE_PROD_API_KEY=<your-api-key>
FIREBASE_PROD_APP_ID=<your-app-id>
FIREBASE_PROD_MESSAGING_SENDER_ID=<sender-id>
FIREBASE_PROD_AUTH_DOMAIN=eduverse-dad5e.firebaseapp.com
FIREBASE_PROD_DATABASE_URL=https://eduverse-dad5e-default-rtdb.firebaseio.com
FIREBASE_PROD_STORAGE_BUCKET=eduverse-dad5e.firebasestorage.app
FIREBASE_PROD_MEASUREMENT_ID=<measurement-id>
```

### Firebase Development
```env
FIREBASE_DEV_PROJECT_ID=eduverse-prod-da5e
FIREBASE_DEV_API_KEY=<dev-api-key>
FIREBASE_DEV_APP_ID=<dev-app-id>
FIREBASE_DEV_MESSAGING_SENDER_ID=<dev-sender-id>
FIREBASE_DEV_AUTH_DOMAIN=eduverse-prod-da5e.firebaseapp.com
FIREBASE_DEV_STORAGE_BUCKET=eduverse-prod-da5e.firebasestorage.app
```

### Android Signing
```env
ANDROID_KEYSTORE_PASSWORD=<keystore-password>
ANDROID_KEY_PASSWORD=<key-password>
ANDROID_KEY_ALIAS=<key-alias>
ANDROID_STORE_FILE=upload-keystore.jks
```

### Payment Gateway
```env
RAZORPAY_KEY_ID=<razorpay-key-id>
RAZORPAY_KEY_SECRET=<razorpay-key-secret>
```

---

## 3. Initial Setup

### 3.1 Clone & Install
```bash
git clone <repo-url>
cd eduverse
flutter pub get
```

### 3.2 Firebase Configuration
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Select project
firebase use eduverse-dad5e
```

Firebase config files should already exist:
- `android/app/google-services.json` — Android Firebase config
- `lib/firebase_options.dart` — Flutter Firebase options
- `.firebaserc` — Firebase project aliases

### 3.3 Cloud Functions Setup
```bash
cd functions
npm install
cd ..
```

### 3.4 Environment File
```bash
cp .env.example .env
# Edit .env with your actual values
```

---

## 4. Running the App

### Android (Primary)
```bash
# Debug mode
flutter run -d <device-id>

# Release mode
flutter run -d <device-id> --release

# List devices
flutter devices
```

### Web (Recommended for Admin Panel)
```bash
flutter run -d chrome --web-port=8080
```

### Desktop
```bash
flutter run -d linux    # Linux
flutter run -d macos    # macOS
flutter run -d windows  # Windows
```

### iOS
```bash
flutter run -d ios
```

---

## 5. Firebase Emulator Setup

### Configuration (already in `firebase.json`)
| Emulator | Port |
|---|---|
| Firestore | `8091` |
| Emulator UI | `4011` |
| Hub | `4411` |
| Logging | `4511` |

### Start Emulators
```bash
firebase emulators:start
```

### Connect Flutter to Emulators
In debug mode, the app can connect to local emulators:
```dart
_db.useFirestoreEmulator('localhost', 8091);
_auth.useAuthEmulator('localhost', 9099);
_storage.useStorageEmulator('localhost', 9199);
_functions.useFunctionsEmulator('localhost', 5001);
```

---

## 6. Deployment

### Deploy Cloud Functions
```bash
firebase deploy --only functions
```

### Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### Deploy Firestore Indexes
```bash
firebase deploy --only firestore:indexes
```

### Deploy Storage Rules
```bash
firebase deploy --only storage
```

### Deploy Web to Firebase Hosting
```bash
flutter build web --release
firebase deploy --only hosting
```

### Build Android APK
```bash
# Debug
flutter build apk --debug

# Release
flutter build apk --release
```

### Deploy Everything
```bash
firebase deploy
```

---

## 7. Admin User Setup

### Create First Admin
1. Create user via Firebase Console → Authentication → Users
2. Note the UID
3. Set admin claims:

**Option A: CLI Script**
```bash
cd functions
node set-admin.js <USER_UID> admin
```

**Option B: Cloud Function**
```bash
# From Firebase Functions shell
firebase functions:shell
> setAdminRole({uid: '<USER_UID>', role: 'admin'})
```

### Role Hierarchy
| Role | Access Level |
|---|---|
| `superadmin` | Full access + role management |
| `admin` | Full content & user management |
| `content_manager` | Content management |
| `support` | Support access |
| `teacher` | Teaching & community access |
| `student` | Standard user |

---

## 8. Scripts & Developer Tools

### Migration Scripts

| Script | Command | Purpose |
|---|---|---|
| Batch → Course migration | `node scripts/migrate_batches_to_courses.js` | Promotes batch content to course-level |
| Batch → Course (dry run) | `node scripts/migrate_batches_to_courses.js --dry-run` | Preview migration without changes |
| Markdown → Delta migration | `node scripts/migrate_markdown_to_delta.js` | Converts legacy markdown to rich text |

### Utility Scripts

| Script | Command | Purpose |
|---|---|---|
| Seed test data | `node seed_test_data.js` | Populate test data |
| Verify data | `node verify_data.js` | Validate data integrity |
| Deploy rules | `node deploy_rules.js` | Deploy security rules |
| Check ADC | `node check_adc.js` | Check Application Default Credentials |

### Flutter Commands

| Command | Purpose |
|---|---|
| `flutter test` | Run unit & widget tests |
| `flutter analyze` | Static analysis |
| `flutter build apk --debug` | Debug APK build |
| `flutter build apk --release` | Release APK build |
| `flutter build web --release` | Web build |
| `flutter pub get` | Install dependencies |
| `flutter pub upgrade --major-versions` | Upgrade dependencies |

---

## 9. Project Structure Quick Reference

```
eduverse/
├── lib/                          # Flutter app source (262 Dart files)
│   ├── main.dart                 # Entry point
│   ├── admin/                    # Admin panel (75 files)
│   ├── auth/                     # Authentication (7 files)
│   ├── common/                   # Shared code (11 files)
│   ├── core/                     # Core services (34 files)
│   ├── feed/                     # Content feed (19 files)
│   ├── navigation/               # Nav shell (1 file)
│   ├── profile/                  # Profile (17 files)
│   ├── settings/                 # Settings (1 file)
│   ├── store/                    # Marketplace (25 files)
│   ├── study/                    # Study module (51 files)
│   ├── utils/                    # Utilities (2 files)
│   └── web/                      # Web landing (17 files)
├── functions/                    # Cloud Functions (Node.js 20)
│   ├── src/index.ts              # Function definitions
│   └── set-admin.js              # Admin role CLI
├── scripts/                      # Migration & utility scripts
├── test/                         # Flutter tests
├── android/                      # Android platform config
├── ios/                          # iOS platform config
├── web/                          # Web platform config
├── firestore.rules               # Firestore security rules
├── storage.rules                 # Storage security rules
├── firestore.indexes.json        # Composite indexes
├── firebase.json                 # Firebase project config
├── pubspec.yaml                  # Flutter dependencies
├── .env                          # Environment variables
└── docs/                         # Project documentation
```

---

## 10. Key Configuration Files

| File | Purpose |
|---|---|
| `pubspec.yaml` | Flutter dependencies and app metadata |
| `firebase.json` | Firebase services config (hosting, functions, emulators) |
| `.firebaserc` | Firebase project aliases |
| `firestore.rules` | Firestore security rules (25KB) |
| `storage.rules` | Storage security rules |
| `firestore.indexes.json` | Composite indexes (9 defined) |
| `cors.json` | Storage CORS config |
| `.env` / `.env.example` | Environment variables |
| `devtools_options.yaml` | Flutter DevTools settings |
| `analysis_options.yaml` | Dart linter rules |
