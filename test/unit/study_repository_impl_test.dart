import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eduverse/core/firebase/eduverse_firebase.dart';
import 'package:eduverse/study/data/repositories/study_repository_impl.dart';
import '../e2e/harness/fake_firebase_firestore.dart';
import '../e2e/harness/fake_firebase_auth.dart';

void main() {
  late Directory tempDir;
  late FakeFirebaseFirestore fakeFirestore;
  late FakeFirebaseAuth fakeAuth;
  late StudyRepositoryImpl repository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_study_repo_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeFirestore = FakeFirebaseFirestore();
    fakeAuth = FakeFirebaseAuth();
    EduverseFirebase.mockFirestore = fakeFirestore;
    EduverseFirebase.mockAuth = fakeAuth;

    // Default authenticated student user
    fakeAuth.changeCurrentUser(FakeUser(
      uid: 'test_student',
      email: 'student@eduverse.com',
    ));

    repository = StudyRepositoryImpl(firestore: fakeFirestore);
  });

  tearDown(() async {
    await Hive.close();
  });

  group('StudyRepositoryImpl - Domain Method Tests', () {
    test('getWorkbooks streams workbooks assigned to the current user', () async {
      final dueDate = DateTime.now().add(const Duration(days: 2));
      fakeFirestore.setDoc('users/test_student/workbooks/wb_1', {
        'title': 'State Mgmt Homework',
        'subject': 'Flutter',
        'dueDate': Timestamp.fromDate(dueDate),
        'status': 'Pending',
      });

      final stream = repository.getWorkbooks();
      final workbooks = await stream.first;

      expect(workbooks.length, 1);
      expect(workbooks[0].id, 'wb_1');
      expect(workbooks[0].title, 'State Mgmt Homework');
      expect(workbooks[0].status, 'Pending');
    });

    test('getTopics streams topic nodes sorted by order', () async {
      fakeFirestore.setDoc('topics/topic_2', {
        'title': 'Design Patterns',
        'order': 2,
      });
      fakeFirestore.setDoc('topics/topic_1', {
        'title': 'Clean Architecture',
        'order': 1,
      });

      final stream = repository.getTopics();
      final topics = await stream.first;

      expect(topics.length, 2);
      expect(topics[0].title, 'Clean Architecture');
      expect(topics[1].title, 'Design Patterns');
    });

    test('getEnrolledCourses resolves and unbundles courses from combination_packs', () async {
      // Seed courses
      fakeFirestore.setDoc('courses/course_1', {
        'title': 'Flutter Core',
        'subtitle': 'Dart & Flutter',
        'emoji': '📱',
        'totalLectures': 12,
        'gradientColors': [0xFF2196F3, 0xFF03A9F4],
      });
      fakeFirestore.setDoc('courses/course_2', {
        'title': 'Cloud Functions',
        'subtitle': 'Serverless backend',
        'emoji': '☁️',
        'totalLectures': 8,
        'gradientColors': [0xFFFF9800, 0xFFFFC107],
      });

      // Seed combination pack
      fakeFirestore.setDoc('combination_packs/combo_bundle', {
        'title': 'Full Stack Bundle',
        'courses': ['course_1', 'course_2'],
      });

      // Seed enrollment with combinationPackId
      fakeFirestore.setDoc('users/test_student/enrolledCourses/enroll_combo', {
        'combinationPackId': 'combo_bundle',
      });

      final stream = repository.getEnrolledCourses();
      final courses = await stream.first;

      expect(courses.length, 2);
      final titles = courses.map((c) => c.title).toList();
      expect(titles, contains('Flutter Core'));
      expect(titles, contains('Cloud Functions'));
      expect(courses.firstWhere((c) => c.id == 'course_1').lessonCount, 12);
      expect(courses.firstWhere((c) => c.id == 'course_2').lessonCount, 8);
    });
  });

  group('StudyRepositoryImpl - T-03-01 Security Authorization Controls', () {
    test('Unauthenticated session (currentUser == null) returns empty stream immediately', () async {
      // Sign out
      fakeAuth.changeCurrentUser(null);

      // Seed enrollment that should not be visible
      fakeFirestore.setDoc('users/test_student/enrolledCourses/enroll_1', {
        'courseId': 'course_1',
      });

      final workbooksStream = repository.getWorkbooks();
      final enrolledStream = repository.getEnrolledCourses();

      expect(await workbooksStream.first, isEmpty);
      expect(await enrolledStream.first, isEmpty);
    });

    test('User without enrolledCourses returns empty list', () async {
      fakeAuth.changeCurrentUser(FakeUser(
        uid: 'unenrolled_student',
        email: 'unenrolled@eduverse.com',
      ));

      final stream = repository.getEnrolledCourses();
      final courses = await stream.first;

      expect(courses, isEmpty);
    });
  });
}
