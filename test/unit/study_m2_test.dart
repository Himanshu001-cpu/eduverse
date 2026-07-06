import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eduverse/study/data/repositories/lecture_progress_repository.dart';
import 'package:eduverse/study/data/repositories/study_local_storage.dart';
import 'package:eduverse/study/data/repositories/study_repository_impl.dart';
import '../e2e/harness/fake_firebase_firestore.dart';

void main() {
  late Directory tempDir;
  late LectureProgressRepository progressRepo;
  late StudyLocalStorage localStorage;

  setUpAll(() async {
    // Create a temporary directory for Hive testing
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    // Clean up temporary Hive directory
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    // Open the box for each test
    final box = await Hive.openBox<Map>('lecture_progress');
    await box.clear();
    progressRepo = LectureProgressRepository();
    localStorage = StudyLocalStorage();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    // Close and delete box after each test to keep state clean
    await Hive.close();
  });

  group('LectureProgressRepository Unit Tests', () {
    test('saveProgress and getProgress basic functionality', () async {
      await progressRepo.saveProgress(
        lectureId: 'lec_1',
        progressSeconds: 10,
        totalDurationSeconds: 100,
        lastOpened: '2026-06-26T20:00:00Z',
      );

      final progress = progressRepo.getProgress('lec_1');
      expect(progress, isNotNull);
      expect(progress!['progressSeconds'], 10);
      expect(progress['totalDurationSeconds'], 100);
      expect(progress['lastOpened'], '2026-06-26T20:00:00Z');
      expect(progress['isCompleted'], false);
    });

    test('isCompleted calculation threshold (>=95%)', () async {
      // 95% exactly should be cleared/deleted (since threshold is >= 95%)
      await progressRepo.saveProgress(
        lectureId: 'lec_95',
        progressSeconds: 95,
        totalDurationSeconds: 100,
      );
      expect(progressRepo.getProgress('lec_95'), isNull);

      // 95.1% should be cleared/deleted (>95%)
      await progressRepo.saveProgress(
        lectureId: 'lec_95_1',
        progressSeconds: 96,
        totalDurationSeconds: 100,
      );
      expect(progressRepo.getProgress('lec_95_1'), isNull);

      // 100% should be cleared/deleted
      await progressRepo.saveProgress(
        lectureId: 'lec_100',
        progressSeconds: 100,
        totalDurationSeconds: 100,
      );
      expect(progressRepo.getProgress('lec_100'), isNull);

      // 0 duration shouldn't crash and should be false
      await progressRepo.saveProgress(
        lectureId: 'lec_zero',
        progressSeconds: 0,
        totalDurationSeconds: 0,
      );
      expect(progressRepo.getProgress('lec_zero')!['isCompleted'], false);
    });

    test('deleteProgress removes lecture progress', () async {
      await progressRepo.saveProgress(
        lectureId: 'lec_to_delete',
        progressSeconds: 50,
        totalDurationSeconds: 100,
      );
      expect(progressRepo.getProgress('lec_to_delete'), isNotNull);

      await progressRepo.deleteProgress('lec_to_delete');
      expect(progressRepo.getProgress('lec_to_delete'), isNull);
    });

    test('getAllProgress returns all entries sorted by lastOpened descending', () async {
      await progressRepo.saveProgress(
        lectureId: 'lec_old',
        progressSeconds: 10,
        totalDurationSeconds: 100,
        lastOpened: '2026-06-26T10:00:00Z',
      );

      await progressRepo.saveProgress(
        lectureId: 'lec_new',
        progressSeconds: 20,
        totalDurationSeconds: 100,
        lastOpened: '2026-06-26T12:00:00Z',
      );

      await progressRepo.saveProgress(
        lectureId: 'lec_mid',
        progressSeconds: 15,
        totalDurationSeconds: 100,
        lastOpened: '2026-06-26T11:00:00Z',
      );

      final allProgress = progressRepo.getAllProgress();
      expect(allProgress.length, 3);
      expect(allProgress[0]['lectureId'], 'lec_new');
      expect(allProgress[1]['lectureId'], 'lec_mid');
      expect(allProgress[2]['lectureId'], 'lec_old');
    });

    test('clearAll clears all repository data', () async {
      await progressRepo.saveProgress(
        lectureId: 'lec_1',
        progressSeconds: 10,
        totalDurationSeconds: 100,
      );
      await progressRepo.saveProgress(
        lectureId: 'lec_2',
        progressSeconds: 20,
        totalDurationSeconds: 100,
      );

      expect(progressRepo.getAllProgress().length, 2);

      await progressRepo.clearAll();
      expect(progressRepo.getAllProgress(), isEmpty);
    });
  });

  group('StudyLocalStorage Unit Tests', () {
    test('save and get selected_batch_id', () async {
      expect(await localStorage.getSelectedBatchId(), isNull);

      await localStorage.setSelectedBatchId('batch_abc');
      expect(await localStorage.getSelectedBatchId(), 'batch_abc');
    });

    test('cache and get favorite_batch_ids', () async {
      expect(await localStorage.getCachedFavoriteBatchIds(), isEmpty);

      final favorites = ['batch_1', 'batch_2'];
      await localStorage.cacheFavoriteBatchIds(favorites);
      expect(await localStorage.getCachedFavoriteBatchIds(), favorites);
    });

    test('clearAll clears local storage settings', () async {
      await localStorage.setSelectedBatchId('batch_abc');
      await localStorage.cacheFavoriteBatchIds(['batch_1']);

      await localStorage.clearAll();

      expect(await localStorage.getSelectedBatchId(), isNull);
      expect(await localStorage.getCachedFavoriteBatchIds(), isEmpty);
    });
  });

  group('Favorites Synchronization & Reconciliation Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late StudyRepositoryImpl studyRepo;
    const String userId = 'user_123';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      studyRepo = StudyRepositoryImpl(firestore: fakeFirestore);
    });

    test('isBatchBookmarked listens to Firestore and updates SharedPreferences cache', () async {
      final docPath = 'users/$userId/courseBookmarks/batch_fav';

      // Initially, it is not bookmarked, and cache is empty
      expect(await localStorage.getCachedFavoriteBatchIds(), isEmpty);

      // Start listening to the bookmark stream
      final stream = studyRepo.isBatchBookmarked(userId, 'batch_fav');
      final queue = <bool>[];
      final subscription = stream.listen(queue.add);

      // Let stream emit initial value
      await Future.delayed(const Duration(milliseconds: 50));
      expect(queue.last, false);
      expect(await localStorage.getCachedFavoriteBatchIds(), isEmpty);

      // Simulate external bookmark addition in Firestore
      fakeFirestore.setDoc(docPath, {'courseId': 'batch_fav'});
      await Future.delayed(const Duration(milliseconds: 50));

      expect(queue.last, true);
      // Verify SharedPreferences has been reconciled/updated
      expect(await localStorage.getCachedFavoriteBatchIds(), contains('batch_fav'));

      // Simulate external bookmark removal in Firestore
      fakeFirestore.deleteDoc(docPath);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(queue.last, false);
      expect(await localStorage.getCachedFavoriteBatchIds(), isNot(contains('batch_fav')));

      await subscription.cancel();
    });

    test('toggleBatchBookmark updates both local SharedPreferences cache and Firestore', () async {
      final docPath = 'users/$userId/courseBookmarks/batch_toggle';

      // 1. Initial State: not bookmarked
      expect(fakeFirestore.data[docPath], isNull);
      expect(await localStorage.getCachedFavoriteBatchIds(), isNot(contains('batch_toggle')));

      // 2. Toggle bookmark (adds bookmark)
      await studyRepo.toggleBatchBookmark(userId, 'batch_toggle');

      // Verify Firestore update
      expect(fakeFirestore.data[docPath], isNotNull);
      // Verify local SharedPreferences cache update
      expect(await localStorage.getCachedFavoriteBatchIds(), contains('batch_toggle'));

      // 3. Toggle bookmark again (removes bookmark)
      await studyRepo.toggleBatchBookmark(userId, 'batch_toggle');

      // Verify Firestore update
      expect(fakeFirestore.data[docPath], isNull);
      // Verify local SharedPreferences cache update
      expect(await localStorage.getCachedFavoriteBatchIds(), isNot(contains('batch_toggle')));
    });
  });

  group('StudyRepositoryImpl Lecture Mapping Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late StudyRepositoryImpl studyRepo;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      studyRepo = StudyRepositoryImpl(firestore: fakeFirestore);
    });

    test('getBatchLectures maps type "folder" and orderIndex correctly', () async {
      fakeFirestore.setDoc('courses/course_1/lessons/lec_folder', {
        'title': 'Chapter 1',
        'type': 'folder',
        'subject': 'Maths',
        'chapter': '',
        'orderIndex': 5,
      });

      final lectures = await studyRepo.getBatchLectures('user_123', 'course_1', 'batch_1');
      expect(lectures.length, 1);
      expect(lectures[0].type, 'folder');
      expect(lectures[0].orderIndex, 5);
      expect(lectures[0].title, 'Chapter 1');
    });
  });
}
