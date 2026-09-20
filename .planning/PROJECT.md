# Eduverse

## What This Is

Eduverse is a full-stack educational technology platform engineered for Indian competitive examination preparation (UPSC CSE, State PSCs, SSC, Banking, JEE, and NEET). It provides structured cohort-based learning, live video broadcasts, on-demand lecture replays, practice quizzes, full-length test series, encrypted e-books, and student-teacher community forums via a unified Flutter cross-platform client and a serverless Firebase backend.

## Core Value

Reliable, zero-friction delivery of structured educational content, interactive live classes, and assessment tools across mobile and web with instant offline resumption and hardware-grade content security.

## Business Context

- **Customer**: Indian competitive exam aspirants (age 18–30) preparing for national and state entrance exams
- **Revenue model**: Paid course enrollments, combination pack bundles, test series packages, and digital e-book purchases via Razorpay
- **Success metric**: Student daily active study retention and completed course progression
- **Strategy notes**: Documented in `docs/PRD.md` and `docs/features.md`

## Requirements

### Validated

- [x] Multi-platform Flutter UI targeting Android, iOS, Web, and Desktop (`lib/`)
- [x] Authentication supporting Email/Password and Phone OTP with role verification (`lib/auth/`, `lib/core/firebase/auth_service.dart`)
- [x] E-Commerce storefront with courses, combination packs, test series, and e-books (`lib/store/`)
- [x] Razorpay payment gateway integration with transactional server-side fulfillment (`lib/core/firebase/razorpay_service.dart`, `functions/src/index.ts`)
- [x] Study center with batch cohort selector, subject/chapter hierarchy, and lecture player (`lib/study/`)
- [x] Offline video lecture progress tracking via Hive (`lib/study/data/repositories/lecture_progress_repository.dart`)
- [x] Hardware screenshot and screen-recording protection for mobile devices (`lib/auth/auth_wrapper.dart`)
- [x] Administrative console for course publishing, timetable management, and sales tracking (`lib/admin/`)
- [x] Universal deep linking for sharing courses and batches (`lib/core/services/deep_link_service.dart`)
- [x] In-memory fake test harness for automated unit and E2E regression testing (`test/e2e/harness/`)

### Active

- [ ] Dual-format rich text editor enhancement (WYSIWYG `super_editor` with LaTeX and diagramming)
- [ ] Refactor legacy study screens (`lib/study/screens/`) to fully use `StudyRepositoryImpl`
- [ ] Server-side pagination for large administrative data tables (`users`, `purchases`)
- [ ] Add root Dart linter configuration (`analysis_options.yaml`)

### Out of Scope

- Self-hosted video streaming infrastructure — YouTube unlisted/live stream embeds are used to minimize bandwidth costs
- Native desktop/web hardware screenshot blocking — browser APIs do not support OS-level capture blocking; mitigated via dynamic watermarking
- Student-to-student private 1-on-1 messaging — discussions are restricted to supervised course community channels

## Context

- 98k+ lines of Dart application code in `lib/` with 14 detailed design/architecture documents in `docs/`
- Modular feature architecture with Clean Architecture layering in `lib/study/` (`domain/`, `data/`, `presentation/`)
- Backend runs on Firebase Cloud Functions (Node.js 20 / TypeScript) with 12 callable and trigger endpoints
- Verified test suite containing 1,340+ lines of unit tests in `test/unit_test.dart` and 10+ E2E scenario suites in `test/e2e/`

## Constraints

- **Security**: Enrollments and purchases collections must remain write-locked in `firestore.rules`; client writes are strictly forbidden
- **Concurrency**: Course seat limits must be decremented inside Cloud Function transactions to eliminate race conditions
- **Storage Limits**: Firestore write operations must be partitioned into chunks of ≤ 400 operations (`commitInChunks`)
- **Web Compatibility**: Web builds must use `youtube_player_iframe` wrapped with `PointerInterceptor` instead of native video controllers
- **Screen Protection**: `ScreenProtector.preventScreenshotOn()` must be active by default for students on Android/iOS

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Dual-Format Rich Content (RFC-001) | Delta JSON for `super_editor` editing + HTML snapshot for fast student rendering | ✓ Good |
| Transactional Purchase Pipeline (RFC-002) | Serverless Firestore trigger `onPurchaseCreate` prevents seat race conditions and client tampering | ✓ Good |
| Secure E-book Protection (RFC-003) | MD5 obfuscated local caching + screenshot blocking protects copyright materials | ✓ Good |
| Hybrid Lecture Progress (RFC-004) | Instant local Hive box writes + debounced cloud Firestore sync | ✓ Good |
| Dual-Storage RBAC (RFC-005) | Firebase Auth custom claims for security rules + Firestore `/users/{uid}.role` for UI state | ✓ Good |
| Recurring Class Timetable (RFC-006) | Schedule rules generate dynamic cohort live class instances | ✓ Good |
| Course-Level Content Flattening (RFC-007) | Lessons belong to courses; batches serve as enrollment cohorts | ✓ Good |
| RTDB Ephemeral Presence (RFC-008) | Lightweight live viewer tracking with `onDisconnect` hooks prevents Firestore write overload | ✓ Good |
| FCM Multicast Notifications (RFC-009) | Firestore triggers dispatch background push notifications to course topics | ✓ Good |

---
*Last updated: 2026-09-20 after /gsd-ingest-docs*
