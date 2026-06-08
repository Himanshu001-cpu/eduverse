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

  /// Link a test series to a specific course.
  Future<void> linkToCourse(String tsId, LinkedCourse course) async {
    await _collection.doc(tsId).update({
      'linkedCourses': FieldValue.arrayUnion([course.toMap()]),
    });
  }

  /// Unlink a test series from a specific course.
  Future<void> unlinkFromCourse(
    String tsId,
    String courseId,
  ) async {
    final doc = await _collection.doc(tsId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final courses = (data['linkedCourses'] as List<dynamic>? ?? [])
        .map((b) => b as Map<String, dynamic>)
        .where((b) => b['courseId'] != courseId)
        .toList();

    await _collection.doc(tsId).update({'linkedCourses': courses});
  }

  /// Get test series linked to a specific course.
  Stream<List<AdminTestSeries>> getTestSeriesForCourse(String courseId) {
    return _collection.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => AdminTestSeries.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .where(
            (ts) => ts.linkedCourses.any(
              (c) => c.courseId == courseId,
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
