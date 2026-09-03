# Eduverse — Database Schema

Complete reference for all data storage: Firestore, Realtime Database, Hive, SharedPreferences, and Firebase Storage.

---

## 1. Firestore Collections

### 1.1 `users`

**Path**: `/users/{uid}`
**Purpose**: User profiles, roles, settings, FCM tokens

| Field | Type | Description |
|---|---|---|
| `uid` | `string` | Firebase Auth UID |
| `name` | `string` | Display name |
| `email` | `string` | Email address |
| `phone` | `string` | Phone number |
| `role` | `string` | `student` \| `admin` \| `superadmin` \| `teacher` \| `content_manager` \| `support` |
| `disabled` | `bool` | Account disabled flag |
| `isTeacher` | `bool` | Teacher access flag |
| `teacherSubjects` | `array<map>` | `[{subjectName, courseId}]` |
| `avatarUrl` | `string` | Profile picture URL |
| `avatarType` | `string` | Avatar type (image/initials/emoji) |
| `avatarColor` | `string` | Avatar background color |
| `headline` | `string` | User tagline |
| `bio` | `string` | User biography |
| `appVersion` | `string` | Last known app version |
| `fcmToken` | `string` | Push notification token |
| `createdAt` | `timestamp` | Account creation time |
| `updatedAt` | `timestamp` | Last profile update |

**Subcollections**:

#### `/users/{uid}/enrolledCourses/{courseId}`
| Field | Type | Description |
|---|---|---|
| `courseId` | `string` | Enrolled course ID |
| `enrolledAt` | `timestamp` | Enrollment timestamp |
| `status` | `string` | Enrollment status |
| `purchaseId` | `string` | Associated purchase ID |

#### `/users/{uid}/purchasedEbooks/{ebookId}`
Ebook purchase records (ebookId, purchasedAt)

#### `/users/{uid}/purchasedTestSeries/{tsId}`
Test series purchase records

#### `/users/{uid}/cart/{itemId}`
| Field | Type | Description |
|---|---|---|
| `courseId` | `string` | Course ID |
| `batchId` | `string?` | Optional batch ID |
| `testSeriesId` | `string?` | Optional test series ID |
| `combinationPackId` | `string?` | Optional combo pack ID |
| `ebookId` | `string?` | Optional ebook ID |
| `recordedBatchId` | `string?` | Optional recorded batch ID |
| `title` | `string` | Display title |
| `price` | `double` | Item price |
| `quantity` | `int` | Quantity |

#### `/users/{uid}/bookmarks/{bookmarkId}`
| Field | Type | Description |
|---|---|---|
| `id` | `string` | Bookmark ID |
| `title` | `string` | Item title |
| `type` | `string` | `course` \| `article` \| `video` \| `batch` |
| `dateAdded` | `timestamp` | Bookmark date |
| `metadata` | `map` | Additional context |

#### `/users/{uid}/transactions/{transactionId}`
Payment history records. **Create-only** (no update/delete for students).

#### `/users/{uid}/quiz_attempts/{attemptId}`
| Field | Type | Description |
|---|---|---|
| `score` | `int` | Points scored |
| `totalQuestions` | `int` | Total questions |
| `correctAnswers` | `int` | Correct count |
| `wrongAnswers` | `int` | Wrong count |
| `unattemptedCount` | `int` | Skipped count |
| `percentage` | `double` | Score percentage |
| `categoryLabel` | `string` | Quiz category/subject |
| `timestamp` | `timestamp` | Attempt time |

**Access**: Create-only (no update/delete).

#### `/users/{uid}/stats/quiz`
Aggregate quiz statistics (totalAttempts, avgScore, bestScore, etc.)

#### `/users/{uid}/stats/watch`
Aggregate watch statistics (totalMinutes, totalSessions, etc.)

#### `/users/{uid}/watch_sessions/{sessionId}`
| Field | Type | Description |
|---|---|---|
| `durationMinutes` | `double` | Session duration |
| `subjectName` | `string?` | Optional subject |
| `timestamp` | `timestamp` | Session time |

**Access**: Create-only.

#### `/users/{uid}/test_attempts/{attemptId}`
Test series submission records.

#### `/users/{uid}/courseProgress/{courseId}/lectures/{lectureId}`
Lecture completion tracking per course.

#### `/users/{uid}/batchProgress/{progressId}`
Legacy batch progress (backward compatibility).

#### `/users/{uid}/courseBookmarks/{bookmarkId}`
Course-specific bookmarks.

#### `/users/{uid}/progress/{lessonId}`
Lesson completion progress.

---

### 1.2 `courses`

**Path**: `/courses/{courseId}`
**Purpose**: Master course catalog

| Field | Type | Description |
|---|---|---|
| `id` | `string` | Course ID |
| `title` | `string` | Course title |
| `subtitle` | `string` | Subtitle |
| `description` | `string` | Full description |
| `emoji` | `string` | Display emoji |
| `gradientColors` | `array<string>` | Card gradient colors |
| `thumbnailUrl` | `string` | Thumbnail image URL |
| `priceDefault` | `double` | Default price |
| `realPrice` | `double` | Original MRP |
| `finalPrice` | `double` | Discounted price |
| `startDate` | `timestamp?` | Course start date |
| `endDate` | `timestamp?` | Course end date |
| `seatsTotal` | `int` | Total seats |
| `seatsLeft` | `int` | Remaining seats |
| `duration` | `string` | Course duration label |
| `isActive` | `bool` | Active flag |
| `visibility` | `string` | `published` \| `draft` |
| `slug` | `string` | URL-friendly slug |
| `language` | `string` | Course language |
| `level` | `string` | Difficulty level |
| `teachers` | `array<map>` | `[{uid, name, subjects}]` |
| `linkedTestSeries` | `array<string>` | Linked test series IDs |
| `linkedEbooks` | `array<string>` | Linked ebook IDs |
| `subjectLogos` | `map<string,string>` | Subject name → logo URL |
| `createdAt` | `timestamp` | Creation time |
| `updatedAt` | `timestamp` | Last update |

**Subcollections**:

#### `/courses/{courseId}/lectures/{lectureId}`
| Field | Type | Description |
|---|---|---|
| `title` | `string` | Lecture title |
| `description` | `string` | Description |
| `videoUrl` | `string` | Video URL (YouTube or Storage) |
| `contentUrl` | `string` | Content URL |
| `subject` | `string` | Subject name |
| `chapter` | `string` | Chapter name |
| `orderIndex` | `int` | Display order |
| `order` | `int` | Sort order |
| `isLocked` | `bool` | Locked for non-enrolled |
| `type` | `string` | Lecture type |
| `duration` | `string` | Duration label |
| `lectureNo` | `int` | Lecture number |
| `linkedNoteIds` | `array<string>` | Associated note IDs |
| `thumbnailUrl` | `string` | Thumbnail URL |
| `storagePath` | `string` | Firebase Storage path |
| `linkedCourses` | `array<map>` | Cross-linked courses |
| `linkedFrom` | `map?` | Source lecture if linked |
| `viewCount` | `int` | Total views |

#### `/courses/{courseId}/live_classes/{classId}`
| Field | Type | Description |
|---|---|---|
| `title` | `string` | Class title |
| `description` | `string` | Description |
| `instructorName` | `string` | Teacher name |
| `startTime` | `timestamp` | Start time |
| `durationMinutes` | `int` | Duration |
| `status` | `string` | `upcoming` \| `live` \| `completed` \| `cancelled` |
| `youtubeUrl` | `string` | YouTube stream URL |
| `thumbnailUrl` | `string` | Thumbnail |
| `subject` | `string` | Subject |
| `chapter` | `string` | Chapter |
| `parentRuleId` | `string?` | Recurring rule source |
| `generatedDateString` | `string?` | Generated date |
| `viewerCount` | `int` | Current viewers |

#### `/courses/{courseId}/notes/{noteId}`
| Field | Type |
|---|---|
| `title` | `string` |
| `fileUrl` | `string` (Storage PDF URL) |
| `subject` | `string` |
| `chapter` | `string` |
| `lectureId` | `string?` |
| `createdAt` | `timestamp` |

#### `/courses/{courseId}/dpps/{dppId}`
| Field | Type |
|---|---|
| `title` | `string` |
| `subject` | `string` |
| `chapter` | `string` |
| `dppPdfUrl` | `string` |
| `solutionPdfUrl` | `string` |
| `lectureId` | `string?` |
| `createdAt` | `timestamp` |

#### `/courses/{courseId}/quizzes/{quizId}`
Quiz definitions with questions, timer, marking scheme.

#### `/courses/{courseId}/planner/{plannerId}`
Study schedule planner items.

#### `/courses/{courseId}/recorded_batches/{batchId}`
Recorded batch archives with own subcollections: `lessons`, `notes`, `dpps`, `quizzes`.

#### `/courses/{courseId}/batches/{batchId}`
Legacy batch hierarchy (backward compatibility).

#### `/courses/{courseId}/scheduler_rules/{ruleId}`
| Field | Type | Description |
|---|---|---|
| `weekdays` | `array<int>` | 1=Mon through 7=Sun |
| `startTime` | `string` | e.g. "10:00" |
| `startDate` | `timestamp` | Rule effective from |
| `endDate` | `timestamp` | Rule effective until |
| `instructorName` | `string` | Teacher name |
| `subject` | `string` | Subject |

---

### 1.3 `combination_packs`

**Path**: `/combination_packs/{packId}`

| Field | Type | Description |
|---|---|---|
| `id` | `string` | Pack ID |
| `title` | `string` | Bundle title |
| `description` | `string` | Description |
| `thumbnailUrl` | `string` | Thumbnail |
| `realPrice` | `double` | Original MRP |
| `finalPrice` | `double` | Discounted price |
| `courses` | `array<string>` | Included course IDs |
| `testSeries` | `array<string>` | Included test series IDs |
| `ebooks` | `array<string>` | Included ebook IDs |
| `isActive` | `bool` | Active flag |
| `isCourseBatch` | `bool` | Combo batch flag |
| `createdAt` | `timestamp` | Creation time |

**Access**: Public read if `isActive == true`, admin write.

---

### 1.4 `test_series`

**Path**: `/test_series/{testSeriesId}`

| Field | Type | Description |
|---|---|---|
| `id` | `string` | Test series ID |
| `title` | `string` | Title |
| `description` | `string` | Description |
| `subject` | `string` | Subject |
| `category` | `string` | Category label |
| `thumbnailUrl` | `string` | Thumbnail |
| `gradientColors` | `array` | Card gradient |
| `emoji` | `string` | Display emoji |
| `price` | `double` | Price |
| `realPrice` | `double` | Original MRP |
| `totalTests` | `int` | Number of tests |
| `visibility` | `string` | `published` \| `draft` |
| `createdAt` | `timestamp` | Creation time |

**Subcollection**: `/test_series/{tsId}/tests/{testId}` — Individual mock tests with questions, timings, marking schemes.

**Index**: `visibility` ASC + `createdAt` DESC.

---

### 1.5 `ebooks`

**Path**: `/ebooks/{ebookId}`

| Field | Type | Description |
|---|---|---|
| `id` | `string` | Ebook ID |
| `title` | `string` | Title |
| `subtitle` | `string` | Subtitle |
| `description` | `string` | Description |
| `thumbnailUrl` | `string` | Cover image |
| `pdfUrl` | `string` | PDF file URL |
| `realPrice` | `double` | Original MRP |
| `finalPrice` | `double` | Discounted price |
| `isActive` | `bool` | Active flag |
| `createdAt` | `timestamp` | Creation time |

**Access**: Public read if `isActive == true`.

---

### 1.6 `feed`

**Path**: `/feed/{feedId}`

| Field | Type | Description |
|---|---|---|
| `id` | `string` | Feed item ID |
| `type` | `string` | `answerWriting` \| `currentAffairs` \| `articles` \| `videos` \| `quizzes` \| `jobs` |
| `title` | `string` | Title |
| `description` | `string` | Short description |
| `categoryLabel` | `string` | Category |
| `emoji` | `string` | Display emoji |
| `color` | `string` | Card color |
| `thumbnailUrl` | `string` | Thumbnail |
| `isPublic` | `bool` | Public visibility |
| `articleContent` | `map` | Article body, tags, read time |
| `currentAffairsContent` | `map` | Event date, context, analysis |
| `answerWritingContent` | `map` | Question, model answer, key points |
| `videoContent` | `map` | Video URL, duration, key points |
| `quizQuestions` | `array` | Quiz questions array |
| `jobContent` | `map` | Organization, salary, apply URL |
| `likesCount` | `int` | Like counter |
| `commentsCount` | `int` | Comment counter |
| `viewCount` | `int` | View counter |
| `createdAt` | `timestamp` | Creation time |
| `updatedAt` | `timestamp` | Last update |
| `*Delta` / `*Html` | `string` | Rich text fields (bodyDelta/bodyHtml, etc.) |

**Subcollections**:
- `/feed/{feedId}/comments/{commentId}`: `userId`, `userName`, `text`, `createdAt`, `userAvatarUrl`
- `/feed/{feedId}/likes/{likeId}`: likeId == auth.uid
- `/feed/{feedId}/answers/{userId}`: Answer writing submissions

**Indexes**: Multiple on `isPublic`, `type`, `id`, `createdAt`.

---

### 1.7 `purchases`

**Path**: `/purchases/{purchaseId}`

| Field | Type | Description |
|---|---|---|
| `userId` | `string` | Buyer UID |
| `items` | `array<map>` | Cart items purchased |
| `amount` | `double` | Total amount |
| `paymentMethod` | `string` | Payment method |
| `status` | `string` | `pending` \| `success` \| `failed` |
| `razorpayPaymentId` | `string?` | Razorpay payment ID |
| `razorpayOrderId` | `string?` | Razorpay order ID |
| `createdAt` | `timestamp` | Purchase time |

**Access**: Create by owner/admin. Update/delete admin only.
**Trigger**: `onPurchaseCreate` Cloud Function fires on document creation.

---

### 1.8 `enrollments`

**Path**: `/enrollments/{userId}_{courseId}`

**⚠️ Write-locked**: `allow write: if false` — managed exclusively by Cloud Functions (`onPurchaseCreate`, `enrollStudent`).

---

### 1.9 `notifications`

**Path**: `/notifications/{notificationId}`

| Field | Type | Description |
|---|---|---|
| `id` | `string` | Notification ID |
| `title` | `string` | Title |
| `body` | `string` | Message body |
| `type` | `string` | Notification type |
| `targetType` | `string` | Target entity type |
| `targetId` | `string` | Target entity ID |
| `batchId` | `string?` | Target batch |
| `courseId` | `string?` | Target course |
| `imageUrl` | `string?` | Image URL |
| `createdAt` | `timestamp` | Creation time |

**Trigger**: `onNotificationCreate` Cloud Function sends FCM multicast.

---

### 1.10 `communities`

**Path**: `/communities/{communityId}`

Community metadata, teacher info, linked courseIds.

**Subcollections**:
- `/communities/{id}/posts/{postId}`: `title`, `body`, `authorId`, `isPinned`, `replyCount`, `isAnswered`, `createdAt`
- `/communities/{id}/posts/{postId}/replies/{replyId}`: Reply content

**Indexes**: `posts` — `isPinned` DESC + `createdAt` DESC (both collection and collection group).

---

### 1.11 Other Root Collections

| Collection | Purpose | Access |
|---|---|---|
| `config/{configId}` | System configs (Razorpay keys, admin settings) | Auth read, admin write |
| `config/promo_codes/codes/{codeId}` | Discount coupon definitions | Admin only |
| `app_config/{docId}` | App versioning & update management | Auth read, admin write |
| `exams/{examId}` | Exam categories (UPSC, SSC, JEE, etc.) | Auth read, admin write |
| `posters/{posterId}` | Banners & announcement popups | Public read, admin write |
| `audits/{auditId}` | Admin action audit trail | Admin only |
| `admin_stats/{docId}` | Aggregated admin metrics cache | Admin only |
| `admins/{adminId}` | Admin directory lookup | Auth read, admin write |
| `live_classes/{classId}` | Global live classes catalog | Auth read, admin write |
| `free_live_classes/{classId}` | Public live classes (with comments) | **Public** read, admin write |
| `mock_tests/{testId}` | Standalone mock tests | Auth read, admin write |
| `questions/{questionId}` | Global question bank | Auth read, admin write |
| `quiz_subjects/{subjectId}` | Quiz subject taxonomy | Auth read, admin write |
| `quizzes_pool/{quizId}` | Shared quiz repository | Auth read, admin write |
| `topics/{topicId}` | Syllabus / map work topics | Auth read, admin write |
| `daily_practice/{practiceId}` | Daily practice sets | Auth read, admin write |
| `workbooks/{workbookId}` | Student practice notebooks | Owner only |

---

## 2. Firestore Composite Indexes

| # | Collection | Scope | Fields |
|---|---|---|---|
| 1 | `batches` | `COLLECTION_GROUP` | `isActive` ASC, `startDate` DESC |
| 2 | `posters` | `COLLECTION` | `isActive` ASC, `showAsPopup` ASC, `order` ASC |
| 3 | `posts` | `COLLECTION` | `isPinned` DESC, `createdAt` DESC |
| 4 | `posts` | `COLLECTION_GROUP` | `isPinned` DESC, `createdAt` DESC |
| 5 | `test_series` | `COLLECTION` | `visibility` ASC, `createdAt` DESC |
| 6 | `feed` | `COLLECTION` | `isPublic` ASC, `createdAt` DESC |
| 7 | `feed` | `COLLECTION` | `isPublic` ASC, `type` ASC, `createdAt` DESC |
| 8 | `feed` | `COLLECTION` | `isPublic` ASC, `type` ASC, `id` ASC |
| 9 | `feed` | `COLLECTION` | `isPublic` ASC, `id` ASC |

---

## 3. Firebase Realtime Database (RTDB)

| Path | Purpose |
|---|---|
| `live_viewers/{sessionKey}/{userId}` | Presence tracking for live class viewer counts |

Uses `onDisconnect().remove()` for automatic cleanup when users leave. Combined with Firestore `viewerCount` atomic increment for accurate counts.

**RTDB URL**: `https://eduverse-dad5e-default-rtdb.firebaseio.com`

---

## 4. Local Storage

### 4.1 Hive

| Box Name | Purpose | Data Shape |
|---|---|---|
| `lecture_progress` | Offline video resume positions | `{ progressSeconds: int, totalDurationSeconds: int, lastOpened: DateTime }` per lecture ID |

Initialized in `main.dart` via `Hive.initFlutter()`.

### 4.2 SharedPreferences

| Key Pattern | Purpose |
|---|---|
| Profile fields (`fullName`, `headline`, `bio`, etc.) | Local profile cache (`ProfileStorage`) |
| `poster_popup_shown_{posterId}` | Poster impression tracking |
| `poster_popup_shown_{posterId}_date` | Daily frequency control |
| `shown_promo_batch_{batchId}` | Batch promotion dismissal |
| `my_downloads_list` | Downloaded file catalog (JSON) |
| `last_selected_batch` | Last selected batch/combo pack |
| `favourite_batches_{comboPackId}` | Favourite batch IDs per combo |

---

## 5. Firebase Storage Bucket Paths

**Bucket**: `eduverse-dad5e.firebasestorage.app`

| Path | Content | Read Access | Write Access |
|---|---|---|---|
| `/courses/thumbnails/` | Course thumbnail images | Public | Admin |
| `/subject_logos/` | Subject icon images | Public | Authenticated |
| `/courses/{courseId}/` | Lectures, notes, DPPs, solutions | Enrolled students | Admin |
| `/batches/` | Legacy batch content | Public | Admin |
| `/feed/` | Feed images and media | Public | Admin |
| `/test_series/` | Test series assets | Public | Admin |
| `/users/{userId}/` | User avatars and uploads | Public | Owner |
| `/communities/{communityId}/` | Community post images | Member/Teacher | Member/Teacher |
| `/notifications/` | Notification images | Public | Admin |
| `/exams/` | Exam category icons | Public | Admin |
| `/ebooks/` | E-book PDFs and covers | Public | Admin |
| `/combination_packs/` | Combo pack thumbnails | Public | Admin |
| `/posters/` | Banner images | Public | Admin |

**CORS**: Origin `*`, Methods `GET`/`HEAD`, Headers include `Content-Range` and `Accept-Ranges` for streaming.
