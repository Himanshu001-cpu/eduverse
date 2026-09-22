---
last_mapped_commit: d2baf761977299b062531946d76c4011f4595d73
last_mapped_at: 2026-09-20
---
# External Integrations

**Analysis Date:** 2026-09-20

## APIs & External Services

**Payments & Financial:**

- Razorpay Payment Gateway - In-app student checkout, order creation, and payment verification
  - Client SDK: `razorpay_flutter: ^1.4.0` in `lib/core/firebase/razorpay_service.dart`
  - Server SDK: `razorpay: ^2.9.6` in `functions/src/index.ts`
  - Auth/Keys: `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET` (configured via Firebase Functions environment)
  - Features: Multi-item cart checkout, promo code deductions, server-side transaction logging, webhook fallback verification, automated refunds via `refundPurchase`

**Video Streaming & Media:**

- YouTube Data / IFrame Streaming - Live lecture broadcasts and on-demand lecture replays
  - Client SDKs: `youtube_player_flutter: ^9.1.3` (Mobile native) and `youtube_player_iframe: ^5.2.0` (Web)
  - Abstraction: `lib/common/widgets/cross_platform_youtube_player.dart` and `lib/core/utils/youtube_utils.dart`
  - Features: Automatic stream status detection, live indicator badge, full-screen playback with gesture control

**Security & Attestation:**

- Firebase App Check - Client identity verification against abuse and API scrapers
  - Client SDK: `firebase_app_check: ^0.4.1+4` in `lib/core/firebase/firebase_initializer.dart`
  - Attestation Providers: Play Integrity (Android), App Attest / DeviceCheck (iOS), reCAPTCHA v3 / Enterprise (Web)

## Data Storage

**Databases:**

- Cloud Firestore - Primary distributed document database
  - Client SDK: `cloud_firestore: ^6.1.0` via `EduverseFirebase.firestore` in `lib/core/firebase/eduverse_firebase.dart`
  - Admin Client: `firebase-admin: ^13.10.0` in `functions/src/index.ts`
  - Security Rules: Declarative path rules in `firestore.rules` (610 lines) enforcing role-based permissions and purchase checks
  - Indexes: Managed composite indexes in `firestore.indexes.json`
- Firebase Realtime Database (RTDB) - Lightweight live viewer presence and concurrency counting
  - Client SDK: `firebase_database: ^12.1.3` in `lib/core/firebase/live_viewer_service.dart`
  - Server Handler: `onLiveViewerDisconnect` trigger in `functions/src/index.ts`

**File & Object Storage:**

- Firebase Cloud Storage - Secure asset storage for course thumbnails, PDF lecture notes, DPPs, e-books, and posters
  - Client SDK: `firebase_storage: ^13.0.1` in `lib/core/firebase/storage_service.dart`
  - Security Rules: Configured in `storage.rules`

**Local Storage & Caching:**

- Hive Local Database: High-speed key-value box (`lecture_progress`) in `lib/study/data/repositories/lecture_progress_repository.dart` for offline video resume timestamps
- SharedPreferences: Key-value persistence for app configuration, dark/light theme preferences, and onboarding flags in `lib/study/data/repositories/study_local_storage.dart`
- PdfCacheService: Local file system cache in app document storage with MD5-hash file obfuscation in `lib/core/services/pdf_cache_service.dart`

## Authentication & Identity

**Auth Provider:**

- Firebase Authentication - Multi-factor identity and session management
  - Client SDK: `firebase_auth: ^6.1.2` in `lib/core/firebase/auth_service.dart`
  - Methods: Email/Password, Phone OTP (SMS verification)
  - Authorization: Custom JWT claims (`admin`, `superadmin`, `teacher`) set via `setAdminRole` callable Cloud Function in `functions/src/index.ts`
  - Client Role Guard: Synchronized claims check and fallback to Firestore user document role in `AuthGuard` (`lib/admin/services/auth_guard.dart`)

## Monitoring & Observability

**Error Tracking & Diagnostics:**

- Client Initialization Guard: `InitializationErrorApp` fallback in `lib/main.dart` displaying configuration issues
- Debug Diagnostics: `debugPrint` instrumentation across services (FCM initialization, Hive box keys, deep links)

**Logs:**

- Google Cloud Logging / Firebase Functions Logger (`functions.logger`) for transaction execution, webhook receipt, and enrollment logs

## CI/CD & Deployment

**Hosting:**

- Firebase Hosting (`firebase.json`) - Serves the compiled Web build from `build/web` with single-page app (SPA) rewrites to `/index.html`
- Domain: Configured for deep link asset links (`/.well-known/assetlinks.json` and `/.well-known/apple-app-site-association`)

**CI/CD Pipeline:**

- Firebase Deployment: `firebase deploy --only hosting`, `firebase deploy --only functions`, `firebase deploy --only firestore:rules`
- Local Emulators: Configured in `firebase.json` for Firestore (port 8091) and Emulator UI (port 4011)

## Environment Configuration

**Required Environment & Config Files:**

- `lib/firebase_options.dart` - Client API credentials for Android, iOS, and Web platforms
- `android/app/google-services.json` - Android native Google services configuration
- `functions/service-account-key.json` (or Google Cloud ADC) - Local development service account for privileged admin operations
- `Razorpay API Keys`: `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET` in serverless runtime environment

**Secrets Location:**

- Firebase Functions environment secrets / Google Secret Manager
- Android signing keystore in `android/key.properties` (gitignored)

## Webhooks & Callbacks

**Incoming:**

- `POST /webhookPaymentUpdate` - Razorpay HTTP webhook in `functions/src/index.ts` listening for asynchronous payment confirmation (`payment.captured`, `payment.failed`) to auto-enroll students if client disconnects mid-payment

**Outgoing:**

- Firebase Cloud Messaging (FCM) - Automated multicast notifications dispatched to topic/token subscribers upon Firestore document creation (`onNotificationCreate` in `functions/src/index.ts`)
- Automated daily backup: Pub/Sub cron schedule `backupFirestoreToStorage` triggered every 24 hours in `functions/src/index.ts`

---

*Integration audit: 2026-09-20*
