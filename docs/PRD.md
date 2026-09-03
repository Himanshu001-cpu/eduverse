# Eduverse — Product Requirements Document (PRD)

---

## 1. Product Overview

**Eduverse** is a full-stack ed-tech platform purpose-built for competitive exam preparation in India (UPSC, State PSC, SSC, Banking, JEE, NEET). It delivers video lectures, study materials, live classes, practice quizzes, test series, e-books, and community discussions through a unified Flutter application with a Firebase backend.

| Attribute | Detail |
|---|---|
| Product Type | B2C Ed-Tech Platform |
| Target Market | Indian competitive exam aspirants |
| Platforms | Android (primary), iOS, Web, Desktop (Linux, macOS, Windows) |
| Version | 1.2.0+21 |
| Tech Stack | Flutter 3.12+ / Dart, Firebase (Firestore, Auth, Functions, Storage, FCM, RTDB), Razorpay |
| Revenue Model | Course sales, combo pack bundles, test series, e-book sales, promo codes |

---

## 2. User Personas

### 2.1 Student (Primary User)
- **Who**: Competitive exam aspirant (age 18–30), preparing for UPSC, State PSC, SSC, etc.
- **Goals**: Access structured courses, watch lectures, practice quizzes/tests, attend live classes, track progress
- **Pain Points**: Scattered study material, no progress tracking, expensive coaching, no community support
- **Device**: Primarily Android smartphone, occasionally web browser

### 2.2 Teacher
- **Who**: Subject matter expert assigned to specific courses
- **Goals**: Conduct live classes, manage discussion communities, schedule recurring classes
- **Access**: Teacher role via custom claims, limited to assigned courses

### 2.3 Admin / Content Manager
- **Who**: Platform operator managing all content and users
- **Goals**: Create/manage courses, upload content, manage enrollments, track revenue, moderate communities
- **Access**: Full admin panel (web recommended, all platforms supported)

### 2.4 Superadmin
- **Who**: Platform owner with highest privileges
- **Goals**: All admin capabilities plus role management (promote/demote admins and teachers)

---

## 3. Core User Journeys

### 3.1 Student Registration & Onboarding
```
Open App → AuthWrapper checks auth state → Login/Register screen
  → Email/Password signup OR Phone OTP login
  → UserService.createUserProfile() → Firestore /users/{uid}
  → NotificationService registers FCM token
  → Navigate to MainNavigationPage (Study | Feed | Store | Profile)
```

### 3.2 Course Discovery & Purchase
```
Store tab → Browse Courses / Combo Packs / Test Series / E-books
  → Course Detail Page (thumbnail, description, pricing, teacher info)
  → "Add to Cart" → Cart Page (multi-item, promo code input)
  → Checkout → Razorpay payment (dynamic config from Firestore)
  → Payment callback → PurchaseService.createPurchase()
  → Cloud Function onPurchaseCreate triggers:
    ├── Expand combo pack items
    ├── Create enrollment docs
    ├── Decrement seat counts
    ├── Write audit log
    └── Set purchase status = 'success'
  → Payment Result Page → Navigate to Study section
```

### 3.3 Study Session
```
Study tab → Batch Selector (combo pack or individual batch)
  → Continue Learning section (Hive-based resume cards)
  → OR browse by Exam → Select course → Course Section Page
  → Subject → Chapter → Lecture tile
  → Lecture Player Screen (YouTube or native video)
    ├── Auto-save progress to Hive every N seconds
    ├── Record watch time to Firestore
    └── Mark complete when >95% watched
  → OR open Notes/DPPs (Secure PDF Viewer)
  → OR take Quiz (timer → submit → results with analytics)
```

### 3.4 Live Class Join
```
Study tab → Live Classes section / Timetable Timeline
  → See 7-day schedule across all enrolled courses
  → Live class shows "LIVE" badge + "JOIN" button
  → Tap JOIN → YouTube player opens (mobile or iframe)
  → LiveViewerService tracks presence (Firestore + RTDB)
  → Cancelled classes shown with strikethrough (not hidden)
```

### 3.5 Quiz / Test Taking
```
Feed Quiz: Feed tab → Quiz card → Quiz Page
  → Timer countdown → Answer questions → Submit
  → Quiz Result Page (score, correct/wrong/unattempted, explanations)
  → QuizStatsService saves attempt to Firestore

Test Series: Study tab → Test Series → Purchase (if needed) → Test Detail
  → Start test → Timer → Submit → Detailed results
```

### 3.6 Performance Review
```
Profile tab → "View Dashboard →" button
  → Performance Dashboard Page
  → Time filter: This Week | This Month | This Year
  → Summary cards: Overall Score, Quizzes Taken, Study Time
  → Improvement arrows (↑/↓ vs previous period)
  → Line chart: Score trend + Study time trend (filterable by subject)
  → Pie chart: Accuracy ring (Correct / Wrong / Unattempted)
```

### 3.7 Community Discussion
```
Study tab → Communities → Browse accessible communities
  → Select community → Posts list (pinned first)
  → Create new post → Write question
  → Teacher replies with verified answer (✓ badge)
  → Other students can reply, like
```

---

## 4. Feature Requirements by Priority

### P0 — Must Have (Core Platform)
| Feature | Status | Module |
|---|---|---|
| Email/password + phone OTP authentication | ✅ Shipped | `auth/` |
| Course catalog with search and filters | ✅ Shipped | `store/` |
| Shopping cart + Razorpay payment | ✅ Shipped | `store/`, `core/firebase/` |
| Auto-enrollment on purchase (Cloud Function) | ✅ Shipped | `functions/` |
| Video lecture playback (YouTube + native) | ✅ Shipped | `study/`, `common/` |
| Course content hierarchy (subjects → chapters → lectures/notes/DPPs) | ✅ Shipped | `study/` |
| FCM push notifications (global + course-specific) | ✅ Shipped | `core/notifications/` |
| Admin panel with course CRUD | ✅ Shipped | `admin/` |
| Firestore security rules (role-based access) | ✅ Shipped | `firestore.rules` |
| User profile management | ✅ Shipped | `profile/` |

### P1 — Should Have (Engagement & Differentiation)
| Feature | Status | Module |
|---|---|---|
| Combination packs (course bundles) | ✅ Shipped | `store/`, `admin/` |
| Test series with progress tracking | ✅ Shipped | `study/`, `admin/` |
| E-books with secure in-app PDF viewer | ✅ Shipped | `study/`, `store/` |
| Live classes with timetable timeline | ✅ Shipped | `study/`, `admin/` |
| Performance dashboard with charts | ✅ Shipped | `profile/` |
| Teacher-student communities | ✅ Shipped | `study/`, `admin/` |
| Rich text editor (super_editor WYSIWYG) | ✅ Shipped | `admin/widgets/` |
| Deep linking (course, batch, feed items) | ✅ Shipped | `core/services/` |
| Feed system (articles, current affairs, quizzes, jobs) | ✅ Shipped | `feed/` |
| Admin scheduling (recurring rules + generation) | ✅ Shipped | `admin/` |

### P2 — Nice to Have (Polish & Monetization)
| Feature | Status | Module |
|---|---|---|
| Offline PDF caching (encrypted filenames) | ✅ Shipped | `core/services/` |
| Screenshot protection for e-books | ✅ Shipped | `study/` |
| Promo codes / discount coupons | ✅ Shipped | `core/firebase/`, `admin/` |
| Banner/poster system with popup frequency | ✅ Shipped | `store/`, `core/services/` |
| Continue learning with Hive resume | ✅ Shipped | `study/` |
| Workbooks (student practice notebooks) | ✅ Shipped | `study/` |
| Map work / geography topics | ✅ Shipped | `study/` |
| Web landing page | ✅ Shipped | `web/` |
| Daily Firestore backup (scheduled function) | ✅ Shipped | `functions/` |
| App update reminders (scheduled function) | ✅ Shipped | `functions/` |
| Refund processing via Razorpay API | ✅ Shipped | `functions/` |

---

## 5. Non-Functional Requirements

### 5.1 Offline Support
- Hive `lecture_progress` box stores video resume positions locally
- `PdfCacheService` caches e-book PDFs in hidden app directory with MD5-hashed filenames
- `SharedPreferences` persists profile, settings, poster impressions, download index
- Firestore built-in offline persistence for read caching

### 5.2 Security
- Firebase App Check (Android Play Integrity in production, Debug provider in development)
- Firestore rules with `isAdmin()`, `isEnrolled()`, `isTeacher()` helper functions
- Storage rules mirror Firestore access patterns
- `screen_protector` blocks screenshots/recording for e-book content
- Enrollment collection is write-locked (Cloud Functions only)
- Transaction records are immutable (create-only, no update/delete for students)
- Razorpay credentials stored in admin-only Firestore config

### 5.3 Performance
- Dual-format content storage: Delta JSON for editing + HTML snapshot for fast student rendering
- Composite Firestore indexes for common query patterns (9 defined)
- Batched FCM multicast (500 tokens per batch) for notification delivery
- Debounced auto-save (1-minute intervals) in rich text editor
- `cached_network_image` for thumbnail performance

### 5.4 Scalability
- Cloud Functions for transactional enrollment (atomic seat decrements)
- Collection group queries for cross-course data (live_classes, batches, posts)
- Firestore managed export backup every 24 hours

---

## 6. Success Metrics

| Category | Metric | Measurement Source |
|---|---|---|
| **Engagement** | Daily Active Users (DAU) | Firebase Analytics |
| **Engagement** | Avg. watch time per session | `users/{uid}/watch_sessions` |
| **Engagement** | Quiz completion rate | `users/{uid}/quiz_attempts` |
| **Engagement** | Community post/reply count | `communities/{id}/posts` |
| **Revenue** | Total purchases / revenue | `purchases` collection |
| **Revenue** | Combo pack vs individual course ratio | Purchase item analysis |
| **Revenue** | Promo code redemption rate | `config/promo_codes/codes` usage |
| **Content** | Feed engagement (likes, comments, views) | `feed` collection counters |
| **Content** | Test series completion rate | `users/{uid}/test_attempts` |
| **Health** | Notification delivery success | FCM delivery reports |
| **Health** | Payment success rate | `purchases` status distribution |
| **Health** | App crash rate | Firebase Crashlytics |

---

## 7. Technical Constraints & Dependencies

| Constraint | Impact |
|---|---|
| Razorpay is India-only | Payment limited to Indian payment methods (UPI, cards, net banking) |
| YouTube for live streaming | No self-hosted video; dependent on YouTube API availability |
| Syncfusion PDF viewer | Requires commercial license for production use |
| super_editor complexity | Rich text editor has complex widget tree; maintenance overhead |
| Firebase quotas | Firestore read/write limits, Storage bandwidth, Cloud Function invocations |
| FCM 500-token multicast limit | Notification delivery batched; large user base needs careful chunking |
| Hive local storage | Not encrypted by default; lecture progress is non-sensitive |
| Firebase App Check | May block legitimate users with rooted devices (Play Integrity) |
