# Roadmap: Eduverse

## Overview

Eduverse is a mature brownfield application with ~98k lines of Dart code, serverless Cloud Functions, and comprehensive documentation in `docs/`. This roadmap outlines the verified baseline architecture and structures the upcoming engineering phases for rich text editing, architectural consolidation, data pagination, and code hygiene.

## Phases

- [x] **Phase 1: Core Platform Verification** - Verify baseline architecture across Auth, Store, Study, and Admin modules
- [x] **Phase 2: Rich Text & Office Suite Integration** - Complete WYSIWYG editor, LaTeX equation builder, tables, and tldraw diagrams
- [ ] **Phase 3: Architecture Consolidation & Repository Migration** - Deprecate legacy `StudyRepository` and migrate all screens to `StudyRepositoryImpl`
- [ ] **Phase 4: Admin Performance & Data Pagination** - Implement server-side Firestore cursor pagination for high-volume admin tables
- [ ] **Phase 5: Code Hygiene & Linter Enforcement** - Configure root `analysis_options.yaml`, prune dead code, and resolve warnings

## Phase Details

### Phase 1: Core Platform Verification
**Goal**: Confirm that the existing multi-platform application, serverless backend, and in-memory test harness operate reliably against established requirements.
**Depends on**: Nothing (Brownfield baseline)
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, STORE-01, STORE-02, STORE-03, STORE-04, STUDY-01, STUDY-02, STUDY-03, STUDY-04, FEED-01, FEED-02, FEED-03, ADMIN-01, ADMIN-02, ADMIN-03, ADMIN-04, PROF-01, PROF-02, PROF-03
**Success Criteria** (what must be TRUE):
  1. Student can authenticate via Phone OTP/Email and access enrolled courses in Study tab
  2. Multi-item cart checkout processes via Razorpay and enrolls user transactionally
  3. Video player resumes playback from local Hive timestamps (`lecture_progress`)
  4. Admin back-office restricts access via `AuthGuard` and provides full course management
  5. Regression test suite (`test/unit_test.dart` and `test/e2e/`) executes without failures
**Plans**: Complete baseline verified

### Phase 2: Rich Text & Office Suite Integration
**Goal**: Provide content creators with an advanced WYSIWYG rich text document editor supporting equations, tables, and diagramming.
**Depends on**: Phase 1
**Requirements**: ENH-01
**Success Criteria** (what must be TRUE):
  1. Admin can format articles and quizzes using `RichDocumentEditor` with full typography controls
  2. Point-and-click LaTeX equation builder inserts math expressions rendered natively in student view
  3. Interactive table builder supports grid resizing and data entry up to 20x20 cells
  4. Embedded `tldraw` WebView exports whiteboard diagrams directly to Firebase Storage
  5. Content saves dual-format (Delta JSON for editing and pre-rendered HTML for student rendering)
**Plans**: TBD (referenced in root `PROJECT.md`)

### Phase 3: Architecture Consolidation & Repository Migration
**Goal**: Eliminate architectural duplication between legacy and modern study repositories across all student screens.
**Depends on**: Phase 1
**Requirements**: ENH-02
**Success Criteria** (what must be TRUE):
  1. `lib/study/screens/workbooks_page.dart` and `my_courses_page.dart` use `StudyRepositoryImpl` or inject `IStudyRepository`
  2. Combination pack course resolutions work consistently across all study subviews
  3. Legacy `lib/study/study_repository.dart` is safely deprecated and removed
  4. All existing study unit and widget tests pass without regressions
**Plans**: TBD

### Phase 4: Admin Performance & Data Pagination
**Goal**: Prevent memory bottlenecks and slow loading times in the administrative panel as database volume grows.
**Depends on**: Phase 1
**Requirements**: ENH-03
**Success Criteria** (what must be TRUE):
  1. Users screen (`lib/admin/screens/users_screen.dart`) loads data in paginated batches of 20 items using Firestore cursors
  2. Purchases screen (`lib/admin/screens/purchases_screen.dart`) supports date-range filtering and infinite scrolling
  3. Network data transfer and Firestore read operations drop by >60% on initial admin dashboard load
**Plans**: TBD

### Phase 5: Code Hygiene & Linter Enforcement
**Goal**: Establish strict static analysis, eliminate dead scaffolding, and guarantee codebase maintainability.
**Depends on**: Phase 1
**Requirements**: ENH-04
**Success Criteria** (what must be TRUE):
  1. `analysis_options.yaml` exists at project root extending `package:flutter_lints/flutter.yaml`
  2. Orphaned dead files (`lib/study/screens/lecture_player_page.dart`) are safely pruned
  3. `flutter analyze` runs clean with zero errors and zero critical warnings
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Core Platform Verification | Verified | Complete | 2026-09-20 |
| 2. Rich Text & Office Suite Integration | 4/4 | Complete | 2026-09-20 |
| 3. Architecture Consolidation & Repository Migration | 0/2 | Pending | - |
| 4. Admin Performance & Data Pagination | 0/2 | Pending | - |
| 5. Code Hygiene & Linter Enforcement | 0/2 | Pending | - |
