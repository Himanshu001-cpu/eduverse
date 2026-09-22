---
last_mapped_commit: d2baf761977299b062531946d76c4011f4595d73
last_mapped_at: 2026-09-20
---
# Coding Conventions

**Analysis Date:** 2026-09-20

## Naming Patterns

**Files:**

- Dart files strictly use `snake_case.dart` (e.g. `main_navigation_page.dart`, `study_repository_impl.dart`, `lecture_player_screen.dart`).
- Screen widgets are suffixed with either `_screen.dart` or `_page.dart`.
- Reusable components are suffixed with `_widget.dart`, `_card.dart`, `_tile.dart`, or `_dialog.dart`.
- Data entities are suffixed with `_model.dart` or `_models.dart`.
- TypeScript backend files use `camelCase.ts` or `index.ts` (e.g. `functions/src/index.ts`).

**Classes & Types:**

- PascalCase for all classes, enums, typedefs, and mixins:
  - `StudyBatch`, `EduverseFirebase`, `LecturePlayerScreen`, `FirebaseAdminService`, `E2EHarness`
  - Abstract repository interfaces start with `I`: `IStudyRepository`
  - Implementations end with `Impl`: `StudyRepositoryImpl`
  - Fake test classes start with `Fake` or `Mock`: `FakeFirebaseFirestore`, `MockFirestore`

**Functions & Methods:**

- camelCase for functions and methods:
  - `getEnrolledBatches()`, `commitInChunks()`, `isApplicableToItem()`, `updateScreenProtection()`
  - Boolean getters start with `is` or `has`: `isAdmin`, `isLive`, `hasMaps`

**Variables & Properties:**

- camelCase for local variables and class members:
  - `courseId`, `seatsLeft`, `combinationPackId`, `enrolledCourses`
  - Private variables and methods are prefixed with an underscore (`_`):
    - `_firestore`, `_authService`, `_lastUserId`, `_protectionSessionId`

**Constants:**

- `lowerCamelCase` or `kCamelCase` for Dart constants: `kIsWeb`, `_defaultDuration`
- `SCREAMING_SNAKE_CASE` for environment variable names in TypeScript/Node: `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`

## Code Style

**Formatting:**

- Dart: Formatted using standard `dart format` rules:
  - Indentation: 2 spaces (no tabs)
  - Semicolons: Required at the end of statements
  - Trailing commas: Universally placed at the end of argument lists and widget trees to enable optimal multi-line auto-formatting
  - Line width: Recommended 80–100 characters
- TypeScript: Configured in `functions/.eslintrc.js`:
  - Indentation: 2 spaces (`"indent": ["error", 2]`)
  - Quotes: Double quotes (`"quotes": ["error", "double"]`)
  - Semicolons: Required

**Linting:**

- Client: `flutter_lints: ^6.0.0` declared in `pubspec.yaml`
- Backend: ESLint extending `eslint:recommended`, `google`, and `plugin:@typescript-eslint/recommended` in `functions/.eslintrc.js`

## Import Organization

**Order:**

1. Dart core libraries (`dart:io`, `dart:convert`, `dart:async`)
2. Flutter framework packages (`package:flutter/material.dart`, `package:flutter/foundation.dart`)
3. Third-party packages (`package:cloud_firestore/...`, `package:provider/...`, `package:hive/...`)
4. Eduverse project absolute packages (`package:eduverse/core/...`, `package:eduverse/study/...`)
5. Relative imports within the same feature folder (`./widgets/course_card.dart`, `../models/admin_models.dart`)

**Path Aliases:**

- Standard Flutter package scheme: `package:eduverse/...`
- Relative imports are used for closely co-located files within a single feature directory

## Error Handling

**Strategy:**

- Wrap network and database operations in `try / catch` blocks with granular error reporting.
- Fail soft on non-critical platform services (e.g. Push notifications during app start in `lib/main.dart:28-30` caught with `.catchError((e) { debugPrint('FCM initialization error (non-fatal): $e'); })`).
- Present informative, actionable UI error screens with retry callbacks (`_ErrorScreen` in `lib/auth/auth_wrapper.dart:203`).
- Fall back safely to secure defaults (e.g. if `isAdmin()` network check fails, screenshot protection remains enabled).

**Batch Chunking Pattern:**

- Firestore has a hard limit of 500 operations per atomic batch write.
- All bulk admin operations MUST use `commitInChunks(operations)` in `lib/admin/services/firebase_admin_service.dart:782` to automatically slice writes into safe batches of 400 operations:

```dart
Future<void> commitInChunks(List<void Function(WriteBatch)> operations, {int chunkSize = 400}) async {
  for (var i = 0; i < operations.length; i += chunkSize) {
    final batch = db.batch();
    final chunk = operations.sublist(i, (i + chunkSize > operations.length) ? operations.length : i + chunkSize);
    for (var op in chunk) {
      op(batch);
    }
    await batch.commit();
  }
}
```

## Logging

**Client Framework:**

- Use `debugPrint('MESSAGE')` instead of raw `print()` statements to prevent stdout bottlenecks on release Android logcats.
- Diagnostic tags used consistently: `debugPrint('HIVE_DIAGNOSTIC: ...')`, `debugPrint('FCM initialization error: ...')`.

**Backend Framework:**

- Use `functions.logger.info()`, `console.log()`, `console.warn()`, and `console.error()` in `functions/src/index.ts`.

## Comments & Documentation

**Guidelines:**

- Triple-slash doc comments (`///`) for public classes, top-level services, and shared widgets explaining intent and lifecycle constraints (e.g. `/// Wrapper widget that manages authentication state...`).
- Numbered section comments (`// 1. Resolve all items...`, `// 2. Process each course enrollment...`) within multi-step transaction handlers.

## Model Design & Immutability

**Serialization Conventions:**

- Models define explicit `toMap()` / `toJson()` maps and `fromMap(Map<String, dynamic> data, String id)` / `fromJson(Map<String, dynamic> json)` factory constructors.
- Deserialization methods defensively handle type ambiguity (e.g. converting both `int` and `double` values safely to `double` via `(data['durationSeconds'] as num?)?.toDouble()`).
- Immutable models provide a `copyWith()` method returning a new instance with updated properties.

---

*Convention analysis: 2026-09-20*
