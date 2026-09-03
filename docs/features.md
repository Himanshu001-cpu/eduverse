# Eduverse — Feature Inventory

Complete feature catalog organized by user role and module.

---

## 🎓 Student Features

### Authentication (`lib/auth/`)
| Feature | Key Files |
|---|---|
| Email/password login | `login_page.dart` |
| Phone OTP login | `phone_login_page.dart`, `phone_verify_dialog.dart` |
| Phone linking to existing account | `auth_service.dart` |
| User registration | `register_page.dart` |
| Forgot password / reset | `forgot_password_page.dart` |
| Account deletion | `lib/settings/delete_account_page.dart` |
| Privacy policy viewer | `privacy_policy_page.dart` |
| Role-based routing (admin vs student) | `auth_wrapper.dart` |

### Store / Marketplace (`lib/store/`)
| Feature | Key Files |
|---|---|
| Browse courses (thumbnails, pricing, seats) | `store_page.dart`, `course_card.dart` |
| Browse combo packs (bundled courses+tests+ebooks) | `combo_pack_card.dart`, `see_all_combo_packs_page.dart` |
| Browse test series | `store_test_series_content.dart` |
| Browse e-books | `store_ebooks_content.dart` |
| Banner/poster slider | `banner_slider.dart` |
| Course detail page with enrollment status | `course_detail_page.dart` |
| Combo pack detail page | `combo_pack_detail_page.dart` |
| E-book detail page | `ebook_detail_page.dart` |
| Shopping cart with multi-item support | `purchase_cart_page.dart`, `cart_item_tile.dart` |
| Promo code / coupon application | `promo_code_service.dart` |
| Razorpay payment integration | `razorpay_service.dart`, `checkout_page.dart` |
| Payment result confirmation | `payment_result_page.dart` |
| Purchase history | `purchase_history_page.dart` |

### Study Section (`lib/study/`)
| Feature | Key Files |
|---|---|
| Batch selector (combo vs individual batch) | `batch_selector_widget.dart`, `batch_selector_bottom_sheet.dart` |
| Favourite batches (combo packs only) | `favourite_batches_section.dart` |
| Continue learning with Hive-based resume | `continue_learning_section.dart`, `lecture_progress_repository.dart` |
| Browse batches by exam category | `browse_by_exam_section.dart` |
| Sticky tab pills (Courses / Test Series / E-books) | `sticky_tab_pills.dart` |
| Course section with subjects & chapters | `course_section_page.dart`, `subject_detail_screen.dart`, `chapter_detail_screen.dart` |
| Video lecture player with skip overlay | `lecture_player_screen.dart`, `video_skip_overlay.dart` |
| Cross-platform YouTube player | `cross_platform_youtube_player.dart` |
| Secure in-app PDF viewer (Syncfusion) | `secure_pdf_viewer_screen.dart` |
| DPPs (Daily Practice Papers) with solutions | Rendered in `chapter_detail_screen.dart` |
| Course notes (downloadable PDFs) | Rendered in `subject_detail_screen.dart` |
| Practice quizzes with timer & results | `study_quiz_screen.dart`, `study_quiz_result_screen.dart` |
| Study planner | Rendered in `batch_detail_screen.dart` |
| Live classes timetable (7-day timeline) | `timetable_timeline_widget.dart`, `live_classes_section.dart` |
| Recorded batches | `recorded_batch_detail_screen.dart` |
| Test series with progress tracking | `study_test_series_screen.dart`, `test_series_detail_screen.dart` |
| Map work / geography topics | `map_work_page.dart` |
| Workbooks (student notebooks) | `workbooks_page.dart` |
| Practice questions | `practice_question_page.dart` |

### Communities (`lib/study/screens/`)
| Feature | Key Files |
|---|---|
| Browse accessible communities | `student_accessible_communities_screen.dart` |
| Community discussion board | `student_community_screen.dart` |
| Post detail with replies | `student_post_detail_screen.dart` |
| Teacher-verified answers | Reply model with `isAnswered` flag |

### Feed (`lib/feed/`)
| Feature | Key Files |
|---|---|
| Articles with rich content | `article_detail_page.dart` |
| Current affairs | `current_affairs_detail_page.dart` |
| Answer writing practice | `answer_writing_page.dart` |
| Video content | `video_detail_page.dart` |
| Feed quizzes | `quiz_page.dart`, `quiz_result_page.dart` |
| Job alerts | `job_detail_page.dart` |
| Trending section | `trending_section.dart`, `trending_card.dart` |
| Comments and likes | `feed_repository.dart` |
| Rich text rendering (HTML + LaTeX) | `rich_text_block.dart`, `rich_content_viewer.dart` |

### Profile (`lib/profile/`)
| Feature | Key Files |
|---|---|
| Profile editing (name, avatar, bio) | `edit_profile_page.dart` |
| Performance dashboard (charts & analytics) | `performance_dashboard_page.dart` |
| Quiz stats (score trends, accuracy ring) | `quiz_stats_service.dart` |
| Watch time tracking | `watch_stats_service.dart` |
| Bookmarks | `bookmarks_page.dart`, `bookmark_service.dart` |
| Push notifications inbox | `notifications_page.dart` |
| Transaction history | `transactions_page.dart` |
| Free live classes catalog | `free_live_classes_page.dart` |
| My downloads (offline files) | `my_downloads_page.dart` |
| About page & version info | `about_page.dart`, `version_card.dart` |

### Cross-Cutting Student Features
| Feature | Key Files |
|---|---|
| Deep linking (course, batch, feed, combo, test series, ebook) | `deep_link_service.dart`, `deep_link_screens.dart` |
| FCM push notifications + local foreground | `notification_service.dart`, `flutter_local_notifications` |
| Offline lecture progress (Hive) | `lecture_progress_repository.dart` |
| Offline PDF caching for ebooks | `pdf_cache_service.dart` |
| File downloads with progress | `download_service.dart` (Dio) |
| Screenshot protection (Android) | `screen_protector` in `secure_pdf_viewer_screen.dart` |
| Firebase App Check | `firebase_initializer.dart` |
| Global search | `global_search_delegate.dart` |
| Live class popup banners | `live_class_popup.dart`, `live_class_notifier_service.dart` |
| New batch promotion dialogs | `new_batch_promotion_service.dart` |
| App-open poster popups (frequency-controlled) | `popup_manager.dart` |

---

## 🛡 Admin Features (`lib/admin/`)

### Dashboard & Analytics
| Feature | Key Files |
|---|---|
| Admin dashboard (revenue, users, courses) | `dashboard_screen.dart`, `admin_stats_service.dart` |
| Student performance analytics | `student_performance_tab.dart`, `student_performance_service.dart` |

### Course Management
| Feature | Key Files |
|---|---|
| CRUD courses (title, pricing, teachers, subjects) | `course_editor_screen.dart` (62KB), `courses_list_screen.dart` |
| Lecture editor (video, notes, DPPs, links) | `lecture_editor_screen.dart` (112KB) |
| Batch notes management | `batch_notes_screen.dart` |
| DPP management | `batch_dpp_screen.dart` |
| Quiz editor | `batch_quiz_editor_screen.dart`, `quiz_editor_screen.dart` |
| Study planner management | `batch_planner_screen.dart` |
| Live class editor & management | `live_class_editor_screen.dart`, `live_classes_screen.dart` |
| Recorded batches | `recorded_batches_list_screen.dart` |
| Cross-course folder copy/paste/delete | `firebase_admin_service.dart` |
| Link lectures/classes across courses | `link_lecture_to_batch_dialog.dart`, `link_class_to_batch_dialog.dart` |

### Scheduling System
| Feature | Key Files |
|---|---|
| Recurring class rules (weekday, time, teacher) | `course_schedule_rules_screen.dart` |
| Generate live classes from rules | `course_schedule_dashboard.dart` |
| Conflict detection (overlapping classes) | `course_schedule_dashboard.dart` |

### Content Management
| Feature | Key Files |
|---|---|
| Combination packs (bundle courses+tests+ebooks) | `combination_packs_screen.dart` |
| Test series CRUD | `test_series_editor_screen.dart`, `test_series_list_screen.dart` |
| Test editor (questions, marking scheme) | `test_series_test_editor_screen.dart` |
| E-book CRUD with PDF upload | `ebooks_screen.dart` |
| Feed content editor (articles, quizzes, jobs, etc.) | `feed_editor_screen.dart` (69KB) |
| Exam category management | `exam_management_screen.dart` |

### Rich Text Editor (Mini Office Suite)
| Feature | Key Files |
|---|---|
| super_editor based WYSIWYG editor | `rich_document_editor.dart` |
| Formatting toolbar (bold, italic, fonts, colors) | `rich_editor_toolbar.dart` |
| LaTeX equation builder | `equation_builder.dart` |
| tldraw diagram whiteboard (via WebView) | `tldraw_webview.dart` |
| Editable tables (max 20×20) | `editable_table_widget.dart` |
| Find & Replace with regex | `find_replace_panel.dart` |
| Dual-format storage (Delta JSON + HTML) | `rich_text_service.dart` |

### User & Payment Management
| Feature | Key Files |
|---|---|
| User list with search & role filter | `users_screen.dart` |
| User detail with enrollments & performance | `user_detail_screen.dart` (45KB) |
| Role management (admin/teacher/student) | Via `setAdminRole` Cloud Function |
| Manual enrollment | `enrollments_screen.dart` |
| Purchase tracking & refunds | `purchases_screen.dart` (45KB) |
| Promo code management | `promo_codes_screen.dart` |
| Payment settings (Razorpay config) | `payment_settings_screen.dart` |

### Notifications & Engagement
| Feature | Key Files |
|---|---|
| Push notification editor | `notification_editor_screen.dart` |
| Notification list | `notification_list_screen.dart` |
| Banner/poster management with popup frequency | `poster_editor_screen.dart`, `poster_list_screen.dart` |

### Communities
| Feature | Key Files |
|---|---|
| Community CRUD | `communities_list_screen.dart` |
| Post management | `community_posts_screen.dart` |
| Post detail & moderation | `community_post_detail_screen.dart` |

### Infrastructure
| Feature | Key Files |
|---|---|
| Admin scaffold with side navigation | `admin_scaffold.dart` |
| Admin routing | `admin_router.dart` |
| Auth guard (role check) | `auth_guard.dart` |
| Audit logging | `firebase_admin_service.dart` |
| Admin settings | `settings_screen.dart` |

---

## 🌐 Web Features (`lib/web/`)

| Feature | Key Files |
|---|---|
| Responsive landing page | `landing_page.dart` |
| Hero section with CTA | `hero_section.dart` |
| Exam categories showcase | `exam_categories_section.dart` |
| Trending courses carousel | `trending_courses_section.dart` |
| Platform features grid | `features_section.dart` |
| Content preview section | `content_section.dart` |
| Stats / social proof | `stats_section.dart` |
| Testimonials slider | `testimonials_section.dart` |
| Team section | `team_section.dart` |
| FAQ accordion | `faq_section.dart` |
| CTA banner | `cta_section.dart` |
| Footer with links | `footer_section.dart` |
| Navigation bar | `navbar.dart` |
| Glass container effects | `glass_container.dart` |
| Web app homepage portal | `web_homepage.dart` |

---

## 🔧 Backend Features (`functions/`)

| Feature | Trigger |
|---|---|
| Auto-enrollment on purchase | Firestore `onCreate` on `purchases` |
| Webhook payment updates | HTTPS endpoint |
| Admin role management | HTTPS `onCall` |
| Invoice generation | HTTPS `onCall` |
| Push notification delivery (batched FCM) | Firestore `onCreate` on `notifications` |
| Lesson view count increment | HTTPS `onCall` |
| Daily Firestore backup | Scheduled (24h) |
| App update reminders | Scheduled (24h) |
| Purchase refund via Razorpay API | HTTPS `onCall` |
