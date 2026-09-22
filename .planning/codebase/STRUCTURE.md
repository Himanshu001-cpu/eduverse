---
last_mapped_commit: d2baf761977299b062531946d76c4011f4595d73
last_mapped_at: 2026-09-20
---
# Codebase Structure

**Analysis Date:** 2026-09-20

## Directory Layout

```
eduverse/
├── android/                   # Android native platform project and Gradle configuration
├── assets/                    # Static image assets, app icons, and about graphics
├── build/                     # Flutter build outputs and compiled web/mobile artifacts (gitignored)
├── docs/                      # Comprehensive technical documentation, PRD, schemas, and specs
├── functions/                 # Firebase Cloud Functions (Node.js 20 / TypeScript)
│   ├── src/                   # Serverless triggers, callable RPCs, webhooks, and cron jobs
│   └── package.json           # Cloud Functions npm dependencies
├── ios/                       # iOS native platform project and CocoaPods configuration
├── lib/                       # Flutter Dart client application codebase (~98k lines)
│   ├── admin/                 # Back-office administration panel (screens, models, services)
│   ├── auth/                  # Authentication wrappers, login screens, and session guards
│   ├── common/                # Shared widgets, search delegates, and download services
│   ├── core/                  # Core services, Firebase wrappers, theme, deep links, notifications
│   ├── feed/                  # Community feed, quizzes, articles, and rich text blocks
│   ├── navigation/            # Bottom navigation bar and main shell routing
│   ├── profile/               # User profile, performance dashboard, transactions, bookmarks
│   ├── settings/              # Account deletion, settings, and legal disclaimers
│   ├── store/                 # Course store, combo packs, test series, cart, and checkout
│   ├── study/                 # Study center, enrolled batches, lecture player, notes, e-books
│   │   ├── data/              # Study repository implementations and local storage
│   │   ├── domain/            # Entities, value objects, and repository interfaces
│   │   ├── presentation/      # Study screens, widgets, and state controllers
│   │   └── screens/           # Legacy study screens
│   ├── utils/                 # General-purpose client helper utilities
│   ├── web/                   # Web-specific landing page and responsive components
│   ├── firebase_options.dart  # FlutterFire generated platform credentials
│   └── main.dart              # Application entry point and top-level route generator
├── linux/                     # Linux desktop platform runner (CMake)
├── macos/                     # macOS desktop platform runner (Xcode)
├── test/                      # Unit, widget, and E2E test suites with in-memory harness
│   ├── e2e/                   # Integration and end-to-end flows with fake Firebase
│   ├── unit/                  # Domain entity and repository unit tests
│   └── widget/                # Flutter UI component tests
├── web/                       # Web static assets, manifest.json, index.html, privacy policy
├── windows/                   # Windows desktop platform runner (CMake)
├── firebase.json              # Firebase Hosting, Functions, and emulator configuration
├── firestore.rules            # Security rules for Cloud Firestore
├── storage.rules              # Security rules for Firebase Cloud Storage
├── firestore.indexes.json     # Firestore composite index definitions
└── pubspec.yaml               # Flutter package configuration and asset registrations
```

## Directory Purposes

**`lib/admin/`:**

- Purpose: Comprehensive administrative control center for content management, user administration, course scheduling, and sales analytics
- Contains: Admin screens, management dialogs, data table cards, rich text document editors, and `FirebaseAdminService`
- Key files: `lib/admin/admin_router.dart`, `lib/admin/admin_entry_page.dart`, `lib/admin/services/firebase_admin_service.dart`

**`lib/study/`:**

- Purpose: Central student learning portal for accessing enrolled courses, batches, recorded lectures, quizzes, homework DPPs, and protected notes
- Contains: Clean Architecture layers (`data/`, `domain/`, `presentation/`)
- Key files: `lib/study/presentation/providers/study_controller.dart`, `lib/study/data/repositories/study_repository_impl.dart`, `lib/study/presentation/screens/lecture_player_screen.dart`

**`lib/store/`:**

- Purpose: E-commerce catalog displaying courses, combo packs, test series, e-books, and shopping cart
- Contains: Product cards, filter widgets, checkout flows, and payment verification screens
- Key files: `lib/store/store_page.dart`, `lib/store/screens/checkout_page.dart`, `lib/store/services/cart_service.dart`

**`lib/feed/`:**

- Purpose: Community feed displaying current affairs, educational updates, interactive mini-quizzes, and video posts
- Contains: Feed cards, quiz runners, answer writing screens, and comment lists
- Key files: `lib/feed/feed_page.dart`, `lib/feed/repository/feed_repository.dart`

**`lib/core/`:**

- Purpose: Foundational infrastructure, Firebase adapters, hardware security, push notifications, and theme definitions
- Contains: Low-level singletons, notification handlers, deep linking interceptors, and PDF cache services
- Key files: `lib/core/firebase/eduverse_firebase.dart`, `lib/core/firebase/auth_service.dart`, `lib/core/services/deep_link_service.dart`, `lib/core/services/pdf_cache_service.dart`

**`lib/web/`:**

- Purpose: High-conversion landing page and web-specific responsive presentations for unauthenticated visitors
- Contains: Hero banner, feature bento grids, course carousels, testimonials, and footer
- Key files: `lib/web/landing/landing_page.dart`, `lib/web/web_homepage.dart`

**`functions/src/`:**

- Purpose: Serverless backend microservices executing transactional mutations and external integrations
- Contains: Cloud Firestore triggers, HTTPS callables, Razorpay webhook handlers, and Pub/Sub cron tasks
- Key files: `functions/src/index.ts`

## Key File Locations

**Entry Points:**

- `lib/main.dart`: Root Flutter entry point configuring Hive, deep links, notifications, and top-level routing
- `lib/auth/auth_wrapper.dart`: Root state discriminator deciding between `LandingPage` (Web visitor), `LoginPage` (Mobile visitor), or `MainNavigationPage` (Authenticated user)
- `lib/admin/admin_router.dart`: Internal router managing all `/admin/*` administrative sub-routes
- `functions/src/index.ts`: Backend entry point for all Firebase Cloud Functions

**Configuration:**

- `pubspec.yaml`: Dart dependencies, SDK environment, assets, and app version
- `lib/firebase_options.dart`: FlutterFire client platform keys
- `firebase.json`: Hosting rewrites, Functions runtime, and Firestore emulator ports
- `firestore.rules`: Declarative security rules for all Firestore database paths
- `storage.rules`: Declarative access rules for Firebase Cloud Storage buckets
- `firestore.indexes.json`: Database query index definitions

**Core Logic:**

- `lib/core/firebase/eduverse_firebase.dart`: Testable database/auth client proxy
- `lib/study/data/repositories/study_repository_impl.dart`: Student batch, lecture, and combo pack data provider
- `lib/study/presentation/providers/study_controller.dart`: Reactive controller for course and lecture state
- `lib/admin/services/firebase_admin_service.dart`: Privileged admin data manipulation engine

**Testing:**

- `test/e2e/harness/e2e_harness.dart`: Centralized singleton test harness for mock injection
- `test/e2e/harness/fake_firebase_firestore.dart`: In-memory Firestore fake
- `test/e2e/harness/fake_firebase_auth.dart`: In-memory Auth fake
- `test/unit_test.dart`: Master unit test suite (1,344 lines) covering deserialization, cart operations, promo codes, and batch commits

## Naming Conventions

**Files:**

- Dart files: `snake_case.dart` (e.g. `lecture_player_screen.dart`, `study_repository_impl.dart`, `cart_service.dart`)
- TypeScript files: `camelCase.ts` or `index.ts` (e.g. `functions/src/index.ts`)
- Model files: suffixed with `_model.dart` or `_models.dart` (e.g. `store_models.dart`, `poster_model.dart`)
- Screen files: suffixed with `_screen.dart` or `_page.dart` (e.g. `batch_detail_screen.dart`, `checkout_page.dart`)
- Service files: suffixed with `_service.dart` or `_repository.dart` (e.g. `auth_service.dart`, `feed_repository.dart`)

**Directories:**

- Feature folders: `snake_case` (e.g. `feed/`, `study/`, `store/`, `profile/`, `admin/`)
- Architecture folders: `presentation/`, `domain/`, `data/`, `repositories/`, `widgets/`, `screens/`

## Where to Add New Code

**New Student Feature:**

- Place feature domain in `lib/<feature_name>/` or within `lib/study/` if related to academic coursework
- Implement domain entities in `lib/<feature_name>/domain/models/`
- Implement repository interfaces in `lib/<feature_name>/domain/repositories/`
- Implement data access in `lib/<feature_name>/data/repositories/`
- Build UI components in `lib/<feature_name>/presentation/screens/` and `widgets/`

**New Administrative Tool:**

- Add screen in `lib/admin/screens/<tool_name>_screen.dart`
- Extend `FirebaseAdminService` or create a specialized service in `lib/admin/services/`
- Register route name and widget builder in `lib/admin/admin_router.dart`
- Add dashboard tile or navigation drawer link in `lib/admin/screens/dashboard_screen.dart`

**New Cloud Function / API:**

- Add export function to `functions/src/index.ts` (or split into modular handlers in `functions/src/handlers/`)
- Ensure security check `context.auth` exists for callable functions
- Update `firestore.rules` if new collections are introduced

**New Automated Test:**

- Unit test: Create `test/unit/<feature>_test.dart`
- Widget test: Create `test/widget/<widget>_test.dart`
- Integration / E2E test: Create `test/e2e/<flow>_e2e_test.dart` using `E2EHarness().setup()`

## Special Directories

**`build/`:**

- Purpose: Flutter compile output for APK, Web, iOS, and desktop binaries
- Generated: Yes
- Committed: No (in `.gitignore`)

**`functions/lib/`:**

- Purpose: JavaScript compile output from TypeScript compilation (`tsc`)
- Generated: Yes
- Committed: No (in `.gitignore`)

**`.planning/`:**

- Purpose: GSD project planning artifacts, codebase maps, requirements, and execution state
- Generated: Managed by GSD
- Committed: Yes

**`assets/`:**

- Purpose: Bundled images, icons, and branding materials
- Generated: No
- Committed: Yes

---

*Structure analysis: 2026-09-20*
