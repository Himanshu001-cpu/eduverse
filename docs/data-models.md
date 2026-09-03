# Eduverse — Data Models Reference

All Dart data model classes organized by module, with fields, types, and source file paths.

---

## 1. Store Models (`lib/store/models/`)

### `Course` — [`store_models.dart`](file:///home/himanshu/codes/eduverse/lib/store/models/store_models.dart)

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Course ID |
| `title` | `String` | Course title |
| `subtitle` | `String` | Subtitle |
| `description` | `String` | Full description |
| `emoji` | `String` | Display emoji |
| `gradientColors` | `List<Color>` | Card gradient colors |
| `thumbnailUrl` | `String` | Thumbnail URL |
| `priceDefault` | `double` | Default price |
| `realPrice` | `double` | Original MRP |
| `finalPrice` | `double` | Discounted price |
| `startDate` | `DateTime?` | Course start date |
| `endDate` | `DateTime?` | Course end date |
| `seatsTotal` | `int` | Total seats |
| `seatsLeft` | `int` | Remaining seats |
| `duration` | `String` | Duration label |
| `isActive` | `bool` | Active flag |
| `isEnrolled` | `bool` | Current user enrolled |
| `linkedTestSeries` | `List<String>` | Linked test series IDs |
| `linkedEbooks` | `List<String>` | Linked ebook IDs |
| `subjectLogos` | `Map<String, String>` | Subject → logo URL |

**Serialization**: `fromMap()`, `toMap()`

---

### `Batch` — [`store_models.dart`](file:///home/himanshu/codes/eduverse/lib/store/models/store_models.dart)

| Field | Type |
|---|---|
| `id` | `String` |
| `name` | `String` |
| `startDate` | `DateTime?` |
| `realPrice` | `double` |
| `finalPrice` | `double` |
| `seatsLeft` | `int` |
| `duration` | `String` |
| `thumbnailUrl` | `String` |
| `isEnrolled` | `bool` |
| `isCourseBatch` | `bool` |

---

### `CartItem` — [`store_models.dart`](file:///home/himanshu/codes/eduverse/lib/store/models/store_models.dart)

| Field | Type |
|---|---|
| `courseId` | `String` |
| `batchId` | `String?` |
| `testSeriesId` | `String?` |
| `combinationPackId` | `String?` |
| `ebookId` | `String?` |
| `recordedBatchId` | `String?` |
| `title` | `String` |
| `price` | `double` |
| `quantity` | `int` |

**Serialization**: `fromMap()`, `toMap()`

---

### `Purchase` — [`store_models.dart`](file:///home/himanshu/codes/eduverse/lib/store/models/store_models.dart)

| Field | Type |
|---|---|
| `userId` | `String` |
| `id` | `String` |
| `timestamp` | `DateTime` |
| `items` | `List<CartItem>` |
| `amount` | `double` |
| `paymentMethod` | `String` |
| `status` | `String` |

---

### `CombinationPack` — [`store_models.dart`](file:///home/himanshu/codes/eduverse/lib/store/models/store_models.dart)

| Field | Type |
|---|---|
| `id` | `String` |
| `title` | `String` |
| `description` | `String` |
| `thumbnailUrl` | `String` |
| `realPrice` | `double` |
| `finalPrice` | `double` |
| `courses` | `List<String>` |
| `testSeries` | `List<String>` |
| `ebooks` | `List<String>` |
| `isActive` | `bool` |
| `isCourseBatch` | `bool` |

---

### `Ebook` — [`store_models.dart`](file:///home/himanshu/codes/eduverse/lib/store/models/store_models.dart)

| Field | Type |
|---|---|
| `id` | `String` |
| `title` | `String` |
| `subtitle` | `String` |
| `description` | `String` |
| `thumbnailUrl` | `String` |
| `pdfUrl` | `String` |
| `realPrice` | `double` |
| `finalPrice` | `double` |
| `isActive` | `bool` |
| `isOwned` | `bool` |

---

### `Poster` / `PosterButton` — [`poster_model.dart`](file:///home/himanshu/codes/eduverse/lib/store/models/poster_model.dart)

**Poster**:
| Field | Type |
|---|---|
| `id` | `String` |
| `title` | `String` |
| `subtitle` | `String` |
| `thumbnailUrl` | `String` |
| `aspectRatio` | `double` |
| `externalUrl` | `String?` |
| `inAppRoute` | `String?` |
| `inAppTargetId` | `String?` |
| `inAppTargetType` | `String?` |
| `buttons` | `List<PosterButton>` |
| `showAsPopup` | `bool` |
| `popupFrequency` | `String` (`once` \| `daily` \| `always`) |
| `showInStore` | `bool` |
| `showInFeed` | `bool` |
| `sendNotification` | `bool` |
| `isActive` | `bool` |
| `order` | `int` |
| `createdAt` / `updatedAt` | `DateTime` |

**PosterButton**: `label`, `externalUrl`, `inAppRoute`, `inAppTargetId`, `inAppTargetType`

---

## 2. Study Models (`lib/study/domain/models/`, `lib/study/models/`)

### `StudyCourse` — [`study_entities.dart`](file:///home/himanshu/codes/eduverse/lib/study/domain/models/study_entities.dart)

| Field | Type |
|---|---|
| `id` | `String` |
| `title` | `String` |
| `subtitle` | `String` |
| `emoji` | `String` |
| `gradientColors` | `List<Color>` |
| `thumbnailUrl` | `String` |
| `totalLectures` | `int` |
| `completedLectures` | `int` |
| `progress` | `double` |

---

### `StudyBatch` — [`study_entities.dart`](file:///home/himanshu/codes/eduverse/lib/study/domain/models/study_entities.dart)

| Field | Type |
|---|---|
| `id` | `String` |
| `courseId` | `String` |
| `name` | `String` |
| `courseName` | `String` |
| `emoji` | `String` |
| `gradientColors` | `List<Color>` |
| `thumbnailUrl` | `String` |
| `startDate` | `DateTime?` |
| `totalLectures` | `int` |
| `completedLectures` | `int` |
| `progress` | `double` |
| `isCourseBatch` | `bool` |
| `isCombo` | `bool` |
| `courseIds` | `List<String>` |

---

### `StudyLecture` — [`study_entities.dart`](file:///home/himanshu/codes/eduverse/lib/study/domain/models/study_entities.dart)

| Field | Type |
|---|---|
| `id` | `String` |
| `title` | `String` |
| `description` | `String` |
| `videoUrl` | `String` |
| `contentUrl` | `String` |
| `subject` | `String` |
| `chapter` | `String` |
| `orderIndex` | `int` |
| `order` | `int` |
| `isLocked` | `bool` |
| `isWatched` | `bool` |
| `type` | `String` |
| `duration` | `String` |
| `lectureNo` | `int` |
| `linkedNoteIds` | `List<String>` |
| `thumbnailUrl` | `String` |

---

### `StudyLiveClass` — [`study_entities.dart`](file:///home/himanshu/codes/eduverse/lib/study/domain/models/study_entities.dart)

| Field | Type |
|---|---|
| `id` | `String` |
| `title` | `String` |
| `description` | `String` |
| `instructorName` | `String` |
| `startTime` | `DateTime` |
| `durationMinutes` | `int` |
| `status` | `String` (`upcoming` \| `live` \| `completed`) |
| `youtubeUrl` | `String` |
| `thumbnailUrl` | `String` |
| `subject` / `chapter` | `String` |
| `courseId` / `courseName` | `String` |
| `batchId` / `batchName` | `String` |
| `parentRuleId` | `String?` |
| `generatedDateString` | `String?` |

---

### Other Study Models — [`study_entities.dart`](file:///home/himanshu/codes/eduverse/lib/study/domain/models/study_entities.dart)

- **`StudyQuiz`**: `id`, `title`, `description`, `questionCount`, `durationMinutes`, `scheduledAt`
- **`StudyNote`**: `id`, `title`, `fileUrl`, `createdAt`, `subject`, `chapter`, `lectureId`
- **`StudyDpp`**: `id`, `title`, `subject`, `chapter`, `dppPdfUrl`, `solutionPdfUrl`, `lectureId`, `createdAt`
- **`StudyRecordedBatch`**: `id`, `courseId`, `title`, `description`, `thumbnailUrl`, `isFreeForEnrolled`, `realPrice`, `finalPrice`, `isActive`, `totalLectures`, `completedLectures`, `progress`

### [`test_series_entities.dart`](file:///home/himanshu/codes/eduverse/lib/study/domain/models/test_series_entities.dart)
- **`TestSeriesItem`**: `id`, `title`, `description`, `subject`, `category`, `thumbnailUrl`, `gradientColors`, `emoji`, `price`, `realPrice`, `totalTests`, `completedTests`, `progress`, `isPurchased`

### [`community_models.dart`](file:///home/himanshu/codes/eduverse/lib/study/models/community_models.dart)
- **`StudentCommunity`**, **`StudentPost`**, **`StudentReply`**

### [`study_models.dart`](file:///home/himanshu/codes/eduverse/lib/study/models/study_models.dart)
- **`ContinueLearningModel`**, **`EnrolledCourseModel`**, **`DailyPracticeModel`**
- **`LessonModel`**, **`TestModel`**, **`QuestionModel`**
- **`TopicNodeModel`**, **`WorkbookModel`**, **`TaskModel`**

---

## 3. Feed Models (`lib/feed/models/`)

### `FeedItem` — [`feed_models.dart`](file:///home/himanshu/codes/eduverse/lib/feed/models/feed_models.dart)

| Field | Type |
|---|---|
| `id` | `String` |
| `type` | `ContentType` enum |
| `title` | `String` |
| `description` | `String` |
| `categoryLabel` | `String` |
| `emoji` | `String` |
| `color` | `String` |
| `thumbnailUrl` | `String` |
| `isPublic` | `bool` |
| `articleContent` | `ArticleContent?` |
| `currentAffairsContent` | `CurrentAffairsContent?` |
| `answerWritingContent` | `AnswerWritingContent?` |
| `videoContent` | `VideoContent?` |
| `quizQuestions` | `List<QuizQuestion>?` |
| `jobContent` | `JobContent?` |
| `likesCount` / `commentsCount` / `viewCount` | `int` |
| `createdAt` / `updatedAt` | `DateTime` |

**ContentType enum**: `answerWriting`, `currentAffairs`, `articles`, `videos`, `quizzes`, `jobs`

### Content Sub-Models:
- **`ArticleContent`**: `body`, `tags`, `estimatedReadTime`, `publishedDate`, `bodyDelta`, `bodyHtml`
- **`CurrentAffairsContent`**: `eventDate`, `context`, `whatHappened`, `whyItMatters`, `examRelevance`, `tags`, delta/html fields
- **`AnswerWritingContent`**: `question`, `wordLimit`, `timeLimitMinutes`, `modelAnswer`, `keyPoints`, delta/html fields
- **`VideoContent`**: `videoUrl`, `durationMinutes`, `keyPoints`, `thumbnailUrl`, `isLive`
- **`JobContent`**: `organization`, `location`, `salaryRange`, `applyUrl`, `detailsText`, `applicationStart`, `applicationEnd`, `eligibility`, `jobType`, `vacancies`, `selectionProcess`, `howToApply`, `examDate`

### `QuizQuestion` / `AnswerOption` / `Quiz`
- **`QuizQuestion`**: `id`, `questionText`, `answerType`, `options` (List<AnswerOption>), `correctBooleanAnswer`, `correctShortAnswer`, `score`, `explanation`, `subject`, `negativeMarks`, delta/html fields
- **`AnswerOption`**: `id`, `text`, `isCorrect`, `textDelta`, `textHtml`
- **`Quiz`**: `id`, `title`, `description`, `instructions`, `timeLimitMinutes`, `marksPerQuestion`, `negativeMarking`, `questions`, `createdAt`, `updatedAt`

### `Comment` — [`comment_model.dart`](file:///home/himanshu/codes/eduverse/lib/feed/models/comment_model.dart)

| Field | Type |
|---|---|
| `id` | `String` |
| `userId` | `String` |
| `userName` | `String` |
| `text` | `String` |
| `createdAt` | `DateTime` |
| `userAvatarUrl` | `String?` |

---

## 4. Admin Models (`lib/admin/models/`)

### [`admin_models.dart`](file:///home/himanshu/codes/eduverse/lib/admin/models/admin_models.dart) (32KB)

- **`AdminCourse`**: Full admin representation with `slug`, `language`, `level`, `visibility`, `teachers` (List<CourseTeacher>), `linkedTestSeries`, `linkedEbooks`, `subjectLogos`. Methods: `fromMap()`, `toMap()`
- **`CourseTeacher`**: `uid`, `name`, `subjects` (List<TeacherSubject>)
- **`TeacherSubject`**: `subjectName`, `courseId`
- **`AdminLecture`**: All lecture fields + `storagePath`, `linkedCourses`, `linkedFrom`, `linkedNoteIds`
- **`AdminUser`**: `uid`, `name`, `email`, `phone`, `role`, `disabled`, `enrolledCourses`, `purchasedTestSeries`, `cart`, `isTeacher`, `teacherSubjects`
- **`AdminPurchase`** / **`AdminPurchaseItem`**: Purchase with itemized breakdown
- **`AdminAudit`**: `action`, `userId`, `targetCollection`, `targetId`, `details`, `timestamp`
- **`AdminNote`**, **`AdminDpp`**, **`AdminPlannerItem`**, **`AdminQuiz`**, **`AdminLiveClass`**
- **`AdminCombinationPack`**, **`AdminRecordedBatch`**

### [`community_models.dart`](file:///home/himanshu/codes/eduverse/lib/admin/models/community_models.dart)
- **`Community`**, **`CommunityPost`**, **`CommunityReply`**

### [`scheduler_models.dart`](file:///home/himanshu/codes/eduverse/lib/admin/models/scheduler_models.dart)
- **`RecurringClassRule`**: `id`, `weekdays` (List<int>), `startTime`, `startDate`, `endDate`, `instructorName`, `subject`, `title`, `durationMinutes`

### [`test_series_models.dart`](file:///home/himanshu/codes/eduverse/lib/admin/models/test_series_models.dart)
- **`AdminTestSeries`**, **`LinkedCourse`**

### [`test_quiz_models.dart`](file:///home/himanshu/codes/eduverse/lib/admin/models/test_quiz_models.dart)
- **`QuizSubject`**, **`QuizQuestion`** (admin-specific quiz question variant)

---

## 5. Core Models

### [`notification_model.dart`](file:///home/himanshu/codes/eduverse/lib/core/notifications/notification_model.dart)

| Field | Type |
|---|---|
| `id` | `String` |
| `title` | `String` |
| `body` | `String` |
| `type` | `String` |
| `targetType` | `String` |
| `targetId` | `String` |
| `batchId` | `String?` |
| `courseId` | `String?` |
| `createdAt` | `DateTime` |
| `imageUrl` | `String?` |
| `isRead` | `bool` |

### `PromoCode` / `PromoCodeResult` — [`promo_code_service.dart`](file:///home/himanshu/codes/eduverse/lib/core/firebase/promo_code_service.dart)
- **`PromoCode`**: `code`, `discountType` (percentage/fixed), `discountValue`, `minOrderAmount`, `maxUsage`, `currentUsage`, `isActive`, `validUntil`
- **`PromoCodeResult`**: `isValid`, `discountAmount`, `message`

### `RazorpayConfig` / `PaymentResult` — [`razorpay_service.dart`](file:///home/himanshu/codes/eduverse/lib/core/firebase/razorpay_service.dart)
- **`RazorpayConfig`**: `keyId`, `keySecret`, `webhookSecret`

---

## 6. Profile Models

### `ProfileModel` — [`profile_storage.dart`](file:///home/himanshu/codes/eduverse/lib/profile/profile_storage.dart)

| Field | Type |
|---|---|
| `fullName` | `String` |
| `headline` | `String` |
| `bio` | `String` |
| `medium` | `String` |
| `avatarType` | `String` |
| `avatarValue` | `String` |
| `avatarColor` | `String` |
| `email` | `String` |
| `phone` | `String` |

### `BookmarkItem` — [`bookmark_model.dart`](file:///home/himanshu/codes/eduverse/lib/profile/models/bookmark_model.dart)

| Field | Type |
|---|---|
| `id` | `String` |
| `title` | `String` |
| `type` | `String` (course, article, video, batch) |
| `dateAdded` | `DateTime` |
| `metadata` | `Map<String, dynamic>` |
