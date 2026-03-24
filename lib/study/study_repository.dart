import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/domain/repositories/i_study_repository.dart';
import 'package:eduverse/study/models/study_models.dart';

class StudyRepository implements IStudyRepository {
  final FirebaseFirestore _firestore;

  StudyRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<StudyBatch>> getEnrolledBatches(String userId) {
    if (userId.isEmpty) return Stream.value([]);

    return Stream.fromFuture(_checkIsAdmin(userId)).asyncExpand((isAdmin) {
      if (isAdmin) {
        // Admin: Listen to ALL batches across all courses
        return _firestore.collection('courses').snapshots().asyncMap((
          coursesSnap,
        ) async {
          List<StudyBatch> allBatches = [];
          for (var courseDoc in coursesSnap.docs) {
            final courseData = courseDoc.data();
            final batchesSnap = await courseDoc.reference
                .collection('batches')
                .get();
            for (var batchDoc in batchesSnap.docs) {
              final progressData = await _fetchBatchProgress(
                userId,
                courseDoc.id,
                batchDoc.id,
              );
              allBatches.add(
                _mapToStudyBatch(
                  batchDoc.id,
                  courseDoc.id,
                  batchDoc.data(),
                  courseData,
                  progressData.progress,
                  progressData.completed,
                ),
              );
            }
          }
          return allBatches;
        });
      } else {
        // Standard User: Listen to 'enrolledCourses' subcollection for direct access
        return _firestore
            .collection('users')
            .doc(userId)
            .collection('enrolledCourses')
            .snapshots()
            .asyncMap((snapshot) async {
              if (snapshot.docs.isEmpty) return [];

              // Extract unique batch references
              final List<({String courseId, String batchId})> batchRefs = [];

              for (var doc in snapshot.docs) {
                final data = doc.data();
                // New structure: simple fields in the enrolled document
                final courseId = data['courseId'] as String?;
                final batchId = data['batchId'] as String?;

                if (courseId != null && batchId != null) {
                  final exists = batchRefs.any(
                    (ref) => ref.courseId == courseId && ref.batchId == batchId,
                  );
                  if (!exists) {
                    batchRefs.add((courseId: courseId, batchId: batchId));
                  }
                }
              }

              if (batchRefs.isEmpty) return [];

              List<StudyBatch> studyBatches = [];
              for (var ref in batchRefs) {
                try {
                  // Fetch course data
                  final courseDoc = await _firestore
                      .collection('courses')
                      .doc(ref.courseId)
                      .get();
                  if (!courseDoc.exists) continue;
                  final courseData = courseDoc.data()!;

                  // Fetch batch data
                  final batchDoc = await courseDoc.reference
                      .collection('batches')
                      .doc(ref.batchId)
                      .get();
                  if (!batchDoc.exists) continue;

                  final progressData = await _fetchBatchProgress(
                    userId,
                    ref.courseId,
                    ref.batchId,
                  );

                  studyBatches.add(
                    _mapToStudyBatch(
                      ref.batchId,
                      ref.courseId,
                      batchDoc.data()!,
                      courseData,
                      progressData.progress,
                      progressData.completed,
                    ),
                  );
                } catch (e) {
                  debugPrint('Error loading batch ${ref.batchId}: $e');
                }
              }
              return studyBatches;
            });
      }
    });
  }

  Future<bool> _checkIsAdmin(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;
      final role = doc.data()?['role'];
      return role == 'admin' || role == 'superadmin';
    } catch (e) {
      return false;
    }
  }

  Future<({double progress, int completed})> _fetchBatchProgress(
    String userId,
    String courseId,
    String batchId,
  ) async {
    try {
      final progressDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('batchProgress')
          .doc('${courseId}_$batchId')
          .get();

      if (progressDoc.exists) {
        final pData = progressDoc.data()!;
        return (
          progress: (pData['progressPercent'] as num?)?.toDouble() ?? 0.0,
          completed: pData['completedLectures'] as int? ?? 0,
        );
      }
    } catch (e) {
      // ignore
    }
    return (progress: 0.0, completed: 0);
  }

  StudyBatch _mapToStudyBatch(
    String batchId,
    String courseId,
    Map<String, dynamic> batchData,
    Map<String, dynamic> courseData,
    double progress,
    int completed,
  ) {
    List<Color> gradient = [const Color(0xFF4A90E2), const Color(0xFF002966)];
    if (courseData['gradientColors'] != null) {
      gradient = (courseData['gradientColors'] as List)
          .map((c) => Color(c as int))
          .toList();
    }

    final thumbnailUrl =
        (batchData['thumbnailUrl'] as String?)?.isNotEmpty == true
        ? batchData['thumbnailUrl'] as String
        : (courseData['thumbnailUrl'] as String?) ?? '';

    return StudyBatch(
      id: batchId,
      courseId: courseId,
      name: batchData['name'] ?? 'Untitled Batch',
      courseName: courseData['title'] ?? 'Untitled Course',
      emoji: courseData['emoji'] ?? '🎓',
      gradientColors: gradient,
      thumbnailUrl: thumbnailUrl,
      startDate:
          (batchData['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalLectures:
          batchData['totalLectures'] ?? courseData['totalLectures'] ?? 0,
      completedLectures: completed,
      progress: progress,
    );
  }

  @override
  Future<List<StudyLecture>> getBatchLectures(
    String userId,
    String courseId,
    String batchId,
  ) async {
    final snapshot = await _firestore
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('lessons')
        .orderBy('orderIndex')
        .get();

    return await _mapLectures(
      snapshot,
      userId,
      courseId,
      batchId,
      checkProgress: true,
    );
  }

  @override
  Stream<List<StudyLecture>> getBatchLecturesStream(
    String userId,
    String courseId,
    String batchId,
  ) {
    return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('lessons')
        .orderBy('orderIndex')
        .snapshots()
        .asyncMap(
          (snapshot) => _mapLectures(
            snapshot,
            userId,
            courseId,
            batchId,
            checkProgress: true,
          ),
        );
  }

  Future<List<StudyLecture>> _mapLectures(
    QuerySnapshot snapshot,
    String userId,
    String courseId,
    String batchId, {
    bool checkProgress = false,
  }) async {
    List<StudyLecture> lectures = [];

    Map<String, bool> watchedStatus = {};
    if (checkProgress && snapshot.docs.isNotEmpty) {
      final progressSnap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('batchProgress')
          .doc('${courseId}_$batchId')
          .collection('lectures')
          .get();

      for (var doc in progressSnap.docs) {
        watchedStatus[doc.id] = doc.data()['watched'] ?? false;
      }
    }

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      lectures.add(
        StudyLecture(
          id: doc.id,
          title: data['title'] ?? 'Untitled Lecture',
          videoUrl: data['videoUrl'] ?? data['storagePath'] ?? '',
          contentUrl: data['contentUrl'] ?? '',
          description: data['description'] ?? '',
          order: data['order'] ?? data['orderIndex'] ?? 0,
          isWatched: watchedStatus[doc.id] ?? false,
          duration: null,
        ),
      );
    }
    return lectures;
  }

  @override
  Future<void> markLectureWatched(
    String userId,
    String courseId,
    String batchId,
    String lectureId,
    bool isWatched,
  ) async {
    final userRef = _firestore.collection('users').doc(userId);
    final batchProgressRef = userRef
        .collection('batchProgress')
        .doc('${courseId}_$batchId');
    final lectureProgressRef = batchProgressRef
        .collection('lectures')
        .doc(lectureId);

    final batch = _firestore.batch();

    batch.set(lectureProgressRef, {
      'watched': isWatched,
      'watchedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();

    await updateBatchProgress(userId, courseId, batchId);
  }

  @override
  Future<void> updateBatchProgress(
    String userId,
    String courseId,
    String batchId,
  ) async {
    final batchRef = _firestore
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId);
    final lessonsSnap = await batchRef.collection('lessons').get();
    int total = lessonsSnap.docs.length;
    if (total == 0) total = 1;

    final watchedSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('batchProgress')
        .doc('${courseId}_$batchId')
        .collection('lectures')
        .where('watched', isEqualTo: true)
        .get();

    int watchedCount = watchedSnap.docs.length;
    double percent = (watchedCount / total).clamp(0.0, 1.0);

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('batchProgress')
        .doc('${courseId}_$batchId')
        .set({
          'progressPercent': percent,
          'completedLectures': watchedCount,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Future<List<StudyQuiz>> getBatchQuizzes(
    String courseId,
    String batchId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('batches')
          .doc(batchId)
          .collection('quizzes')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final questions = (data['questions'] as List<dynamic>?) ?? [];
        return StudyQuiz(
          id: doc.id,
          title: data['title'] ?? 'Untitled Quiz',
          description: data['description'] ?? '',
          questionCount: questions.length,
          durationMinutes: data['durationMinutes'] ?? 30,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching batch quizzes: $e');
      return [];
    }
  }

  @override
  Future<List<StudyNote>> getBatchNotes(String courseId, String batchId) async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('batches')
          .doc(batchId)
          .collection('notes')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return StudyNote(
          id: doc.id,
          title: data['title'] ?? 'Untitled Note',
          fileUrl: data['pdfUrl'] as String?,
          createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching batch notes: $e');
      return [];
    }
  }

  @override
  Future<List<StudyPlannerItem>> getBatchPlanner(
    String courseId,
    String batchId,
  ) async {
    try {
      debugPrint('Fetching planner for course: $courseId, batch: $batchId');
      final snapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('batches')
          .doc(batchId)
          .collection('planner')
          .get();

      debugPrint('Planner query returned ${snapshot.docs.length} documents');

      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        debugPrint('Planner doc ${doc.id}: $data');
        return StudyPlannerItem(
          id: doc.id,
          title: data['title'] ?? 'Untitled Item',
          description: data['subtitle'] as String?,
          dueDate: (data['date'] as Timestamp?)?.toDate(),
          fileUrl: data['pdfUrl'] as String?,
        );
      }).toList();

      items.sort(
        (a, b) => (a.dueDate ?? DateTime.now()).compareTo(
          b.dueDate ?? DateTime.now(),
        ),
      );
      return items;
    } catch (e) {
      debugPrint('Error fetching batch planner: $e');
      return [];
    }
  }

  @override
  Future<List<StudyLiveClass>> getBatchLiveClasses(
    String courseId,
    String batchId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('batches')
          .doc(batchId)
          .collection('live_classes')
          .orderBy('startTime')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return StudyLiveClass(
          id: doc.id,
          title: data['title'] ?? 'Untitled Class',
          description: data['description'] ?? '',
          instructorName: data['instructorName'] ?? '',
          startTime:
              (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 60,
          status: data['status'] ?? 'upcoming',
          youtubeUrl: data['youtubeUrl'] as String?,
          thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching batch live classes: $e');
      return [];
    }
  }

  @override
  Future<List<StudyLiveClass>> getFreeLiveClasses() async {
    try {
      debugPrint('Fetching free live classes...');
      final snapshot = await _firestore.collection('free_live_classes').get();

      debugPrint(
        'Found ${snapshot.docs.length} documents in free_live_classes',
      );

      return snapshot.docs.map((doc) {
        final data = doc.data();
        debugPrint('Doc ${doc.id} data: $data');
        return StudyLiveClass(
          id: doc.id,
          title: data['title'] ?? 'Untitled Class',
          description: data['description'] ?? '',
          instructorName: data['instructorName'] ?? '',
          startTime: _parseDateTime(data['startTime']) ?? DateTime.now(),
          durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 60,
          status: data['status'] ?? 'upcoming',
          youtubeUrl: data['youtubeUrl'] as String?,
          thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching free live classes: $e');
      return [];
    }
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        debugPrint('Error parsing date string: $value');
      }
    }
    return null;
  }

  @override
  Future<StudyBatch?> getBatch(
    String batchId, {
    required String courseId,
  }) async {
    try {
      final courseDoc = await _firestore
          .collection('courses')
          .doc(courseId)
          .get();
      if (!courseDoc.exists) return null;
      final courseData = courseDoc.data()!;

      final batchDoc = await courseDoc.reference
          .collection('batches')
          .doc(batchId)
          .get();
      if (!batchDoc.exists) return null;

      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final progressData = userId.isNotEmpty
          ? await _fetchBatchProgress(userId, courseId, batchId)
          : (progress: 0.0, completed: 0);

      return _mapToStudyBatch(
        batchId,
        courseId,
        batchDoc.data()!,
        courseData,
        progressData.progress,
        progressData.completed,
      );
    } catch (e) {
      debugPrint('Error fetching batch $batchId: $e');
      return null;
    }
  }

  /// Returns a stream of topics for the map work page.
  Stream<List<TopicNodeModel>> getTopics() {
    return _firestore
        .collection('topics')
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TopicNodeModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Returns a stream of enrolled courses for the current user.
  Stream<List<StudyCourseModel>> getEnrolledCourses() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('enrolledCourses')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StudyCourseModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Returns a stream of workbooks assigned to the current user.
  Stream<List<WorkbookModel>> getWorkbooks() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('workbooks')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WorkbookModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Stream<bool> isBatchBookmarked(String userId, String batchId) {
    if (userId.isEmpty) return Stream.value(false);
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('batchBookmarks')
        .doc(batchId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  @override
  Future<void> toggleBatchBookmark(String userId, String batchId) async {
    if (userId.isEmpty) return;
    final bookmarkRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('batchBookmarks')
        .doc(batchId);

    final doc = await bookmarkRef.get();
    if (doc.exists) {
      await bookmarkRef.delete();
    } else {
      await bookmarkRef.set({
        'createdAt': FieldValue.serverTimestamp(),
        'batchId': batchId,
      });
    }
  }
}
