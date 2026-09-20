---
phase: "05"
slug: "05-code-hygiene-linter-enforcement"
status: draft
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-20"
---

# Phase 05 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter Test / Dart Analyzer |
| **Config file** | `analysis_options.yaml` |
| **Quick run command** | `/home/himanshu/development/flutter/bin/flutter analyze` |
| **Full suite command** | `/home/himanshu/development/flutter/bin/flutter test && /home/himanshu/development/flutter/bin/flutter analyze` |
| **Estimated runtime** | ~24 seconds (~19s test, ~5s analyze) |

---

## Sampling Rate

- **After every task commit:** Run `/home/himanshu/development/flutter/bin/flutter analyze`
- **After every plan wave:** Run `/home/himanshu/development/flutter/bin/flutter test`
- **Before `/gsd-verify-work`:** Full suite and analyzer must be green (0 issues, 405 tests passing)
- **Max feedback latency:** 25 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | ENH-04 | — | `analysis_options.yaml` created extending `flutter.yaml` and `pubspec.yaml` updated with direct dependencies | config/analysis | `test -f analysis_options.yaml && /home/himanshu/development/flutter/bin/flutter analyze` | ❌ W0 | ⬜ pending |
| 05-01-02 | 01 | 1 | ENH-04 | T-05-01 | `lecture_player_page.dart` deleted, all 5 debug prints removed, `avoid_print` errors 0 | static/security | `test ! -f lib/study/screens/lecture_player_page.dart && ! git grep -n "avoid_print" lib/` | ✅ | ⬜ pending |
| 05-01-03 | 01 | 1 | ENH-04 | — | `dart fix --apply` executed; ~96 AST issues resolved; 405 tests green | automated/unit | `/home/himanshu/development/flutter/bin/flutter test` | ✅ | ⬜ pending |
| 05-02-01 | 02 | 2 | ENH-04 | — | 23 async context issues in `course_schedule_dashboard.dart` and admin screens resolved | static/ui | `/home/himanshu/development/flutter/bin/flutter analyze lib/admin/` | ✅ | ⬜ pending |
| 05-02-02 | 02 | 2 | ENH-04 | — | Remaining async context issues in `lib/` and test helpers resolved | static/full | `/home/himanshu/development/flutter/bin/flutter analyze` | ✅ | ⬜ pending |
| 05-02-03 | 02 | 2 | ENH-04 | T-05-01 | Full verification: 0 analyzer issues, 405 tests passing | integration/full | `/home/himanshu/development/flutter/bin/flutter test && /home/himanshu/development/flutter/bin/flutter analyze` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing infrastructure covers all phase requirements. (Flutter test harness, analyzer, and `flutter_lints` already present).

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-09-20
