# Requirements: Eduverse

**Defined:** 2026-09-20
**Core Value:** Reliable, zero-friction delivery of structured educational content, interactive live classes, and assessment tools across mobile and web with instant offline resumption and hardware-grade content security.

## v1 Requirements

Requirements for current release and verified baseline.

### Authentication & Security (AUTH)

- [x] **AUTH-01**: User can register and sign in via Email/Password or Phone OTP SMS verification
- [x] **AUTH-02**: System synchronizes role custom claims (`student`, `teacher`, `admin`, `superadmin`) into session JWT
- [x] **AUTH-03**: Mobile client activates hardware-level screenshot and screen recording blocking for student sessions
- [x] **AUTH-04**: Unauthenticated web visitors land on responsive public landing page with deep-link redirects

### Storefront & Checkout (STORE)

- [x] **STORE-01**: User can browse courses, combination packs, test series, and digital e-books with category filtering
- [x] **STORE-02**: Multi-item shopping cart persists items across app restarts in Firestore `/users/{uid}/cart`
- [x] **STORE-03**: Promo code engine validates discounts, item inclusion/exclusion rules, and expiration dates
- [x] **STORE-04**: Razorpay payment checkout verifies signatures server-side and atomically enrolls student via Cloud Functions

### Student Study Center (STUDY)

- [x] **STUDY-01**: Student can switch between enrolled cohort batches and browse subject/chapter hierarchies
- [x] **STUDY-02**: Video lecture player tracks playback positions in local Hive storage (`lecture_progress`) for instant resume
- [x] **STUDY-03**: Encrypted PDF viewer displays lecture notes and e-books from obfuscated local cache without download options
- [x] **STUDY-04**: Student can join live streaming lectures with real-time viewer presence tracked via RTDB

### Community & Practice (FEED)

- [x] **FEED-01**: Student can answer daily practice mini-quizzes with instant score calculation and explanations
- [x] **FEED-02**: Student can submit answer writing responses with text and image attachments for instructor review
- [x] **FEED-03**: Course community channels allow peer discussions supervised by assigned teachers

### Administrative Back-Office (ADMIN)

- [x] **ADMIN-01**: Back-office routes are protected by `AuthGuard` and restricted to verified admin/teacher credentials
- [x] **ADMIN-02**: Admin can create and modify courses, batches, lectures, tests, and promotional posters
- [x] **ADMIN-03**: Course schedule rules engine automatically instantiates recurring live class timetables
- [x] **ADMIN-04**: Bulk administrative operations partition Firestore writes into safe chunks of ≤ 400 operations (`commitInChunks`)

### Profile & Analytics (PROF)

- [x] **PROF-01**: Interactive charts (`fl_chart`) display quiz accuracy trends and weekly study watch minutes
- [x] **PROF-02**: Student can bookmark key lectures, articles, and video resources for quick access
- [x] **PROF-03**: Google Play Store compliant account deletion workflow removes profile and anonymizes transactions

## Active / Upcoming Enhancements (ENH)

- [ ] **ENH-01**: Enhanced rich text editor (`super_editor`) with LaTeX equation builder and whiteboard diagramming
- [ ] **ENH-02**: Unified Study Repository migration: deprecate legacy `StudyRepository` and route all screens to `StudyRepositoryImpl`
- [ ] **ENH-03**: Server-side cursor pagination for administrative user and purchase data tables
- [ ] **ENH-04**: Root Dart linter configuration (`analysis_options.yaml`) enforcing strict code hygiene

## Out of Scope

| Feature | Reason |
|---------|--------|
| In-house Video CDN | YouTube live/unlisted streaming eliminates high infrastructure bandwidth costs |
| Web Hardware DRM | Web browsers lack OS-level screenshot prevention; mitigated via dynamic watermarking |
| 1-on-1 Direct Messaging | Avoid unmonitored communication channels; student discussions occur in supervised communities |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | Phase 1: Core Platform Verification | Complete |
| AUTH-02 | Phase 1: Core Platform Verification | Complete |
| AUTH-03 | Phase 1: Core Platform Verification | Complete |
| AUTH-04 | Phase 1: Core Platform Verification | Complete |
| STORE-01 | Phase 1: Core Platform Verification | Complete |
| STORE-02 | Phase 1: Core Platform Verification | Complete |
| STORE-03 | Phase 1: Core Platform Verification | Complete |
| STORE-04 | Phase 1: Core Platform Verification | Complete |
| STUDY-01 | Phase 1: Core Platform Verification | Complete |
| STUDY-02 | Phase 1: Core Platform Verification | Complete |
| STUDY-03 | Phase 1: Core Platform Verification | Complete |
| STUDY-04 | Phase 1: Core Platform Verification | Complete |
| FEED-01 | Phase 1: Core Platform Verification | Complete |
| FEED-02 | Phase 1: Core Platform Verification | Complete |
| FEED-03 | Phase 1: Core Platform Verification | Complete |
| ADMIN-01 | Phase 1: Core Platform Verification | Complete |
| ADMIN-02 | Phase 1: Core Platform Verification | Complete |
| ADMIN-03 | Phase 1: Core Platform Verification | Complete |
| ADMIN-04 | Phase 1: Core Platform Verification | Complete |
| PROF-01 | Phase 1: Core Platform Verification | Complete |
| PROF-02 | Phase 1: Core Platform Verification | Complete |
| PROF-03 | Phase 1: Core Platform Verification | Complete |
| ENH-01 | Phase 2: Rich Text & Office Suite Integration | Pending |
| ENH-02 | Phase 3: Architecture Consolidation & Repository Migration | Pending |
| ENH-03 | Phase 4: Admin Performance & Data Pagination | Pending |
| ENH-04 | Phase 5: Code Hygiene & Linter Enforcement | Pending |

**Coverage:**
- Baseline v1 requirements: 22 total (22/22 verified)
- Active enhancement requirements: 4 total (4/4 mapped to roadmap phases)
- Unmapped: 0 ✓

---
*Requirements defined: 2026-09-20*
*Last updated: 2026-09-20 after /gsd-ingest-docs*
