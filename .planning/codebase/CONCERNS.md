---
last_mapped_commit: d2baf761977299b062531946d76c4011f4595d73
last_mapped_at: 2026-09-20
---
# Codebase Concerns

**Analysis Date:** 2026-09-20

## Tech Debt

**Monolithic Mega-Services & Mega-Screens:**

- Issue: Several files in `lib/admin/` and `lib/study/` exceed 2,000–3,800 lines of code, combining complex UI layout, business validation, multi-step Firestore queries, and state management into giant classes.
- Files:
  - `lib/admin/services/firebase_admin_service.dart` (3,891 lines)
  - `lib/admin/screens/lecture_editor_screen.dart` (2,670 lines)
  - `lib/study/presentation/screens/batch_detail_screen.dart` (2,319 lines)
  - `lib/admin/screens/feed_editor_screen.dart` (2,054 lines)
  - `lib/study/presentation/screens/lecture_player_screen.dart` (1,583 lines)
  - `lib/admin/screens/course_editor_screen.dart` (1,481 lines)
- Impact: High cognitive load, elevated risk of merge conflicts during parallel feature development, and difficult isolated unit testing.
- Fix approach: Decompose screens into modular sub-widgets and tabs; break `FirebaseAdminService` into domain-specific services (`AdminCourseService`, `AdminQuizService`, `AdminPromoService`, `AdminComboService`).

**Dual Repository Architecture & Incomplete Migration:**

- Issue: Two parallel study repository implementations coexist: `lib/study/study_repository.dart` (legacy, 851 lines) and `lib/study/data/repositories/study_repository_impl.dart` (modern, 974 lines). Older screens like `lib/study/screens/workbooks_page.dart`, `lib/study/screens/my_courses_page.dart`, and `lib/profile/screens/bookmarks_page.dart` still instantiate `StudyRepository()` directly.
- Files: `lib/study/study_repository.dart`, `lib/study/data/repositories/study_repository_impl.dart`, `lib/study/screens/workbooks_page.dart`, `lib/study/screens/my_courses_page.dart`
- Impact: Legacy repository does not resolve combination pack bundled courses, bypasses `EduverseFirebase.mockFirestore` test mocking, and fragments data fetching logic.
- Fix approach: Deprecate `lib/study/study_repository.dart`, migrate all direct instantiations to `StudyRepositoryImpl` or inject `IStudyRepository` via `StudyController`.

**Orphaned Legacy Screen:**

- Issue: `lib/study/screens/lecture_player_page.dart` is completely orphaned and unreferenced in any routing or UI file, having been superseded by `lib/study/presentation/screens/lecture_player_screen.dart`.
- Files: `lib/study/screens/lecture_player_page.dart`
- Impact: Dead code creating confusion for developers modifying video playback behavior.
- Fix approach: Remove `lib/study/screens/lecture_player_page.dart`.

**Missing Root Dart Linter Configuration:**

- Issue: `analysis_options.yaml` is absent from the project root even though `flutter_lints: ^6.0.0` is declared in `pubspec.yaml`.
- Files: `pubspec.yaml`
- Impact: Dart analyzer defaults to minimal warnings; style deviations and dead imports are not surfaced automatically during local development or CI.
- Fix approach: Add `analysis_options.yaml` including `package:flutter_lints/flutter.yaml`.

## Known Bugs & Fragile Areas

**Multi-Item Transactional Limits in Cloud Functions:**

- Symptoms: Potential transaction contention or timeout during high-traffic flash sales for large combination packs.
- Files: `functions/src/index.ts:34-100` (`onPurchaseCreate`)
- Trigger: A user purchases a combination pack containing 10+ bundled courses while multiple other students purchase individual courses in the same batch simultaneously.
- Workaround: Cloud function currently warns on zero seats and overrides enrollment, but does not gracefully retry partitioned transactions if the 500-write or 10MB transaction buffer is reached.
- Fix approach: Batch bundle resolutions or enqueue individual enrollment jobs via Cloud Tasks.

**Web Platform Screenshot Leakage:**

- Symptoms: Students using the Web application can take screenshots, screen recordings, or inspect HTML source to extract video URLs and PDF assets.
- Files: `lib/auth/auth_wrapper.dart:28-61`
- Trigger: Logging into Eduverse via desktop web browser.
- Current mitigation: `ScreenProtector` is disabled on Web (`if (kIsWeb) return;`) because web browsers do not support hardware-level screen capture prevention flags.
- Fix approach: Add dynamic watermark overlays (user email + IP + timestamp) over the video player and PDF viewer on Web to deter unauthorized recording.

## Security Considerations

**Privileged Service Account Keys:**

- Risk: Exposing server credentials if `service-account-key.json` is inadvertently committed.
- Files: `functions/service-account-key.json`
- Current mitigation: Included in `.gitignore`.
- Recommendations: Enforce pre-commit hooks to block `.json` credentials and migrate functions testing to Google Cloud Workload Identity Federation or Application Default Credentials (ADC).

**Admin Role Verification Dual-Check:**

- Risk: Privilege escalation if custom claims and Firestore profile roles become out of sync.
- Files: `firestore.rules:6-13`, `lib/admin/services/auth_guard.dart`
- Current mitigation: Security rules verify both custom claims token (`request.auth.token.role in ['admin', 'superadmin']`) and user profile documents (`users/$(request.auth.uid).data.role`).
- Recommendations: Ensure revoking an admin role in `removeAdminRole` Cloud Function forces a token refresh on the client.

## Performance Bottlenecks

**Unpaginated Admin Queries:**

- Problem: Large collections (users, enrollments, purchases) queried in full snapshots without pagination cursors.
- Files: `lib/admin/screens/users_screen.dart`, `lib/admin/screens/purchases_screen.dart`
- Cause: Using `collection('users').snapshots()` without limit/startAfter clauses.
- Improvement path: Implement infinite scroll pagination using Firestore `startAfterDocument()` and `limit(20)`.

**Lecture Progress Box Memory Overhead:**

- Problem: Full `lecture_progress` Hive box opened synchronously at startup in `lib/main.dart:24`.
- Files: `lib/main.dart`, `lib/study/data/repositories/lecture_progress_repository.dart`
- Cause: Reading all progress keys into RAM at app launch.
- Improvement path: Lazy open the box or segment keys by active `courseId`.

## Test Coverage Gaps

**Administrative Panel UI Tests:**

- What's not tested: Complex editor form interactions and CRUD validations in `lib/admin/screens/`.
- Files: `lib/admin/screens/` (40+ screens with near-zero widget tests).
- Risk: Regressions in course publishing, test series creation, or promo code configurations may go unnoticed until reported by admins.
- Priority: Medium

**Web Landing Breakpoints:**

- What's not tested: Responsive UI layout behavior on mobile vs desktop for `lib/web/landing/`.
- Files: `lib/web/landing/`
- Risk: Visual overflows or broken grids on non-standard viewport widths.
- Priority: Low

---

*Concerns audit: 2026-09-20*
