// ignore_for_file: subtype_of_sealed_class
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eduverse/core/firebase/eduverse_firebase.dart';
import 'package:eduverse/study/presentation/widgets/study_ebooks_content.dart';
import 'package:eduverse/study/presentation/screens/secure_pdf_viewer_screen.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/admin/models/admin_models.dart';
import 'package:eduverse/store/services/cart_service.dart';
import 'package:eduverse/admin/services/firebase_admin_service.dart';
import 'package:eduverse/core/firebase/purchase_service.dart';
import 'package:eduverse/core/firebase/promo_code_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eduverse/core/services/new_batch_promotion_service.dart';
import 'package:eduverse/core/services/live_class_notifier_service.dart';

// Mocks for testing commitInChunks
class MockFirestore extends Fake implements FirebaseFirestore {
  final List<MockWriteBatch> batches = [];

  @override
  WriteBatch batch() {
    final b = MockWriteBatch();
    batches.add(b);
    return b;
  }
}

class MockWriteBatch extends Fake implements WriteBatch {
  final Map<DocumentReference, Map<String, dynamic>> setWrites = {};
  int operationsCount = 0;
  int commitsCount = 0;

  @override
  void set<T>(DocumentReference<T> documentReference, T data, [SetOptions? options]) {
    setWrites[documentReference as DocumentReference] = data as Map<String, dynamic>;
    operationsCount++;
  }

  @override
  void update(DocumentReference documentReference, Map<Object, Object?> data) {
    operationsCount++;
  }

  @override
  void delete(DocumentReference documentReference) {
    operationsCount++;
  }

  @override
  Future<void> commit() async {
    commitsCount++;
  }
}

class MockDocumentReference extends Fake implements DocumentReference {}

// Mocks for testing backfill migration
class MockMigrationFirestore extends Fake implements FirebaseFirestore {
  final MockQueryCollection purchasesCollection = MockQueryCollection();
  final MockQueryCollection comboCollection = MockQueryCollection();
  final MockUsersCollection usersCollection = MockUsersCollection();
  final MockWriteBatch batchInstance = MockWriteBatch();

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    if (path == 'purchases') return purchasesCollection;
    if (path == 'combination_packs') return comboCollection;
    if (path == 'users') return usersCollection;
    throw UnimplementedError('Collection path $path not mocked');
  }

  @override
  WriteBatch batch() => batchInstance;
}

class MockQueryCollection extends Fake implements CollectionReference<Map<String, dynamic>> {
  final List<DocumentSnapshot<Map<String, dynamic>>> docs = [];

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return MockQuerySnapshot(docs);
  }
}

class MockQuerySnapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  MockQuerySnapshot(List<DocumentSnapshot<Map<String, dynamic>>> documentSnapshots)
      : docs = documentSnapshots.cast<QueryDocumentSnapshot<Map<String, dynamic>>>();
}

class MockQueryDocumentSnapshot extends Fake implements QueryDocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic> _data;

  MockQueryDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Map<String, dynamic> data([SnapshotOptions? options]) => _data;

  @override
  DocumentReference<Map<String, dynamic>> get reference => MockDocumentReferenceWithPath(id);
}

class MockDocumentReferenceWithPath extends Fake implements DocumentReference<Map<String, dynamic>> {
  final String pathId;
  MockDocumentReferenceWithPath(this.pathId);

  @override
  String get id => pathId;
}

class MockUsersCollection extends Fake implements CollectionReference<Map<String, dynamic>> {
  final Map<String, MockUserDocumentReference> userDocs = {};

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return userDocs.putIfAbsent(path!, () => MockUserDocumentReference(path));
  }
}

class MockUserDocumentReference extends Fake implements DocumentReference<Map<String, dynamic>> {
  final String userId;
  final Map<String, dynamic> setWrites = {};
  final Map<String, MockSubcollection> subcollections = {};

  MockUserDocumentReference(this.userId);

  @override
  String get id => userId;

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    setWrites.addAll(data);
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return subcollections.putIfAbsent(path, () => MockSubcollection());
  }
}

class MockSubcollection extends Fake implements CollectionReference<Map<String, dynamic>> {
  final Map<String, MockUserDocumentReference> docs = {};

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return docs.putIfAbsent(path!, () => MockUserDocumentReference(path));
  }
}

// Mocks for NewBatchPromotionService and LiveClassNotifierService
class MockAuth extends Fake implements FirebaseAuth {
  final User? mockUser;
  MockAuth(this.mockUser);

  @override
  User? get currentUser => mockUser;

  @override
  Stream<User?> authStateChanges() => Stream.value(mockUser);
}

class MockUser extends Fake implements User {
  final String mockUid;
  MockUser(this.mockUid);

  @override
  String get uid => mockUid;
}

class MockSharedPreferences extends Fake implements SharedPreferences {
  final Map<String, bool> values = {};

  @override
  bool? getBool(String key) => values[key];

  @override
  Future<bool> setBool(String key, bool value) async {
    values[key] = value;
    return true;
  }
}

class MockPromoFirestore extends Fake implements FirebaseFirestore {
  final MockPromoCoursesCollection coursesCollection = MockPromoCoursesCollection();
  final MockPromoUsersCollection usersCollection = MockPromoUsersCollection();

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    if (path == 'courses') return coursesCollection;
    if (path == 'users') return usersCollection;
    throw UnimplementedError('Collection path $path not mocked');
  }
}

class MockPromoCoursesCollection extends Fake implements CollectionReference<Map<String, dynamic>> {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];
  final Map<String, MockPromoCourseDocRef> courseDocs = {};

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return courseDocs.putIfAbsent(path!, () => MockPromoCourseDocRef(path));
  }

  @override
  Query<Map<String, dynamic>> where(Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    return this;
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return MockQuerySnapshot(docs);
  }
}

class MockPromoCourseDocRef extends Fake implements DocumentReference<Map<String, dynamic>> {
  final String courseId;
  final MockPromoEnrolledCollection liveClassesCollection = MockPromoEnrolledCollection();

  MockPromoCourseDocRef(this.courseId);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    if (path == 'live_classes') return liveClassesCollection;
    throw UnimplementedError('Subcollection path $path not mocked');
  }
}

class MockPromoUsersCollection extends Fake implements CollectionReference<Map<String, dynamic>> {
  final Map<String, MockPromoUserDocRef> userDocs = {};

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return userDocs.putIfAbsent(path!, () => MockPromoUserDocRef(path));
  }
}

class MockPromoUserDocRef extends Fake implements DocumentReference<Map<String, dynamic>> {
  final String userId;
  final MockPromoEnrolledCollection enrolledCollection = MockPromoEnrolledCollection();

  MockPromoUserDocRef(this.userId);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    if (path == 'enrolledCourses') return enrolledCollection;
    throw UnimplementedError('Subcollection path $path not mocked');
  }
}

class MockPromoEnrolledCollection extends Fake implements CollectionReference<Map<String, dynamic>> {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];

  @override
  Query<Map<String, dynamic>> where(Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    return this;
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return MockQuerySnapshot(docs);
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    return Stream.value(MockQuerySnapshot(docs));
  }
}

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

    test('CartItem.fromJson handles null vs empty vs present fields safely', () {
      // 1. All fields present
      final jsonBoth = {
        'courseId': 'c123',
        'batchId': 'b456',
        'combinationPackId': 'combo789',
        'testSeriesId': 'ts456',
        'title': 'Test Item',
        'price': 150.0,
        'quantity': 2,
      };
      final itemBoth = CartItem.fromJson(jsonBoth);
      expect(itemBoth.combinationPackId, 'combo789');
      expect(itemBoth.testSeriesId, 'ts456');

      // 2. combinationPackId is empty string, testSeriesId is null
      final jsonEmptyPack = {
        'courseId': 'c123',
        'batchId': 'b456',
        'combinationPackId': '',
        'testSeriesId': null,
        'title': 'Test Item',
        'price': 150.0,
      };
      final itemEmptyPack = CartItem.fromJson(jsonEmptyPack);
      expect(itemEmptyPack.combinationPackId, '');
      expect(itemEmptyPack.testSeriesId, isNull);

      // 3. combinationPackId and testSeriesId missing entirely
      final jsonMissing = {
        'courseId': 'c123',
        'batchId': 'b456',
        'title': 'Test Item',
        'price': 150.0,
      };
      final itemMissing = CartItem.fromJson(jsonMissing);
      expect(itemMissing.combinationPackId, isNull);
      expect(itemMissing.testSeriesId, isNull);
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
      expect(pack.batches[1]['batchId'], '');
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
        courses: const ['c1'],
        testSeries: const ['ts1'],
        isActive: false,
        createdAt: createdTime,
      );

      final Map<String, dynamic> data = pack.toMap();
      expect(data['title'], 'Admin Pack');
      expect(data['realPrice'], 500.0);
      expect(data['isActive'], false);
      expect(data['createdAt'], isNull);

      final Map<String, dynamic> firestoreData = {
        ...data,
        'createdAt': Timestamp.fromDate(createdTime),
      };

      final deserialized = AdminCombinationPack.fromMap(firestoreData, 'adm_combo');
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

  group('Remediation Extended Unit Tests', () {
    test('CartService.getCartDocId returns correct ID format for all types', () {
      final cartService = CartService();

      // Legacy/standard item
      final courseBatchItem = CartItem(
        courseId: 'c123',
        batchId: 'b456',
        title: 'Physics course batch',
        price: 999.0,
      );
      expect(cartService.getCartDocId(courseBatchItem), 'c123_b456');

      // Combination pack item
      final comboPackItem = CartItem(
        courseId: '',
        batchId: '',
        combinationPackId: 'combo789',
        title: 'Awesome Combination Pack',
        price: 1999.0,
      );
      expect(cartService.getCartDocId(comboPackItem), 'combo_combo789');

      // Test series item (using legacy/backward-compatible scheme)
      final testSeriesItem = CartItem(
        courseId: 'ts456',
        batchId: 'test_series',
        testSeriesId: 'ts456',
        title: 'Mega Test Series',
        price: 499.0,
      );
      expect(cartService.getCartDocId(testSeriesItem), 'ts456_test_series');
    });

    test('PromoCartItem.uniqueKey returns correct formatted key', () {
      // Combination pack
      const comboPromoItem = PromoCartItem(
        courseId: '',
        batchId: '',
        combinationPackId: 'combo789',
        price: 1999.0,
      );
      expect(comboPromoItem.uniqueKey, 'combo_combo789');

      // Test series (using legacy/backward-compatible scheme)
      const testSeriesPromoItem = PromoCartItem(
        courseId: 'ts456',
        batchId: 'test_series',
        testSeriesId: 'ts456',
        price: 499.0,
      );
      expect(testSeriesPromoItem.uniqueKey, 'ts456_test_series');

      // Standard item
      const standardPromoItem = PromoCartItem(
        courseId: 'c123',
        batchId: 'b456',
        price: 999.0,
      );
      expect(standardPromoItem.uniqueKey, 'c123_b456');
    });

    test('PromoCode.isApplicableToItem checks exclusion and inclusion limits correctly', () {
      // Promo code with no course restrictions (but combos/test series excluded by default)
      const generalPromo = PromoCode(
        code: 'WELCOME50',
        type: 'percentage',
        value: 50.0,
      );

      // Promo code with explicit combination pack / test series inclusion
      const inclusivePromo = PromoCode(
        code: 'INCLUSIVE',
        type: 'percentage',
        value: 10.0,
        applicableCourseIds: ['combo789', 'ts456', 'c123'],
      );

      // Verify general promo: applies to standard course batch
      expect(
        generalPromo.isApplicableToItem(
          courseId: 'c123',
          batchId: 'b456',
        ),
        isTrue,
      );

      // Verify general promo: does NOT apply to combo pack by default
      expect(
        generalPromo.isApplicableToItem(
          courseId: '',
          batchId: '',
          combinationPackId: 'combo789',
        ),
        isFalse,
      );

      // Verify general promo: does NOT apply to test series by default
      expect(
        generalPromo.isApplicableToItem(
          courseId: 'ts456',
          batchId: 'test_series',
          testSeriesId: 'ts456',
        ),
        isFalse,
      );

      // Verify inclusive promo: applies to explicitly allowed combination pack
      expect(
        inclusivePromo.isApplicableToItem(
          courseId: '',
          batchId: '',
          combinationPackId: 'combo789',
        ),
        isTrue,
      );

      // Verify inclusive promo: applies to explicitly allowed test series
      expect(
        inclusivePromo.isApplicableToItem(
          courseId: 'ts456',
          batchId: 'test_series',
          testSeriesId: 'ts456',
        ),
        isTrue,
      );

      // Verify inclusive promo: does not apply to non-listed combo pack
      expect(
        inclusivePromo.isApplicableToItem(
          courseId: '',
          batchId: '',
          combinationPackId: 'combo999',
        ),
        isFalse,
      );
    });

    test('AdminCombinationPack parses updatedAt correctly with fallback logic', () {
      final now = DateTime.now();
      final createdAtTimestamp = Timestamp.fromDate(now.subtract(const Duration(days: 1)));
      final updatedAtTimestamp = Timestamp.fromDate(now);

      // 1. Parse map with both createdAt and updatedAt
      final dataWithBoth = {
        'title': 'Test Combo Pack',
        'realPrice': 1200.0,
        'finalPrice': 600.0,
        'batches': <Map<String, String>>[],
        'testSeries': <String>[],
        'isActive': true,
        'createdAt': createdAtTimestamp,
        'updatedAt': updatedAtTimestamp,
      };

      final parsedBoth = AdminCombinationPack.fromMap(dataWithBoth, 'pack_123');
      expect(parsedBoth.createdAt, createdAtTimestamp.toDate());
      expect(parsedBoth.updatedAt, updatedAtTimestamp.toDate());

      // 2. Parse map with missing updatedAt (should fallback to createdAt)
      final dataMissingUpdated = {
        'title': 'Test Combo Pack',
        'realPrice': 1200.0,
        'finalPrice': 600.0,
        'batches': <Map<String, String>>[],
        'testSeries': <String>[],
        'isActive': true,
        'createdAt': createdAtTimestamp,
      };

      final parsedMissingUpdated = AdminCombinationPack.fromMap(dataMissingUpdated, 'pack_456');
      expect(parsedMissingUpdated.createdAt, createdAtTimestamp.toDate());
      expect(parsedMissingUpdated.updatedAt, createdAtTimestamp.toDate()); // fallback matches createdAt
    });

    test('FirebaseAdminService.commitInChunks handles boundary limits correctly', () async {
      final mockFirestore = MockFirestore();
      final adminService = FirebaseAdminService(db: mockFirestore);

      // 1. 0 operations
      await adminService.commitInChunks([]);
      expect(mockFirestore.batches.length, 0);

      // 2. 400 operations (exactly 1 chunk)
      final docRef = MockDocumentReference();
      final ops400 = List<void Function(WriteBatch)>.generate(
        400,
        (index) => (batch) => batch.delete(docRef),
      );
      await adminService.commitInChunks(ops400);
      expect(mockFirestore.batches.length, 1);
      expect(mockFirestore.batches[0].operationsCount, 400);
      expect(mockFirestore.batches[0].commitsCount, 1);

      // 3. 401 operations (should break into 2 chunks: 400 and 1)
      mockFirestore.batches.clear();
      final ops401 = List<void Function(WriteBatch)>.generate(
        401,
        (index) => (batch) => batch.delete(docRef),
      );
      await adminService.commitInChunks(ops401);
      expect(mockFirestore.batches.length, 2);
      expect(mockFirestore.batches[0].operationsCount, 400);
      expect(mockFirestore.batches[0].commitsCount, 1);
      expect(mockFirestore.batches[1].operationsCount, 1);
      expect(mockFirestore.batches[1].commitsCount, 1);
    });

    test('PurchaseService migrateExistingPurchasesToUserDoc processes combo packs and test series correctly', () async {
      final mockFirestore = MockMigrationFirestore();
      final purchaseService = PurchaseService(firestore: mockFirestore);

      // 1. Setup a mock combination pack in combination_packs collection
      final comboPackDoc = MockQueryDocumentSnapshot('combo123', {
        'batches': [
          {'courseId': 'courseA', 'batchId': 'batchA'},
          {'courseId': 'courseB', 'batchId': 'batchB'},
        ],
        'testSeries': ['tsA', 'tsB'],
        'isActive': true,
      });
      mockFirestore.comboCollection.docs.add(comboPackDoc);

      // 2. Setup a successful purchase of this combo pack in purchases collection
      final purchaseDoc = MockQueryDocumentSnapshot('purchase123', {
        'userId': 'userXYZ',
        'status': 'completed',
        'items': [
          {
            'courseId': '',
            'batchId': '',
            'combinationPackId': 'combo123',
          }
        ]
      });
      mockFirestore.purchasesCollection.docs.add(purchaseDoc);

      // 3. Run migration
      final result = await purchaseService.migrateExistingPurchasesToUserDoc();
      expect(result, contains('Migration complete'));

      // 4. Verify mock document sets
      final userXYZDoc = mockFirestore.usersCollection.userDocs['userXYZ'];
      expect(userXYZDoc, isNotNull);
      expect(userXYZDoc!.setWrites['enrolledCourses'], isNotNull);
      expect(userXYZDoc.setWrites['purchasedTestSeries'], isNotNull);

      // Verify subcollection docs were set
      final subRef1 = userXYZDoc.subcollections['enrolledCourses']?.docs['courseA'];
      expect(subRef1, isNotNull);
      expect(subRef1!.setWrites['status'], 'active');
      expect(subRef1.setWrites['courseId'], 'courseA');

      final subRef2 = userXYZDoc.subcollections['enrolledCourses']?.docs['courseB'];
      expect(subRef2, isNotNull);
      expect(subRef2!.setWrites['status'], 'active');
      expect(subRef2.setWrites['courseId'], 'courseB');
    });
  });

  group('NewBatchPromotionService Unit Tests', () {
    test('getEligiblePromotion returns correct promo and filters enrolled courses & dismissed promos', () async {
      final mockFirestore = MockPromoFirestore();
      final mockAuth = MockAuth(MockUser('user123'));
      final mockPrefs = MockSharedPreferences();

      final promoService = NewBatchPromotionService(
        firestore: mockFirestore,
        auth: mockAuth,
        prefs: mockPrefs,
      );

      // Add courses in courses collection
      mockFirestore.coursesCollection.docs.addAll([
        MockQueryDocumentSnapshot('course_physics', {
          'title': 'Physics Course',
          'subtitle': 'Learn physics',
          'emoji': '⚡',
          'isActive': true,
          'visibility': 'published',
          'startDate': Timestamp.fromDate(DateTime(2026, 6, 1)),
        }),
        MockQueryDocumentSnapshot('course_math', {
          'title': 'Math Course',
          'subtitle': 'Learn math',
          'emoji': '📐',
          'isActive': true,
          'visibility': 'published',
          'startDate': Timestamp.fromDate(DateTime(2026, 6, 10)), // newer launch
        }),
        MockQueryDocumentSnapshot('course_chemistry', {
          'title': 'Chemistry Course',
          'subtitle': 'Learn chemistry',
          'emoji': '🧪',
          'isActive': true,
          'visibility': 'published',
          'startDate': Timestamp.fromDate(DateTime(2026, 5, 20)), // older launch
        }),
      ]);

      // Initially, user is not enrolled in anything and has not dismissed anything.
      // So the newest course (course_math, 2026-06-10) should be promoted.
      final result1 = await promoService.getEligiblePromotion();
      expect(result1, isNotNull);
      expect(result1!.course.id, 'course_math');
      expect(result1.course.title, 'Math Course');

      // Now, let's enroll the user in 'course_math'
      final userDoc = mockFirestore.usersCollection.doc('user123') as MockPromoUserDocRef;
      userDoc.enrolledCollection.docs.add(
        MockQueryDocumentSnapshot('course_math', {
          'courseId': 'course_math',
          'status': 'active',
        }),
      );

      // Now 'course_math' is enrolled. The next newest course is 'course_physics' (2026-06-01).
      final result2 = await promoService.getEligiblePromotion();
      expect(result2, isNotNull);
      expect(result2!.course.id, 'course_physics');

      // Now, let's mark 'course_physics' promo as dismissed in SharedPreferences
      mockPrefs.values['shown_promo_batch_course_physics'] = true;

      // The next eligible is chemistry (2026-05-20)
      final result3 = await promoService.getEligiblePromotion();
      expect(result3, isNotNull);
      expect(result3!.course.id, 'course_chemistry');
    });
  });

  group('LiveClassNotifierService Unit Tests', () {
    test('subscribes to live classes and updates activeClasses', () async {
      final mockFirestore = MockPromoFirestore();
      
      // 1. Enroll user in course_physics
      final userDoc = mockFirestore.usersCollection.doc('user123') as MockPromoUserDocRef;
      userDoc.enrolledCollection.docs.add(
        MockQueryDocumentSnapshot('enroll_physics', {
          'courseId': 'course_physics',
          'status': 'active',
        }),
      );

      // 2. Add a live class under course_physics/live_classes
      final courseDoc = mockFirestore.coursesCollection.doc('course_physics') as MockPromoCourseDocRef;
      courseDoc.liveClassesCollection.docs.add(
        MockQueryDocumentSnapshot('live1', {
          'title': 'Intro to Mechanics',
          'description': 'Physics live session',
          'instructorName': 'H. C. Verma',
          'status': 'live',
          'startTime': Timestamp.fromDate(DateTime(2026, 6, 5, 10, 0)),
          'durationMinutes': 60,
          'youtubeUrl': 'https://youtube.com/live_test',
          'thumbnailUrl': 'https://thumbnail.url',
          'subject': 'Mechanics',
          'chapter': 'Kinematics',
        }),
      );

      // 3. Initialize notifier
      final notifier = LiveClassNotifierService(uid: 'user123', firestore: mockFirestore);
      
      // Let the stream subscriptions fire
      await Future.delayed(Duration.zero);

      expect(notifier.activeClasses.length, 1);
      final active = notifier.activeClasses.first;
      expect(active.courseId, 'course_physics');
      expect(active.liveClass.id, 'live1');
      expect(active.liveClass.title, 'Intro to Mechanics');
      expect(active.liveClass.instructorName, 'H. C. Verma');
      expect(active.batchId, '');

      // 4. Test dismissal
      notifier.dismissClass('live1');
      expect(notifier.dismissedClassIds.contains('live1'), isTrue);

      notifier.dispose();
    });
  });

  group('Test Series Progress Calculation Unit Tests', () {
    test('filters attempts to only count those matching currently existing test IDs in the subcollection and uses the correct count as denominator', () {
      final testSeriesId = 'series_1';
      final existingTestIds = {'test_a', 'test_b', 'test_c'};
      final actualTotalTests = existingTestIds.length;

      // Simulated Firestore docs for attempts
      final attemptDocs = [
        {'id': 'series_1_test_a', 'score': 10}, // matches test_a
        {'id': 'series_1_test_b', 'score': 20}, // matches test_b
        {'id': 'series_1_test_deleted', 'score': 30}, // not in existingTestIds
        {'id': 'series_2_test_a', 'score': 40}, // different series ID
      ];

      int completedCount = 0;
      final prefix = '${testSeriesId}_';
      for (final doc in attemptDocs) {
        final docId = doc['id'] as String;
        if (docId.startsWith(prefix)) {
          final testId = docId.substring(prefix.length);
          if (existingTestIds.contains(testId)) {
            completedCount++;
          }
        }
      }

      final total = actualTotalTests > 0 ? actualTotalTests : 1;
      final progressVal = (completedCount / total).clamp(0.0, 1.0);

      expect(completedCount, 2);
      expect(total, 3);
      expect(progressVal, closeTo(2 / 3, 0.001));
    });

    test('handles empty tests list boundary conditions without dividing by zero', () {
      final testSeriesId = 'series_empty';
      final existingTestIds = <String>{};
      final actualTotalTests = existingTestIds.length;

      final attemptDocs = [
        {'id': 'series_empty_test_a'},
      ];

      int completedCount = 0;
      final prefix = '${testSeriesId}_';
      for (final doc in attemptDocs) {
        final docId = doc['id'] as String;
        if (docId.startsWith(prefix)) {
          final testId = docId.substring(prefix.length);
          if (existingTestIds.contains(testId)) {
            completedCount++;
          }
        }
      }

      final total = actualTotalTests > 0 ? actualTotalTests : 1;
      final progressVal = (completedCount / total).clamp(0.0, 1.0);

      expect(completedCount, 0);
      expect(total, 1);
      expect(progressVal, 0.0);
    });
  });

  group('Ebook Model and Cart Integration Tests', () {
    test('Ebook.fromMap parses standard map data correctly', () {
      final map = {
        'title': 'Test E-book',
        'subtitle': 'John Doe',
        'description': 'A book about test development.',
        'thumbnailUrl': 'https://example.com/thumb.png',
        'pdfUrl': 'https://example.com/book.pdf',
        'realPrice': 500.0,
        'finalPrice': 299.0,
        'isActive': true,
      };

      final ebook = Ebook.fromMap(map, 'eb_123', isOwned: true);

      expect(ebook.id, 'eb_123');
      expect(ebook.title, 'Test E-book');
      expect(ebook.subtitle, 'John Doe');
      expect(ebook.description, 'A book about test development.');
      expect(ebook.thumbnailUrl, 'https://example.com/thumb.png');
      expect(ebook.pdfUrl, 'https://example.com/book.pdf');
      expect(ebook.realPrice, 500.0);
      expect(ebook.finalPrice, 299.0);
      expect(ebook.isActive, true);
      expect(ebook.isOwned, true);
    });

    test('Ebook.toMap serializes correctly', () {
      final ebook = Ebook(
        id: 'eb_456',
        title: 'Serialized Ebook',
        subtitle: 'Jane Smith',
        description: 'Description here',
        thumbnailUrl: 'https://example.com/image.png',
        pdfUrl: 'https://example.com/doc.pdf',
        realPrice: 400.0,
        finalPrice: 199.0,
        isActive: false,
      );

      final map = ebook.toMap();

      expect(map['title'], 'Serialized Ebook');
      expect(map['subtitle'], 'Jane Smith');
      expect(map['description'], 'Description here');
      expect(map['thumbnailUrl'], 'https://example.com/image.png');
      expect(map['pdfUrl'], 'https://example.com/doc.pdf');
      expect(map['realPrice'], 400.0);
      expect(map['finalPrice'], 199.0);
      expect(map['isActive'], false);
    });

    test('CartItem serialization supports ebookId correctly', () {
      final cartItem = CartItem(
        courseId: '',
        batchId: '',
        ebookId: 'eb_789',
        title: 'Cart Ebook',
        price: 299.0,
        quantity: 1,
      );

      final json = cartItem.toJson();
      expect(json['ebookId'], 'eb_789');

      final parsed = CartItem.fromJson(json);
      expect(parsed.ebookId, 'eb_789');
      expect(parsed.courseId, '');
      expect(parsed.batchId, '');
      expect(parsed.title, 'Cart Ebook');
      expect(parsed.price, 299.0);
      expect(parsed.quantity, 1);
    });
  });

  group('StudyEbooksContent Widget Tests', () {
    final MockEbooksFirestore mockFirestore = MockEbooksFirestore();
    late MockAuth mockAuth;

    setUpAll(() {
      EduverseFirebase.mockFirestore = mockFirestore;
    });

    setUp(() {
      mockFirestore.clear();
      mockAuth = MockAuth(MockUser('user123'));
      EduverseFirebase.mockAuth = mockAuth;
      PdfNavigationManager.reset();
    });

    testWidgets('displays empty state when there are no e-books', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StudyEbooksContent(),
        ),
      ));

      // Wait for stream to emit
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
      expect(find.text('No e-books yet'), findsOneWidget);
      expect(find.text('Purchase e-books from the Store to read them here!'), findsOneWidget);
    });

    testWidgets('displays empty state when ebooks exist but none are owned', (WidgetTester tester) async {
      mockFirestore.ebooksCollection.docs.add(
        MockQueryDocumentSnapshot('eb1', {
          'title': 'Intro to Coding',
          'subtitle': 'Compiler Creator',
          'description': 'A nice programming book',
          'thumbnailUrl': 'https://image.url',
          'pdfUrl': 'https://pdf.url',
          'realPrice': 50.0,
          'finalPrice': 25.0,
          'isActive': true,
        }),
      );

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StudyEbooksContent(),
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Intro to Coding'), findsNothing);
      expect(find.text('No e-books yet'), findsOneWidget);
    });

    testWidgets('displays e-book cards and responds to tap/button to open PDF', (WidgetTester tester) async {
      final mockLauncher = MockUrlLauncher();
      UrlLauncherPlatform.instance = mockLauncher;

      mockFirestore.ebooksCollection.docs.add(
        MockQueryDocumentSnapshot('eb1', {
          'title': 'Intro to Coding',
          'subtitle': 'Compiler Creator',
          'description': 'A nice programming book',
          'thumbnailUrl': 'https://image.url',
          'pdfUrl': 'https://pdf.url',
          'realPrice': 50.0,
          'finalPrice': 25.0,
          'isActive': true,
        }),
      );

      // Add to user's purchased ebooks
      final userDoc = mockFirestore.usersCollection.doc('user123') as MockEbooksUserDocRef;
      userDoc.purchasedCollection.docs.add(
        MockQueryDocumentSnapshot('eb1', {}),
      );

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StudyEbooksContent(),
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Intro to Coding'), findsOneWidget);
      expect(find.text('Compiler Creator'), findsOneWidget);
      expect(find.text('No e-books yet'), findsNothing);

      // Tap the "Read E-book" button
      await tester.tap(find.text('Read E-book'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SecurePdfViewerScreen), findsOneWidget);
    });
  });

  group('FolderClipboard Unit Tests', () {
    test('copy, clear, and hasData work correctly', () {
      FolderClipboard.clear();
      expect(FolderClipboard.hasData, isFalse);

      FolderClipboard.copy(
        courseId: 'c1',
        subject: 's1',
        folderPath: 'p1',
        folderName: 'n1',
      );

      expect(FolderClipboard.hasData, isTrue);
      expect(FolderClipboard.sourceCourseId, 'c1');
      expect(FolderClipboard.sourceSubject, 's1');
      expect(FolderClipboard.sourceFolderPath, 'p1');
      expect(FolderClipboard.sourceFolderName, 'n1');

      FolderClipboard.clear();

      expect(FolderClipboard.hasData, isFalse);
      expect(FolderClipboard.sourceCourseId, isNull);
    });
  });
}

class MockUrlLauncher extends Fake with MockPlatformInterfaceMixin implements UrlLauncherPlatform {
  String? launchedUrl;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrl = url;
    return true;
  }
}

class MockEbooksFirestore extends Fake implements FirebaseFirestore {
  final MockEbooksCollection ebooksCollection = MockEbooksCollection();
  final MockEbooksUsersCollection usersCollection = MockEbooksUsersCollection();

  void clear() {
    ebooksCollection.docs.clear();
    usersCollection.userDocs.clear();
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    if (path == 'ebooks') return ebooksCollection;
    if (path == 'users') return usersCollection;
    throw UnimplementedError('Collection path $path not mocked');
  }
}

class MockEbooksCollection extends Fake implements CollectionReference<Map<String, dynamic>> {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];

  @override
  Query<Map<String, dynamic>> where(Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    return this;
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    return Stream.value(MockQuerySnapshot(docs));
  }
}

class MockEbooksUsersCollection extends Fake implements CollectionReference<Map<String, dynamic>> {
  final Map<String, MockEbooksUserDocRef> userDocs = {};

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return userDocs.putIfAbsent(path!, () => MockEbooksUserDocRef(path));
  }
}

class MockEbooksUserDocRef extends Fake implements DocumentReference<Map<String, dynamic>> {
  final String userId;
  final MockEbooksPurchasedCollection purchasedCollection = MockEbooksPurchasedCollection();

  MockEbooksUserDocRef(this.userId);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    if (path == 'purchasedEbooks') return purchasedCollection;
    throw UnimplementedError('Subcollection path $path not mocked');
  }
}

class MockEbooksPurchasedCollection extends Fake implements CollectionReference<Map<String, dynamic>> {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return MockQuerySnapshot(docs);
  }
}
