# Eduverse — Screen Guide (Student · Teacher · Admin)

Detailed breakdown of every screen in the app, organized by user role. Each entry includes the screen's purpose, key UI elements, navigation context, data sources, and source file.

---

## Navigation Architecture

```
App Launch → main.dart → AuthWrapper
  │
  ├── 🔒 Not Authenticated
  │     └── Auth Screens (Login / Register / Phone / Forgot Password)
  │
  ├── 🎓 Student Role
  │     └── MainNavigationPage (Bottom Tabs)
  │           ├── Tab 0: Study
  │           ├── Tab 1: Feed
  │           ├── Tab 2: Store
  │           └── Tab 3: Profile
  │
  ├── 👨‍🏫 Teacher Role
  │     └── AdminApp → AdminRouter (limited side nav)
  │
  └── 🛡 Admin / Superadmin Role
        └── AdminApp → AdminRouter (full side nav)
```

---

## 🔒 Auth Screens (All Roles)

### LoginPage
| | |
|---|---|
| **File** | [`lib/auth/login_page.dart`](file:///home/himanshu/codes/eduverse/lib/auth/login_page.dart) |
| **Purpose** | Primary entry — email/password sign-in |
| **Key UI** | Email field, password field (with toggle visibility), "Login" button, "Forgot Password?" link, "Create Account" link, "Login with Phone" link |
| **Navigation** | → `RegisterPage`, → `ForgotPasswordPage`, → `PhoneLoginPage`, → `AuthWrapper` (on success) |
| **Data** | `AuthService.signInWithEmail()` |

### RegisterPage
| | |
|---|---|
| **File** | [`lib/auth/register_page.dart`](file:///home/himanshu/codes/eduverse/lib/auth/register_page.dart) |
| **Purpose** | New student account creation |
| **Key UI** | Full name, email, phone, password, confirm password fields, "Register" button, terms checkbox |
| **Navigation** | → `AuthWrapper` (on success), → `LoginPage` |
| **Data** | `AuthService.signUpWithEmail()` → `UserService.createUserProfile()` |

### PhoneLoginPage
| | |
|---|---|
| **File** | [`lib/auth/phone_login_page.dart`](file:///home/himanshu/codes/eduverse/lib/auth/phone_login_page.dart) |
| **Purpose** | Phone number OTP login |
| **Key UI** | Phone number input (+91 prefix), "Send OTP" button, opens `PhoneVerifyDialog` |
| **Navigation** | → `PhoneVerifyDialog` → `AuthWrapper` (on success) |
| **Data** | `AuthService.verifyPhoneNumber()` |

### PhoneVerifyDialog
| | |
|---|---|
| **File** | [`lib/auth/phone_verify_dialog.dart`](file:///home/himanshu/codes/eduverse/lib/auth/phone_verify_dialog.dart) |
| **Purpose** | OTP entry and verification dialog |
| **Key UI** | 6-digit OTP input, timer countdown, "Resend" button, "Verify" button |
| **Data** | `AuthService.verifyOTP()` |

### ForgotPasswordPage
| | |
|---|---|
| **File** | [`lib/auth/forgot_password_page.dart`](file:///home/himanshu/codes/eduverse/lib/auth/forgot_password_page.dart) |
| **Purpose** | Password reset via email link |
| **Key UI** | Email input, "Send Reset Link" button, success confirmation |
| **Data** | `FirebaseAuth.sendPasswordResetEmail()` |

### PrivacyPolicyPage
| | |
|---|---|
| **File** | [`lib/auth/privacy_policy_page.dart`](file:///home/himanshu/codes/eduverse/lib/auth/privacy_policy_page.dart) |
| **Purpose** | Display terms of service and privacy policy |
| **Key UI** | Scrollable rich text content, accept button |

---

## 🎓 Student Screens

### Study Tab

#### StudyPage (Tab Root)
| | |
|---|---|
| **File** | [`lib/study/study_page.dart`](file:///home/himanshu/codes/eduverse/lib/study/study_page.dart) |
| **Purpose** | Study tab root — hosts batch selector + dynamic content based on selection |
| **Key UI** | `BatchSelectorWidget` at top, `StickyTabPills` (Courses / Test Series / E-books), scrollable content below |
| **Sections** | If combo pack selected: Favourite Batches → Continue Learning → Live Classes → Browse by Exam. If individual batch: Continue Learning → Explore Batch button |
| **Data** | `StudyController` (ChangeNotifier), `StudyRepositoryImpl` |

#### StudyHomeScreen
| | |
|---|---|
| **File** | [`lib/study/presentation/screens/study_home_screen.dart`](file:///home/himanshu/codes/eduverse/lib/study/presentation/screens/study_home_screen.dart) |
| **Purpose** | Inner study home content container |
| **Key UI** | Hosts study sections rendered by `StudyController` state |

#### BatchDetailScreen ⭐ (87KB — largest student screen)
| | |
|---|---|
| **File** | [`lib/study/presentation/screens/batch_detail_screen.dart`](file:///home/himanshu/codes/eduverse/lib/study/presentation/screens/batch_detail_screen.dart) |
| **Purpose** | Full course content viewer — primary learning screen |
| **Key UI** | Course header (thumbnail, title, progress), subject tabs, lecture list, notes tab, DPP tab, quiz tab, planner tab, live classes tab, recorded batches, community link |
| **Navigation** | → `LecturePlayerScreen`, → `SecurePdfViewerScreen`, → `StudyQuizScreen`, → `StudentCommunityScreen` |
| **Data** | `StudyRepositoryImpl` — fetches lectures, notes, DPPs, quizzes, planner from `courses/{courseId}/*` |

#### CourseSectionPage (42KB)
| | |
|---|---|
| **File** | [`lib/study/screens/course_section_page.dart`](file:///home/himanshu/codes/eduverse/lib/study/screens/course_section_page.dart) |
| **Purpose** | Subject/chapter hierarchy navigation for a course |
| **Key UI** | Subject list with logos, expandable chapters, lecture/note/DPP tiles, folder tree navigation |
| **Navigation** | → `SubjectDetailScreen`, → `ChapterDetailScreen`, → `LecturePlayerScreen` |

#### SubjectDetailScreen (35KB)
| | |
|---|---|
| **File** | [`lib/study/screens/subject_detail_screen.dart`](file:///home/himanshu/codes/eduverse/lib/study/screens/subject_detail_screen.dart) |
| **Purpose** | All content within a specific subject |
| **Key UI** | Lecture list, notes list (with PDF download buttons), DPP list, chapter filter |
| **Navigation** | → `LecturePlayerScreen`, → `SecurePdfViewerScreen` |

#### ChapterDetailScreen (26KB)
| | |
|---|---|
| **File** | [`lib/study/screens/chapter_detail_screen.dart`](file:///home/himanshu/codes/eduverse/lib/study/screens/chapter_detail_screen.dart) |
| **Purpose** | All content within a specific chapter |
| **Key UI** | Lecture tiles, linked notes, DPPs with solution PDFs, quiz links |
| **Navigation** | → `LecturePlayerScreen`, → `SecurePdfViewerScreen` |

#### LecturePlayerScreen ⭐ (61KB)
| | |
|---|---|
| **File** | [`lib/study/presentation/screens/lecture_player_screen.dart`](file:///home/himanshu/codes/eduverse/lib/study/presentation/screens/lecture_player_screen.dart) |
| **Purpose** | Video lecture player with full study context |
| **Key UI** | `CrossPlatformYoutubePlayer` / native video player, `VideoSkipOverlay` (10s skip), progress bar, lecture title/description, linked notes panel, next/prev lecture buttons |
| **Behaviors** | Auto-saves progress to Hive every N seconds, records watch time to Firestore via `WatchStatsService`, resumes from saved position, marks complete at >95% |
| **Data** | `LectureProgressRepository` (Hive), `WatchStatsService`, `LiveViewerService` |

#### LecturePlayerPage (19KB — legacy)
| | |
|---|---|
| **File** | [`lib/study/screens/lecture_player_page.dart`](file:///home/himanshu/codes/eduverse/lib/study/screens/lecture_player_page.dart) |
| **Purpose** | Legacy lecture player (backward compatibility) |

#### SecurePdfViewerScreen (19KB)
| | |
|---|---|
| **File** | [`lib/study/presentation/screens/secure_pdf_viewer_screen.dart`](file:///home/himanshu/codes/eduverse/lib/study/presentation/screens/secure_pdf_viewer_screen.dart) |
| **Purpose** | In-app PDF viewer for ebooks, notes, DPPs |
| **Key UI** | `SfPdfViewer` (Syncfusion), page indicator, zoom controls, text search, dark mode toggle |
| **Security** | For ebooks: download/share disabled, text selection disabled, screenshot protection (`screen_protector`). For notes/DPPs: download/share enabled |
| **Data** | `PdfCacheService` for offline ebook caching |

#### StudyQuizScreen (26KB)
| | |
|---|---|
| **File** | [`lib/study/presentation/screens/study_quiz_screen.dart`](file:///home/himanshu/codes/eduverse/lib/study/presentation/screens/study_quiz_screen.dart) |
| **Purpose** | Quiz taking interface with timer |
| **Key UI** | Question card, answer options (MCQ/true-false/short answer), timer countdown, question navigator, "Submit" button |
| **Navigation** | → `StudyQuizResultScreen` (on submit) |
| **Data** | Quiz data from `courses/{courseId}/quizzes/{quizId}` |

#### StudyQuizResultScreen (21KB)
| | |
|---|---|
| **File** | [`lib/study/presentation/screens/study_quiz_result_screen.dart`](file:///home/himanshu/codes/eduverse/lib/study/presentation/screens/study_quiz_result_screen.dart) |
| **Purpose** | Quiz results with analytics |
| **Key UI** | Score card (percentage, correct/wrong/unattempted), question-by-question review with explanations, performance comparison |
| **Data** | `QuizStatsService.saveQuizAttempt()` |

#### StudyTestSeriesScreen (10KB)
| | |
|---|---|
| **File** | [`lib/study/presentation/screens/study_test_series_screen.dart`](file:///home/himanshu/codes/eduverse/lib/study/presentation/screens/study_test_series_screen.dart) |
| **Purpose** | Purchased test series catalog |
| **Key UI** | Test series cards with progress bars, thumbnail, title, test count |
| **Navigation** | → `TestSeriesDetailScreen` |

#### TestSeriesDetailScreen (20KB)
| | |
|---|---|
| **File** | [`lib/study/presentation/screens/test_series_detail_screen.dart`](file:///home/himanshu/codes/eduverse/lib/study/presentation/screens/test_series_detail_screen.dart) |
| **Purpose** | Individual test series with list of tests |
| **Key UI** | Series header (progress %), test list with status (locked/available/completed), start test button |
| **Navigation** | → `TestDetailPage` → Quiz taking flow |
| **Data** | `test_series/{tsId}/tests` |

#### RecordedBatchDetailScreen (12KB)
| | |
|---|---|
| **File** | [`lib/study/presentation/screens/recorded_batch_detail_screen.dart`](file:///home/himanshu/codes/eduverse/lib/study/presentation/screens/recorded_batch_detail_screen.dart) |
| **Purpose** | Archived batch content viewer |
| **Key UI** | Lecture list, notes, DPPs from recorded batch subcollections |

#### MyCoursesPage (11KB)
| | |
|---|---|
| **File** | [`lib/study/screens/my_courses_page.dart`](file:///home/himanshu/codes/eduverse/lib/study/screens/my_courses_page.dart) |
| **Purpose** | All enrolled courses list |
| **Key UI** | Course cards with progress, enrollment date |

#### MapWorkPage (5KB)
| | |
|---|---|
| **File** | [`lib/study/screens/map_work_page.dart`](file:///home/himanshu/codes/eduverse/lib/study/screens/map_work_page.dart) |
| **Purpose** | Geography map work topics (for UPSC/geography exams) |
| **Key UI** | Topic tree nodes, expandable sections |

#### WorkbooksPage (7KB)
| | |
|---|---|
| **File** | [`lib/study/screens/workbooks_page.dart`](file:///home/himanshu/codes/eduverse/lib/study/screens/workbooks_page.dart) |
| **Purpose** | Student practice notebooks |
| **Key UI** | Workbook list, create new, tasks with completion |

#### PracticeQuestionPage (10KB)
| | |
|---|---|
| **File** | [`lib/study/screens/practice_question_page.dart`](file:///home/himanshu/codes/eduverse/lib/study/screens/practice_question_page.dart) |
| **Purpose** | Daily practice questions |
| **Key UI** | Question display, answer input, solution reveal |

#### TestDetailPage (6KB)
| | |
|---|---|
| **File** | [`lib/study/screens/test_detail_page.dart`](file:///home/himanshu/codes/eduverse/lib/study/screens/test_detail_page.dart) |
| **Purpose** | Individual test info before starting |
| **Key UI** | Test title, duration, total marks, question count, "Start Test" button |

#### StudentAccessibleCommunitiesScreen (14KB)
| | |
|---|---|
| **File** | [`lib/study/screens/student_accessible_communities_screen.dart`](file:///home/himanshu/codes/eduverse/lib/study/screens/student_accessible_communities_screen.dart) |
| **Purpose** | Browse discussion communities for enrolled courses |
| **Key UI** | Community cards (title, teacher name, post count, member count) |
| **Navigation** | → `StudentCommunityScreen` |

#### StudentCommunityScreen (16KB)
| | |
|---|---|
| **File** | [`lib/study/screens/student_community_screen.dart`](file:///home/himanshu/codes/eduverse/lib/study/screens/student_community_screen.dart) |
| **Purpose** | Community discussion board |
| **Key UI** | Post list (pinned first), "New Post" FAB, search, filter (all/unanswered/my posts) |
| **Navigation** | → `StudentPostDetailScreen` |

#### StudentPostDetailScreen (16KB)
| | |
|---|---|
| **File** | [`lib/study/screens/student_post_detail_screen.dart`](file:///home/himanshu/codes/eduverse/lib/study/screens/student_post_detail_screen.dart) |
| **Purpose** | Single post with replies |
| **Key UI** | Post body (rich text), reply list, "Write Reply" input, teacher verified answer badge (✓), upvote/downvote |

---

### Feed Tab

#### FeedPage (Tab Root)
| | |
|---|---|
| **File** | [`lib/feed/feed_page.dart`](file:///home/himanshu/codes/eduverse/lib/feed/feed_page.dart) |
| **Purpose** | Feed tab root — content discovery |
| **Key UI** | `TrendingSection` at top, feed cards list (articles, current affairs, quizzes, videos, jobs, answer writing), category filter chips |
| **Data** | `FeedRepository` → `feed` collection |

#### ArticleDetailPage (21KB)
| | |
|---|---|
| **File** | [`lib/feed/screens/article_detail_page.dart`](file:///home/himanshu/codes/eduverse/lib/feed/screens/article_detail_page.dart) |
| **Purpose** | Full article reader |
| **Key UI** | Title, author, publish date, estimated read time, rich content body (`RichContentViewer` for HTML or `flutter_markdown` for legacy), tags, like/comment buttons, share button, comment section |

#### CurrentAffairsDetailPage (24KB)
| | |
|---|---|
| **File** | [`lib/feed/screens/current_affairs_detail_page.dart`](file:///home/himanshu/codes/eduverse/lib/feed/screens/current_affairs_detail_page.dart) |
| **Purpose** | Current affairs analysis |
| **Key UI** | Event date, "What Happened" section, "Why It Matters" section, "Exam Relevance" section, context, tags, comments |

#### AnswerWritingPage (20KB)
| | |
|---|---|
| **File** | [`lib/feed/screens/answer_writing_page.dart`](file:///home/himanshu/codes/eduverse/lib/feed/screens/answer_writing_page.dart) |
| **Purpose** | Answer writing practice for UPSC Mains-style questions |
| **Key UI** | Question display, word limit indicator, timer, text editor for student answer, "Submit" button, model answer reveal, key points checklist |

#### VideoDetailPage (29KB)
| | |
|---|---|
| **File** | [`lib/feed/screens/video_detail_page.dart`](file:///home/himanshu/codes/eduverse/lib/feed/screens/video_detail_page.dart) |
| **Purpose** | Video content player |
| **Key UI** | YouTube player / native video, title, description, key points list, like/comment, related content |

#### QuizPage (25KB)
| | |
|---|---|
| **File** | [`lib/feed/screens/quiz_page.dart`](file:///home/himanshu/codes/eduverse/lib/feed/screens/quiz_page.dart) |
| **Purpose** | Feed quiz (lighter than study quiz) |
| **Key UI** | Question cards, MCQ options, timer, progress indicator, submit |
| **Navigation** | → `QuizResultPage` |

#### QuizResultPage (23KB)
| | |
|---|---|
| **File** | [`lib/feed/screens/quiz_result_page.dart`](file:///home/himanshu/codes/eduverse/lib/feed/screens/quiz_result_page.dart) |
| **Purpose** | Feed quiz results |
| **Key UI** | Score percentage, correct/wrong/unattempted breakdown, question review with explanations |

#### JobDetailPage (19KB)
| | |
|---|---|
| **File** | [`lib/feed/screens/job_detail_page.dart`](file:///home/himanshu/codes/eduverse/lib/feed/screens/job_detail_page.dart) |
| **Purpose** | Government job alert detail |
| **Key UI** | Organization, location, salary range, vacancies, eligibility, selection process, application dates, "Apply" button (external URL), how to apply instructions |

---

### Store Tab

#### StorePage (Tab Root)
| | |
|---|---|
| **File** | [`lib/store/store_page.dart`](file:///home/himanshu/codes/eduverse/lib/store/store_page.dart) |
| **Purpose** | Marketplace with 3 tabs: Courses, Test Series, E-books |
| **Key UI** | Tab bar, `BannerSlider` (poster carousel), combo pack horizontal slider in Courses tab, course grid, "See All" buttons |
| **Navigation** | → `CourseDetailPage`, → `ComboPackDetailPage`, → `EbookDetailPage`, → `SeeAllCoursesPage`, → `SeeAllComboPacksPage` |

#### CourseDetailPage (15KB)
| | |
|---|---|
| **File** | [`lib/store/screens/course_detail_page.dart`](file:///home/himanshu/codes/eduverse/lib/store/screens/course_detail_page.dart) |
| **Purpose** | Course info with enrollment/purchase CTA |
| **Key UI** | Hero thumbnail, title, subtitle, teacher names, price (MRP strikethrough + final price), seat count, duration, description, "Add to Cart" / "Buy Now" / "Already Enrolled" button |

#### ComboPackDetailPage (21KB)
| | |
|---|---|
| **File** | [`lib/store/screens/combo_pack_detail_page.dart`](file:///home/himanshu/codes/eduverse/lib/store/screens/combo_pack_detail_page.dart) |
| **Purpose** | Combo pack detail showing bundled items |
| **Key UI** | Pack thumbnail, title, price, included courses list, included test series, included ebooks, "Add to Cart" button |

#### EbookDetailPage (9KB)
| | |
|---|---|
| **File** | [`lib/store/screens/ebook_detail_page.dart`](file:///home/himanshu/codes/eduverse/lib/store/screens/ebook_detail_page.dart) |
| **Purpose** | E-book info with purchase CTA |
| **Key UI** | Cover image, title, subtitle, description, price, "Buy" / "Read Now" button |

#### PurchaseCartPage (20KB)
| | |
|---|---|
| **File** | [`lib/store/screens/purchase_cart_page.dart`](file:///home/himanshu/codes/eduverse/lib/store/screens/purchase_cart_page.dart) |
| **Purpose** | Shopping cart with multi-item support |
| **Key UI** | `CartItemTile` list (swipe to delete), promo code input field, price summary (subtotal, discount, total), "Proceed to Checkout" button |

#### CheckoutPage (21KB)
| | |
|---|---|
| **File** | [`lib/store/screens/checkout_page.dart`](file:///home/himanshu/codes/eduverse/lib/store/screens/checkout_page.dart) |
| **Purpose** | Payment method selection and final confirmation |
| **Key UI** | Order summary, payment method tiles, promo code application, total amount, "Pay Now" button → Razorpay checkout |
| **Data** | `RazorpayService.startPayment()`, `PurchaseService.createPurchase()` |

#### PaymentResultPage (7KB)
| | |
|---|---|
| **File** | [`lib/store/screens/payment_result_page.dart`](file:///home/himanshu/codes/eduverse/lib/store/screens/payment_result_page.dart) |
| **Purpose** | Payment success/failure confirmation |
| **Key UI** | Success animation or error message, transaction ID, "Go to My Courses" / "Retry" button |

#### PurchaseHistoryPage (8KB)
| | |
|---|---|
| **File** | [`lib/store/screens/purchase_history_page.dart`](file:///home/himanshu/codes/eduverse/lib/store/screens/purchase_history_page.dart) |
| **Purpose** | Past purchase records |
| **Key UI** | Transaction list with date, amount, status, items purchased |

---

### Profile Tab

#### ProfilePage (Tab Root)
| | |
|---|---|
| **File** | [`lib/profile/profile_page.dart`](file:///home/himanshu/codes/eduverse/lib/profile/profile_page.dart) |
| **Purpose** | Profile tab root |
| **Key UI** | `ProfileHeader` (avatar, name, headline), `StatsSection` (quiz stats, watch time, "View Dashboard" button), `MenuGrid` (grid of action buttons) |

#### EditProfilePage (14KB)
| | |
|---|---|
| **File** | [`lib/profile/edit_profile_page.dart`](file:///home/himanshu/codes/eduverse/lib/profile/edit_profile_page.dart) |
| **Purpose** | Edit user profile |
| **Key UI** | Avatar picker (camera/gallery/emoji/initials), full name, headline, bio, email (read-only), phone (with link/update), "Save" button |

#### PerformanceDashboardPage ⭐ (49KB)
| | |
|---|---|
| **File** | [`lib/profile/screens/performance_dashboard_page.dart`](file:///home/himanshu/codes/eduverse/lib/profile/screens/performance_dashboard_page.dart) |
| **Purpose** | Analytics dashboard with charts |
| **Key UI** | Time period chips (This Week / This Month / This Year), summary cards (Overall Score with ↑/↓ trend, Quizzes Taken, Study Time), subject filter dropdown, `LineChart` (score + study time trends), `PieChart` accuracy ring (correct/wrong/unattempted) |
| **Data** | `PerformanceDashboardService`, `QuizStatsService`, `WatchStatsService` |

#### BookmarksPage (10KB)
| | |
|---|---|
| **File** | [`lib/profile/screens/bookmarks_page.dart`](file:///home/himanshu/codes/eduverse/lib/profile/screens/bookmarks_page.dart) |
| **Purpose** | Saved bookmarks (courses, articles, videos, batches) |
| **Key UI** | Bookmark list grouped by type, swipe to remove, tap to navigate |

#### NotificationsPage (15KB)
| | |
|---|---|
| **File** | [`lib/profile/screens/notifications_page.dart`](file:///home/himanshu/codes/eduverse/lib/profile/screens/notifications_page.dart) |
| **Purpose** | In-app notification inbox |
| **Key UI** | Notification cards (image, title, body, timestamp), read/unread indicator, "Mark All Read" button, tap to navigate to target |

#### TransactionsPage (13KB)
| | |
|---|---|
| **File** | [`lib/profile/screens/transactions_page.dart`](file:///home/himanshu/codes/eduverse/lib/profile/screens/transactions_page.dart) |
| **Purpose** | Payment transaction history |
| **Key UI** | Transaction list (date, amount, status badge, payment method), transaction detail expansion |

#### FreeLiveClassesPage (12KB)
| | |
|---|---|
| **File** | [`lib/profile/screens/free_live_classes_page.dart`](file:///home/himanshu/codes/eduverse/lib/profile/screens/free_live_classes_page.dart) |
| **Purpose** | Public free live classes catalog |
| **Key UI** | Live class cards (title, teacher, time, status), "JOIN" button for live classes, YouTube player |
| **Data** | `free_live_classes` collection (public read) |

#### MyDownloadsPage (11KB)
| | |
|---|---|
| **File** | [`lib/profile/screens/my_downloads_page.dart`](file:///home/himanshu/codes/eduverse/lib/profile/screens/my_downloads_page.dart) |
| **Purpose** | Downloaded files manager |
| **Key UI** | File list (name, size, date), tap to open with system app, swipe to delete |
| **Data** | `DownloadService`, SharedPreferences `my_downloads_list` |

#### AboutPage (15KB)
| | |
|---|---|
| **File** | [`lib/profile/screens/about_page.dart`](file:///home/himanshu/codes/eduverse/lib/profile/screens/about_page.dart) |
| **Purpose** | About the platform, team info |
| **Key UI** | Platform description, team members, contact info, social links |

### Settings

#### DeleteAccountPage (4KB)
| | |
|---|---|
| **File** | [`lib/settings/delete_account_page.dart`](file:///home/himanshu/codes/eduverse/lib/settings/delete_account_page.dart) |
| **Purpose** | Permanent account deletion |
| **Key UI** | Warning message, password re-authentication, "Delete Account" confirmation button |

---

## 👨‍🏫 Teacher Screens

Teachers access the **AdminApp** with a limited sidebar. They share many admin screens but with restricted data access (only assigned courses/communities).

| Screen | File | Teacher-Specific Behavior |
|---|---|---|
| `AdminLoginScreen` | `admin_login_screen.dart` | Same login flow, routed by `isTeacher` claim |
| `DashboardScreen` | `dashboard_screen.dart` | Limited dashboard (may show only assigned course stats) |
| `LiveClassesScreen` | `live_classes_screen.dart` | View/manage live classes for assigned courses |
| `LiveClassEditorScreen` | `live_class_editor_screen.dart` | Create/edit live classes for assigned courses |
| `CourseScheduleRulesScreen` | `course_schedule_rules_screen.dart` | Create/manage recurring schedule rules |
| `CourseScheduleDashboard` | `course_schedule_dashboard.dart` | View generated class timeline, reschedule/cancel |
| `CommunitiesListScreen` | `communities_list_screen.dart` | View/manage owned communities |
| `CommunityPostsScreen` | `community_posts_screen.dart` | Moderate posts, pin, mark as answered |
| `CommunityPostDetailScreen` | `community_post_detail_screen.dart` | Reply to posts with verified teacher answer badge |
| `LectureEditorScreen` | `lecture_editor_screen.dart` | View lecture details (write access gated by rules) |

**Firestore Rule**: `isTeacher()` grants read on `batches`, `lessons`, `live_classes` collection groups, and write on `live_classes` and `scheduler_rules`.

---

## 🛡 Admin Screens

Admins access the **AdminApp** via [`AdminRouter`](file:///home/himanshu/codes/eduverse/lib/admin/admin_router.dart) with [`AdminScaffold`](file:///home/himanshu/codes/eduverse/lib/admin/widgets/admin_scaffold.dart) (persistent side navigation).

### Dashboard & Analytics

#### DashboardScreen
| | |
|---|---|
| **File** | [`lib/admin/screens/dashboard_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/dashboard_screen.dart) |
| **Purpose** | Admin overview dashboard |
| **Key UI** | Revenue card, active users count, total courses, total enrollments, recent activity feed |
| **Data** | `AdminStatsService` → `admin_stats/dashboard` |

#### UserDetailScreen ⭐ (45KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/user_detail_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/user_detail_screen.dart) |
| **Purpose** | Detailed user management |
| **Key UI** | User info header, role selector dropdown, enrolled courses list, purchased test series, cart items, transaction history, `StudentPerformanceTab` (quiz analytics charts), disable/enable toggle, manual enrollment button |
| **Data** | `users/{uid}` + all subcollections, `StudentPerformanceService` |

### Course Management

#### CoursesListScreen (13KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/courses_list_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/courses_list_screen.dart) |
| **Purpose** | All courses list with search |
| **Key UI** | Course cards (thumbnail, title, price, status badge), search bar, "+" FAB, filter (active/draft/all) |
| **Navigation** | → `CourseEditorScreen`, → `CourseDetailScreen` |

#### CourseEditorScreen ⭐ (62KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/course_editor_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/course_editor_screen.dart) |
| **Purpose** | Create/edit course with all metadata |
| **Key UI** | Title, subtitle, description, emoji picker, gradient color picker, `ThumbnailUploadWidget`, pricing (MRP, final price), dates, seats, duration, language, level, visibility toggle, teacher assignment, subject logos, linked test series/ebooks, save/delete buttons |

#### CourseDetailScreen (18KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/course_detail_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/course_detail_screen.dart) |
| **Purpose** | Course overview with navigation to content management |
| **Key UI** | Course info summary, action buttons: Manage Lectures, Notes, DPPs, Quizzes, Planner, Live Classes, Schedule, Recorded Batches |

#### LectureEditorScreen ⭐ (112KB — largest file in project)
| | |
|---|---|
| **File** | [`lib/admin/screens/lecture_editor_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/lecture_editor_screen.dart) |
| **Purpose** | Full lecture management — create folders, lectures, link across courses |
| **Key UI** | Folder tree navigation, create folder/lecture buttons, lecture form (title, description, video URL, subject, chapter, order, type, thumbnail), `PdfUploadWidget` for notes, `MediaUploader` for video, cross-course linking dialogs, folder copy/paste/delete, bulk operations |

#### BatchNotesScreen (23KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/batch_notes_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/batch_notes_screen.dart) |
| **Purpose** | Manage course notes (PDF study materials) |
| **Key UI** | Notes list (title, subject, chapter), "+" FAB, upload PDF, link to lecture, edit/delete |

#### BatchDppScreen (25KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/batch_dpp_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/batch_dpp_screen.dart) |
| **Purpose** | Manage Daily Practice Papers |
| **Key UI** | DPP list, create DPP (title, subject, chapter, DPP PDF upload, solution PDF upload), link to lecture |

#### BatchQuizEditorScreen (44KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/batch_quiz_editor_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/batch_quiz_editor_screen.dart) |
| **Purpose** | Create/edit quizzes with questions |
| **Key UI** | Quiz metadata (title, time limit, marks), question builder (MCQ/true-false/short answer), `RichDocumentEditor` for question text, answer options, explanation, import from quiz library |

#### BatchPlannerScreen (5KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/batch_planner_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/batch_planner_screen.dart) |
| **Purpose** | Study planner management |
| **Key UI** | Planner item list, create/edit planner entries |

### Live Classes & Scheduling

#### LiveClassesScreen (21KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/live_classes_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/live_classes_screen.dart) |
| **Purpose** | Live class catalog management |
| **Key UI** | Class list with status badges (upcoming/live/completed/cancelled), search, filter by course |

#### LiveClassEditorScreen (32KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/live_class_editor_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/live_class_editor_screen.dart) |
| **Purpose** | Create/edit live class |
| **Key UI** | Title, description, instructor, date/time pickers, duration, YouTube URL, subject, chapter, status selector, thumbnail, link to batch dialog |

#### CourseScheduleDashboard ⭐ (50KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/course_schedule_dashboard.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/course_schedule_dashboard.dart) |
| **Purpose** | Schedule management — view generated classes, detect conflicts |
| **Key UI** | Calendar/timeline view, generated class list, conflict highlights (overlapping times), reschedule individual class, cancel class, generate new classes from rules button |

#### CourseScheduleRulesScreen (32KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/course_schedule_rules_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/course_schedule_rules_screen.dart) |
| **Purpose** | Recurring class rule management |
| **Key UI** | Rule list, create rule form (weekday checkboxes, time picker, date range, instructor, subject, title, duration), edit/delete rules, "Generate Classes" button with date range picker |

### Content Management

#### CombinationPacksScreen (27KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/combination_packs_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/combination_packs_screen.dart) |
| **Purpose** | Combo pack CRUD |
| **Key UI** | Pack list, editor form (title, description, thumbnail, pricing, course multi-select, test series multi-select, ebook multi-select, active toggle) |

#### TestSeriesListScreen (11KB) → TestSeriesEditorScreen (36KB) → TestSeriesTestsListScreen (6KB) → TestSeriesTestEditorScreen (51KB)
| | |
|---|---|
| **Files** | `lib/admin/screens/test_series_*.dart` |
| **Purpose** | Full test series management chain |
| **Flow** | List all series → Edit series metadata → List tests in series → Edit individual test (questions, options, marking, timer) |

#### EbooksScreen (17KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/ebooks_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/ebooks_screen.dart) |
| **Purpose** | E-book CRUD |
| **Key UI** | Ebook list, editor form (title, subtitle, description, thumbnail upload, PDF upload, pricing, active toggle) |

#### FeedEditorScreen ⭐ (69KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/feed_editor_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/feed_editor_screen.dart) |
| **Purpose** | Create/edit all feed content types |
| **Key UI** | Content type selector, `RichDocumentEditor` for body, type-specific fields (article: tags/read time, current affairs: event date/sections, quiz: question builder, job: org/salary/dates, answer writing: question/model answer, video: URL/duration) |

#### ExamManagementScreen (14KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/exam_management_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/exam_management_screen.dart) |
| **Purpose** | Exam category management |
| **Key UI** | Exam list with drag-and-drop reorder, create exam (name, icon upload), assign courses to exams via multi-select, delete |

#### RecordedBatchesListScreen (16KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/recorded_batches_list_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/recorded_batches_list_screen.dart) |
| **Purpose** | Manage recorded/archived batches |
| **Key UI** | Batch list, create/edit (title, description, thumbnail, pricing, active toggle) |

### User & Payment Management

#### UsersScreen (18KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/users_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/users_screen.dart) |
| **Purpose** | User directory with search and filtering |
| **Key UI** | User data table (name, email, phone, role, status), search bar, role filter dropdown, tap to open `UserDetailScreen` |

#### EnrollmentsScreen (7KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/enrollments_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/enrollments_screen.dart) |
| **Purpose** | Manual enrollment management |
| **Key UI** | Search user, select course, "Enroll" button, enrollment history |

#### PurchasesScreen ⭐ (45KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/purchases_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/purchases_screen.dart) |
| **Purpose** | Purchase tracking, filtering, refund processing |
| **Key UI** | Purchase data table (user, items, amount, status, date), status filter, date range filter, search, refund button (triggers `refundPurchase` Cloud Function), purchase detail expansion |

#### PromoCodesScreen (34KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/promo_codes_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/promo_codes_screen.dart) |
| **Purpose** | Discount coupon management |
| **Key UI** | Code list (code, type, value, usage/limit, status), create form (code, discount type percentage/fixed, value, min order, max usage, validity date, active toggle) |

### Notifications & Engagement

#### NotificationListScreen (15KB) → NotificationEditorScreen (31KB)
| | |
|---|---|
| **Files** | `lib/admin/screens/notification_*.dart` |
| **Purpose** | Push notification management |
| **Editor UI** | Title, body, image upload, target type (global/course-specific), course selector, notification type, send now / schedule |

#### PosterListScreen (9KB) → PosterEditorScreen (44KB)
| | |
|---|---|
| **Files** | `lib/admin/screens/poster_*.dart` |
| **Purpose** | Banner/popup management |
| **Editor UI** | Image upload, title, subtitle, action buttons (external URL / in-app route), show as popup toggle, popup frequency (once/daily/always), show in store/feed toggles, active toggle, display order |

### Communities

#### CommunitiesListScreen (12KB) → CommunityPostsScreen (17KB) → CommunityPostDetailScreen (18KB)
| | |
|---|---|
| **Files** | `lib/admin/screens/communit*.dart` |
| **Purpose** | Community management and moderation |
| **Key UI** | Community list with member counts, post moderation (pin/unpin, delete), reply management, mark answer as verified |

### Settings & Configuration

#### SettingsScreen (5KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/settings_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/settings_screen.dart) |
| **Purpose** | Admin settings (app config, version management) |

#### PaymentSettingsScreen (9KB)
| | |
|---|---|
| **File** | [`lib/admin/screens/payment_settings_screen.dart`](file:///home/himanshu/codes/eduverse/lib/admin/screens/payment_settings_screen.dart) |
| **Purpose** | Razorpay configuration |
| **Key UI** | Key ID, Key Secret inputs, test/live mode toggle, save button |
| **Data** | `config/razorpay` Firestore doc |

---

## 🌐 Web Screens

#### WebHomepage (41KB)
| | |
|---|---|
| **File** | [`lib/web/web_homepage.dart`](file:///home/himanshu/codes/eduverse/lib/web/web_homepage.dart) |
| **Purpose** | Web app entry portal |

#### LandingPage (2KB + 12 section widgets)
| | |
|---|---|
| **File** | [`lib/web/landing/landing_page.dart`](file:///home/himanshu/codes/eduverse/lib/web/landing/landing_page.dart) |
| **Purpose** | Marketing landing page |
| **Sections** | `Navbar` → `HeroSection` → `ExamCategoriesSection` → `TrendingCoursesSection` → `FeaturesSection` → `ContentSection` → `StatsSection` → `TestimonialsSection` → `TeamSection` → `FaqSection` → `CtaSection` → `FooterSection` |

---

## 📊 Screen Count Summary

| Role | Screen Count | Notes |
|---|---|---|
| **Auth (shared)** | 6 | Login, Register, Phone, OTP, Forgot Password, Privacy |
| **Student** | 35 | Study (21), Feed (8), Store (10), Profile (8), Settings (1) — some overlap |
| **Teacher** | ~10 | Subset of admin screens (live classes, schedule, communities) |
| **Admin** | 41 | Full content, user, payment, notification management |
| **Web** | 2 | Landing page + web homepage (with 12 section components) |
| **Deep Link** | 6 | Course, Batch, Feed, ComboPack, TestSeries, Ebook wrappers |
| **Total unique** | **~90** | Across all roles |
