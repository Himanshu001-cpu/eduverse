import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/domain/repositories/i_study_repository.dart';
import 'package:eduverse/study/models/study_models.dart';
import 'package:eduverse/study/screens/workbooks_page.dart';

class MockWorkbooksStudyRepository implements IStudyRepository {
  List<WorkbookModel> mockWorkbooks = [];

  @override
  Stream<List<WorkbookModel>> getWorkbooks() => Stream.value(mockWorkbooks);

  @override
  Stream<List<StudyBatch>> getEnrolledBatches(String userId) => Stream.value([]);

  @override
  Stream<List<StudyCourseModel>> getEnrolledCourses() => Stream.value([]);

  @override
  Stream<List<TopicNodeModel>> getTopics() => Stream.value([]);

  @override
  Future<List<StudyLecture>> getBatchLectures(String userId, String courseId, String batchId) async => [];

  @override
  Stream<List<StudyLecture>> getBatchLecturesStream(String userId, String courseId, String batchId) => Stream.value([]);

  @override
  Future<void> markLectureWatched(String userId, String courseId, String batchId, String lectureId, bool isWatched) async {}

  @override
  Future<void> updateBatchProgress(String userId, String courseId, String batchId) async {}

  @override
  Future<List<StudyQuiz>> getBatchQuizzes(String courseId, String batchId) async => [];

  @override
  Future<List<StudyNote>> getBatchNotes(String courseId, String batchId) async => [];

  @override
  Future<List<StudyPlannerItem>> getBatchPlanner(String courseId, String batchId) async => [];

  @override
  Future<List<StudyLiveClass>> getBatchLiveClasses(String courseId, String batchId) async => [];

  @override
  Future<List<StudyDpp>> getBatchDpps(String courseId, String batchId) async => [];

  @override
  Future<List<StudyLiveClass>> getFreeLiveClasses() async => [];

  @override
  Future<StudyBatch?> getBatch(String batchId, {required String courseId}) async => null;

  @override
  Stream<bool> isBatchBookmarked(String userId, String batchId) => Stream.value(false);

  @override
  Future<void> toggleBatchBookmark(String userId, String batchId) async {}

  @override
  Future<List<StudyRecordedBatch>> getRecordedBatchesForCourse(String courseId) async => [];

  @override
  Future<List<StudyLecture>> getRecordedBatchLectures(String userId, String courseId, String batchId) async => [];

  @override
  Future<List<StudyNote>> getRecordedBatchNotes(String courseId, String batchId) async => [];

  @override
  Future<List<StudyDpp>> getRecordedBatchDpps(String courseId, String batchId) async => [];

  @override
  Future<List<StudyQuiz>> getRecordedBatchQuizzes(String courseId, String batchId) async => [];
}

void main() {
  late MockWorkbooksStudyRepository mockRepo;

  setUp(() {
    mockRepo = MockWorkbooksStudyRepository();
    mockRepo.mockWorkbooks = [
      WorkbookModel(
        id: 'wb_1',
        userId: 'student_1',
        title: 'Calculus Assignment 1',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        status: 'In Progress',
        progress: 0.5,
        tasks: [
          TaskModel(id: 't_1', title: 'Derivatives Practice', isCompleted: true),
          TaskModel(id: 't_2', title: 'Integrals Problem Set', isCompleted: false),
        ],
      ),
      WorkbookModel(
        id: 'wb_2',
        userId: 'student_1',
        title: 'Physics Mechanics Lab',
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
        status: 'Overdue',
        progress: 0.1,
        tasks: [
          TaskModel(id: 't_3', title: 'Friction Experiment', isCompleted: false),
        ],
      ),
    ];
  });

  testWidgets('WorkbooksPage renders workbooks and filters by status chips', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: WorkbooksPage(repository: mockRepo),
    ));
    await tester.pump();

    // Verify header and both workbooks are rendered
    expect(find.text('Workbooks'), findsOneWidget);
    expect(find.text('Calculus Assignment 1'), findsOneWidget);
    expect(find.text('Physics Mechanics Lab'), findsOneWidget);

    // Tap 'Due Soon' filter chip
    await tester.tap(find.text('Due Soon'));
    await tester.pumpAndSettle();

    // Only Calculus Assignment 1 should be visible
    expect(find.text('Calculus Assignment 1'), findsOneWidget);
    expect(find.text('Physics Mechanics Lab'), findsNothing);

    // Tap 'Overdue' filter chip
    await tester.tap(find.text('Overdue'));
    await tester.pumpAndSettle();

    // Only Physics Mechanics Lab should be visible
    expect(find.text('Calculus Assignment 1'), findsNothing);
    expect(find.text('Physics Mechanics Lab'), findsOneWidget);

    // Tap 'All' filter chip to restore full list
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(find.text('Calculus Assignment 1'), findsOneWidget);
    expect(find.text('Physics Mechanics Lab'), findsOneWidget);
  });

  testWidgets('Tapping a workbook card opens task detail bottom sheet', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: WorkbooksPage(repository: mockRepo),
    ));
    await tester.pump();

    // Tap the first workbook
    await tester.tap(find.text('Calculus Assignment 1'));
    await tester.pumpAndSettle();

    // Modal bottom sheet should show workbook title and tasks
    expect(find.text('Derivatives Practice'), findsOneWidget);
    expect(find.text('Integrals Problem Set'), findsOneWidget);
  });
}
