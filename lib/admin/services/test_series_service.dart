import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/test_series_models.dart';

/// Admin service for managing Test Series in Firestore.
/// Collection path: `test_series/{testSeriesId}`
/// Sub-collection for tests: `test_series/{testSeriesId}/tests/{testId}`
class TestSeriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore.collection('test_series');

  /// Stream all test series (admin view — includes drafts).
  Stream<List<AdminTestSeries>> getTestSeriesList() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AdminTestSeries.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  /// Get a single test series by ID.
  Future<AdminTestSeries?> getTestSeries(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return AdminTestSeries.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Create a new test series.
  Future<String> createTestSeries(AdminTestSeries ts) async {
    final docRef = await _collection.add(ts.toMap());
    return docRef.id;
  }

  /// Update an existing test series.
  Future<void> updateTestSeries(AdminTestSeries ts) async {
    await _collection.doc(ts.id).update(ts.toMap());
  }

  /// Delete a test series and its sub-collection of tests.
  Future<void> deleteTestSeries(String id) async {
    // Delete all tests in sub-collection first
    final testsSnapshot = await _collection.doc(id).collection('tests').get();
    for (final doc in testsSnapshot.docs) {
      await doc.reference.delete();
    }
    await _collection.doc(id).delete();
  }

  /// Link a test series to a specific course batch.
  Future<void> linkToBatch(String tsId, LinkedBatch batch) async {
    await _collection.doc(tsId).update({
      'linkedBatches': FieldValue.arrayUnion([batch.toMap()]),
    });
  }

  /// Unlink a test series from a specific course batch.
  Future<void> unlinkFromBatch(
    String tsId,
    String courseId,
    String batchId,
  ) async {
    final doc = await _collection.doc(tsId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final batches = (data['linkedBatches'] as List<dynamic>? ?? [])
        .map((b) => b as Map<String, dynamic>)
        .where((b) => !(b['courseId'] == courseId && b['batchId'] == batchId))
        .toList();

    await _collection.doc(tsId).update({'linkedBatches': batches});
  }

  /// Get test series linked to a specific batch.
  Stream<List<AdminTestSeries>> getTestSeriesForBatch(
    String courseId,
    String batchId,
  ) {
    return _collection.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => AdminTestSeries.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .where(
            (ts) => ts.linkedBatches.any(
              (b) => b.courseId == courseId && b.batchId == batchId,
            ),
          )
          .toList(),
    );
  }

  /// Update the totalTests count on a test series document.
  Future<void> updateTestCount(String tsId) async {
    final testsSnapshot = await _collection.doc(tsId).collection('tests').get();
    await _collection.doc(tsId).update({
      'totalTests': testsSnapshot.docs.length,
    });
  }
}
