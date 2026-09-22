---
phase: "4"
slug: "admin-performance-data-pagination"
status: draft
nyquist_compliant: true
wave_0_complete: false
created: "2026-09-20"
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter Test / Dart SDK |
| **Config file** | `pubspec.yaml` |
| **Quick run command** | `/home/himanshu/development/flutter/bin/flutter test test/unit/admin_pagination_test.dart test/unit/admin_stats_service_test.dart` |
| **Full suite command** | `/home/himanshu/development/flutter/bin/flutter test` |
| **Estimated runtime** | ~15-25 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **After every plan wave:** Run `/home/himanshu/development/flutter/bin/flutter test test/unit/admin_pagination_test.dart test/unit/admin_stats_service_test.dart test/widget/admin_users_pagination_widget_test.dart test/widget/admin_purchases_pagination_widget_test.dart`
- **Before `/gsd-verify-work`:** Full test suite (`flutter test`) and static analysis (`flutter analyze`) must be completely green
- **Max feedback latency:** 25 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 1 | ENH-03 | — | N/A | unit | `/home/himanshu/development/flutter/bin/flutter test test/unit/admin_pagination_test.dart` | ❌ W0 | ⬜ pending |
| 04-01-02 | 01 | 1 | ENH-03 | T-04-01 | Non-admin callers blocked from pagination queries | unit | `/home/himanshu/development/flutter/bin/flutter test test/unit/admin_pagination_test.dart` | ❌ W0 | ⬜ pending |
| 04-01-03 | 01 | 1 | ENH-03 | — | Stream cached doc, avoid raw collection polling | unit | `/home/himanshu/development/flutter/bin/flutter test test/unit/admin_stats_service_test.dart` | ❌ W0 | ⬜ pending |
| 04-02-01 | 02 | 2 | ENH-03 | T-04-01 | Admin auth verified before loading user batches | widget | `/home/himanshu/development/flutter/bin/flutter test test/widget/admin_users_pagination_widget_test.dart` | ❌ W0 | ⬜ pending |
| 04-02-02 | 02 | 2 | ENH-03 | T-04-01 | Date range bounds and user resolution guarded | widget | `/home/himanshu/development/flutter/bin/flutter test test/widget/admin_purchases_pagination_widget_test.dart` | ❌ W0 | ⬜ pending |
| 04-02-03 | 02 | 2 | ENH-03 | — | N/A | integration/full | `/home/himanshu/development/flutter/bin/flutter test && /home/himanshu/development/flutter/bin/flutter analyze` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/admin_pagination_test.dart` — tests for `FakeQuery` cursors, `getUsersPaginated`, `getPurchasesPaginated`, and T-04-01 security
- [ ] `test/unit/admin_stats_service_test.dart` — tests for cached dashboard stats stream and 1-doc read reduction
- [ ] `test/widget/admin_users_pagination_widget_test.dart` — widget tests for 20-batch user table, infinite scroll, and search debounce
- [ ] `test/widget/admin_purchases_pagination_widget_test.dart` — widget tests for date-range picker, infinite scroll, and LRU user resolution

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual smoothness of infinite scroll fling on mobile | ENH-03 | High refresh-rate gesture feel | Open Admin Panel on a mobile device or emulator, fling scroll to bottom, observe smooth spinner and row append without stutter |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** verified 2026-09-20
