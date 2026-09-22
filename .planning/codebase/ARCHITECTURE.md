---
last_mapped_commit: d2baf761977299b062531946d76c4011f4595d73
last_mapped_at: 2026-09-20
---
<!-- refreshed: 2026-09-20 -->

# Architecture

**Analysis Date:** 2026-09-20

## System Overview

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                             Presentation Layer                              │
├──────────────────────┬──────────────────────┬───────────────────────────────┤
│   Student Client     │    Admin Console     │      Web Landing Experience   │
│  `lib/navigation/`   │     `lib/admin/`     │         `lib/web/`            │
│  `lib/feed/`         │   `AdminRouter`      │        `LandingPage`          │
│  `lib/study/`        │   `AdminScaffold`    │        `WebHomepage`          │
│  `lib/store/`        │                      │                               │
│  `lib/profile/`      │                      │                               │
└──────────┬───────────┴──────────┬───────────┴───────────────┬───────────────┘
           │                      │                           │
           ▼                      ▼                           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     State Management & Domain Layer                         │
│   `StudyController` (`lib/study/presentation/providers/study_controller.dart`)│
│   `LiveClassNotifierService` (`lib/core/services/live_class_notifier_service.dart`)│
│   `IStudyRepository` (`lib/study/domain/repositories/i_study_repository.dart`)│
│   Domain Entities (`lib/study/domain/models/`, `lib/store/models/`)         │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Data & Services Layer                             │
│   `StudyRepositoryImpl` (`lib/study/data/repositories/study_repository_impl.dart`)│
│   `EduverseFirebase` abstraction (`lib/core/firebase/eduverse_firebase.dart`) │
│   `AuthService`, `PurchaseService`, `RazorpayService`, `StorageService`     │
│   `Hive` (`lecture_progress`) & `SharedPreferences`                         │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                       Cloud & Serverless Backend                            │
│   Cloud Firestore (`firestore.rules`)  •  Cloud Storage (`storage.rules`)   │
│   Cloud Functions Node.js 20 (`functions/src/index.ts`)                     │
│   Firebase Realtime Database (RTDB)  •  Razorpay Payment Gateway            │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| `MainNavigationPage` | Bottom navigation bar hosting Feed, Study, Store, and Profile tabs | `lib/navigation/main_navigation_page.dart` |
| `AuthWrapper` | Stream-based authentication gate, Web landing redirect, and screenshot protector | `lib/auth/auth_wrapper.dart` |
| `EduverseFirebase` | Global injection point for Firestore and Auth instances supporting unit/E2E test mocks | `lib/core/firebase/eduverse_firebase.dart` |
| `StudyController` | Manages active batch state, subject filtering, lecture selection, and progress sync | `lib/study/presentation/providers/study_controller.dart` |
| `StudyRepositoryImpl` | Core repository executing Firestore queries for courses, batches, lessons, and combo packs | `lib/study/data/repositories/study_repository_impl.dart` |
| `AdminRouter` | Route generator and role-based screen routing for the admin portal | `lib/admin/admin_router.dart` |
| `FirebaseAdminService` | Administrative CRUD operations, chunked batch commits, and course catalog authoring | `lib/admin/services/firebase_admin_service.dart` |
| `DeepLinkService` | Intercepts custom URL schemes and universal app links for course and batch sharing | `lib/core/services/deep_link_service.dart` |
| `CloudFunctions` (backend) | Transactional enrollment, seat decrement, payment webhooks, notifications, and scheduled backups | `functions/src/index.ts` |

## Pattern Overview

**Overall:** Feature-First Modular Flutter Architecture with Clean Architecture principles in the core Study module and centralized Serverless BaaS.

**Key Characteristics:**

- **Layered Clean Architecture in Study:** Clean separation into `domain/` (entities and interfaces), `data/` (repository implementations and local cache), and `presentation/` (screens, widgets, and state controllers).
- **Testable Backend Abstraction:** Database and Auth access routed through `EduverseFirebase.firestore` and `EduverseFirebase.auth` rather than raw static singletons, enabling in-memory test mocks without mockito boilerplates.
- **Unified Dual-Persona App:** Both student learning interfaces and the administrative management console reside within the same codebase, segmented at runtime by role claims (`admin`, `superadmin`, `teacher`).
- **Serverless Event-Driven Business Logic:** Complex transactions (seat limits, multi-course combo pack expansion, payment verification) execute securely in Cloud Functions triggers.

## Layers

**Presentation Layer:**

- Purpose: Render Material 3 UI widgets, handle user input, animate transitions, and react to state changes
- Location: `lib/navigation/`, `lib/feed/`, `lib/study/presentation/`, `lib/store/screens/`, `lib/profile/screens/`, `lib/admin/screens/`, `lib/web/`
- Contains: Flutter widgets, Page screens, Dialogs, Bottom sheets, and Notifiers
- Depends on: Domain layer entities and Presentation controllers (`StudyController`)

**Domain Layer:**

- Purpose: Encapsulate core business entities, data contracts, and repository interfaces
- Location: `lib/study/domain/`, `lib/feed/models/`, `lib/store/models/`, `lib/admin/models/`
- Contains: Pure Dart entities (`StudyBatch`, `StudyCourse`, `StudyLecture`, `CartItem`, `CombinationPack`) and repository interfaces (`IStudyRepository`)
- Depends on: No dependencies on Flutter UI frameworks or third-party storage plugins

**Data Layer:**

- Purpose: Retrieve, persist, cache, and transform data from Firestore, Hive, and local disk
- Location: `lib/study/data/repositories/`, `lib/store/services/`, `lib/core/firebase/`
- Contains: `StudyRepositoryImpl`, `LectureProgressRepository`, `StudyLocalStorage`, and network services
- Depends on: `cloud_firestore`, `hive`, `shared_preferences`, and `EduverseFirebase`

**Core & Platform Infrastructure:**

- Purpose: Cross-cutting services, authentication, deep links, notification dispatch, and hardware security
- Location: `lib/core/`
- Contains: `AuthService`, `NotificationService`, `DeepLinkService`, `PdfCacheService`, `ScreenProtector` integration

## Data Flow

### Primary Request Path (Course Purchase & Enrollment)

1. **Store Selection:** User selects a course or combo pack and proceeds to checkout (`lib/store/screens/checkout_page.dart:180`)
2. **Payment Processing:** `RazorpayService` opens native gateway checkout with generated order metadata (`lib/core/firebase/razorpay_service.dart:65`)
3. **Purchase Staging:** On payment success, client writes purchase record to `/purchases/{purchaseId}` (`lib/core/firebase/purchase_service.dart:120`)
4. **Backend Transaction:** Cloud Function trigger `onPurchaseCreate` fires (`functions/src/index.ts:9`), opens a Firestore transaction, resolves combination pack bundles, verifies and decrements `seatsLeft`, and creates enrollment records in `/enrollments/{userId}_{courseId}` and `/users/{uid}/enrolledCourses/{courseId}`
5. **Study Tab Sync:** Student navigates to Study tab; `StudyController` listens to `StudyRepositoryImpl.getEnrolledBatches(uid)` stream, instantly rendering the newly enrolled batch

### Secondary Flow (Live Class Streaming & Presence)

1. **Broadcast Creation:** Admin schedules live lecture via `LiveClassEditorScreen` (`lib/admin/screens/live_class_editor_screen.dart:110`)
2. **Notification Broadcast:** Firestore trigger `onNotificationCreate` dispatches FCM topic message to enrolled students (`functions/src/index.ts:460`)
3. **Player Join:** Student clicks notification; `DeepLinkService` routes to `LecturePlayerScreen` (`lib/study/presentation/screens/lecture_player_screen.dart:85`)
4. **Presence Tracking:** `LiveViewerService` logs connection to Firebase Realtime Database path `/live_viewers/{classId}/{userId}` with disconnect hooks (`lib/core/firebase/live_viewer_service.dart:45`)
5. **Disconnect Cleanup:** RTDB automatically executes `onDisconnect()` hook, triggering serverless recount via `onLiveViewerDisconnect` (`functions/src/index.ts:520`)

**State Management:**

- `StudyController` (`ChangeNotifier`) holds current selected batch, active tab index, filter criteria, and study timeline state
- `LiveClassNotifierService` listens for ongoing live classes and surfaces global in-app alert popups (`LiveClassPopup`)
- Local lecture progress is written synchronously to `Hive` (`lecture_progress` box) before debouncing network writes to Firestore

## Key Abstractions

**`EduverseFirebase`:**

- Purpose: Decouples the application from static Firebase singletons to enable seamless unit and E2E testing
- File: `lib/core/firebase/eduverse_firebase.dart`
- Pattern: Service Locator / Singleton with static mock injectors (`EduverseFirebase.mockFirestore`)

**`IStudyRepository`:**

- Purpose: Abstract contract defining data queries for courses, batches, subjects, chapters, and lectures
- File: `lib/study/domain/repositories/i_study_repository.dart`
- Pattern: Repository Pattern

**`AuthGuard`:**

- Purpose: Protects administrative routes and endpoints by evaluating JWT custom claims and user profile roles
- File: `lib/admin/services/auth_guard.dart`
- Pattern: Route Guard / Interceptor

## Entry Points

**Mobile & Desktop Application:**

- Location: `lib/main.dart`
- Triggers: User launches application binary on Android, iOS, Windows, macOS, Linux
- Responsibilities: Initialize Flutter bindings, configure path URL strategy, initialize Firebase and Hive, start background NotificationService, mount `AuthWrapper`

**Web Single-Page Application:**

- Location: `web/index.html` -> `lib/main.dart` -> `lib/auth/auth_wrapper.dart`
- Triggers: User visits root URL on web browser
- Responsibilities: If unauthenticated, displays responsive `LandingPage` (`lib/web/landing/landing_page.dart`); if authenticated, renders `MainNavigationPage`

**Deep Link Interceptor:**

- Location: `lib/core/services/deep_link_service.dart`
- Triggers: Universal app link or intent scheme click (`/course?id=...`, `/batch?courseId=...`, `/feed?id=...`)
- Responsibilities: Parses URI path and parameters, pushes specialized deep-link screen onto Navigator

**Cloud Functions Backend:**

- Location: `functions/src/index.ts`
- Triggers: Firestore document mutations, HTTPS RPC callables, HTTP Webhooks, PubSub crons
- Responsibilities: Privileged administrative actions, payment verification, automated transactional enrollment

## Architectural Constraints

- **Hardware Screenshot Protection:** On Android and iOS, `ScreenProtector.preventScreenshotOn()` must remain enabled for students to protect intellectual property (`lib/auth/auth_wrapper.dart:37`).
- **Atomic Seat Allocation:** Seat decrementing for limited-capacity courses must occur strictly inside Firestore transactions within Cloud Functions (`functions/src/index.ts:34`).
- **Web Video Compatibility:** The native video player cannot embed YouTube streams on Web; web builds must conditionally instantiate `youtube_player_iframe` wrapped with `PointerInterceptor` (`lib/common/widgets/cross_platform_youtube_player.dart:40`).

## Anti-Patterns & Known Inconsistencies

### Legacy Study Screens vs Clean Presentation Slices

**What happens:** Older screens in `lib/study/screens/` (e.g. `workbooks_page.dart`, `my_courses_page.dart`) instantiate the concrete legacy `StudyRepository()` directly.
**Why it's wrong:** Bypasses `IStudyRepository` dependency injection, misses combination pack batch resolution, and hinders unit testing with test harnesses.
**Do this instead:** Migrate calls to inject `IStudyRepository` via `StudyController` or instantiate `StudyRepositoryImpl` using `EduverseFirebase.firestore`.

### Mega-Files in Admin Module

**What happens:** Administrative screens and services contain huge monolithic classes exceeding 2,000–3,800 lines (`lib/admin/services/firebase_admin_service.dart` has 3,891 lines; `lib/admin/screens/lecture_editor_screen.dart` has 2,670 lines).
**Why it's wrong:** High cognitive complexity, difficult code review, and frequent merge conflicts.
**Do this instead:** Decompose large editor screens into isolated tab widgets and extract domain-specific CRUD operations from `firebase_admin_service.dart` into specialized domain services.

---

*Architecture analysis: 2026-09-20*
