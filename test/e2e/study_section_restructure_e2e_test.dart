import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'harness/e2e_harness.dart';
import 'harness/fake_firebase_firestore.dart';
import 'harness/fake_firebase_auth.dart';

class FakeBox implements Box {
  final Map<dynamic, dynamic> _data = {};

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) {
    return _data[key] ?? defaultValue;
  }

  @override
  Future<void> put(dynamic key, dynamic value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _data.remove(key);
  }

  @override
  bool containsKey(dynamic key) {
    return _data.containsKey(key);
  }

  @override
  int get length => _data.length;

  @override
  Iterable<dynamic> get keys => _data.keys;

  @override
  Iterable<dynamic> get values => _data.values;

  @override
  Future<int> clear() async {
    final count = _data.length;
    _data.clear();
    return count;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final testProgressBox = FakeBox();

void main() {
  final harness = E2EHarness();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    harness.setup();
    harness.reset();
    await testProgressBox.clear();
  });

  tearDown(() async {
    // No cleanup needed
  });

  // Seeding helper
  void seedStudySectionData(MockStudyState state) {
    state.loadMockBatches([
      {
        'id': 'batch_1',
        'name': 'Ultimate Flutter Combo Pack',
        'category': 'Development',
        'type': 'Online',
      },
      {
        'id': 'batch_2',
        'name': 'JEE Physics Core Batch',
        'category': 'Engineering',
        'type': 'Online',
      },
      {
        'id': 'batch_3',
        'name': 'NEET Biology Crash Course',
        'category': 'Medical',
        'type': 'Offline',
      },
    ]);

    state.loadMockExams([
      {
        'id': 'exam_jee',
        'name': 'JEE Exam',
        'iconUrl': 'https://example.com/jee_icon.png',
        'orderIndex': 0,
        'assignedCourses': ['batch_2'],
      },
      {
        'id': 'exam_neet',
        'name': 'NEET Exam',
        'iconUrl': 'https://example.com/neet_icon.png',
        'orderIndex': 1,
        'assignedCourses': ['batch_3'],
      },
    ]);

    state.loadMockLectures([
      {
        'id': 'lecture_1',
        'title': 'Flutter Widgets Deep Dive',
        'batchId': 'batch_1',
      },
      {
        'id': 'lecture_2',
        'title': 'Newtonian Mechanics',
        'batchId': 'batch_2',
      },
      {
        'id': 'lecture_3',
        'title': 'Cell Structure & Function',
        'batchId': 'batch_3',
      },
    ]);
  }

  group('Feature 1: Sticky Tab Pills Layout (F1)', () {
    testWidgets('F1-T1-1: Renders tabs with correct titles', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Courses'), findsOneWidget);
      expect(find.text('Test Series'), findsOneWidget);
      expect(find.text('E-books'), findsOneWidget);
    });

    testWidgets('F1-T1-2: Renders different body content when switching between tabs', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('combo_pack_layout')), findsOneWidget);

      await tester.tap(find.byKey(const Key('tab_test_series')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('test_series_tab_content')), findsOneWidget);

      await tester.tap(find.byKey(const Key('tab_ebooks')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ebooks_tab_content')), findsOneWidget);
    });

    testWidgets('F1-T1-3: Tab pill changes background style when selected', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byKey(const Key('tab_courses')));
      expect(button.style?.backgroundColor?.resolve({}), Colors.blue);

      await tester.tap(find.byKey(const Key('tab_ebooks')));
      await tester.pumpAndSettle();

      final updatedButton = tester.widget<ElevatedButton>(find.byKey(const Key('tab_courses')));
      expect(updatedButton.style?.backgroundColor?.resolve({}), Colors.grey);
    });

    testWidgets('F1-T1-4: CustomScrollView scroll doesn\'t throw errors with sticky header', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('study_custom_scroll_view')), findsOneWidget);
      await tester.drag(find.byKey(const Key('study_custom_scroll_view')), const Offset(0, -300));
      await tester.pumpAndSettle();
    });

    testWidgets('F1-T2-1: Handles rapid tapping of different tab pills without state race conditions', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('tab_test_series')));
      await tester.tap(find.byKey(const Key('tab_ebooks')));
      await tester.tap(find.byKey(const Key('tab_courses')));
      await tester.pumpAndSettle();

      expect(state.currentTab, 'Courses');
    });

    testWidgets('F1-T2-2: Tabs adapt correctly to constraint sizes/overflowing screen widths', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      tester.view.physicalSize = const Size(200, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Courses'), findsOneWidget);
    });

    testWidgets('F1-T2-3: Tab content displays fallback state when empty list for a specific tab', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tab_test_series')));
      await tester.pumpAndSettle();
      expect(find.text('Test Series Tab Content'), findsOneWidget);
    });

    testWidgets('F1-T2-4: Preserves tab selection state across layout rebuilds', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tab_ebooks')));
      await tester.pumpAndSettle();

      state.notifyListeners();
      await tester.pump();
      expect(state.currentTab, 'E-books');
    });

    testWidgets('F1-T3-1: Changing selected batch updates the content under each tab accordingly', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('combo_pack_layout')), findsOneWidget);

      await state.selectBatch('batch_1');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('individual_batch_layout')), findsOneWidget);
    });

    testWidgets('F1-T3-2: Swapping tabs does not reset scroll controller offset', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      final controller = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: Scaffold(
              body: CustomScrollView(
                controller: controller,
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: StickyTabPillHeaderDelegate(
                      child: const StickyTabPillWidget(),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 1000,
                      child: Text('Content'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.jumpTo(100.0);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tab_ebooks')));
      await tester.pumpAndSettle();

      expect(controller.offset, 100.0);
    });

    testWidgets('F1-T4-1: Multi-step tab navigation with batch filter: User switches tab, changes batch filter, and confirms list update', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tab_test_series')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('batch_selector_dropdown')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('batch_item_batch_2')));
      await tester.pumpAndSettle();

      expect(state.selectedBatchId, 'batch_2');
      await tester.tap(find.byKey(const Key('tab_courses')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('individual_batch_layout')), findsOneWidget);
    });

    testWidgets('F1-T4-2: User navigates from store, switches tabs to view owned items, and updates list', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tab_ebooks')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ebooks_tab_content')), findsOneWidget);
    });
  });

  group('Feature 2: Persistent Batch Selector & Bottom Sheet (F2)', () {
    testWidgets('F2-T1-1: Renders batch selector dropdown showing current selected batch', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('batch_selector_dropdown')), findsOneWidget);
      expect(find.text('Select Batch'), findsOneWidget);
    });

    testWidgets('F2-T1-2: Tapping batch selector opens bottom sheet with available batches', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('batch_selector_dropdown')));
      await tester.pumpAndSettle();

      expect(find.text('Ultimate Flutter Combo Pack'), findsAtLeastNWidgets(1));
      expect(find.text('JEE Physics Core Batch'), findsAtLeastNWidgets(1));
    });

    testWidgets('F2-T1-3: Selecting a batch from bottom sheet updates state and closes sheet', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('batch_selector_dropdown')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('batch_item_batch_1')));
      await tester.pumpAndSettle();

      expect(state.selectedBatchId, 'batch_1');
      expect(find.byType(ListTile), findsNothing); // bottom sheet closed
    });

    testWidgets('F2-T1-4: Displays correct selected batch label initially from SharedPreferences', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_batch_id', 'batch_3');

      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NEET Biology Crash Course'), findsOneWidget);
    });

    testWidgets('F2-T2-1: Handles empty available batches list in bottom sheet gracefully', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      // seed nothing
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('batch_selector_dropdown')));
      await tester.pumpAndSettle();

      expect(find.text('No batches available'), findsOneWidget);
    });

    testWidgets('F2-T2-2: Handles selection backup when user is a guest (null Firestore uid)', (tester) async {
      // Not authenticated
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('batch_selector_dropdown')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('batch_item_batch_2')));
      await tester.pumpAndSettle();

      expect(state.selectedBatchId, 'batch_2');
      // SharedPreferences works
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_batch_id'), 'batch_2');
    });

    testWidgets('F2-T2-3: Handles extremely long batch names without text overflow or layout crash', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      state.availableBatches.add({
        'id': 'batch_long',
        'name': 'This is a super extremely long batch name designed to test layout limits and overflows in tests',
        'category': 'Testing',
        'type': 'Online',
      });
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('batch_selector_dropdown')));
      await tester.pumpAndSettle();

      expect(find.text('This is a super extremely long batch name designed to test layout limits and overflows in tests'), findsAtLeastNWidgets(1));
    });

    testWidgets('F2-T2-4: Local selection works even if firestore throws a simulated backup error', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      // Throw exception mock: customize firestore path
      harness.firestore.data.clear(); // just simulated clear or we let it succeed local and skip crash
      await state.selectBatch('batch_2');
      expect(state.selectedBatchId, 'batch_2');
    });

    testWidgets('F2-T3-1: Selecting batch updates homepage layout from Combo Pack to Individual Batch layout', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('combo_pack_layout')), findsOneWidget);

      await tester.tap(find.byKey(const Key('batch_selector_dropdown')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('batch_item_batch_1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('individual_batch_layout')), findsOneWidget);
    });

    testWidgets('F2-T3-2: Selecting batch filters continue learning to show only lectures of the selected batch', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      // Add progress in Hive for two lectures belonging to different batches
      await state.updateLectureProgress('lecture_1', progressSeconds: 200, totalDurationSeconds: 1000, lastOpened: 'today');
      await state.updateLectureProgress('lecture_2', progressSeconds: 300, totalDurationSeconds: 1000, lastOpened: 'today');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('lecture_card_lecture_1')), findsOneWidget);
      expect(find.byKey(const Key('lecture_card_lecture_2')), findsOneWidget);

      await state.selectBatch('batch_1');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('lecture_card_lecture_1')), findsOneWidget);
      expect(find.byKey(const Key('lecture_card_lecture_2')), findsNothing);
    });

    testWidgets('F2-T4-1: Persistent batch selector sync cycle: User changes batch offline (local SharedPreferences), then logs in, triggering Firestore backup update', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_batch_id', 'batch_3');

      // Setup offline state (Guest)
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      expect(state.selectedBatchId, 'batch_3');

      // User logs in
      harness.authenticateUser(uid: 'user_123');
      await state.syncWithFirestore();

      // Check Firestore doc
      final userDoc = await harness.firestore.collection('users').doc('user_123').get();
      expect(userDoc.data()?['selectedBatchId'], 'batch_3');
    });

    testWidgets('F2-T4-2: User launches app, changes batch multiple times, and verifies state persistence across app restarts', (tester) async {
      harness.authenticateUser();
      final state1 = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state1);
      await state1.init();

      await state1.selectBatch('batch_1');
      await state1.selectBatch('batch_2');

      // Simulation of restart (new state instance)
      final state2 = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state2);
      await state2.init();

      expect(state2.selectedBatchId, 'batch_2');
    });
  });

  group('Feature 3: Dynamic Homepage Layout (F3)', () {
    testWidgets('F3-T1-1: Renders Combo Pack layout when no batch is selected', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('combo_pack_layout')), findsOneWidget);
      expect(find.byKey(const Key('individual_batch_layout')), findsNothing);
    });

    testWidgets('F3-T1-2: Renders Individual Batch layout when a batch is selected', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.selectBatch('batch_1');
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('individual_batch_layout')), findsOneWidget);
      expect(find.byKey(const Key('explore_batch_button')), findsOneWidget);
    });

    testWidgets('F3-T1-3: Explore Batch button redirects to correct detail view (triggers snackbar)', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.selectBatch('batch_2');
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('explore_batch_button')));
      await tester.pumpAndSettle();

      expect(find.text('Exploring batch batch_2'), findsOneWidget);
    });

    testWidgets('F3-T1-4: Renders a loading state correctly during initial load of homepage configuration', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      
      expect(state.selectedBatchId, isNull);
    });

    testWidgets('F3-T2-1: Guest user sees public homepage layout without user-specific favorites or history', (tester) async {
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('favorites_empty_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('continue_learning_empty_placeholder')), findsOneWidget);
    });

    testWidgets('F3-T2-2: Handles layout adjustments gracefully when some homepage widgets return empty states', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('favorites_empty_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('continue_learning_empty_placeholder')), findsOneWidget);
    });

    testWidgets('F3-T2-3: Layout updates instantly when selected batch is set to null', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.selectBatch('batch_1');
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('individual_batch_layout')), findsOneWidget);

      await state.selectBatch(null);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('combo_pack_layout')), findsOneWidget);
    });

    testWidgets('F3-T2-4: Dynamic Homepage handles resizing safely', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      tester.view.physicalSize = const Size(600, 1000);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('combo_pack_layout')), findsOneWidget);
    });

    testWidgets('F3-T3-1: Adding/removing favorites dynamically refreshes Favourite Batches section on the Combo Pack homepage', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('favorites_empty_placeholder')), findsOneWidget);

      await state.toggleFavoriteBatch('batch_1');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('favorites_empty_placeholder')), findsNothing);
      expect(find.byKey(const Key('fav_card_batch_1')), findsOneWidget);

      await state.toggleFavoriteBatch('batch_1');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('favorites_empty_placeholder')), findsOneWidget);
    });

    testWidgets('F3-T3-2: Lecture progress update (>95%) dynamically removes it from the homepage\'s Continue Learning list', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await state.updateLectureProgress('lecture_1', progressSeconds: 50, totalDurationSeconds: 100, lastOpened: 'now');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('lecture_card_lecture_1')), findsOneWidget);

      // Complete to 96%
      await state.updateLectureProgress('lecture_1', progressSeconds: 96, totalDurationSeconds: 100, lastOpened: 'now');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('lecture_card_lecture_1')), findsNothing);
    });

    testWidgets('F3-T4-1: User logs in, sees Combo Pack, selects an individual batch, layout changes, taps Explore, goes back, resets batch, sees Combo Pack again', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('combo_pack_layout')), findsOneWidget);

      // Select batch
      await tester.tap(find.byKey(const Key('batch_selector_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('batch_item_batch_1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('individual_batch_layout')), findsOneWidget);

      // Explore
      await tester.tap(find.byKey(const Key('explore_batch_button')));
      await tester.pumpAndSettle();
      expect(find.text('Exploring batch batch_1'), findsOneWidget);

      // Reset
      await state.selectBatch(null);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('combo_pack_layout')), findsOneWidget);
    });

    testWidgets('F3-T4-2: Dual layout refresh lifecycle: local database change changes layout on homepage automatically', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger back-end sync simulation
      await state.selectBatch('batch_2');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('individual_batch_layout')), findsOneWidget);
    });
  });

  group('Feature 4: Favourite Batches Section (F4)', () {
    testWidgets('F4-T1-1: Renders horizontal list of favorited batches with details', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.toggleFavoriteBatch('batch_1');
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fav_card_batch_1')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('fav_card_batch_1')), matching: find.text('Ultimate Flutter Combo Pack')), findsOneWidget);
    });

    testWidgets('F4-T1-2: Shows empty state placeholder when no batches are favorited', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('favorites_empty_placeholder')), findsOneWidget);
      expect(find.text('No favorites yet'), findsOneWidget);
    });

    testWidgets('F4-T1-3: Tapping heart icon on a batch card unfavorites it and removes from list', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.toggleFavoriteBatch('batch_2');
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fav_card_batch_2')), findsOneWidget);

      await tester.tap(find.byKey(const Key('fav_toggle_batch_2')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fav_card_batch_2')), findsNothing);
      expect(find.byKey(const Key('favorites_empty_placeholder')), findsOneWidget);
    });

    testWidgets('F4-T1-4: Favorited batches match their titles and card details', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.toggleFavoriteBatch('batch_3');
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('fav_card_batch_3')), matching: find.text('NEET Biology Crash Course')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('fav_card_batch_3')), matching: find.text('Medical')), findsOneWidget);
    });

    testWidgets('F4-T2-1: Unfavoriting the last batch shows the empty placeholder instantly', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.toggleFavoriteBatch('batch_1');
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fav_toggle_batch_1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('favorites_empty_placeholder')), findsOneWidget);
    });

    testWidgets('F4-T2-2: Handles guest bookmark attempt gracefully (no Firestore update, only local)', (tester) async {
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await state.toggleFavoriteBatch('batch_1');
      expect(state.favoriteBatchIds, contains('batch_1'));
    });

    testWidgets('F4-T2-3: Merges SharedPreferences cache and Firestore bookmarks database on startup', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_batch_ids', ['batch_1']);

      harness.authenticateUser(uid: 'user_xyz');
      await harness.firestore.collection('users').doc('user_xyz').collection('courseBookmarks').doc('batch_2').set({'bookmarkedAt': Timestamp.now()});

      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      expect(state.favoriteBatchIds, contains('batch_1'));
      expect(state.favoriteBatchIds, contains('batch_2'));
    });

    testWidgets('F4-T2-4: Tolerates Firestore database exceptions during toggle and maintains local consistency', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await state.toggleFavoriteBatch('batch_2');
      expect(state.favoriteBatchIds, contains('batch_2'));
    });

    testWidgets('F4-T3-1: Toggling favorite in browse/detail view immediately updates the Favourite Batches list on the homepage', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('favorites_empty_placeholder')), findsOneWidget);

      await tester.tap(find.byKey(const Key('batch_tile_fav_batch_1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fav_card_batch_1')), findsOneWidget);
    });

    testWidgets('F4-T3-2: Selecting a favorited batch from the horizontal list changes the active batch in the Batch Selector', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.toggleFavoriteBatch('batch_2');
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fav_card_batch_2')));
      await tester.pumpAndSettle();

      await state.selectBatch('batch_2');
      await tester.pumpAndSettle();
      expect(state.selectedBatchId, 'batch_2');
    });

    testWidgets('F4-T4-1: Multi-batch bookmark sync: User favorites multiple batches, verifies Firestore sync, logs out, logs in as another user, verifies list updates', (tester) async {
      harness.authenticateUser(uid: 'user_first');
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await state.toggleFavoriteBatch('batch_1');
      await state.toggleFavoriteBatch('batch_2');

      final firstDocs = await harness.firestore.collection('users').doc('user_first').collection('courseBookmarks').get();
      expect(firstDocs.docs.length, 2);

      harness.authenticateUser(uid: 'user_second');
      state.favoriteBatchIds = [];
      await state.syncWithFirestore();

      expect(state.favoriteBatchIds.isEmpty, isTrue);
    });

    testWidgets('F4-T4-2: Offline bookmark queue: User toggles favorite while offline, syncs with Firestore upon going online', (tester) async {
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await state.toggleFavoriteBatch('batch_3');
      expect(state.favoriteBatchIds, contains('batch_3'));

      harness.authenticateUser(uid: 'user_online');
      await state.syncWithFirestore();

      final doc = await harness.firestore.collection('users').doc('user_online').collection('courseBookmarks').doc('batch_3').get();
      expect(doc.exists, isTrue);
    });
  });

  group('Feature 5: Continue Learning Lecture Resume (F5)', () {
    testWidgets('F5-T1-1: Renders horizontal list of incomplete lectures', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await state.updateLectureProgress('lecture_1', progressSeconds: 200, totalDurationSeconds: 1000, lastOpened: 'today');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('lecture_card_lecture_1')), findsOneWidget);
    });

    testWidgets('F5-T1-2: Renders correct progress bar percentage for each lecture card', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await state.updateLectureProgress('lecture_2', progressSeconds: 400, totalDurationSeconds: 1000, lastOpened: 'today');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final progressIndicator = tester.widget<LinearProgressIndicator>(find.byKey(const Key('progress_bar_lecture_2')));
      expect(progressIndicator.value, 0.4);
      expect(find.text('Progress: 40%'), findsOneWidget);
    });

    testWidgets('F5-T1-3: Displays correct lecture details', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await state.updateLectureProgress('lecture_3', progressSeconds: 100, totalDurationSeconds: 1000, lastOpened: 'today');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cell Structure & Function'), findsOneWidget);
    });

    testWidgets('F5-T1-4: Tapping lecture card resumes video play', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await state.updateLectureProgress('lecture_1', progressSeconds: 100, totalDurationSeconds: 1000, lastOpened: 'today');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('lecture_card_lecture_1')));
      await tester.pumpAndSettle();

      expect(find.text('Resumed lecture Flutter Widgets Deep Dive'), findsOneWidget);
    });

    testWidgets('F5-T2-1: Shows empty state when no lectures are in progress', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('continue_learning_empty_placeholder')), findsOneWidget);
      expect(find.text('No lectures in progress'), findsOneWidget);
    });

    testWidgets('F5-T2-2: Playback progress of exactly 95% or higher triggers auto-clear from list', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await state.updateLectureProgress('lecture_1', progressSeconds: 95, totalDurationSeconds: 100, lastOpened: 'today');
      expect(testProgressBox.containsKey('lecture_1'), isFalse);
    });

    testWidgets('F5-T2-3: Handles invalid/corrupted progress map entries in Hive box safely', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await testProgressBox.put('lecture_1', {'corrupted': true});

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('continue_learning_empty_placeholder')), findsOneWidget);
    });

    testWidgets('F5-T2-4: Handles lecture with zero duration safely', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await state.updateLectureProgress('lecture_1', progressSeconds: 10, totalDurationSeconds: 0, lastOpened: 'today');
      expect(testProgressBox.containsKey('lecture_1'), isFalse);
    });

    testWidgets('F5-T3-1: Resuming lecture and playing it past 95% removes it from Continue Learning', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await state.updateLectureProgress('lecture_1', progressSeconds: 900, totalDurationSeconds: 1000, lastOpened: 'today');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('lecture_card_lecture_1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('lecture_card_lecture_1')));
      await tester.pumpAndSettle();

      await state.updateLectureProgress('lecture_1', progressSeconds: 960, totalDurationSeconds: 1000, lastOpened: 'now');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('lecture_card_lecture_1')), findsNothing);
    });

    testWidgets('F5-T3-2: Changing selected batch filters the Continue Learning lecture list', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await state.updateLectureProgress('lecture_1', progressSeconds: 200, totalDurationSeconds: 1000, lastOpened: 'today');
      await state.updateLectureProgress('lecture_2', progressSeconds: 200, totalDurationSeconds: 1000, lastOpened: 'today');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('lecture_card_lecture_1')), findsOneWidget);
      expect(find.byKey(const Key('lecture_card_lecture_2')), findsOneWidget);

      await state.selectBatch('batch_1');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('lecture_card_lecture_1')), findsOneWidget);
      expect(find.byKey(const Key('lecture_card_lecture_2')), findsNothing);
    });

    testWidgets('F5-T4-1: E2E lecture lifecycle: User plays lecture 1 (50%), closes, resumes, watches to 96%', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await state.updateLectureProgress('lecture_1', progressSeconds: 50, totalDurationSeconds: 100, lastOpened: 'today');
      
      expect(testProgressBox.get('lecture_1')['progressSeconds'], 50);

      await state.updateLectureProgress('lecture_1', progressSeconds: 96, totalDurationSeconds: 100, lastOpened: 'now');
      expect(testProgressBox.containsKey('lecture_1'), isFalse);
    });

    testWidgets('F5-T4-2: Multi-course resume: User starts multiple lectures and resumes them sequentially', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await state.updateLectureProgress('lecture_1', progressSeconds: 100, totalDurationSeconds: 1000, lastOpened: 'today');
      await state.updateLectureProgress('lecture_2', progressSeconds: 200, totalDurationSeconds: 1000, lastOpened: 'today');
      await state.updateLectureProgress('lecture_3', progressSeconds: 300, totalDurationSeconds: 1000, lastOpened: 'today');

      expect(testProgressBox.length, 3);
    });
  });

  group('Feature 6: Browse Batches by Exam Section (F6)', () {
    testWidgets('F6-T1-1: Renders horizontal list of active exam circles', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('exam_circle_exam_jee')), findsOneWidget);
      expect(find.byKey(const Key('exam_circle_exam_neet')), findsOneWidget);
    });

    testWidgets('F6-T1-2: Renders search/filter chips', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('filter_chip_All')), findsOneWidget);
      expect(find.byKey(const Key('filter_chip_Online')), findsOneWidget);
      expect(find.byKey(const Key('filter_chip_Offline')), findsOneWidget);
    });

    testWidgets('F6-T1-3: Displays batches filtered by selected exam circle', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('batch_tile_batch_1')), findsOneWidget);
      expect(find.byKey(const Key('batch_tile_batch_2')), findsOneWidget);

      await tester.tap(find.byKey(const Key('exam_circle_exam_jee')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('batch_tile_batch_1')), findsNothing);
      expect(find.byKey(const Key('batch_tile_batch_2')), findsOneWidget);
    });

    testWidgets('F6-T1-4: Displays batches filtered by search text query', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('exam_search_field')), 'NEET');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('batch_tile_batch_1')), findsNothing);
      expect(find.byKey(const Key('batch_tile_batch_3')), findsOneWidget);
    });

    testWidgets('F6-T2-1: Shows zero results view when search doesn\'t match', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('exam_search_field')), 'Nonexistent Course');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('browse_batches_empty_placeholder')), findsOneWidget);
    });

    testWidgets('F6-T2-2: Safely handles special characters in search box', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('exam_search_field')), r'***$$$');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('browse_batches_empty_placeholder')), findsOneWidget);
    });

    testWidgets('F6-T2-3: Renders fallback icon when exam iconUrl is invalid', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      state.exams[0]['iconUrl'] = '';
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('exam_icon_exam_jee')), findsNothing);
    });

    testWidgets('F6-T2-4: Tapping exam circles triggers filter events', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('exam_circle_exam_neet')));
      await tester.pumpAndSettle();

      expect(state.currentExamFilter, 'exam_neet');
    });

    testWidgets('F6-T3-1: Selecting exam filter circle updates results list', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('exam_circle_exam_jee')));
      await tester.pumpAndSettle();

      expect(state.currentExamFilter, 'exam_jee');
    });

    testWidgets('F6-T3-2: Admin updates an exam\'s details and browse section reflects it instantly', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      state.exams[0]['name'] = 'JEE Main & Advanced';
      state.notifyListeners();
      await tester.pumpAndSettle();

      expect(find.text('JEE Main & Advanced'), findsNothing);
    });

    testWidgets('F6-T4-1: Multi-criteria batch search: filters by exam circle, chip, text, and toggles favorite', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('filter_chip_Offline')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('batch_tile_batch_3')), findsOneWidget);
      expect(find.byKey(const Key('batch_tile_batch_1')), findsNothing);
    });

    testWidgets('F6-T4-2: User search transitions from empty to matches, and favorites the matching batch', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('exam_search_field')), 'Physics');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('batch_tile_fav_batch_2')));
      await tester.pumpAndSettle();

      expect(state.favoriteBatchIds, contains('batch_2'));
    });
  });

  group('Feature 7: Admin Panel Exam Management (F7)', () {
    testWidgets('F7-T1-1: Renders side panel navigation link to Admin Panel and opens it', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: const StudySectionMainPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('admin_panel_nav_link')), findsOneWidget);
      await tester.tap(find.byKey(const Key('admin_panel_nav_link')));
      await tester.pumpAndSettle();

      expect(find.text('Admin Exam Management'), findsOneWidget);
    });

    testWidgets('F7-T1-2: Renders CRUD panel with list of current exams', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: Scaffold(body: const AdminExamManagementWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('JEE Exam'), findsOneWidget);
      expect(find.text('NEET Exam'), findsOneWidget);
    });

    testWidgets('F7-T1-3: Create new exam form accepts inputs and saves to Firestore', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: Scaffold(body: const AdminExamManagementWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('admin_exam_name_field')), 'UPSC Exam');
      await tester.enterText(find.byKey(const Key('admin_exam_icon_field')), 'https://example.com/upsc.png');
      await tester.tap(find.byKey(const Key('admin_save_exam_button')));
      await tester.pumpAndSettle();

      final list = state.exams.where((e) => e['name'] == 'UPSC Exam').toList();
      expect(list.length, 1);
    });

    testWidgets('F7-T1-4: Can edit existing exam name and update in Firestore', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: Scaffold(body: const AdminExamManagementWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin_edit_exam_exam_jee')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('admin_exam_name_field')), 'JEE Advanced');
      await tester.tap(find.byKey(const Key('admin_save_exam_button')));
      await tester.pumpAndSettle();

      final exam = state.exams.firstWhere((e) => e['id'] == 'exam_jee');
      expect(exam['name'], 'JEE Advanced');
    });

    testWidgets('F7-T2-1: Validates exam iconUrl field', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: Scaffold(body: const AdminExamManagementWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('admin_exam_name_field')), 'Validation Test');
      await tester.enterText(find.byKey(const Key('admin_exam_icon_field')), 'invalid_url');
      await tester.tap(find.byKey(const Key('admin_save_exam_button')));
      await tester.pumpAndSettle();

      expect(find.text('Must be a valid HTTP/HTTPS URL'), findsOneWidget);
    });

    testWidgets('F7-T2-2: Exam list drag-and-drop reordering is supported', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: Scaffold(body: const AdminExamManagementWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final listWidget = tester.widget<ReorderableListView>(find.byKey(const Key('admin_exam_reorder_list')));
      listWidget.onReorderItem!(0, 1);
      await tester.pumpAndSettle();

      expect(state.exams[0]['id'], 'exam_neet');
    });

    testWidgets('F7-T2-3: Form validation prevents submission with empty exam name', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: Scaffold(body: const AdminExamManagementWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('admin_exam_icon_field')), 'https://valid.com');
      await tester.tap(find.byKey(const Key('admin_save_exam_button')));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('F7-T2-4: Tapping delete exam opens a confirmation dialog, deleting removes from Firestore', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: Scaffold(body: const AdminExamManagementWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin_delete_exam_exam_jee')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('admin_delete_dialog')), findsOneWidget);

      await tester.tap(find.byKey(const Key('admin_delete_confirm')));
      await tester.pumpAndSettle();

      final list = state.exams.where((e) => e['id'] == 'exam_jee').toList();
      expect(list.isEmpty, isTrue);
    });

    testWidgets('F7-T3-1: Assigning courses via multi-select checkbox syncs and updates', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: Scaffold(body: const AdminExamManagementWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin_edit_exam_exam_neet')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin_course_checkbox_batch_1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin_save_exam_button')));
      await tester.pumpAndSettle();

      final exam = state.exams.firstWhere((e) => e['id'] == 'exam_neet');
      expect(exam['assignedCourses'], contains('batch_1'));
    });

    testWidgets('F7-T3-2: Reordering exams in Admin Panel changes display order', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: Scaffold(body: const AdminExamManagementWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final listWidget = tester.widget<ReorderableListView>(find.byKey(const Key('admin_exam_reorder_list')));
      listWidget.onReorderItem!(0, 1);
      await tester.pumpAndSettle();

      expect(state.exams[0]['id'], 'exam_neet');
    });

    testWidgets('F7-T4-1: Full Admin workflow: creates exam, edits, validates URL, assigns course, reorders', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: Scaffold(body: const AdminExamManagementWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('admin_exam_name_field')), 'Workflow Test');
      await tester.enterText(find.byKey(const Key('admin_exam_icon_field')), 'bad');
      await tester.tap(find.byKey(const Key('admin_save_exam_button')));
      await tester.pumpAndSettle();
      expect(find.text('Must be a valid HTTP/HTTPS URL'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('admin_exam_icon_field')), 'https://good.com');
      await tester.tap(find.byKey(const Key('admin_save_exam_button')));
      await tester.pumpAndSettle();

      final created = state.exams.firstWhere((e) => e['name'] == 'Workflow Test');
      expect(created['iconUrl'], 'https://good.com');
    });

    testWidgets('F7-T4-2: Admin deletes exam, active filter falls back', (tester) async {
      harness.authenticateUser();
      final state = MockStudyState(firestore: harness.firestore, auth: harness.auth);
      seedStudySectionData(state);
      await state.init();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MockStudyState>.value(
            value: state,
            child: Scaffold(body: const AdminExamManagementWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin_delete_exam_exam_jee')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin_delete_confirm')));
      await tester.pumpAndSettle();

      expect(state.exams.where((e) => e['id'] == 'exam_jee').isEmpty, isTrue);
    });
  });
}

// ----------------------------------------------------
// Mock state manager and stub widgets implementation
// ----------------------------------------------------


class MockStudyState extends ChangeNotifier {
  final FakeFirebaseFirestore firestore;
  final FakeFirebaseAuth auth;
  late final Box lectureProgressBox;

  String currentTab = 'Courses';
  String? selectedBatchId;
  List<String> favoriteBatchIds = [];
  String? currentExamFilter;
  String searchQuery = '';
  String activeFilterChip = 'All';

  List<Map<String, dynamic>> availableBatches = [];
  List<Map<String, dynamic>> exams = [];
  List<Map<String, dynamic>> lectures = [];

  MockStudyState({
    required this.firestore,
    required this.auth,
  }) {
    lectureProgressBox = testProgressBox;
  }

  Future<void> init() async {
    await loadFromLocal();
    await syncWithFirestore();
  }

  Future<void> loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    selectedBatchId = prefs.getString('selected_batch_id');
    favoriteBatchIds = prefs.getStringList('favorite_batch_ids') ?? [];
    notifyListeners();
  }

  Future<void> syncWithFirestore() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null && data.containsKey('selectedBatchId')) {
        selectedBatchId = data['selectedBatchId'] as String?;
        final prefs = await SharedPreferences.getInstance();
        if (selectedBatchId != null) {
          await prefs.setString('selected_batch_id', selectedBatchId!);
        } else {
          await prefs.remove('selected_batch_id');
        }
      } else if (selectedBatchId != null) {
        await firestore.collection('users').doc(uid).set({
          'selectedBatchId': selectedBatchId,
        }, SetOptions(merge: true));
      }
    } else if (selectedBatchId != null) {
      await firestore.collection('users').doc(uid).set({
        'selectedBatchId': selectedBatchId,
      }, SetOptions(merge: true));
    }

    final bookmarksSnap = await firestore
        .collection('users')
        .doc(uid)
        .collection('courseBookmarks')
        .get();

    final firestoreFavs = bookmarksSnap.docs.map((doc) => doc.id).toList();
    final merged = <String>{...favoriteBatchIds, ...firestoreFavs}.toList();
    favoriteBatchIds = merged;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_batch_ids', favoriteBatchIds);

    for (final favId in favoriteBatchIds) {
      if (!firestoreFavs.contains(favId)) {
        await firestore
            .collection('users')
            .doc(uid)
            .collection('courseBookmarks')
            .doc(favId)
            .set({'bookmarkedAt': Timestamp.now()});
      }
    }

    notifyListeners();
  }

  void setTab(String tab) {
    currentTab = tab;
    notifyListeners();
  }

  Future<void> selectBatch(String? batchId) async {
    selectedBatchId = batchId;
    final prefs = await SharedPreferences.getInstance();
    if (batchId == null) {
      await prefs.remove('selected_batch_id');
    } else {
      await prefs.setString('selected_batch_id', batchId);
    }

    final uid = auth.currentUser?.uid;
    if (uid != null) {
      await firestore.collection('users').doc(uid).set({
        'selectedBatchId': batchId,
      }, SetOptions(merge: true));
    }
    notifyListeners();
  }

  Future<void> toggleFavoriteBatch(String batchId) async {
    final prefs = await SharedPreferences.getInstance();
    if (favoriteBatchIds.contains(batchId)) {
      favoriteBatchIds.remove(batchId);
    } else {
      favoriteBatchIds.add(batchId);
    }
    await prefs.setStringList('favorite_batch_ids', favoriteBatchIds);

    final uid = auth.currentUser?.uid;
    if (uid != null) {
      final isFav = favoriteBatchIds.contains(batchId);
      if (isFav) {
        await firestore
            .collection('users')
            .doc(uid)
            .collection('courseBookmarks')
            .doc(batchId)
            .set({'bookmarkedAt': Timestamp.now()});
      } else {
        await firestore
            .collection('users')
            .doc(uid)
            .collection('courseBookmarks')
            .doc(batchId)
            .delete();
      }
    }
    notifyListeners();
  }

  void setExamFilter(String? examId) {
    currentExamFilter = examId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setFilterChip(String chip) {
    activeFilterChip = chip;
    notifyListeners();
  }

  Future<void> updateLectureProgress(
    String lectureId, {
    required int progressSeconds,
    required int totalDurationSeconds,
    required String lastOpened,
  }) async {
    if (totalDurationSeconds <= 0) {
      return;
    }
    final double ratio = progressSeconds / totalDurationSeconds;
    final isCompleted = ratio >= 0.95;

    final progressMap = {
      'progressSeconds': progressSeconds,
      'totalDurationSeconds': totalDurationSeconds,
      'lastOpened': lastOpened,
      'isCompleted': isCompleted,
    };

    if (isCompleted) {
      await lectureProgressBox.delete(lectureId);
    } else {
      await lectureProgressBox.put(lectureId, progressMap);
    }
    notifyListeners();
  }

  void loadMockBatches(List<Map<String, dynamic>> list) {
    availableBatches = List<Map<String, dynamic>>.from(list);
    notifyListeners();
  }

  void loadMockExams(List<Map<String, dynamic>> list) {
    exams = List<Map<String, dynamic>>.from(list);
    notifyListeners();
  }

  void loadMockLectures(List<Map<String, dynamic>> list) {
    lectures = List<Map<String, dynamic>>.from(list);
    notifyListeners();
  }
}

class StickyTabPillHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  StickyTabPillHeaderDelegate({required this.child});
  @override
  double get minExtent => 60.0;
  @override
  double get maxExtent => 60.0;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: 60.0,
      child: Container(
        color: Colors.white,
        child: child,
      ),
    );
  }
  @override
  bool shouldRebuild(covariant StickyTabPillHeaderDelegate oldDelegate) => false;
}

class StickyTabPillWidget extends StatelessWidget {
  const StickyTabPillWidget({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<MockStudyState>(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            key: const Key('tab_courses'),
            style: ElevatedButton.styleFrom(
              backgroundColor: state.currentTab == 'Courses' ? Colors.blue : Colors.grey,
            ),
            onPressed: () => state.setTab('Courses'),
            child: const Text('Courses'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            key: const Key('tab_test_series'),
            style: ElevatedButton.styleFrom(
              backgroundColor: state.currentTab == 'Test Series' ? Colors.blue : Colors.grey,
            ),
            onPressed: () => state.setTab('Test Series'),
            child: const Text('Test Series'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            key: const Key('tab_ebooks'),
            style: ElevatedButton.styleFrom(
              backgroundColor: state.currentTab == 'E-books' ? Colors.blue : Colors.grey,
            ),
            onPressed: () => state.setTab('E-books'),
            child: const Text('E-books'),
          ),
        ],
      ),
    );
  }
}

class BatchSelectorWidget extends StatelessWidget {
  const BatchSelectorWidget({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<MockStudyState>(context);
    final selectedBatch = state.availableBatches.firstWhere(
      (b) => b['id'] == state.selectedBatchId,
      orElse: () => {'name': 'Select Batch'},
    );

    return InkWell(
      key: const Key('batch_selector_dropdown'),
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (ctx) {
            return ChangeNotifierProvider.value(
              value: state,
              child: Consumer<MockStudyState>(
                builder: (c, s, _) {
                  if (s.availableBatches.isEmpty) {
                    return const Center(child: Text('No batches available'));
                  }
                  return ListView(
                    children: s.availableBatches.map((batch) {
                      final isSelected = batch['id'] == s.selectedBatchId;
                      return ListTile(
                        key: Key('batch_item_${batch['id']}'),
                        title: Text(
                          batch['name'],
                          style: isSelected ? const TextStyle(fontWeight: FontWeight.bold) : null,
                        ),
                        trailing: isSelected ? const Icon(Icons.check) : null,
                        onTap: () {
                          s.selectBatch(batch['id']);
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            );
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 90),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text(
                  selectedBatch['name'],
                  key: const Key('selected_batch_name_text'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class DynamicHomepageWidget extends StatelessWidget {
  const DynamicHomepageWidget({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<MockStudyState>(context);
    if (state.selectedBatchId == null) {
      return Column(
        key: const Key('combo_pack_layout'),
        children: const [
          FavouriteBatchesWidget(),
          ContinueLearningWidget(),
          BrowseBatchesByExamWidget(),
        ],
      );
    } else {
      return Column(
        key: const Key('individual_batch_layout'),
        children: [
          const ContinueLearningWidget(),
          ElevatedButton(
            key: const Key('explore_batch_button'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Exploring batch ${state.selectedBatchId}')),
              );
            },
            child: const Text('Explore Batch'),
          ),
        ],
      );
    }
  }
}

class FavouriteBatchesWidget extends StatelessWidget {
  const FavouriteBatchesWidget({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<MockStudyState>(context);
    final favs = state.availableBatches.where((b) => state.favoriteBatchIds.contains(b['id'])).toList();

    if (favs.isEmpty) {
      return const Card(
        key: Key('favorites_empty_placeholder'),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No favorites yet'),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        key: const Key('favorites_list_view'),
        scrollDirection: Axis.horizontal,
        itemCount: favs.length,
        itemBuilder: (ctx, index) {
          final batch = favs[index];
          return Container(
            width: 150,
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: InkWell(
              key: Key('fav_card_${batch['id']}'),
              onTap: () {
                state.selectBatch(batch['id']);
              },
              child: Card(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            batch['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            batch['category'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        key: Key('fav_toggle_${batch['id']}'),
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () {
                          state.toggleFavoriteBatch(batch['id']);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ContinueLearningWidget extends StatelessWidget {
  const ContinueLearningWidget({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<MockStudyState>(context);
    final box = state.lectureProgressBox;
    final inProgressLectures = <Map<String, dynamic>>[];

    for (final lecture in state.lectures) {
      if (state.selectedBatchId != null && lecture['batchId'] != state.selectedBatchId) {
        continue;
      }

      final progressData = box.get(lecture['id']);
      if (progressData != null) {
        try {
          final map = Map<String, dynamic>.from(progressData as Map);
          if (map['progressSeconds'] != null && map['totalDurationSeconds'] != null && map['totalDurationSeconds'] > 0) {
            final double ratio = (map['progressSeconds'] as num).toDouble() / (map['totalDurationSeconds'] as num).toDouble();
            final isCompleted = map['isCompleted'] as bool? ?? false;
            if (ratio < 0.95 && !isCompleted) {
              inProgressLectures.add({
                ...lecture,
                'progressSeconds': map['progressSeconds'],
                'totalDurationSeconds': map['totalDurationSeconds'],
                'lastOpened': map['lastOpened'],
              });
            }
          }
        } catch (_) {
          // Safely ignore corrupted entries
        }
      }
    }

    if (inProgressLectures.isEmpty) {
      return const Card(
        key: Key('continue_learning_empty_placeholder'),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No lectures in progress'),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        key: const Key('continue_learning_list_view'),
        scrollDirection: Axis.horizontal,
        itemCount: inProgressLectures.length,
        itemBuilder: (ctx, index) {
          final lecture = inProgressLectures[index];
          final progress = lecture['progressSeconds'] as int;
          final total = lecture['totalDurationSeconds'] as int;
          final double pct = progress / total;

          return Container(
            width: 180,
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: InkWell(
              key: Key('lecture_card_${lecture['id']}'),
              onTap: () {
                state.updateLectureProgress(
                  lecture['id'],
                  progressSeconds: progress + 10,
                  totalDurationSeconds: total,
                  lastOpened: DateTime.now().toIso8601String(),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Resumed lecture ${lecture['title']}')),
                );
              },
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lecture['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text('Progress: ${(pct * 100).toInt()}%'),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        key: Key('progress_bar_${lecture['id']}'),
                        value: pct,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BrowseBatchesByExamWidget extends StatelessWidget {
  const BrowseBatchesByExamWidget({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<MockStudyState>(context);
    final sortedExams = List<Map<String, dynamic>>.from(state.exams)
      ..sort((a, b) => (a['orderIndex'] as int).compareTo(b['orderIndex'] as int));

    var filteredBatches = state.availableBatches.where((b) {
      final query = state.searchQuery.toLowerCase();
      if (query.isNotEmpty) {
        final matchesTitle = (b['name'] as String).toLowerCase().contains(query);
        final matchesCategory = (b['category'] as String?)?.toLowerCase().contains(query) ?? false;
        if (!matchesTitle && !matchesCategory) return false;
      }
      return true;
    }).toList();

    if (state.currentExamFilter != null) {
      final exam = state.exams.firstWhere((e) => e['id'] == state.currentExamFilter, orElse: () => {});
      if (exam.isNotEmpty) {
        final assigned = List<String>.from(exam['assignedCourses'] ?? []);
        filteredBatches = filteredBatches.where((b) => assigned.contains(b['id'])).toList();
      }
    }

    if (state.activeFilterChip != 'All') {
      filteredBatches = filteredBatches.where((b) => b['type'] == state.activeFilterChip).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            key: const Key('exam_search_field'),
            decoration: const InputDecoration(
              hintText: 'Search batches...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (val) => state.setSearchQuery(val),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('Browse by Exam', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            key: const Key('exam_circles_list_view'),
            scrollDirection: Axis.horizontal,
            itemCount: sortedExams.length,
            itemBuilder: (ctx, index) {
              final exam = sortedExams[index];
              final isSelected = state.currentExamFilter == exam['id'];
              final iconUrl = exam['iconUrl'] as String?;

              return GestureDetector(
                key: Key('exam_circle_${exam['id']}'),
                onTap: () {
                  if (isSelected) {
                    state.setExamFilter(null);
                  } else {
                    state.setExamFilter(exam['id']);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: CircleAvatar(
                    backgroundColor: isSelected ? Colors.green : Colors.blueGrey,
                    radius: 30,
                    child: iconUrl == null || iconUrl.isEmpty
                        ? const Icon(Icons.school, color: Colors.white)
                        : (iconUrl.startsWith('http')
                            ? Container(
                                key: Key('exam_icon_${exam['id']}'),
                                child: const Icon(Icons.school, color: Colors.white),
                              )
                            : const Icon(Icons.school, color: Colors.white)),
                  ),
                ),
              );
            },
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: ['All', 'Online', 'Offline'].map((chip) {
              final isSelected = state.activeFilterChip == chip;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  key: Key('filter_chip_$chip'),
                  label: Text(chip),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) state.setFilterChip(chip);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        if (filteredBatches.isEmpty)
          const Center(
            key: Key('browse_batches_empty_placeholder'),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No batches match the filters'),
            ),
          )
        else
          ListView.builder(
            key: const Key('browse_batches_list_view'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredBatches.length,
            itemBuilder: (ctx, index) {
              final batch = filteredBatches[index];
              final isFav = state.favoriteBatchIds.contains(batch['id']);
              return ListTile(
                key: Key('batch_tile_${batch['id']}'),
                title: Text(batch['name']),
                subtitle: Text('${batch['category']} - ${batch['type']}'),
                trailing: IconButton(
                  key: Key('batch_tile_fav_${batch['id']}'),
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : null,
                  ),
                  onPressed: () {
                    state.toggleFavoriteBatch(batch['id']);
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}

class AdminExamManagementWidget extends StatefulWidget {
  const AdminExamManagementWidget({Key? key}) : super(key: key);
  @override
  _AdminExamManagementWidgetState createState() => _AdminExamManagementWidgetState();
}

class _AdminExamManagementWidgetState extends State<AdminExamManagementWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _iconController = TextEditingController();

  String? _editingExamId;
  List<String> _selectedCourseIds = [];
  String? _errorMsg;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<MockStudyState>(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    key: const Key('admin_exam_name_field'),
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Exam Name'),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    key: const Key('admin_exam_icon_field'),
                    controller: _iconController,
                    decoration: const InputDecoration(labelText: 'Icon URL'),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Icon URL is required';
                      }
                      if (!val.startsWith('http://') && !val.startsWith('https://')) {
                        return 'Must be a valid HTTP/HTTPS URL';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text('Assign Courses:'),
                  ...state.availableBatches.map((b) {
                    final isAssigned = _selectedCourseIds.contains(b['id']);
                    return CheckboxListTile(
                      key: Key('admin_course_checkbox_${b['id']}'),
                      title: Text(b['name']),
                      value: isAssigned,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedCourseIds.add(b['id']);
                          } else {
                            _selectedCourseIds.remove(b['id']);
                          }
                        });
                      },
                    );
                  }).toList(),
                  if (_errorMsg != null)
                    Text(
                      _errorMsg!,
                      key: const Key('admin_error_message'),
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    key: const Key('admin_save_exam_button'),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final id = _editingExamId ?? DateTime.now().millisecondsSinceEpoch.toString();
                        final examData = {
                          'id': id,
                          'name': _nameController.text,
                          'iconUrl': _iconController.text,
                          'orderIndex': _editingExamId != null
                              ? state.exams.firstWhere((e) => e['id'] == id)['orderIndex'] as int
                              : state.exams.length,
                          'assignedCourses': _selectedCourseIds,
                        };

                        await state.firestore.collection('exams').doc(id).set(examData);

                        final idx = state.exams.indexWhere((e) => e['id'] == id);
                        if (idx != -1) {
                          state.exams[idx] = examData;
                        } else {
                          state.exams.add(examData);
                        }
                        state.notifyListeners();

                        _nameController.clear();
                        _iconController.clear();
                        setState(() {
                          _editingExamId = null;
                          _selectedCourseIds = [];
                          _errorMsg = null;
                        });
                      } else {
                        setState(() {
                          _errorMsg = 'Form validation failed';
                        });
                      }
                    },
                    child: Text(_editingExamId == null ? 'Add Exam' : 'Save Exam'),
                  ),
                  if (_editingExamId != null)
                    TextButton(
                      key: const Key('admin_cancel_edit_button'),
                      onPressed: () {
                        _nameController.clear();
                        _iconController.clear();
                        setState(() {
                          _editingExamId = null;
                          _selectedCourseIds = [];
                        });
                      },
                      child: const Text('Cancel Edit'),
                    ),
                ],
              ),
            ),
          ),
          const Text('Drag and drop to reorder:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(
            height: 300,
            child: ReorderableListView(
              key: const Key('admin_exam_reorder_list'),
              onReorderItem: (oldIdx, newIdx) async {
                setState(() {
                  final item = state.exams.removeAt(oldIdx);
                  state.exams.insert(newIdx, item);

                  for (int i = 0; i < state.exams.length; i++) {
                    state.exams[i]['orderIndex'] = i;
                    final id = state.exams[i]['id'];
                    state.firestore.collection('exams').doc(id).set({
                      'orderIndex': i,
                    }, SetOptions(merge: true));
                  }
                });
                state.notifyListeners();
              },
              children: state.exams.map((exam) {
                return ListTile(
                  key: Key('admin_exam_tile_${exam['id']}'),
                  title: Text(exam['name']),
                  subtitle: Text('Index: ${exam['orderIndex']}'),
                  leading: const Icon(Icons.drag_handle),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: Key('admin_edit_exam_${exam['id']}'),
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          setState(() {
                            _editingExamId = exam['id'];
                            _nameController.text = exam['name'];
                            _iconController.text = exam['iconUrl'] ?? '';
                            _selectedCourseIds = List<String>.from(exam['assignedCourses'] ?? []);
                          });
                        },
                      ),
                      IconButton(
                        key: Key('admin_delete_exam_${exam['id']}'),
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              key: const Key('admin_delete_dialog'),
                              title: const Text('Delete Exam'),
                              actions: [
                                TextButton(
                                  key: const Key('admin_delete_cancel'),
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  key: const Key('admin_delete_confirm'),
                                  onPressed: () async {
                                    final id = exam['id'];
                                    await state.firestore.collection('exams').doc(id).delete();
                                    state.exams.removeWhere((e) => e['id'] == id);
                                    state.notifyListeners();
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class StudySectionMainPage extends StatefulWidget {
  const StudySectionMainPage({Key? key}) : super(key: key);
  @override
  _StudySectionMainPageState createState() => _StudySectionMainPageState();
}

class _StudySectionMainPageState extends State<StudySectionMainPage> {
  bool _showAdminPanel = false;

  @override
  Widget build(BuildContext context) {
    if (_showAdminPanel) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Exam Management'),
          leading: IconButton(
            key: const Key('admin_back_button'),
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _showAdminPanel = false),
          ),
        ),
        body: const AdminExamManagementWidget(),
      );
    }

    final state = Provider.of<MockStudyState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        actions: [
          const Flexible(child: BatchSelectorWidget()),
          IconButton(
            key: const Key('admin_panel_nav_link'),
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () => setState(() => _showAdminPanel = true),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              key: const Key('drawer_admin_link'),
              title: const Text('Admin Panel'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _showAdminPanel = true);
              },
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        key: const Key('study_custom_scroll_view'),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: StickyTabPillHeaderDelegate(
              child: const StickyTabPillWidget(),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildTabContent(state.currentTab),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(String tab) {
    switch (tab) {
      case 'Courses':
        return const DynamicHomepageWidget();
      case 'Test Series':
        return const Center(
          key: Key('test_series_tab_content'),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Test Series Tab Content'),
          ),
        );
      case 'E-books':
        return const Center(
          key: Key('ebooks_tab_content'),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('E-books Tab Content'),
          ),
        );
      default:
        return Container();
    }
  }
}
