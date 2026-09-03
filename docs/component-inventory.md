# Eduverse — Component Inventory

Complete catalog of all screens, widgets, services, and navigation structure.

---

## 1. Navigation Structure

### App Entry Flow
```
main.dart → AuthWrapper
  ├── Not authenticated → LoginPage
  ├── Admin/Teacher role → AdminApp → AdminRouter (side nav)
  └── Student role → MainNavigationPage (bottom nav)
```

### Student Bottom Navigation
| Tab | Index | Screen | Module |
|---|---|---|---|
| Study | 0 | `StudyPage` → `StudyHomeScreen` | `study/` |
| Feed | 1 | `FeedPage` | `feed/` |
| Store | 2 | `StorePage` | `store/` |
| Profile | 3 | `ProfilePage` | `profile/` |

**Shell**: [`MainNavigationPage`](file:///home/himanshu/codes/eduverse/lib/navigation/main_navigation_page.dart)

### Admin Side Navigation
Managed by [`AdminRouter`](file:///home/himanshu/codes/eduverse/lib/admin/admin_router.dart) with [`AdminScaffold`](file:///home/himanshu/codes/eduverse/lib/admin/widgets/admin_scaffold.dart):

| Section | Screen |
|---|---|
| Dashboard | `DashboardScreen` |
| Courses | `CoursesListScreen` |
| Combo Packs | `CombinationPacksScreen` |
| Test Series | `TestSeriesListScreen` |
| E-books | `EbooksScreen` |
| Live Classes | `LiveClassesScreen` |
| Recorded Batches | `RecordedBatchesListScreen` |
| Exams | `ExamManagementScreen` |
| Feed | `FeedListScreen` |
| Communities | `CommunitiesListScreen` |
| Users | `UsersScreen` |
| Enrollments | `EnrollmentsScreen` |
| Purchases | `PurchasesScreen` |
| Promo Codes | `PromoCodesScreen` |
| Notifications | `NotificationListScreen` |
| Posters | `PosterListScreen` |
| Settings | `SettingsScreen` |
| Payment Settings | `PaymentSettingsScreen` |

---

## 2. Screen Inventory

### Auth Screens (7 files — `lib/auth/`)

| Screen | File | Purpose |
|---|---|---|
| `AuthWrapper` | `auth_wrapper.dart` | Auth state dispatcher & role-based routing |
| `LoginPage` | `login_page.dart` | Email/password login form |
| `PhoneLoginPage` | `phone_login_page.dart` | Phone OTP authentication |
| `PhoneVerifyDialog` | `phone_verify_dialog.dart` | OTP entry dialog |
| `RegisterPage` | `register_page.dart` | New user registration |
| `ForgotPasswordPage` | `forgot_password_page.dart` | Password reset |
| `PrivacyPolicyPage` | `privacy_policy_page.dart` | Terms & privacy display |

### Store Screens (9 — `lib/store/screens/`)

| Screen | File | Size | Purpose |
|---|---|---|---|
| `StorePage` | `store_page.dart` | 10KB | 3-tab store (Courses, Test Series, E-books) |
| `CourseDetailPage` | `course_detail_page.dart` | 15KB | Course info + enrollment |
| `ComboPackDetailPage` | `combo_pack_detail_page.dart` | 21KB | Bundle detail + purchase |
| `EbookDetailPage` | `ebook_detail_page.dart` | 9KB | E-book info + purchase |
| `PurchaseCartPage` | `purchase_cart_page.dart` | 20KB | Cart management |
| `CheckoutPage` | `checkout_page.dart` | 21KB | Payment method + promo code |
| `PaymentResultPage` | `payment_result_page.dart` | 7KB | Success/failure confirmation |
| `PurchaseHistoryPage` | `purchase_history_page.dart` | 8KB | Past purchases list |
| `SeeAllComboPacksPage` | `see_all_combo_packs_page.dart` | 9KB | Full combo pack listing |
| `SeeAllCoursesPage` | `see_all_courses_page.dart` | 3KB | Full course listing |

### Study Screens (21 — `lib/study/presentation/screens/` + `lib/study/screens/`)

| Screen | File | Size | Purpose |
|---|---|---|---|
| `StudyPage` | `study_page.dart` | 16KB | Study tab root with batch selector |
| `StudyHomeScreen` | `study_home_screen.dart` | 3KB | Study home content |
| `BatchDetailScreen` | `batch_detail_screen.dart` | **87KB** | Full course content viewer |
| `CourseSectionPage` | `course_section_page.dart` | **42KB** | Subject/chapter hierarchy |
| `SubjectDetailScreen` | `subject_detail_screen.dart` | 35KB | Subject lectures & notes |
| `ChapterDetailScreen` | `chapter_detail_screen.dart` | 26KB | Chapter content |
| `LecturePlayerScreen` | `lecture_player_screen.dart` | **61KB** | Video player + notes |
| `LecturePlayerPage` | `lecture_player_page.dart` | 19KB | Legacy lecture player |
| `SecurePdfViewerScreen` | `secure_pdf_viewer_screen.dart` | 19KB | Protected PDF viewer |
| `StudyQuizScreen` | `study_quiz_screen.dart` | 26KB | Quiz taking interface |
| `StudyQuizResultScreen` | `study_quiz_result_screen.dart` | 21KB | Quiz results + analytics |
| `StudyTestSeriesScreen` | `study_test_series_screen.dart` | 10KB | Test series catalog |
| `TestSeriesDetailScreen` | `test_series_detail_screen.dart` | 20KB | Test series detail + tests |
| `RecordedBatchDetailScreen` | `recorded_batch_detail_screen.dart` | 12KB | Recorded batch content |
| `MyCoursesPage` | `my_courses_page.dart` | 11KB | Enrolled courses list |
| `MapWorkPage` | `map_work_page.dart` | 5KB | Geography topics |
| `WorkbooksPage` | `workbooks_page.dart` | 7KB | Student notebooks |
| `PracticeQuestionPage` | `practice_question_page.dart` | 10KB | Practice problems |
| `TestDetailPage` | `test_detail_page.dart` | 6KB | Individual test detail |
| `StudentAccessibleCommunitiesScreen` | `student_accessible_communities_screen.dart` | 14KB | Community browser |
| `StudentCommunityScreen` | `student_community_screen.dart` | 16KB | Community discussion |
| `StudentPostDetailScreen` | `student_post_detail_screen.dart` | 16KB | Post with replies |

### Feed Screens (8 — `lib/feed/screens/`)

| Screen | File | Size | Purpose |
|---|---|---|---|
| `FeedPage` | `feed_page.dart` | 2KB | Feed tab root |
| `ArticleDetailPage` | `article_detail_page.dart` | 21KB | Article reader |
| `CurrentAffairsDetailPage` | `current_affairs_detail_page.dart` | 24KB | Current affairs detail |
| `AnswerWritingPage` | `answer_writing_page.dart` | 20KB | Answer writing practice |
| `VideoDetailPage` | `video_detail_page.dart` | 29KB | Video content player |
| `QuizPage` | `quiz_page.dart` | 25KB | Feed quiz interface |
| `QuizResultPage` | `quiz_result_page.dart` | 23KB | Feed quiz results |
| `JobDetailPage` | `job_detail_page.dart` | 19KB | Job alert detail |
| `GenericFeedDetailRouter` | `generic_feed_detail_router.dart` | 2KB | Type-based routing |

### Profile Screens (8 — `lib/profile/screens/`)

| Screen | File | Size | Purpose |
|---|---|---|---|
| `ProfilePage` | `profile_page.dart` | 1KB | Profile tab root |
| `EditProfilePage` | `edit_profile_page.dart` | 14KB | Profile editor |
| `PerformanceDashboardPage` | `performance_dashboard_page.dart` | **49KB** | Analytics dashboard |
| `BookmarksPage` | `bookmarks_page.dart` | 10KB | Saved bookmarks |
| `NotificationsPage` | `notifications_page.dart` | 15KB | Notification inbox |
| `TransactionsPage` | `transactions_page.dart` | 13KB | Payment history |
| `FreeLiveClassesPage` | `free_live_classes_page.dart` | 12KB | Free live class catalog |
| `MyDownloadsPage` | `my_downloads_page.dart` | 11KB | Downloaded files |
| `AboutPage` | `about_page.dart` | 15KB | About & team |

### Admin Screens (41 — `lib/admin/screens/`)

| Screen | File | Size | Purpose |
|---|---|---|---|
| `AdminLoginScreen` | `admin_login_screen.dart` | 4KB | Admin login |
| `DashboardScreen` | `dashboard_screen.dart` | 3KB | Admin dashboard |
| `CourseEditorScreen` | `course_editor_screen.dart` | **62KB** | Course CRUD |
| `LectureEditorScreen` | `lecture_editor_screen.dart` | **112KB** | Lecture editor (largest file) |
| `FeedEditorScreen` | `feed_editor_screen.dart` | **69KB** | Feed content editor |
| `CourseScheduleDashboard` | `course_schedule_dashboard.dart` | **50KB** | Schedule management |
| `TestSeriesTestEditorScreen` | `test_series_test_editor_screen.dart` | **51KB** | Test question editor |
| `UserDetailScreen` | `user_detail_screen.dart` | **45KB** | User management |
| `PurchasesScreen` | `purchases_screen.dart` | **45KB** | Purchase management |
| `PosterEditorScreen` | `poster_editor_screen.dart` | **44KB** | Banner editor |
| `BatchQuizEditorScreen` | `batch_quiz_editor_screen.dart` | **44KB** | Quiz editor |
| `QuizEditorScreen` | `quiz_editor_screen.dart` | 44KB | Quiz pool editor |
| `TestSeriesEditorScreen` | `test_series_editor_screen.dart` | 36KB | Test series CRUD |
| `PromoCodesScreen` | `promo_codes_screen.dart` | 34KB | Promo code management |
| `CourseScheduleRulesScreen` | `course_schedule_rules_screen.dart` | 32KB | Recurring rules |
| `LiveClassEditorScreen` | `live_class_editor_screen.dart` | 32KB | Live class CRUD |
| `NotificationEditorScreen` | `notification_editor_screen.dart` | 31KB | Notification composer |
| `CombinationPacksScreen` | `combination_packs_screen.dart` | 27KB | Combo pack management |
| `BatchDppScreen` | `batch_dpp_screen.dart` | 25KB | DPP management |
| `BatchNotesScreen` | `batch_notes_screen.dart` | 23KB | Notes management |
| `LiveClassesScreen` | `live_classes_screen.dart` | 21KB | Live class list |
| `UsersScreen` | `users_screen.dart` | 18KB | User list |
| `CourseDetailScreen` | `course_detail_screen.dart` | 18KB | Course detail (admin) |
| `CommunityPostsScreen` | `community_posts_screen.dart` | 17KB | Post management |
| `CommunityPostDetailScreen` | `community_post_detail_screen.dart` | 18KB | Post moderation |
| `EbooksScreen` | `ebooks_screen.dart` | 17KB | E-book management |
| `RecordedBatchesListScreen` | `recorded_batches_list_screen.dart` | 16KB | Recorded batches |
| `NotificationListScreen` | `notification_list_screen.dart` | 15KB | Notification list |
| `ExamManagementScreen` | `exam_management_screen.dart` | 14KB | Exam categories |
| `CoursesListScreen` | `courses_list_screen.dart` | 13KB | Course list |
| `CommunitiesListScreen` | `communities_list_screen.dart` | 12KB | Communities |
| `TestSeriesListScreen` | `test_series_list_screen.dart` | 11KB | Test series list |
| `FeedListScreen` | `feed_list_screen.dart` | 10KB | Feed items list |
| `PaymentSettingsScreen` | `payment_settings_screen.dart` | 9KB | Razorpay config |
| `PosterListScreen` | `poster_list_screen.dart` | 9KB | Banner list |
| `EnrollmentsScreen` | `enrollments_screen.dart` | 7KB | Enrollment management |
| `TestSeriesTestsListScreen` | `test_series_tests_list_screen.dart` | 6KB | Tests list |
| `SettingsScreen` | `settings_screen.dart` | 5KB | Admin settings |
| `BatchPlannerScreen` | `batch_planner_screen.dart` | 5KB | Planner |
| `BatchQuizListScreen` | `batch_quiz_list_screen.dart` | 4KB | Quiz list |

### Web Screens (2 — `lib/web/`)

| Screen | File | Size | Purpose |
|---|---|---|---|
| `WebHomepage` | `web_homepage.dart` | 41KB | Web app portal |
| `LandingPage` | `landing_page.dart` | 2KB | Marketing landing (12 sections) |

---

## 3. Widget Catalog

### Study Widgets (`lib/study/presentation/widgets/`)

| Widget | File | Purpose |
|---|---|---|
| `BatchSelectorWidget` | `batch_selector_widget.dart` | Batch/combo selector header |
| `BatchSelectorBottomSheet` | `batch_selector_bottom_sheet.dart` | Bottom sheet for batch selection |
| `FavouriteBatchesSection` | `favourite_batches_section.dart` | Horizontal favourite cards |
| `ContinueLearningSection` | `continue_learning_section.dart` | Resume watching cards |
| `BrowseByExamSection` | `browse_by_exam_section.dart` | Exam category filter |
| `ComboBatchesSection` | `combo_batches_section.dart` | Combo pack batches |
| `LiveClassesSection` | `live_classes_section.dart` | Upcoming live classes |
| `StickyTabPills` | `sticky_tab_pills.dart` | Sticky Courses/Test/Ebooks tabs |
| `TimetableTimelineWidget` | `timetable_timeline_widget.dart` | 7-day class timeline |
| `StudyEbooksContent` | `study_ebooks_content.dart` | Purchased ebooks grid |
| `ExploreBatchButton` | `explore_batch_button.dart` | Navigate to batch detail |
| `BatchThumbnailWidget` | `batch_thumbnail_widget.dart` | Batch card thumbnail |

### Store Widgets (`lib/store/widgets/`)

| Widget | File | Purpose |
|---|---|---|
| `BannerSlider` | `banner_slider.dart` | Poster/banner carousel |
| `CourseCard` | `course_card.dart` | Course catalog card |
| `CourseListCard` | `course_list_card.dart` | Course list item |
| `ComboPackCard` | `combo_pack_card.dart` | Combo pack card |
| `CartItemTile` | `cart_item_tile.dart` | Cart item row |
| `BatchBadge` | `batch_badge.dart` | Batch status badge |
| `PaymentMethodTile` | `payment_method_tile.dart` | Payment option |
| `StoreEbooksContent` | `store_ebooks_content.dart` | E-book catalog grid |
| `StoreTestSeriesContent` | `store_test_series_content.dart` | Test series catalog |

### Admin Widgets (`lib/admin/widgets/`)

| Widget | File | Purpose |
|---|---|---|
| `AdminScaffold` | `admin_scaffold.dart` | Admin shell with side nav |
| `RichDocumentEditor` | `rich_document_editor.dart` | super_editor WYSIWYG |
| `RichEditorToolbar` | `rich_editor_toolbar.dart` | Formatting toolbar |
| `EquationBuilder` | `equation_builder.dart` | LaTeX equation builder |
| `TldrawWebview` | `tldraw_webview.dart` | Diagram whiteboard |
| `EditableTableWidget` | `editable_table_widget.dart` | In-doc tables |
| `FindReplacePanel` | `find_replace_panel.dart` | Find & replace UI |
| `StudentPerformanceTab` | `student_performance_tab.dart` | Student analytics |
| `ThumbnailUploadWidget` | `thumbnail_upload_widget.dart` | Image uploader |
| `PdfUploadWidget` | `pdf_upload_widget.dart` | PDF uploader |
| `MediaUploader` | `media_uploader.dart` | Generic media upload |
| `QuizLibraryDialog` | `quiz_library_dialog.dart` | Quiz pool browser |
| `LinkLectureToBatchDialog` | `link_lecture_to_batch_dialog.dart` | Cross-link lectures |
| `LinkClassToBatchDialog` | `link_class_to_batch_dialog.dart` | Cross-link classes |
| `LinkLiveClassDialog` | `link_live_class_dialog.dart` | Link live classes |
| `ManageLinkedCoursesDialog` | `manage_linked_courses_dialog.dart` | Course linking |

### Common Widgets (`lib/common/widgets/`)

| Widget | File | Purpose |
|---|---|---|
| `CrossPlatformYoutubePlayer` | `cross_platform_youtube_player.dart` | YouTube (mobile + web) |
| `RichContentViewer` | `rich_content_viewer.dart` | HTML/LaTeX student renderer |
| `VideoSkipOverlay` | `video_skip_overlay.dart` | Skip forward/backward overlay |
| `LiveClassPopup` | `live_class_popup.dart` | Live class notification banner |
| `EmptyState` | `empty_state.dart` | Empty list placeholder |
| `Cards` | `cards.dart` | Reusable card components |

### Web Landing Sections (`lib/web/landing/sections/`)

12 section widgets: `Navbar`, `HeroSection`, `ExamCategoriesSection`, `TrendingCoursesSection`, `FeaturesSection`, `ContentSection`, `StatsSection`, `TestimonialsSection`, `TeamSection`, `FaqSection`, `CtaSection`, `FooterSection`

---

## 4. Service Inventory

### Core Firebase Services (`lib/core/firebase/`)

| Service | File | Key Responsibility |
|---|---|---|
| `AuthService` | `auth_service.dart` | Auth (email, phone, roles) |
| `UserService` | `user_service.dart` | User profile CRUD |
| `PurchaseService` | `purchase_service.dart` | Purchase transactions |
| `CartService` | `cart_service.dart` | Shopping cart |
| `BookmarkService` | `bookmark_service.dart` | Bookmarks |
| `PromoCodeService` | `promo_code_service.dart` | Discount coupons |
| `QuizStatsService` | `quiz_stats_service.dart` | Quiz attempt tracking |
| `WatchStatsService` | `watch_stats_service.dart` | Watch time tracking |
| `RazorpayService` | `razorpay_service.dart` | Payment gateway |
| `LiveViewerService` | `live_viewer_service.dart` | Live class presence |
| `StorageService` | `storage_service.dart` | File uploads |

### Core Services (`lib/core/services/`)

| Service | File | Key Responsibility |
|---|---|---|
| `DeepLinkService` | `deep_link_service.dart` | Universal/deep link handling |
| `LiveClassNotifierService` | `live_class_notifier_service.dart` | Real-time live class detection |
| `PopupManager` | `popup_manager.dart` | App-open popup management |
| `NewBatchPromotionService` | `new_batch_promotion_service.dart` | Promotion dialogs |
| `MigrationService` | `migration_service.dart` | Legacy data migration |
| `PdfCacheService` | `pdf_cache_service.dart` | Secure PDF caching |
| `PermissionService` | `permission_service.dart` | Runtime permissions |
| `RichTextService` | `rich_text_service.dart` | Delta/HTML serialization |

### Admin Services (`lib/admin/services/`)

| Service | File | Size | Key Responsibility |
|---|---|---|---|
| `FirebaseAdminService` | `firebase_admin_service.dart` | **121KB** | All admin CRUD operations |
| `AdminStatsService` | `admin_stats_service.dart` | 4KB | Dashboard metrics |
| `CommunityService` | `community_service.dart` | 9KB | Community management |
| `StudentPerformanceService` | `student_performance_service.dart` | 8KB | Student analytics |
| `TestSeriesService` | `test_series_service.dart` | 3KB | Test series operations |
| `AuthGuard` | `auth_guard.dart` | 1KB | Admin route protection |

### Providers / Controllers

| Provider | File | Type |
|---|---|---|
| `StudyController` | `study_controller.dart` | `ChangeNotifier` |
| `LiveClassNotifierService` | `live_class_notifier_service.dart` | `ChangeNotifier` |
