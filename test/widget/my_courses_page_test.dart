import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/domain/repositories/i_study_repository.dart';
import 'package:eduverse/study/models/study_models.dart';
import 'package:eduverse/study/screens/my_courses_page.dart';

class MockCoursesStudyRepository implements IStudyRepository {
  List<StudyCourseModel> mockCourses = [];

  @override
  Stream<List<StudyCourseModel>> getEnrolledCourses() => Stream.value(mockCourses);

  @override
  Stream<List<WorkbookModel>> getWorkbooks() => Stream.value([]);

  @override
  Stream<List<StudyBatch>> getEnrolledBatches(String userId) => Stream.value([]);

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
  late MockCoursesStudyRepository mockRepo;

  setUp(() {
    mockRepo = MockCoursesStudyRepository();
    mockRepo.mockCourses = [
      const StudyCourseModel(
        id: 'c_1',
        title: 'Flutter Architecture',
        subtitle: 'Clean Code Patterns',
        emoji: '📱',
        gradientColors: [Colors.blue, Colors.lightBlueAccent],
        lessonCount: 20,
        progress: 0.75,
      ),
      const StudyCourseModel(
        id: 'c_2',
        title: 'Firebase Cloud Functions',
        subtitle: 'Serverless Mastery',
        emoji: '☁️',
        gradientColors: [Colors.orange, Colors.amber],
        lessonCount: 10,
        progress: 0.25,
      ),
    ];
  });

  testWidgets('MyCoursesPage renders course cards in grid and search bar', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MyCoursesPage(repository: mockRepo),
    ));
    await tester.pump();

    // Verify title and search field
    expect(find.text('My Courses'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Verify course titles and emoji
    expect(find.text('Flutter Architecture'), findsOneWidget);
    expect(find.text('Firebase Cloud Functions'), findsOneWidget);
    expect(find.text('📱'), findsOneWidget);
    expect(find.text('☁️'), findsOneWidget);

    // Verify progress text
    expect(find.text('75% Complete'), findsOneWidget);
    expect(find.text('25% Complete'), findsOneWidget);
  });

  testWidgets('Tapping a course card opens modal sheet with Go to Lessons button', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MyCoursesPage(repository: mockRepo),
    ));
    await tester.pump();

    // Tap course card
    await tester.tap(find.text('Flutter Architecture'));
    await tester.pumpAndSettle();

    // Bottom sheet assertions
    expect(find.text('About this course'), findsOneWidget);
    expect(find.text('Go to Lessons'), findsOneWidget);
  });
}
