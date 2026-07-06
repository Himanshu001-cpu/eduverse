import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/domain/repositories/i_study_repository.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/study/presentation/widgets/live_classes_section.dart';

import 'package:eduverse/core/firebase/eduverse_firebase.dart';
import '../e2e/harness/fake_firebase_firestore.dart';
import '../e2e/harness/fake_firebase_auth.dart';

class FakeStudyRepository implements IStudyRepository {
  List<StudyLiveClass> liveClasses = [];

  @override
  Stream<List<StudyBatch>> getEnrolledBatches(String userId) => Stream.value([
        StudyBatch(
          id: 'batch_1',
          courseId: 'course_1',
          name: 'NDA Batch',
          courseName: 'NDA Course',
          gradientColors: const [],
          startDate: DateTime.now(),
        ),
      ]);

  @override
  Future<List<StudyLecture>> getBatchLectures(
          String userId, String courseId, String batchId) async =>
      [];

  @override
  Stream<List<StudyLecture>> getBatchLecturesStream(
          String userId, String courseId, String batchId) =>
      Stream.value([]);

  @override
  Future<void> markLectureWatched(String userId, String courseId,
      String batchId, String lectureId, bool isWatched) async {}

  @override
  Future<void> updateBatchProgress(
      String userId, String courseId, String batchId) async {}

  @override
  Future<List<StudyQuiz>> getBatchQuizzes(
          String courseId, String batchId) async =>
      [];

  @override
  Future<List<StudyNote>> getBatchNotes(
          String courseId, String batchId) async =>
      [];

  @override
  Future<List<StudyPlannerItem>> getBatchPlanner(
          String courseId, String batchId) async =>
      [];

  @override
  Future<List<StudyLiveClass>> getBatchLiveClasses(
          String courseId, String batchId) async =>
      liveClasses;

  @override
  Future<List<StudyDpp>> getBatchDpps(
          String courseId, String batchId) async =>
      [];

  @override
  Future<List<StudyLiveClass>> getFreeLiveClasses() async => [];

  @override
  Future<StudyBatch?> getBatch(String batchId, {required String courseId}) async => null;

  @override
  Stream<bool> isBatchBookmarked(String userId, String batchId) =>
      Stream.value(false);

  @override
  Future<void> toggleBatchBookmark(String userId, String batchId) async {}
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_live_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Hive.openBox('lecture_progress');

    final fakeFirestore = FakeFirebaseFirestore();
    final fakeAuth = FakeFirebaseAuth();
    EduverseFirebase.mockFirestore = fakeFirestore;
    EduverseFirebase.mockAuth = fakeAuth;
  });

  tearDown(() async {
    await Hive.close();
  });

  testWidgets('LiveClassesSection renders nothing when empty',
      (WidgetTester tester) async {
    final repo = FakeStudyRepository();
    repo.liveClasses = [];

    final controller = StudyController(repository: repo, userId: 'test_user');
    await controller.loadAllLiveClasses();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<StudyController>.value(
            value: controller,
            child: const LiveClassesSection(),
          ),
        ),
      ),
    );

    expect(find.byType(LiveClassesSection), findsOneWidget);
    expect(find.text('Live Classes'), findsNothing);
  });

  testWidgets('LiveClassesSection renders list item when live class present',
      (WidgetTester tester) async {
    final repo = FakeStudyRepository();
    repo.liveClasses = [
      StudyLiveClass(
        id: 'lc_1',
        title: 'Current Live Calculus Class',
        status: 'live',
        startTime: DateTime.now().subtract(const Duration(minutes: 10)),
        durationMinutes: 60,
        youtubeUrl: 'https://youtube.com/watch?v=12345678901',
        subject: 'Maths',
      ),
    ];

    final controller = StudyController(repository: repo, userId: 'test_user');
    await controller.loadAllLiveClasses();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<StudyController>.value(
            value: controller,
            child: const LiveClassesSection(),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Live Classes'), findsOneWidget);
    expect(find.text('Current Live Calculus Class'), findsOneWidget);
    expect(find.text('MATHS'), findsOneWidget);
  });
}
