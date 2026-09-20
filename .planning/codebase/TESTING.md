---
last_mapped_commit: d2baf761977299b062531946d76c4011f4595d73
last_mapped_at: 2026-09-20
---
# Testing Patterns

**Analysis Date:** 2026-09-20

## Test Framework

**Runner:**

- `flutter_test` (Flutter SDK built-in test runner)
- Config: `pubspec.yaml` under `dev_dependencies`

**Assertion Library:**

- `package:flutter_test/flutter_test.dart` (`expect`, `isTrue`, `isFalse`, `equals`, `isNull`, `isNotNull`, `isEmpty`, `hasLength`, `throwsA`)

**Run Commands:**

```bash
flutter test                                   # Run all unit, widget, and E2E tests
flutter test test/unit_test.dart               # Run primary regression unit test suite
flutter test test/e2e/                         # Run all end-to-end integration scenarios
flutter test test/unit/study_m2_test.dart      # Run specific study milestone unit tests
flutter test test/widget/                      # Run widget UI component tests
flutter test --coverage                        # Generate lcov coverage file in coverage/lcov.info
```

## Test File Organization

**Location:**

- Dedicated `test/` directory at project root, mirrored into functional subdirectories:

```
test/
├── e2e/                             # End-to-end scenario verification
│   ├── harness/                     # Mock infrastructure and fake service providers
│   │   ├── e2e_harness.dart         # Master setup/reset harness and baseline data seeder
│   │   ├── fake_firebase_auth.dart  # In-memory mock authentication provider
│   │   ├── fake_firebase_firestore.dart # In-memory Firestore with document/collection maps
│   │   └── fake_url_launcher.dart   # Fake platform launcher intercepting external URLs
│   ├── course_schedule_e2e_test.dart
│   ├── cross_feature_e2e_test.dart
│   ├── pdf_viewer_e2e_test.dart
│   ├── performance_dashboard_e2e_test.dart
│   ├── progress_e2e_test.dart
│   ├── rich_text_e2e_test.dart
│   ├── store_e2e_test.dart
│   ├── study_e2e_test.dart
│   ├── study_room_tab_selection_test.dart
│   └── study_section_restructure_e2e_test.dart
├── unit/                            # Unit tests for domain services and algorithms
│   ├── folder_copy_paste_delete_test.dart
│   ├── scheduler_milestone1_test.dart
│   └── study_m2_test.dart
├── widget/                          # Widget render and interaction tests
│   └── live_classes_section_test.dart
└── unit_test.dart                   # Comprehensive master unit test suite (1,344 lines)
```

**Naming:**

- All test files must end with `_test.dart`.

## Test Structure

**Suite Organization:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';

void main() {
  group('StudyLecture Unit Tests', () {
    test('StudyLecture.fromMap deserializes double durationSeconds safely', () {
      final Map<String, dynamic> data = {
        'title': 'Test Lecture',
        'durationSeconds': 120.5,
      };

      final lecture = StudyLecture.fromMap(data, 'lect_123');

      expect(lecture.id, 'lect_123');
      expect(lecture.title, 'Test Lecture');
      expect(lecture.duration!.inSeconds, 120);
    });

    test('StudyLecture.copyWith works correctly', () {
      const original = StudyLecture(
        id: '1',
        title: 'Original',
        videoUrl: 'original_url',
      );

      final modified = original.copyWith(title: 'Modified');

      expect(modified.id, '1');
      expect(modified.title, 'Modified');
    });
  });
}
```

## Mocking

**Framework & Approach:**

- Rather than heavy reflection-based mocking packages (like Mockito with code generation), the project uses lightweight, hand-crafted in-memory fakes extending `Fake`:
  - `FakeFirebaseFirestore` (`test/e2e/harness/fake_firebase_firestore.dart`)
  - `FakeFirebaseAuth` (`test/e2e/harness/fake_firebase_auth.dart`)
  - `FakeUrlLauncher` (`test/e2e/harness/fake_url_launcher.dart`)
- Mocks are injected via the testable dependency injection hooks on `EduverseFirebase`:

```dart
E2EHarness().setup();
// Injects fakes:
EduverseFirebase.mockFirestore = FakeFirebaseFirestore();
EduverseFirebase.mockAuth = FakeFirebaseAuth();
UrlLauncherPlatform.instance = FakeUrlLauncher();
```

**What to Mock:**

- Firebase cloud network connections (Firestore queries, auth state changes, storage uploads)
- Hardware-specific platform channels (URL launcher, camera/file pickers, screen protector)
- Payment gateways (Razorpay SDK)

**What NOT to Mock:**

- Domain entity models and serialization logic (`StudyLecture.fromMap`, `CartItem.toJson`)
- Business pricing calculations, discount deduplication, and promo code verification algorithms
- In-memory data transformations in repositories

## Fixtures and Factories

**Test Harness Data Seeding (`test/e2e/harness/e2e_harness.dart`):**

```dart
final harness = E2EHarness();
harness.setup();
harness.authenticateUser(uid: 'student_1', email: 'student@eduverse.com');
harness.seedBaselineData(); // Populates course_1, course_2, ebooks, test series into fake Firestore
```

## Common Testing Patterns

**Async Testing & Stream Verification:**

```dart
test('getEnrolledBatches returns batches for authenticated student', () async {
  final batchesStream = repository.getEnrolledBatches('user_1');
  final batches = await batchesStream.first;
  expect(batches, isNotEmpty);
  expect(batches.first.courseId, 'course_1');
});
```

**Widget Testing with Injected Providers:**

```dart
testWidgets('renders live classes section when stream emits active class', (WidgetTester tester) async {
  final fakeRepo = FakeStudyRepository();
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LiveClassesSection(repository: fakeRepo),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('Live Now'), findsOneWidget);
});
```

---

*Testing analysis: 2026-09-20*
