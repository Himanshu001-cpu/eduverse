# Eduverse — Security Documentation

Complete reference for authentication, authorization, Firestore/Storage rules, App Check, and content protection.

---

## 1. Authentication

### Providers
- **Email/Password**: Primary auth method via `FirebaseAuth`
- **Phone OTP**: Phone number verification with SMS OTP
- **Phone Linking**: Link phone to existing email account

### Auth Flow
```
App Launch → AuthWrapper checks FirebaseAuth.currentUser
  ├── Not authenticated → LoginPage / RegisterPage
  ├── Authenticated + admin/teacher claims → AdminApp
  └── Authenticated + student → MainNavigationPage (Study/Feed/Store/Profile)
```

### Key Service: [`AuthService`](file:///home/himanshu/codes/eduverse/lib/core/firebase/auth_service.dart)

| Method | Purpose |
|---|---|
| `isAdmin()` | Check if current user has admin custom claims |
| `hasAdminOrTeacherAccess()` | Check admin or teacher role |
| `signInWithEmail(email, password)` | Email/password login |
| `signUpWithEmail(email, password, name)` | Registration + profile creation |
| `verifyPhoneNumber(phone, callbacks)` | Initiate phone OTP |
| `verifyOTP(verificationId, otp)` | Verify OTP code |
| `linkPhoneToAccount(verificationId, otp)` | Link phone to email account |
| `signOut()` | Sign out + clear local state |

### Token Management
- Custom claims are set via `setAdminRole` Cloud Function
- `getIdTokenResult(true)` force-refreshes tokens after role changes
- `AuthWrapper` reads claims on auth state changes to dispatch routing

---

## 2. Authorization Roles

### Role Hierarchy

| Role | Level | Capabilities |
|---|---|---|
| `superadmin` | Highest | All admin + role management (promote/demote others) |
| `admin` | High | Full CRUD on all collections, user management, refunds |
| `content_manager` | High | Same as admin in current rules implementation |
| `support` | High | Same as admin in current rules implementation |
| `teacher` | Medium | Read batches/lessons/live_classes, write live_classes/scheduler_rules, manage assigned communities |
| `student` | Standard | Read enrolled content, write own user data (cart, bookmarks, stats, attempts) |

### Role Storage
Roles are stored in **two places** (for redundancy):
1. **Firebase Auth Custom Claims**: `request.auth.token.role` — authoritative, set by Cloud Function
2. **Firestore `/users/{uid}`**: `role` field — used as fallback in security rules

### Role Assignment
```
Admin → calls setAdminRole Cloud Function
  → Sets auth.customClaims({role, isTeacher})
  → Updates users/{uid} Firestore doc
  → Creates audit log entry
  → User must force-refresh token on next login
```

---

## 3. Firestore Security Rules

**File**: [`firestore.rules`](file:///home/himanshu/codes/eduverse/firestore.rules) (25KB)

### Helper Functions

```javascript
function isAdmin() {
  // Checks both custom claims AND Firestore user doc
  return request.auth != null && (
    request.auth.token.role in ['admin', 'superadmin'] ||
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'superadmin']
  );
}

function isEnrolled(courseId) {
  return request.auth != null && (
    exists(/databases/$(database)/documents/users/$(request.auth.uid)/enrolledCourses/$(courseId)) ||
    isAdmin()
  );
}

function isTeacher() {
  return request.auth != null && (
    request.auth.token.role == 'teacher' ||
    request.auth.token.isTeacher == true ||
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isTeacher == true
  );
}

function isCommunityOwner(teacherId) {
  return request.auth.uid == teacherId;
}

function isCommunityMember(courseIds) {
  return isAdmin() || (hasActiveEnrollment matching courseIds);
}
```

### Access Pattern Matrix

| Pattern | Collections | Description |
|---|---|---|
| **Owner-only** | `users/{uid}/*` (cart, bookmarks, stats, progress) | Only the user can read/write their own data |
| **Enrollment-gated** | `courses/{id}/lectures`, `notes`, `dpps`, `quizzes`, `planner` | Requires `isEnrolled(courseId)` for read |
| **Admin-only write** | `courses`, `combination_packs`, `test_series`, `ebooks`, `exams`, `posters` | Admin write, various read patterns |
| **Create-only** | `quiz_attempts`, `watch_sessions`, `transactions` | Students can create but not update/delete (immutable audit trails) |
| **Write-locked** | `enrollments` | `allow write: if false` — Cloud Functions only |
| **Public read** | `free_live_classes`, `posters`, published `courses`, active `combination_packs`, active `ebooks` | Anyone can read |
| **Auth read, admin write** | `config`, `app_config`, `notifications`, `admins` | Authenticated users read, admin write |
| **Community access** | `communities`, `posts`, `replies` | Based on `isCommunityMember()` or `isCommunityOwner()` |

### Collection Group Rules
```
/{path=**}/live_classes/{classId} → Read: isAdmin() or isTeacher()
/{path=**}/batches/{batchId}      → Read: isAdmin() or isTeacher()
/{path=**}/lessons/{lessonId}     → Read: isAdmin() or isTeacher()
```

### Notable Security Constraints

1. **Feed updates restricted**: Authenticated users can only update `likesCount` and `commentsCount` fields
2. **Live class viewer count**: Enrolled students can only update the `viewerCount` field
3. **Comment ownership**: Only the author or admin can update/delete comments
4. **Like enforcement**: `likeId` must equal `auth.uid`
5. **Community posts**: Pinning and marking as answered restricted to admin/teacher

---

## 4. Firebase Storage Security Rules

**File**: [`storage.rules`](file:///home/himanshu/codes/eduverse/storage.rules)

| Path | Read | Write | Notes |
|---|---|---|---|
| `/courses/thumbnails/**` | Public | Admin | Course cover images |
| `/subject_logos/**` | Public | Authenticated | Subject icons |
| `/courses/{courseId}/**` | `isEnrolled(courseId)` | Admin | Lectures, notes, DPPs — enrollment-gated |
| `/batches/**` | Public | Admin | Legacy batch content |
| `/feed/**` | Public | Admin | Feed images/media |
| `/test_series/**` | Public | Admin | Test series assets |
| `/users/{userId}/**` | Public | `auth.uid == userId` | User avatars & uploads |
| `/communities/{communityId}/**` | Member/Teacher | Member/Teacher | Post images |
| `/notifications/**` | Public | Admin | Notification images |
| `/exams/**` | Public | Admin | Exam category icons |
| `/ebooks/**` | Public | Admin | E-book PDFs & covers |
| `/combination_packs/**` | Public | Admin | Combo pack thumbnails |
| `/posters/**` | Public | Admin | Banner images |

### Helper Functions (mirroring Firestore)
```javascript
function isAdmin() { ... }        // Same check as Firestore
function isEnrolled(courseId) { ... } // Same enrollment check
```

---

## 5. Firebase App Check

**Configuration**: [`firebase_initializer.dart`](file:///home/himanshu/codes/eduverse/lib/core/firebase/firebase_initializer.dart)

| Mode | Provider | Notes |
|---|---|---|
| Production (Android) | Play Integrity | Validates app authenticity via Google Play services |
| Debug | Debug Provider | Allows development/testing without Play Integrity |

App Check is initialized during `FirebaseInitializer.init()` before any Firestore/Storage/Functions calls.

---

## 6. Content Protection

### E-book PDF Protection

| Protection Layer | Implementation |
|---|---|
| **In-app viewing only** | `syncfusion_flutter_pdfviewer` — no external app launch |
| **No download/share buttons** | UI buttons hidden for ebook content type |
| **Text selection disabled** | Disabled in PDF viewer configuration |
| **Screenshot blocking (Android)** | `screen_protector` package — `FLAG_SECURE` on window |
| **Secure local caching** | `PdfCacheService` stores PDFs in hidden app directory |
| **Obfuscated filenames** | MD5 hash of PDF URL used as local filename |
| **App documents directory** | Stored in `getApplicationDocumentsDirectory()/.cached_ebooks/` — not user-accessible |

### Content Type Access Control

| Content | In-App View | Download | Share | Screenshot Protection |
|---|---|---|---|---|
| E-books (paid) | ✅ | ❌ | ❌ | ✅ (Android) |
| Course notes | ✅ | ✅ | ✅ | ❌ |
| DPPs / Solutions | ✅ | ✅ | ✅ | ❌ |
| Planner PDFs | ✅ | ✅ | ✅ | ❌ |

---

## 7. Payment Security

| Aspect | Implementation |
|---|---|
| **Credential storage** | Razorpay keys stored in `config/razorpay` Firestore doc (admin-only access) |
| **Dynamic config loading** | `RazorpayService.loadConfig()` fetches keys at runtime (not hardcoded) |
| **Webhook verification** | `webhookPaymentUpdate` Cloud Function validates payment callbacks |
| **Refund processing** | Server-side only via `refundPurchase` Cloud Function (admin auth required) |
| **Purchase immutability** | Students can create purchase docs but cannot update/delete them |
| **Enrollment atomicity** | `onPurchaseCreate` uses Firestore transactions for atomic seat decrements |
| **Transaction records** | `users/{uid}/transactions` is create-only (no update/delete for students) |

---

## 8. CORS Configuration

**File**: [`cors.json`](file:///home/himanshu/codes/eduverse/cors.json)

```json
{
  "origin": ["*"],
  "method": ["GET", "HEAD"],
  "responseHeader": [
    "Content-Type",
    "Content-Length",
    "Content-Range",
    "Accept-Ranges"
  ],
  "maxAgeSeconds": 3600
}
```

Configured for web video streaming, PDF viewing, and range-request downloads.

---

## 9. Security Checklist

- ✅ Custom claims properly set for all admin/teacher users
- ✅ Firestore rules prevent non-admin writes to content collections
- ✅ Storage rules prevent non-admin uploads to content buckets
- ✅ Cloud Functions validate admin tokens before privileged operations
- ✅ Enrollment collection write-locked (Cloud Functions only)
- ✅ Audit logs enabled for all admin mutations
- ✅ Quiz attempts and transactions are immutable (create-only)
- ✅ App Check enabled (Play Integrity for production Android)
- ✅ E-book PDFs protected from screenshots, downloads, and sharing
- ✅ Razorpay credentials not hardcoded (dynamic Firestore config)
- ✅ Daily Firestore backups via scheduled Cloud Function
