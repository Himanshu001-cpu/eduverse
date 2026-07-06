# Original User Request

## Initial Request — 2026-06-24T04:05:59Z

Restructure the Store and Study pages in the Eduverse Flutter app to merge Combo Packs, add an E-books tab, and fix test progress calculation bugs where deleted tests cause inflated percentage displays.

Working directory: `/home/himanshu/codes/eduverse`
Integrity mode: development

## Requirements

### R1. Store Page Restructuring
- Merge Combo Packs into the Courses tab. Keep the horizontal combo packs slider, but direct its "See All" button to a new full-page `SeeAllComboPacksPage` instead of navigating to a tab.
- Replace the third tab of the Store page (currently "Combo Packs") with a new "E-books" tab displaying available e-books via `StoreEbooksContent`. Match the Store Test Series UI design (cards with thumbnails).
- Implement an e-book details page (`EbookDetailPage`) and purchase flow using the existing cart service and purchase service.
- Clean up any unused code from `store_page.dart` (such as the orphaned `_ComboPacksContent`).

### R2. Study Page E-books Tab
- Add a third tab to the Study page for "E-books".
- Fetch and display the user's purchased e-books.
- Allow users to open purchased e-books. Use `url_launcher` to open the ebook URL directly in the browser or external PDF viewer.

### R3. Test Progress Calculation Fix
- Correct the test progress calculation on the Study Test Series list screen and Test Series detail screen.
- Filter the user's attempts to only count those corresponding to currently existing tests in the subcollection.
- Use the actual count of existing tests as the denominator for progress calculation, instead of using cached total counts.
- Ensure user progress data is not deleted or altered in Firestore; only the UI display of progress must be corrected.

## Verification Plan

### Automated Tests
- Run `flutter test` to ensure existing unit tests continue to pass and no regressions are introduced.

### Manual Verification
- Verify that the Store page has exactly 3 tabs (Courses, Test Series, E-books).
- Verify that clicking "See All" on the Combo Packs slider in the Courses tab navigates to a dedicated page showing all combo packs.
- Verify that the Store E-books tab displays a grid/list of e-books.
- Verify that purchasing an e-book works (adding to cart and purchasing successfully).
- Verify that the Study page has exactly 3 tabs (Courses, Test Series, E-books).
- Verify that the Study E-books tab displays purchased e-books and that tapping on them opens the URL via `url_launcher`.
- Verify that the progress percentage in the Study Test Series list and detail screens is calculated accurately based on active tests, especially when a test has been deleted by an admin.

## Acceptance Criteria

### Store and Study UI Restructure
- [ ] Store page has exactly 3 tabs: Courses, Test Series, and E-books.
- [ ] Clicking "See All" on the Combo Packs slider in the Courses tab navigates to a dedicated page showing all combo packs.
- [ ] Store E-books tab loads and displays a grid/list of e-books.
- [ ] Users can purchase e-books, adding them to the cart and purchasing successfully.
- [ ] Study page has exactly 3 tabs: Courses, Test Series, and E-books.
- [ ] Study E-books tab displays only the purchased e-books.
- [ ] Tapping on a purchased e-book opens/reads it.

### Test Progress Accuracy
- [ ] Test series list cards show correct progress percentage based on existing tests.
- [ ] Test series detail page header shows correct progress percentage.
- [ ] If a test is deleted by an admin, the user's progress display is recalculated accurately using only the remaining tests.

## Follow-up — 2026-06-24T09:27:09Z

The API quota has reset. Please continue execution and complete the project milestones.

## Follow-up — 2026-06-24T11:10:57Z

Build a performance dashboard in the Eduverse Flutter app. It provides students with time-filtered analytics on quiz performance, study time, improvement trends, and visual breakdowns using charts.

Working directory: `/home/himanshu/codes/eduverse`
Integrity mode: `development`

## Requirements

### R1. Charting Dependency
- Integrate `fl_chart: ^0.70.2` in `pubspec.yaml` to handle line and ring charts.

### R2. Data Layer Enhancements
- Enhance `QuizStatsService.saveQuizAttempt()` to store `wrongAnswers`, `unattemptedCount`, `percentage`, and `categoryLabel`. Update `lib/feed/screens/quiz_result_page.dart` and `lib/study/presentation/screens/study_quiz_result_screen.dart` to pass these fields.
- Add `QuizStatsService.getQuizAttemptsInRange(DateTime start, DateTime end)` and `getDistinctCategories()`.
- Enhance `WatchStatsService.recordWatchTime()` to accept and store an optional `subjectName`. Update `lib/study/presentation/screens/lecture_player_screen.dart` to save `subjectName`.
- Add `WatchStatsService.getWatchSessionsInRange(DateTime start, DateTime end)`.

### R3. Performance Dashboard Service
- Create `PerformanceDashboardService` to aggregate:
  - **Overall Score**: Average percentage of quizzes taken in the current period, and improvement comparison against the previous equivalent period (e.g. for "This Week", compare the current 7 days to the previous 7 days).
  - **Quizzes Taken**: Count of quizzes taken in the current period, and improvement count comparison against the previous period.
  - **Study Time**: Total watch time in current period (formatted as hours/minutes), and improvement percentage comparison against the previous period.
  - **Graph Data**: Daily/weekly/monthly points for line charts (scores and study time) filtered by category/subject.
  - **Accuracy Ring Data**: Total correct, wrong, and unattempted counts in the current period.

### R4. Performance Dashboard UI Screen
- Create `lib/profile/screens/performance_dashboard_page.dart`.
- The page must include:
  - **AppBar**: "Performance Dashboard" title with back button.
  - **Time Period Selector**: Horizontal chips: "This Week" (last 7 days from now), "This Month" (last 30 days from now), and "This Year" (last 365 days from now).
  - **Summary Cards**: Displays Overall Score, Quizzes Taken, and Study Time, each showing their respective value and a small arrow indicator (e.g., `↑ X% from last week/month/year` in green, or `↓ Y%` in red).
  - **Line Chart Section**: Dropdown filter for "All Subjects" + unique categories. A `LineChart` showing the quiz score trend (indigo) and study time trend (teal) with legend.
  - **Quiz Accuracy Donut/Ring**: A `PieChart` showing Correct (green), Incorrect (red), and Unattempted (grey/orange) with a legend.

### R5. Entry Point Navigation
- Modify `StatsSection` in `lib/profile/widgets/stats_section.dart` to display a "Performance Dashboard →" or "View Dashboard →" button which navigates to the `PerformanceDashboardPage`.

## Acceptance Criteria

### Static Analysis and Build
- [ ] Code has no Dart compilation errors.
- [ ] `flutter analyze` passes with no errors.
- [ ] `flutter build apk --debug` completes successfully.

### Performance Dashboard Functionality
- [ ] Accessing Profile page and clicking "View Dashboard →" navigates to the dashboard screen.
- [ ] Switching between "This Week", "This Month", and "This Year" successfully refreshes data for the correct date range (computed relative to the current timestamp).
- [ ] Improvement calculations compare the current period (e.g., last 30 days) with the prior equivalent period (e.g., prior 30 days before that). If no previous data is available, it gracefully shows "0%" or "N/A".
- [ ] Selecting a specific subject from the dropdown correctly filters only those data points on the line chart.
- [ ] Accuracy ring chart correctly displays correct, incorrect, and unattempted question distribution based on actual quiz attempts.
- [ ] All elements conform to the Material 3 UI design guidelines and match the light theme indigo seed color.

## Follow-up — 2026-06-26T23:11:19+05:30

Restructure the Study Section UI of the Eduverse Flutter app to introduce a sticky tab-pill layout, a persistent batch/combo selector, a Hive-based "Continue Learning" section with playback resume support, "Favourite Batches", and "Browse Batches by Exam" sections.

Working directory: `/home/himanshu/codes/eduverse`
Integrity mode: `development`

## Requirements

### R1. Persistent Batch Selector & Dynamic Home Layout
- Add a top persistent batch selector showing the current selected batch/combo pack name, tapping it opens a bottom sheet allowing selecting combo packs or individual batches. Save the last selected batch to SharedPreferences and backup to Firestore.
- Dynamically adjust the homepage layout:
  - If a **Combo Pack** is selected: show Favourite Batches, Continue Learning, and Browse Batches by Exam sections.
  - If an **Individual Batch** is selected: show Continue Learning and an "Explore Batch" button.

### R2. Favourite Batches Section (Combo Packs Only)
- Display a horizontal scroll of mini-cards representing courses marked as favorites within the selected combo pack.
- Include a heart icon toggle to add/remove a batch from favourites, persisting to Firestore + SharedPreferences hybrid storage.
- Tapping a favourite card must open the `BatchDetailScreen` for that course.

### R3. Continue Learning Lecture Resume
- Track and save lecture playback progress (in seconds) locally using Hive.
- Display a "Continue Learning" horizontal list of incomplete lectures. Each card shows the thumbnail, lecture title, progress bar, and relative watched time (e.g., "Opened 2 hours ago").
- Tapping a card opens the `LecturePlayerScreen`, resuming playback from the exact saved position. Clear progress once a lecture is completed (>95% watched).

### R4. Browse Batches by Exam Section (Combo Packs Only)
- Display a horizontal scrollable row of active exam circles (image/icon + name).
- Underneath, display filter chips (Search, Filter, Category, Started, Upcoming).
- Display courses assigned to the selected exam in full-width horizontal cards showing thumbnail, title, start date, and a heart icon.

### R5. Sticky Tab Pills
- Implement a `SliverPersistentHeader` representing three horizontal pills: Courses, Test Series, and E-books.
- The tab pills must stick to the top when the user scrolls past. Swapping tabs switches the scroll view's content appropriately.

### R6. Admin Panel Exam Management
- Create `ExamManagementScreen` to allow admins to perform full CRUD operations on exams: Create, Read, Update, Delete, drag-and-drop reordering, and multi-selecting courses.
- Add an "Exams" navigation entry to the admin side panel.

## Acceptance Criteria

### Code Quality & Correctness
- [ ] No compilation errors or warnings; `flutter analyze` runs clean.
- [ ] The app builds successfully: `flutter build apk --debug` succeeds.
- [ ] State management correctly propagates batch changes across the UI.

### Functional Verification
- [ ] Changing selection in the batch selector updates the home page dynamically (correct sections displayed).
- [ ] The last selected batch/combo pack persists across app restarts (loaded from SharedPreferences).
- [ ] Adding/removing favorites correctly updates Firestore and local state immediately.
- [ ] Lecture video playback saves progress locally using Hive when paused or closed.
- [ ] Tapping a "Continue Learning" item resumes video playback from the correct position.
- [ ] Admins can create exams, upload icon images, reorder them, and assign courses.
- [ ] Exams and their assigned courses appear correctly in the "Browse Batches by Exam" section under the selected combo pack.

### User Interface & Experience
- [ ] Premium, high-fidelity light theme design matching the style guides.
- [ ] Smooth transitions, sticky tab behavior, and micro-animations for interactions.

## Follow-up — 2026-06-28T08:13:53Z

Run the Flutter app on device `RMX3870` in release mode, monitor the console logs for Firebase/Storage errors when logging in as admin, quickly resolve any rules/permissions issues, and deploy the fixes.

Working directory: /home/himanshu/codes/eduverse
Integrity mode: development

## Requirements

### R1. Flutter App Run & Monitor
- Run `flutter run -d RMX3870 --release` and log the output.
- Monitor the application log outputs for any exceptions or issues.

### R2. Firebase Diagnostic & Live Rules/Claims Deployment
- Analyze logs for any Firestore or Storage errors (e.g. Permission Denied).
- If rules errors or missing custom claims are detected, resolve them in `firestore.rules`, `storage.rules`, or custom claims.
- Deploy the updated rules immediately to Firebase (project `eduverse-dad5e`).

## Acceptance Criteria

### Execution & Verification
- [ ] Flutter app builds and runs successfully in release mode on `RMX3870`.
- [ ] Admin login does not trigger Firebase Firestore or Storage permission/rules errors in the logs.
- [ ] Rules or configuration changes are successfully deployed to the active Firebase project (`eduverse-dad5e`).

## Follow-up — 2026-06-28T09:14:12Z

Allow copying, pasting, and deleting entire folders (with all their contents) in the course lectures editor, supporting copy/paste across different courses.

Working directory: /home/himanshu/codes/eduverse
Integrity mode: development

## Requirements

### R1. Cross-Course Folder Copy & Deep Paste
Admins must be able to copy a folder (including its nested lectures, notes, DPPs, and subfolders) from one course/subject and pictorial representation path and paste it into another course or subject.
- The pasted content must be deep copies (new Firestore documents with new IDs, not linked copies).
- Subject and chapter fields of copied documents must be updated to match the new location.
- Cross-references like `linkedNoteIds` and `lectureId` within the folder must be mapped to their new copied counterparts to preserve links within the pasted folder.
- Suppress push notifications to students during bulk paste operations.

### R2. Paste Conflict Warning and Rename
If a folder with the same name already exists in the destination folder path:
- Warn the user about the name conflict.
- If confirmed, proceed with an auto-rename (e.g., "Folder Name (Copy)").

### R3. Enhanced Folder Deletion
When deleting a folder recursively, the confirmation dialog must display a count of items to be deleted (e.g., "This folder contains 5 lectures, 3 notes, 2 DPPs").

## Acceptance Criteria

### Verification Criteria
- [ ] Folder copy/paste duplicates all subfolders, lectures, notes, and DPPs with new IDs.
- [ ] Paste operation updates the `subject` and `chapter` properties of all created items to match the destination.
- [ ] Any internal links between lectures, notes, and DPPs in the copied folder are preserved (using the new copied document IDs).
- [ ] A name conflict warning is shown when pasting a folder with a duplicate name, and confirming renames the folder.
- [ ] Deletion of folders shows a count of all nested items to be deleted before confirmation.
- [ ] Pasting a folder does not trigger student push notifications.

## Follow-up — 2026-07-01T06:13:39Z

Implement a comprehensive dynamic scheduler and timetable system for courses in the Eduverse Flutter app. This system will allow admins/teachers to define recurring class rules, generate individual live classes, manage schedules, and let students view a combined weekly timeline of upcoming and live classes.

Working directory: /home/himanshu/codes/eduverse
Integrity mode: development

## Requirements

### R1. Recurring Schedule Rules & Generation
- Admin and assigned teachers can create, edit, and delete recurring class rules (e.g., "Math every Mon/Wed 10:00 AM with Instructor X").
- Admins can trigger generation of individual live class instances (`live_classes` collection) from these recurring rules for a user-specified date range (e.g. next 2 weeks).
- Send a push notification to enrolled students when new classes are generated.

### R2. Admin Schedule Management & Conflict Detection
- A dedicated "Course Schedule" screen under the course detail page showing the list of rules and a timeline of generated classes.
- Ability to reschedule or cancel individual generated classes without affecting the parent recurring rule.
- Highlight scheduling conflicts (e.g. overlapping classes or same teacher scheduled at the same time) with a visual indicator but do not block saving.

### R3. Student Timetable Timeline View
- A dedicated student-facing timeline view displaying today + the next 7 days of classes in a merged view across all enrolled courses.
- Show class subject, teacher, start/end time, and countdown timer for upcoming classes.
- Live classes should show a "LIVE" badge and a "JOIN" button.
- Cancelled classes must be shown as cancelled (with strikethrough/badge) rather than hidden.
- Days with no classes should display a "(No classes)" placeholder.

## Verification Resources
- Run existing Flutter unit/widget tests using `flutter test` to ensure zero regressions.

## Acceptance Criteria

### Compilation and Standards
- [ ] The app builds successfully (`flutter build apk --debug`).
- [ ] No compilation errors or static analysis issues (`flutter analyze` runs clean).

### Functional Behavior
- [ ] Recurring rules can be added, updated, and deleted by admins and teachers.
- [ ] Generation process creates individual classes in `courses/{courseId}/live_classes` without duplicating already-generated dates.
- [ ] A student's schedule page merges classes from all enrolled courses correctly.
- [ ] Updating/cancelling a single generated class leaves other classes generated by the same rule untouched.
- [ ] Visual indicators highlight overlapping class times in both admin and student views.
- [ ] Existing automated tests continue to pass (`flutter test`).

## Follow-up — 2026-07-03T10:04:25+05:30

Implement a secure, in-app PDF viewer in the Eduverse Flutter application to replace external PDF opening/downloading for paid ebooks and course notes, thus preventing unauthorized sharing while supporting offline access for ebooks via secure local caching.

Working directory: /home/himanshu/codes/eduverse
Integrity mode: development

## Requirements

### R1. Secure In-App PDF Viewer Screen
- Build a reusable, full-screen in-app PDF viewer using the `syncfusion_flutter_pdfviewer` package.
- It must support smooth zoom, text search, page navigation, and a dark/night mode.
- Ebooks (paid content) must have direct downloading and sharing disabled, text selection disabled, and screenshot protection enabled (on Android).
- Course notes/DPPs/Planners can allow direct downloading and sharing, and should open in-app first.

### R2. Offline Ebook Caching (Secure Local Storage)
- Support offline viewing for ebooks by downloading them to a secure/hidden local directory (e.g., app's document directory with custom obfuscated/encrypted naming or file structures, preventing students from easily finding and opening/sharing the raw PDF file directly from storage).
- When offline, the app should be able to load these securely cached files in the PDF viewer screen.

### R3. Screen Protection Integration
- Prevent taking screenshots or screen recording when viewing protected content (ebooks) on Android devices.

### R4. Update All PDF Navigation
- Refactor the 7 identified screens (Chapter Detail, Subject Detail, Course Section Page, Lecture Player Page, Batch Detail Screen, Study Ebooks Content, Ebook Detail Page) to route PDF viewing requests to the new in-app PDF viewer instead of launching external browsers or external PDF applications.

## Acceptance Criteria

### Security & Functional Controls
- [ ] Ebooks load in-app using `syncfusion_flutter_pdfviewer`.
- [ ] Ebooks do not show any direct download, export, or share buttons in the UI.
- [ ] Ebooks are cached locally in a secure, hidden, or obfuscated file format/location for offline viewing.
- [ ] Ebooks can be successfully viewed in the app while offline (without internet connection) using the secure local cache.
- [ ] Course notes, DPPs, and Solutions load in-app with download/share controls enabled.
- [ ] Android screenshot protection successfully blocks captures when viewing ebooks.
- [ ] Text search, page indicator, and zoom work smoothly.
- [ ] All 7 identified screens successfully launch the in-app PDF viewer.
- [ ] `flutter analyze` passes with no errors.
- [ ] The app builds and runs successfully.

## Follow-up — 2026-07-03T22:31:12+05:30

Implement a comprehensive rich text editing system (mini office suite) for the Eduverse admin panel, replacing the current markdown-based FormattedTextField with a super_editor-based document editor, integrating tldraw for diagrams (exported as SVG), an equation builder (generating LaTeX), native editable tables, find and replace with regex, and multi-format rendering (Delta JSON and HTML) for test series, feed items, and course tests.

Working directory: /home/himanshu/codes/eduverse
Integrity mode: development

## Requirements

### R1. Rich Text Formatting & Editor UI
- Replace the existing `FormattedTextField` with a custom `RichDocumentEditor` widget based on `super_editor`.
- Implement a consistent toolbar across all editors containing: bold, italic, underline, superscript, subscript, highlight with preset/custom color picker, foreground text color picker, system fonts, predefined font sizes (10-72), paragraph alignment, line spacing, and multi-level nested lists.
- Support auto-save debounced/throttled at 1-minute intervals.

### R2. Custom Elements Integration (Images, Tables, Equations, Diagrams)
- **Images**: Inline image insertion, uploading files to Firebase Storage and storing download URLs in the document Delta.
- **Tables**: Native editable grid component inside the document editor (max size 20x20).
- **Equations**: Visual point-and-click equation builder that outputs LaTeX, rendering inline/block equations via `flutter_math_fork`.
- **Diagrams**: Full tldraw whiteboard embedded via WebView (self-hosted on Firebase Hosting), exporting diagrams as SVG to Firebase Storage.

### R3. Dual-Format Storage & Student Rendering
- Store rich content in Firestore in dual-format: a structured Delta JSON (for future edits) and a generated HTML snapshot (for fast rendering).
- Create a `RichContentViewer` widget for the student side using `flutter_widget_from_html_core` to render HTML snapshots, with custom widget factories for equations (LaTeX), diagrams (SVG/network images), and tables.
- Implement backward compatibility to automatically render legacy markdown strings using the old renderer, and new HTML/Delta JSON content using the new renderer.

### R4. Find & Replace
- Build a floating Find & Replace panel within the editor.
- Support finding text, replacing individual matches, replacing all, case-sensitivity toggles, and regular expression (regex) search.

### R5. Migration and Old Code Cleanup
- Implement a safe migration path.
- Phase 1: Deploy new editor and backward-compatible viewer.
- Phase 2: Run a migration script (`scripts/migrate_markdown_to_delta.js` or similar Node.js script) to convert all legacy Firestore markdown documents to Delta JSON/HTML.
- Phase 3: Remove old rendering code and the legacy `FormattedTextField`.

## Acceptance Criteria

### Editor Functionality
- [ ] Admins can create and edit documents using bold, italic, underline, highlight, alignment, lists, and font sizes.
- [ ] Admins can insert images, tables (capped at 20x20), LaTeX math equations, and draw diagrams via the embedded tldraw view.
- [ ] Find & Replace finds text (including via regex) and replaces matches dynamically.
- [ ] Auto-save successfully triggers every 1 minute.

### Storage & Serialization
- [ ] Documents are serialized to Firestore containing both `Delta JSON` and an `HTML snapshot`.
- [ ] Images and diagrams are uploaded to Firebase Storage, with valid URLs embedded in the document.

### Student Viewer
- [ ] Students can view all rich content (formatting, math equations, SVG diagrams, and tables) on Android, iOS, and Web.
- [ ] Legacy documents (plain strings) continue to render correctly using the legacy renderer.

### Migration
- [ ] A migration script successfully converts test markdown data to Delta JSON and HTML without losing content structure.


