import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/domain/repositories/i_study_repository.dart';
import 'package:eduverse/study/models/study_models.dart';
import 'package:eduverse/study/data/repositories/study_local_storage.dart';
import 'package:eduverse/core/firebase/eduverse_firebase.dart';

class StudyRepositoryImpl implements IStudyRepository {
  final FirebaseFirestore _firestore;

  StudyRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? EduverseFirebase.firestore;

  @override
  Stream<List<StudyBatch>> getEnrolledBatches(String userId) {
    if (userId.isEmpty) return Stream.value([]);

    return Stream.fromFuture(_checkIsAdmin(userId)).asyncExpand((isAdmin) {
      if (isAdmin) {
        // Admin: Listen to ALL courses and ALL combo packs
        return _firestore.collection('courses').snapshots().asyncExpand((coursesSnap) {
          return _firestore.collection('combination_packs').snapshots().asyncMap((combosSnap) async {
            List<StudyBatch> allBatches = [];

            // Add all combo packs
            for (var comboDoc in combosSnap.docs) {
              final comboData = comboDoc.data();
              final List<String> coursesList = [];
              if (comboData['courses'] != null) {
                coursesList.addAll(List<String>.from(comboData['courses']));
              } else if (comboData['batches'] != null) {
                final List<dynamic> legacyBatches = comboData['batches'] ?? [];
                for (var b in legacyBatches) {
                  if (b is Map && b['courseId'] != null) {
                    coursesList.add(b['courseId'].toString());
                  }
                }
              }
              allBatches.add(
                StudyBatch(
                  id: comboDoc.id,
                  courseId: comboDoc.id,
                  name: comboData['title'] ?? 'Combo Pack',
                  courseName: comboData['title'] ?? 'Combo Pack',
                  emoji: '📦',
                  gradientColors: [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
                  thumbnailUrl: comboData['thumbnailUrl'] ?? '',
                  startDate: DateTime.now(),
                  totalLectures: 0,
                  completedLectures: 0,
                  progress: 0.0,
                  isCourseBatch: false,
                  isCombo: true,
                  courseIds: coursesList,
                ),
              );
            }

            // Add all individual courses
            for (var courseDoc in coursesSnap.docs) {
              final courseData = courseDoc.data();
              final progressData = await _fetchCourseProgress(userId, courseDoc.id);
              allBatches.add(
                _mapToStudyBatch(
                  courseDoc.id,
                  courseDoc.id,
                  courseData,
                  progressData.progress,
                  progressData.completed,
                ).copyWith(isCombo: false, courseIds: [courseDoc.id]),
              );
            }

            return allBatches;
          });
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

          final Set<String> comboPackIds = {};
          final List<Map<String, dynamic>> individualCourseEnrollments = [];

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final comboId = data['combinationPackId'] as String?;
            if (comboId != null && comboId.isNotEmpty) {
              comboPackIds.add(comboId);
            } else {
              individualCourseEnrollments.add(data);
            }
          }

          List<StudyBatch> studyBatches = [];
          final Set<String> addedBatchIds = {};

          // 1. Fetch and map Combo Packs
          for (final comboId in comboPackIds) {
            try {
              final comboDoc = await _firestore
                  .collection('combination_packs')
                  .doc(comboId)
                  .get();
              if (!comboDoc.exists) continue;
              final comboData = comboDoc.data()!;

              final List<String> coursesList = [];
              if (comboData['courses'] != null) {
                coursesList.addAll(List<String>.from(comboData['courses']));
              } else if (comboData['batches'] != null) {
                final List<dynamic> legacyBatches = comboData['batches'] ?? [];
                for (var b in legacyBatches) {
                  if (b is Map && b['courseId'] != null) {
                    coursesList.add(b['courseId'].toString());
                  }
                }
              }

              double totalProgress = 0.0;
              int completedCount = 0;
              int lecturesCount = 0;

              for (final courseId in coursesList) {
                final progressData = await _fetchCourseProgress(userId, courseId);
                totalProgress += progressData.progress;
                completedCount += progressData.completed;

                final courseDoc = await _firestore.collection('courses').doc(courseId).get();
                if (courseDoc.exists) {
                  final courseData = courseDoc.data()!;
                  lecturesCount += (courseData['totalLectures'] as num?)?.toInt() ?? 0;

                  // Implicitly add the individual course as a StudyBatch for standard user
                  if (!addedBatchIds.contains(courseId)) {
                    studyBatches.add(
                      _mapToStudyBatch(
                        courseId,
                        courseId,
                        courseData,
                        progressData.progress,
                        progressData.completed,
                      ).copyWith(isCombo: false, courseIds: [courseId]),
                    );
                    addedBatchIds.add(courseId);
                  }
                }
              }

              final double avgProgress = coursesList.isNotEmpty ? (totalProgress / coursesList.length) : 0.0;

              studyBatches.add(
                StudyBatch(
                  id: comboId,
                  courseId: comboId,
                  name: comboData['title'] ?? 'Combo Pack',
                  courseName: comboData['title'] ?? 'Combo Pack',
                  emoji: '📦',
                  gradientColors: [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
                  thumbnailUrl: comboData['thumbnailUrl'] ?? '',
                  startDate: DateTime.now(),
                  totalLectures: lecturesCount,
                  completedLectures: completedCount,
                  progress: avgProgress,
                  isCourseBatch: false,
                  isCombo: true,
                  courseIds: coursesList,
                ),
              );
              addedBatchIds.add(comboId);
            } catch (e) {
              debugPrint('Error loading combo pack $comboId: $e');
            }
          }

          // 2. Fetch and map Individual Courses
          for (var enrollment in individualCourseEnrollments) {
            final courseId = enrollment['courseId'] as String? ?? enrollment['id'];
            if (courseId == null || courseId.isEmpty) continue;
            if (addedBatchIds.contains(courseId)) continue;
            try {
              final courseDoc = await _firestore
                  .collection('courses')
                  .doc(courseId)
                  .get();
              if (!courseDoc.exists) continue;
              final courseData = courseDoc.data()!;

              final progressData = await _fetchCourseProgress(userId, courseId);

              studyBatches.add(
                _mapToStudyBatch(
                  courseId,
                  courseId,
                  courseData,
                  progressData.progress,
                  progressData.completed,
                ).copyWith(isCombo: false, courseIds: [courseId]),
              );
            } catch (e) {
              debugPrint('Error loading individual course $courseId: $e');
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

  Future<({double progress, int completed})> _fetchCourseProgress(
    String userId,
    String courseId,
  ) async {
    try {
      final progressDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('courseProgress')
          .doc(courseId)
          .get();

      if (progressDoc.exists) {
        final pData = progressDoc.data()!;
        return (
          progress: (pData['progressPercent'] as num?)?.toDouble() ?? 0.0,
          completed: pData['completedLectures'] as int? ?? 0,
        );
      }

      // Fallback for legacy batchProgress checks if migrated
      final legacyProgressDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('batchProgress')
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();

      if (legacyProgressDoc.docs.isNotEmpty) {
        final pData = legacyProgressDoc.docs.first.data();
        return (
          progress: (pData['progressPercent'] as num?)?.toDouble() ?? 0.0,
          completed: pData['completedLectures'] as int? ?? 0,
        );
      }
    } catch (e) {
      debugPrint('Error fetching progress for course $courseId: $e');
    }
    return (progress: 0.0, completed: 0);
  }

  StudyBatch _mapToStudyBatch(
    String batchId,
    String courseId,
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

    final thumbnailUrl = (courseData['thumbnailUrl'] as String?) ?? '';

    return StudyBatch(
      id: batchId,
      courseId: courseId,
      name: courseData['title'] ?? 'Untitled Course',
      courseName: courseData['title'] ?? 'Untitled Course',
      emoji: courseData['emoji'] ?? '🎓',
      gradientColors: gradient,
      thumbnailUrl: thumbnailUrl,
      startDate: courseData['startDate'] != null
          ? (courseData['startDate'] is Timestamp
              ? (courseData['startDate'] as Timestamp).toDate()
              : DateTime.tryParse(courseData['startDate'].toString()) ?? DateTime.now())
          : DateTime.now(),
      totalLectures: courseData['totalLectures'] ?? 0,
      completedLectures: completed,
      progress: progress,
      isCourseBatch: courseData['isCourseBatch'] as bool? ?? false,
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
          .collection('courseProgress')
          .doc(courseId)
          .collection('lectures')
          .get();

      for (var doc in progressSnap.docs) {
        watchedStatus[doc.id] = doc.data()['watched'] ?? false;
      }
    }

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      lectures.add(
        StudyLecture.fromMap(data, doc.id).copyWith(
          isWatched: watchedStatus[doc.id] ?? false,
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
    final courseProgressRef = userRef
        .collection('courseProgress')
        .doc(courseId);
    final lectureProgressRef = courseProgressRef
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
    final courseRef = _firestore.collection('courses').doc(courseId);
    final lessonsSnap = await courseRef.collection('lessons').get();
    int total = lessonsSnap.docs.length;
    if (total == 0) total = 1;

    final watchedSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('courseProgress')
        .doc(courseId)
        .collection('lectures')
        .where('watched', isEqualTo: true)
        .get();

    int watchedCount = watchedSnap.docs.length;
    double percent = (watchedCount / total).clamp(0.0, 1.0);

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('courseProgress')
        .doc(courseId)
        .set({
      'progressPercent': percent,
      'completedLectures': watchedCount,
      'lastUpdated': FieldValue.serverTimestamp(),
      'courseId': courseId,
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
          scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching quizzes: $e');
      return [];
    }
  }

  @override
  Future<List<StudyNote>> getBatchNotes(String courseId, String batchId) async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .doc(courseId)
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
          subject: data['subject'] ?? '',
          chapter: data['chapter'] ?? '',
          lectureId: data['lectureId'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching notes: $e');
      return [];
    }
  }

  @override
  Future<List<StudyPlannerItem>> getBatchPlanner(
    String courseId,
    String batchId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('planner')
          .get();

      final items = snapshot.docs.map((doc) {
        final data = doc.data();
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
      debugPrint('Error fetching planner: $e');
      return [];
    }
  }

  @override
  Future<List<StudyDpp>> getBatchDpps(String courseId, String batchId) async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('dpps')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return StudyDpp(
          id: doc.id,
          title: data['title'] ?? '',
          subject: data['subject'] ?? '',
          chapter: data['chapter'] ?? '',
          dppPdfUrl: data['dppPdfUrl'] ?? '',
          solutionPdfUrl: data['solutionPdfUrl'] ?? '',
          lectureId: data['lectureId'] as String?,
          createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching DPPs: $e');
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
          parentRuleId: data['parentRuleId'] as String?,
          generatedDateString: data['generatedDateString'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching live classes: $e');
      return [];
    }
  }

  @override
  Future<List<StudyLiveClass>> getFreeLiveClasses() async {
    try {
      final snapshot = await _firestore.collection('free_live_classes').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
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
          parentRuleId: data['parentRuleId'] as String?,
          generatedDateString: data['generatedDateString'] as String?,
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

      final userId = EduverseFirebase.auth.currentUser?.uid ?? '';
      final progressData = userId.isNotEmpty
          ? await _fetchCourseProgress(userId, courseId)
          : (progress: 0.0, completed: 0);

      return _mapToStudyBatch(
        courseId,
        courseId,
        courseData,
        progressData.progress,
        progressData.completed,
      );
    } catch (e) {
      debugPrint('Error fetching course as study room batch $courseId: $e');
      return null;
    }
  }

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

  Stream<List<StudyCourseModel>> getEnrolledCourses() {
    final userId = EduverseFirebase.auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('enrolledCourses')
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return [];

      final List<String> courseIds = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final courseId = data['courseId'] as String? ?? doc.id.split('_')[0];
        if (courseId.isNotEmpty && !courseIds.contains(courseId)) {
          courseIds.add(courseId);
        }
      }

      if (courseIds.isEmpty) return [];

      List<StudyCourseModel> studyCourses = [];
      for (var courseId in courseIds) {
        try {
          final courseDoc = await _firestore
              .collection('courses')
              .doc(courseId)
              .get();
          if (!courseDoc.exists) continue;
          final courseData = courseDoc.data()!;

          final progressData = await _fetchCourseProgress(
            userId,
            courseId,
          );

          List<Color> gradientColors = [Colors.blue, Colors.lightBlueAccent];
          if (courseData['gradientColors'] != null) {
            gradientColors = (courseData['gradientColors'] as List)
                .map((c) => Color(c as int))
                .toList();
          }

          studyCourses.add(
            StudyCourseModel(
              id: courseId,
              title: courseData['title'] ?? '',
              subtitle: courseData['subtitle'] ?? '',
              emoji: courseData['emoji'] ?? '📚',
              gradientColors: gradientColors,
              lessonCount: courseData['totalLectures'] ?? 0,
              progress: progressData.progress,
            ),
          );
        } catch (e) {
          debugPrint('Error loading course progress $courseId: $e');
        }
      }
      return studyCourses;
    });
  }

  Stream<List<WorkbookModel>> getWorkbooks() {
    final userId = EduverseFirebase.auth.currentUser?.uid;
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
        .collection('courseBookmarks')
        .snapshots()
        .asyncMap((snapshot) async {
          final favoriteIds = snapshot.docs.map((doc) => doc.id).toList();
          await StudyLocalStorage().cacheFavoriteBatchIds(favoriteIds);
          return favoriteIds.contains(batchId);
        });
  }

  @override
  Future<void> toggleBatchBookmark(String userId, String batchId) async {
    if (userId.isEmpty) return;
    final bookmarkRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('courseBookmarks')
        .doc(batchId);

    final localStorage = StudyLocalStorage();
    final cached = await localStorage.getCachedFavoriteBatchIds();
    final updated = List<String>.from(cached);

    final doc = await bookmarkRef.get();
    if (doc.exists) {
      await bookmarkRef.delete();
      updated.remove(batchId);
    } else {
      await bookmarkRef.set({
        'createdAt': FieldValue.serverTimestamp(),
        'courseId': batchId,
      });
      if (!updated.contains(batchId)) {
        updated.add(batchId);
      }
    }
    await localStorage.cacheFavoriteBatchIds(updated);
  }
}
