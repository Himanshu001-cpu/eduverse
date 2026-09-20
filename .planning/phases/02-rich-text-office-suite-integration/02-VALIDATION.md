---
phase: "02"
slug: "rich-text-office-suite-integration"
status: draft
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-20"
---

# Phase 02 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (Flutter SDK 3.47 / Dart 3.13) |
| **Config file** | `pubspec.yaml` |
| **Quick run command** | `/home/himanshu/development/flutter/bin/flutter test test/e2e/rich_text_e2e_test.dart` |
| **Full suite command** | `/home/himanshu/development/flutter/bin/flutter test` |
| **Estimated runtime** | ~20 seconds |

---

## Sampling Rate

- **After every task commit:** Run `/home/himanshu/development/flutter/bin/flutter test test/e2e/rich_text_e2e_test.dart`
- **After every plan wave:** Run `/home/himanshu/development/flutter/bin/flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green (369+ tests passing, 0 failures)
- **Max feedback latency:** 25 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | ENH-01 | — | Dual-format Delta+HTML persistence & legacy fallback | unit/e2e | `/home/himanshu/development/flutter/bin/flutter test test/e2e/rich_text_e2e_test.dart --name "Dual-Format\|F19"` | ✅ | ⬜ pending |
| 02-01-02 | 01 | 1 | ENH-01 | — | Auto-detect legacy plain text/markdown on editor open | widget/e2e | `/home/himanshu/development/flutter/bin/flutter test test/e2e/rich_text_e2e_test.dart --name "Upgrade"` | ✅ | ⬜ pending |
| 02-02-01 | 02 | 2 | ENH-01 | — | Categorized LaTeX palette (Algebra, Calculus, Greek, Matrices, Symbols) | widget/e2e | `/home/himanshu/development/flutter/bin/flutter test test/e2e/rich_text_e2e_test.dart --name "Equation"` | ✅ | ⬜ pending |
| 02-02-02 | 02 | 2 | ENH-01 | — | Native canvas math rendering with theme contrast | widget/e2e | `/home/himanshu/development/flutter/bin/flutter test test/e2e/rich_text_e2e_test.dart --name "LaTeX"` | ✅ | ⬜ pending |
| 02-03-01 | 03 | 2 | ENH-01 | T-02-01 | Upload diagram SVG/PNG to Firebase Storage CDN (`/diagrams/`) | unit/e2e | `/home/himanshu/development/flutter/bin/flutter test test/e2e/rich_text_e2e_test.dart --name "Diagram"` | ✅ | ⬜ pending |
| 02-03-02 | 03 | 2 | ENH-01 | — | Full-screen preview, replace canvas, and delete diagram cards | widget/e2e | `/home/himanshu/development/flutter/bin/flutter test test/e2e/rich_text_e2e_test.dart --name "Whiteboard"` | ✅ | ⬜ pending |
| 02-04-01 | 04 | 3 | ENH-01 | — | Visual table builder dialog (up to 20x20) with header toggle | widget/e2e | `/home/himanshu/development/flutter/bin/flutter test test/e2e/rich_text_e2e_test.dart --name "Table"` | ✅ | ⬜ pending |
| 02-04-02 | 04 | 3 | ENH-01 | — | Horizontally scrollable mobile table card with shadow cues | widget/e2e | `/home/himanshu/development/flutter/bin/flutter test test/e2e/rich_text_e2e_test.dart --name "Table"` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing test infrastructure in `test/e2e/rich_text_e2e_test.dart` and `test/e2e/harness/` covers all phase requirements. No framework installation needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real stylus touch input on mobile device | ENH-01 | Touch hardware latency and Apple Pencil / S-Pen palm rejection | Open editor on physical tablet, tap diagram icon, draw handwriting sample with stylus, verify palm rejection. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 25s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-09-20
