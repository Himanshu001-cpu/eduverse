# Synthesized Product Requirements

**Ingest Date:** 2026-09-20

## REQ-AUTH: Student & Admin Identity Management
- source: `docs/PRD.md`
- description: Support dual authentication mechanisms (Email/Password and Phone OTP) paired with automated profile initialization in `/users/{uid}`, device FCM token capture, and custom claims verification for administrative roles (`student`, `teacher`, `admin`, `superadmin`).
- acceptance_criteria:
  - Phone OTP login verifies SMS code and routes to `MainNavigationPage` on success
  - Email/Password registration creates user profile document with default `student` role
  - Token refresh automatically propagates admin custom claims to client within session lifecycle

## REQ-STORE: E-Commerce Catalog & Checkout
- source: `docs/PRD.md`
- description: Provide comprehensive storefront supporting single courses, combination pack bundles, test series, and digital e-books with shopping cart and promotional discount support.
- acceptance_criteria:
  - Multi-item shopping cart persists items across sessions in Firestore `/users/{uid}/cart`
  - Promo code engine validates expiration, usage limits, and course inclusion/exclusion rules
  - Razorpay checkout verifies signature on server-side and executes transactional enrollment upon payment success

## REQ-STUDY: Student Study Center & Media Player
- source: `docs/PRD.md`
- description: Dedicated learning space organizing enrolled courses into cohorts, subject/chapter modules, video lectures with playback resume, secure PDF notes, homework DPPs, and live classes.
- acceptance_criteria:
  - Active cohort batch switcher allows seamless filtering between enrolled batches
  - Video player tracks playback position in Hive (`lecture_progress`) and resumes across app restarts
  - Protected PDF viewer prevents downloading and screenshot capture on supported platforms

## REQ-FEED: Community & Daily Practice Feed
- source: `docs/PRD.md`
- description: Interactive social learning feed featuring current affairs articles, interactive practice mini-quizzes, answer writing evaluations, and educational video cards.
- acceptance_criteria:
  - Mini-quizzes record student responses and display instant answer explanations
  - Answer writing page allows text and image attachment submissions for teacher evaluation

## REQ-PROFILE: Analytics & Account Lifecycle
- source: `docs/PRD.md`
- description: Personal user hub featuring quiz/study performance graphs, bookmarks, transaction receipts, offline downloads, and account deletion compliance.
- acceptance_criteria:
  - Interactive charts (`fl_chart`) display quiz accuracy trends and weekly study duration
  - Google Play Store compliant account deletion workflow removes profile and anonymizes audit logs

## REQ-ADMIN: Content & Operational Control Center
- source: `docs/PRD.md`
- description: Comprehensive back-office console for creating courses, editing rich text lecture content, managing timetables, moderating community discussions, and viewing sales metrics.
- acceptance_criteria:
  - Route guarded (`AuthGuard`) preventing unprivileged student access
  - WYSIWYG document editor produces dual-format Delta JSON and pre-rendered HTML
  - Course scheduler enables recurring weekly timetable generation with automatic live class instances
