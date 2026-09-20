---
phase: "3"
slug: "architecture-consolidation-repository-migration"
status: approved
nyquist_compliant: true
wave_0_complete: false
created: "2026-09-20"
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter Test SDK 3.32+ / Dart 3.8+ |
| **Config file** | none — Flutter built-in test runner |
| **Quick run command** | `/home/himanshu/development/flutter/bin/flutter test test/unit/study_m2_test.dart test/widget/live_classes_section_test.dart` |
| **Full suite command** | `/home/himanshu/development/flutter/bin/flutter test test/unit/ test/widget/ test/e2e/study_e2e_test.dart test/e2e/cross_feature_e2e_test.dart test/e2e/study_room_tab_selection_test.dart` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `/home/himanshu/development/flutter/bin/flutter test test/unit/study_m2_test.dart test/widget/live_classes_section_test.dart` and `/home/himanshu/development/flutter/bin/flutter analyze lib/study/`
- **After every plan wave:** Run `/home/himanshu/development/flutter/bin/flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green with zero regressions
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | ENH-02 | — | N/A | unit | `/home/himanshu/development/flutter/bin/flutter test test/widget/live_classes_section_test.dart test/e2e/pdf_viewer_e2e_test.dart` | ✅ | ⬜ pending |
| 03-01-02 | 01 | 1 | ENH-02 | — | N/A | widget | `/home/himanshu/development/flutter/bin/flutter analyze lib/study/ lib/profile/screens/bookmarks_page.dart && /home/himanshu/development/flutter/bin/flutter test test/unit/study_m2_test.dart test/e2e/study_room_tab_selection_test.dart` | ✅ | ⬜ pending |
| 03-02-01 | 02 | 2 | ENH-02 | T-03-01 | Access control: only enrolled/combo courses returned | unit | `! grep -rn "study_repository\.dart" lib/ test/ && /home/himanshu/development/flutter/bin/flutter analyze lib/` | ✅ | ⬜ pending |
| 03-02-02 | 02 | 2 | ENH-02 | T-03-01 | Wave 0 test suites pass and full regression suite green | regression | `/home/himanshu/development/flutter/bin/flutter test test/unit/study_repository_impl_test.dart test/widget/workbooks_page_test.dart test/widget/my_courses_page_test.dart test/unit/study_m2_test.dart test/widget/live_classes_section_test.dart test/e2e/study_e2e_test.dart test/e2e/cross_feature_e2e_test.dart test/e2e/pdf_viewer_e2e_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/study_repository_impl_test.dart` — tests for `getWorkbooks()`, `getEnrolledCourses()`, `getTopics()`, and combination pack course resolution using `FakeFirebaseFirestore`.
- [ ] `test/widget/workbooks_page_test.dart` — tests for `WorkbooksPage` rendering, filtering, and task interaction with injected `IStudyRepository`.
- [ ] `test/widget/my_courses_page_test.dart` — tests for `MyCoursesPage` grid rendering and course navigation with injected `IStudyRepository`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| All phase behaviors have automated verification. | ENH-02 | N/A | N/A |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 20s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved
