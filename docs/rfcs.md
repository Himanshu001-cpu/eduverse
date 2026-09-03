# Eduverse — Technical RFCs

Design decisions and technical rationale for major features implemented in the platform.

---

## RFC-001: Dual-Format Rich Content Storage

### Problem
The admin panel needs a WYSIWYG editor for creating articles, quizzes, and course content. Students need fast rendering of this content on mobile/web. Raw markdown was limited (no tables, equations, diagrams). A single format couldn't serve both editing and rendering efficiently.

### Decision
Store content in **dual format**:
1. **Delta JSON** — Structured document format for reloading into `super_editor` for future edits
2. **HTML Snapshot** — Pre-rendered HTML for fast student-side rendering via `flutter_widget_from_html_core`

### Rationale
- Delta JSON preserves editor state (selections, formatting, embedded objects) losslessly
- HTML renders 10-100x faster than parsing Delta JSON on student devices
- Backward compatibility: legacy markdown strings are detected and rendered with the old renderer
- Custom widget factories handle LaTeX equations (`flutter_math_fork`), SVG diagrams, and tables within HTML

### Files
- Editor: `lib/admin/widgets/rich_document_editor.dart`
- Viewer: `lib/common/widgets/rich_content_viewer.dart`
- Serialization: `lib/core/services/rich_text_service.dart`

---

## RFC-002: Purchase & Enrollment Transactional Pipeline

### Problem
Purchasing a course must atomically enroll the student, decrement seat counts, expand combo pack bundles, and create audit trails — all without partial failures leaving inconsistent state.

### Decision
Use a **Firestore Cloud Function trigger** (`onPurchaseCreate`) that runs a Firestore transaction to:
1. Read the purchase document
2. Expand combo packs → list of individual courses/test series/ebooks
3. Deduplicate targets
4. Check and decrement `seatsLeft` atomically
5. Create `enrollments/{userId}_{courseId}` documents
6. Write audit log
7. Set purchase status to `success` or `failed`

The `enrollments` collection is **write-locked** (`allow write: if false`) — only Cloud Functions can modify it.

### Rationale
- Server-side transactions prevent race conditions on seat counts
- Write-locked enrollments prevent client-side manipulation
- Audit trail ensures traceability for support/refund scenarios
- Combo pack expansion is centralized (not duplicated in client code)

### Files
- Cloud Function: `functions/src/index.ts` (`onPurchaseCreate`)
- Client: `lib/core/firebase/purchase_service.dart`

---

## RFC-003: Secure E-book Content Protection

### Problem
Paid e-book PDFs must not be easily downloadable, shareable, or screenshottable by students, while still supporting offline reading.

### Decision
Multi-layered protection:
1. **In-app viewing only** — Syncfusion PDF viewer, no external app launch
2. **UI restrictions** — Download/share/text-selection buttons hidden for ebook content type
3. **Screenshot blocking** — Android `FLAG_SECURE` via `screen_protector` package
4. **Obfuscated caching** — PDFs cached in hidden app directory (`getApplicationDocumentsDirectory()/.cached_ebooks/`) with MD5 hash filenames

### Rationale
- No protection is 100% (screen recording on external devices, etc.) but this raises the barrier significantly
- Obfuscated filenames prevent casual file manager browsing
- Hidden directory prefix (`.cached_ebooks`) hides from most file explorers
- Separate download/share behavior for notes/DPPs (allowed) vs ebooks (blocked) via content type flag

### Files
- Viewer: `lib/study/presentation/screens/secure_pdf_viewer_screen.dart`
- Cache: `lib/core/services/pdf_cache_service.dart`

---

## RFC-004: Hybrid Lecture Progress Persistence

### Problem
Students expect video playback to resume from where they left off. Progress must survive app restarts, work offline, and not create excessive Firestore writes.

### Decision
Use **Hive** (local key-value store) as the primary progress store:
- Save `progressSeconds`, `totalDurationSeconds`, `lastOpened` per lecture
- Auto-save every N seconds during playback
- Mark as complete when >95% watched (clear from "Continue Learning")
- Firestore `watch_sessions` for analytics only (write once on session end, not continuously)

### Rationale
- Hive is instant (no network latency) and works fully offline
- Firestore writes are expensive at scale — saving every few seconds would be cost-prohibitive
- Session-end write to Firestore captures total duration for analytics without continuous syncing
- `SharedPreferences` was considered but Hive handles structured data and multiple entries better

### Files
- Hive repository: `lib/study/data/repositories/lecture_progress_repository.dart`
- Player: `lib/study/presentation/screens/lecture_player_screen.dart`
- Analytics: `lib/core/firebase/watch_stats_service.dart`

---

## RFC-005: Role-Based Authorization with Dual Storage

### Problem
Access control must be enforced both on the client (UI routing) and server (Firestore rules). Firebase custom claims are authoritative but require token refresh. Firestore rules need instant access without waiting for claim propagation.

### Decision
Store roles in **two places**:
1. **Firebase Auth Custom Claims** (`request.auth.token.role`) — authoritative, set via `setAdminRole` Cloud Function
2. **Firestore `/users/{uid}.role`** — fallback, updated simultaneously by the same Cloud Function

Security rules check **both** sources:
```javascript
function isAdmin() {
  return request.auth.token.role in ['admin', 'superadmin'] ||
         get(/users/$(request.auth.uid)).data.role in ['admin', 'superadmin'];
}
```

### Rationale
- Custom claims are embedded in the JWT token (no extra Firestore reads for rule evaluation)
- But claims require token refresh to propagate (up to 1 hour delay)
- Firestore fallback ensures immediate access after role assignment
- Dual check is redundant but eliminates the "just assigned, can't access yet" problem

### Files
- Cloud Function: `functions/src/index.ts` (`setAdminRole`, `removeAdminRole`)
- Client: `lib/core/firebase/auth_service.dart`
- Rules: `firestore.rules` (`isAdmin()` function)

---

## RFC-006: Recurring Class Scheduling System

### Problem
Admins and teachers need to define recurring class patterns ("Math every Mon/Wed 10am") and generate individual live class instances without manual creation.

### Decision
Two-level architecture:
1. **Scheduler Rules** (`courses/{courseId}/scheduler_rules/{ruleId}`) — Define recurring patterns (weekdays, time, date range, instructor, subject)
2. **Generated Classes** (`courses/{courseId}/live_classes/{classId}`) — Individual class instances with `parentRuleId` reference

Generation is **on-demand** (admin clicks "Generate Classes" with a date range), not automatic. Individual classes can be rescheduled/cancelled without affecting the parent rule.

### Rationale
- On-demand generation avoids orphaned future classes if a rule is deleted
- `parentRuleId` links back to the source rule for traceability
- Deduplication by `generatedDateString` prevents re-generating already-created classes
- Conflict detection runs at generation time (highlights overlaps, doesn't block)

### Files
- Rules: `lib/admin/screens/course_schedule_rules_screen.dart`
- Dashboard: `lib/admin/screens/course_schedule_dashboard.dart`
- Student timeline: `lib/study/presentation/widgets/timetable_timeline_widget.dart`
- Model: `lib/admin/models/scheduler_models.dart`

---

## RFC-007: Batch Migration to Course-Level Content

### Problem
Originally, content (lectures, notes, quizzes) was nested under `courses/{id}/batches/{batchId}/`. This created data duplication when multiple batches shared the same lectures and complicated queries.

### Decision
Migrate content to course-level subcollections (`courses/{id}/lectures/`, `courses/{id}/notes/`, etc.) while maintaining backward compatibility:
1. Run migration script (`scripts/migrate_batches_to_courses.js`) with `--dry-run` support
2. Use `SafeBatchWriter` (≤450 ops/chunk) to avoid Firestore batch limits
3. Dual-write enrollments (new format + legacy composite keys)
4. Preserve legacy batch documents for older client versions

### Files
- Migration: `scripts/migrate_batches_to_courses.js`
- Seed/verify: `seed_test_data.js`, `verify_data.js`
- Service: `lib/core/services/migration_service.dart`

---

## RFC-008: Live Class Viewer Presence (Firestore + RTDB Hybrid)

### Problem
Tracking real-time viewer counts for live classes requires instant updates when users join/leave. Firestore alone can't handle high-frequency increments without contention.

### Decision
Hybrid approach:
1. **Firestore** `viewerCount` — Atomic `FieldValue.increment(1)` on join, `-1` on leave
2. **Realtime Database** `live_viewers/{sessionKey}/{userId}` — Presence tracking with `onDisconnect().remove()` for automatic cleanup when users disconnect unexpectedly

### Rationale
- RTDB `onDisconnect()` is the only Firebase mechanism that guarantees cleanup on abrupt disconnects (app crash, network loss)
- Firestore increment handles the display count
- RTDB handles the "who is currently watching" list and auto-cleanup

### Files
- Service: `lib/core/firebase/live_viewer_service.dart`
- RTDB path: `live_viewers/{sessionKey}/{userId}`

---

## RFC-009: Notification Delivery Pipeline

### Problem
Notifications must reach all students enrolled in a specific course (or all users globally) via FCM push. A single course may have thousands of enrolled students.

### Decision
Use a **Firestore trigger** (`onNotificationCreate`) that:
1. Determines target audience (course-specific → query enrolled users, or global → all users)
2. Collects FCM tokens from `users` documents
3. Batches tokens into chunks of **500** (FCM multicast limit)
4. Sends multicast push notifications via `admin.messaging().sendEachForMulticast()`

Separate scheduled function (`sendUpdateReminders`) handles app update nag notifications.

### Rationale
- Firestore trigger decouples notification sending from the admin UI (fire-and-forget)
- 500-token batching respects FCM limits
- Token collection is server-side (tokens never exposed to admin client)

### Files
- Cloud Function: `functions/src/index.ts` (`onNotificationCreate`, `sendUpdateReminders`)
- Client: `lib/core/notifications/notification_service.dart`
- Repository: `lib/core/notifications/notification_repository.dart`
