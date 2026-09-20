# Synthesized Architecture Decisions

**Ingest Date:** 2026-09-20

## RFC-001: Dual-Format Rich Content Storage
- source: `docs/rfcs.md`
- status: locked (Accepted)
- decision: Store rich content in dual-format: Delta JSON for WYSIWYG reloading in `super_editor` and pre-rendered HTML Snapshot for fast student rendering via `flutter_widget_from_html_core` with custom equation/table factories.
- scope: rich content, WYSIWYG, student rendering, LaTeX math

## RFC-002: Purchase & Enrollment Transactional Pipeline
- source: `docs/rfcs.md`
- status: locked (Accepted)
- decision: Use Firestore Cloud Function trigger `onPurchaseCreate` to execute an atomic multi-step transaction that expands combination packs, decrements `seatsLeft` safely, creates write-locked `enrollments/{userId}_{courseId}` documents, and logs audit events.
- scope: payments, enrollment, transactions, seat limits, combination packs

## RFC-003: Secure E-book Content Protection
- source: `docs/rfcs.md`
- status: locked (Accepted)
- decision: Implement multi-layered PDF DRM protection combining obfuscated MD5 local caching (`PdfCacheService`), native hardware screenshot/recording prevention (`ScreenProtector`), and removal of user-facing download/export capabilities.
- scope: e-books, PDFs, DRM, content protection, screen protector

## RFC-004: Hybrid Lecture Progress Persistence
- source: `docs/rfcs.md`
- status: locked (Accepted)
- decision: Maintain instant offline playback resume timestamps using local Hive key-value box (`lecture_progress`), debouncing remote network sync writes to Firestore `/users/{uid}/watch_sessions`.
- scope: lecture progress, offline caching, Hive, watch stats

## RFC-005: Role-Based Authorization with Dual Storage
- source: `docs/rfcs.md`
- status: locked (Accepted)
- decision: Synchronize user roles between Firebase Auth custom JWT claims (for instant security rules evaluation) and Firestore user documents in `/users/{uid}.role` (for real-time profile queries and admin UI listing).
- scope: authorization, RBAC, custom claims, security rules

## RFC-006: Recurring Class Scheduling System
- source: `docs/rfcs.md`
- status: locked (Accepted)
- decision: Automate lecture timetable generation using recurring scheduling rules stored in `course_schedule_rules`, instantiating concrete `live_classes` documents dynamically per cohort batch.
- scope: timetable, recurring scheduler, live classes

## RFC-007: Batch Migration to Course-Level Content
- source: `docs/rfcs.md`
- status: locked (Accepted)
- decision: Flatten content structure from deeply nested batch subcollections up to `courses/{courseId}/lessons`, treating batches as temporal student cohorts and enrollment gates rather than content containers.
- scope: database schema, content hierarchy, batch architecture

## RFC-008: Live Class Viewer Presence (Firestore + RTDB Hybrid)
- source: `docs/rfcs.md`
- status: locked (Accepted)
- decision: Delegate ephemeral real-time presence detection and concurrency counters to Firebase Realtime Database with `onDisconnect()` lifecycle hooks, preserving Firestore for immutable class metadata and chat logs.
- scope: presence, live streaming, RTDB, viewer counters

## RFC-009: Notification Delivery Pipeline
- source: `docs/rfcs.md`
- status: locked (Accepted)
- decision: Trigger automated multicast push notifications via Firebase Cloud Functions listening to Firestore `notifications` collection writes, dispatching topic-based FCM messages with foreground local alert presentation.
- scope: push notifications, FCM, local alerts
