# E2E Test Infra: Comprehensive Rich Text Editing System

## Test Philosophy
- Opaque-box, requirement-driven. No dependency on implementation design.
- Methodology: Category-Partition + BVA + Pairwise + Workload Testing.

## Feature Inventory
| # | Feature | Source (requirement) | Tier 1 | Tier 2 | Tier 3 |
|---|---------|---------------------|:------:|:------:|:------:|
| 1 | Text Formatting | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ |
| 2 | Find & Replace | ORIGINAL_REQUEST §R4 | 5 | 5 | ✓ |
| 3 | Image Insertion | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ |
| 4 | Editable Tables | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ |
| 5 | Equation Builder | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ |
| 6 | Whiteboard Diagrams | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ |
| 7 | Dual-Format Storage | ORIGINAL_REQUEST §R3 | 5 | 5 | ✓ |
| 8 | Student Viewer & Compatibility | ORIGINAL_REQUEST §R3 | 5 | 5 | ✓ |

## Test Architecture
- Test runner: `flutter test test/e2e/rich_text_e2e_test.dart`
- Test case format: Flutter Widget testing using `E2EHarness` to verify Firestore writes, Storage uploads, and UI/WebView interactions.
- Directory layout:
  - Tests: `test/e2e/rich_text_e2e_test.dart`
  - Mock Harness: `test/e2e/harness/e2e_harness.dart`

## Real-World Application Scenarios (Tier 4)
| # | Scenario | Features Exercised | Complexity |
|---|----------|--------------------|------------|
| 1 | Admin creates a new course test with structured paragraphs, formats fonts/colors, inserts an equation and an interactive table, triggers auto-save, and verifies student side renders exactly. | F1, F4, F5, F7, F8 | High |
| 2 | Admin creates feed item with an inline diagram, draws whiteboard shapes, exports diagram to Firebase Storage as SVG, embeds SVG, saves, and student viewer loads the SVG correctly. | F1, F6, F7, F8 | High |

## Coverage Thresholds
- Tier 1: ≥5 per feature
- Tier 2: ≥5 per feature (where boundaries exist)
- Tier 3: pairwise coverage of major feature interactions
- Tier 4: ≥5 realistic application scenarios
