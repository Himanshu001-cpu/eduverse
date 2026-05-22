import 'package:flutter_test/flutter_test.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/admin/models/admin_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('StudyLecture Unit Tests', () {
    test('StudyLecture.fromMap deserializes double durationSeconds safely', () {
      final Map<String, dynamic> data = {
        'title': 'Test Lecture',
        'description': 'Description here',
        'videoUrl': 'https://video.url',
        'subject': 'Physics',
        'chapter': 'Electrostatics',
        'orderIndex': 5,
        'isLocked': true,
        'isWatched': false,
        'type': 'video',
        'durationSeconds': 120.5, // stored as double in Firestore
        'lectureNo': 1,
        'linkedNoteIds': ['note1', 'note2'],
      };

      final lecture = StudyLecture.fromMap(data, 'lect_123');

      expect(lecture.id, 'lect_123');
      expect(lecture.title, 'Test Lecture');
      expect(lecture.videoUrl, 'https://video.url');
      expect(lecture.subject, 'Physics');
      expect(lecture.chapter, 'Electrostatics');
      expect(lecture.orderIndex, 5);
      expect(lecture.isLocked, true);
      expect(lecture.isWatched, false);
      expect(lecture.type, 'video');
      expect(lecture.lectureNo, 1);
      expect(lecture.linkedNoteIds, ['note1', 'note2']);
      
      // Verify duration conversions
      expect(lecture.duration, isNotNull);
      expect(lecture.duration!.inSeconds, 120);
    });

    test('StudyLecture.fromMap deserializes integer durationSeconds safely', () {
      final Map<String, dynamic> data = {
        'title': 'Int Lecture',
        'videoUrl': 'https://video.url',
        'durationSeconds': 90, // stored as int
      };

      final lecture = StudyLecture.fromMap(data, 'lect_456');

      expect(lecture.duration, isNotNull);
      expect(lecture.duration!.inSeconds, 90);
    });

    test('StudyLecture.fromMap handles missing/null values with defaults', () {
      final Map<String, dynamic> data = {
        // missing almost all fields
      };

      final lecture = StudyLecture.fromMap(data, 'lect_empty');

      expect(lecture.id, 'lect_empty');
      expect(lecture.title, '');
      expect(lecture.description, '');
      expect(lecture.videoUrl, '');
      expect(lecture.subject, '');
      expect(lecture.chapter, '');
      expect(lecture.orderIndex, 0);
      expect(lecture.order, 0);
      expect(lecture.isLocked, false);
      expect(lecture.isWatched, false);
      expect(lecture.type, 'video');
      expect(lecture.duration, isNull);
      expect(lecture.lectureNo, isNull);
      expect(lecture.linkedNoteIds, isEmpty);
    });

    test('StudyLecture.copyWith works correctly', () {
      const original = StudyLecture(
        id: '1',
        title: 'Original',
        videoUrl: 'original_url',
        subject: 'Math',
        chapter: 'Calculus',
        orderIndex: 1,
        isLocked: false,
        isWatched: false,
        type: 'video',
      );

      final modified = original.copyWith(
        title: 'Modified',
        isLocked: true,
        orderIndex: 2,
      );

      expect(modified.id, '1'); // remains unchanged
      expect(modified.title, 'Modified');
      expect(modified.videoUrl, 'original_url'); // remains unchanged
      expect(modified.subject, 'Math');
      expect(modified.isLocked, true);
      expect(modified.orderIndex, 2);
    });
  });

  group('StudyBatch Unit Tests', () {
    test('StudyBatch copyWith works correctly', () {
      final batch = StudyBatch(
        id: 'b1',
        courseId: 'c1',
        name: 'Batch Alpha',
        courseName: 'Course 101',
        gradientColors: const [],
        startDate: DateTime(2026, 1, 1),
        totalLectures: 10,
        completedLectures: 2,
        progress: 0.2,
      );

      final updated = batch.copyWith(
        name: 'Batch Beta',
        completedLectures: 5,
        progress: 0.5,
      );

      expect(updated.id, 'b1');
      expect(updated.name, 'Batch Beta');
      expect(updated.completedLectures, 5);
      expect(updated.progress, 0.5);
      expect(updated.totalLectures, 10);
    });
  });

  group('CartItem Unit Tests', () {
    test('toJson and fromJson support combinationPackId correctly', () {
      final item = CartItem(
        courseId: 'c123',
        batchId: 'b456',
        combinationPackId: 'combo789',
        title: 'Super Bundle Pack',
        price: 1500.0,
      );

      final json = item.toJson();

      expect(json['courseId'], 'c123');
      expect(json['batchId'], 'b456');
      expect(json['combinationPackId'], 'combo789');
      expect(json['title'], 'Super Bundle Pack');
      expect(json['price'], 1500.0);
      expect(json['quantity'], 1);

      final deserialized = CartItem.fromJson(json);

      expect(deserialized.courseId, 'c123');
      expect(deserialized.batchId, 'b456');
      expect(deserialized.combinationPackId, 'combo789');
      expect(deserialized.title, 'Super Bundle Pack');
      expect(deserialized.price, 1500.0);
      expect(deserialized.quantity, 1);
    });
  });

  group('CombinationPack Unit Tests', () {
    test('CombinationPack.fromMap handles types and parsing correctly', () {
      final Map<String, dynamic> data = {
        'title': 'Awesome Combo',
        'description': 'Description here',
        'thumbnailUrl': 'https://thumb.url',
        'realPrice': 2000, // int
        'finalPrice': 999.99, // double
        'batches': [
          {'courseId': 'c1', 'batchId': 'b1'},
          {'courseId': 'c2', 'batchId': 'b2'},
        ],
        'testSeries': ['ts1', 'ts2'],
        'isActive': true,
      };

      final pack = CombinationPack.fromMap(data, 'combo_123');

      expect(pack.id, 'combo_123');
      expect(pack.title, 'Awesome Combo');
      expect(pack.description, 'Description here');
      expect(pack.thumbnailUrl, 'https://thumb.url');
      expect(pack.realPrice, 2000.0);
      expect(pack.finalPrice, 999.99);
      expect(pack.batches.length, 2);
      expect(pack.batches[0]['courseId'], 'c1');
      expect(pack.batches[1]['batchId'], 'b2');
      expect(pack.testSeries, ['ts1', 'ts2']);
      expect(pack.isActive, true);
    });
  });

  group('AdminCombinationPack Unit Tests', () {
    test('AdminCombinationPack serialization and copyWith work correctly', () {
      final createdTime = DateTime(2026, 5, 22);
      final pack = AdminCombinationPack(
        id: 'adm_combo',
        title: 'Admin Pack',
        description: 'Admin Desc',
        thumbnailUrl: 'thumb_url',
        realPrice: 500.0,
        finalPrice: 250.0,
        batches: const [
          {'courseId': 'c1', 'batchId': 'b1'}
        ],
        testSeries: const ['ts1'],
        isActive: false,
        createdAt: createdTime,
      );

      final Map<String, dynamic> data = pack.toMap();
      expect(data['title'], 'Admin Pack');
      expect(data['realPrice'], 500.0);
      expect(data['isActive'], false);
      expect(data['createdAt'], isA<Timestamp>());

      final deserialized = AdminCombinationPack.fromMap(data, 'adm_combo');
      expect(deserialized.id, 'adm_combo');
      expect(deserialized.title, 'Admin Pack');
      expect(deserialized.realPrice, 500.0);
      expect(deserialized.isActive, false);
      expect(deserialized.createdAt, createdTime);

      final updated = pack.copyWith(
        title: 'New Title',
        isActive: true,
      );
      expect(updated.title, 'New Title');
      expect(updated.isActive, true);
      expect(updated.id, 'adm_combo'); // remains unchanged
    });
  });
}
