import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/domain/repositories/i_study_repository.dart';

class StudyRepositoryImpl implements IStudyRepository {
  final FirebaseFirestore _firestore;

  StudyRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<StudyCourse>> getEnrolledCourses(String userId) {
    if (userId.isEmpty) return Stream.value([]);

    // We can't easily perform the async admin check inside the stream creation without rxdart or Stream.fromFuture
    // So we use Stream.fromFuture to perform the check then switch to the appropriate stream
    
    return Stream.fromFuture(_checkIsAdmin(userId)).asyncExpand((isAdmin) {
       if (isAdmin) {
         // Admin: Listen to ALL courses
         // Note: Real-time updates for "ALL" courses might be heavy if there are thousands, 
         // but for an admin panel/app manageable.
         return _firestore.collection('courses').snapshots().asyncMap((snapshot) async {
            List<StudyCourse> studyCourses = [];
            for (var doc in snapshot.docs) {
               final courseData = doc.data();
               // Fetch progress for this admin user
               final progressData = await _fetchProgress(userId, doc.id);
               studyCourses.add(_mapToStudyCourse(doc.id, courseData, progressData.progress, progressData.completed));
            }
            return studyCourses;
         });
       } else {
         // Standard User: Listen to Purchases
         return _firestore
          .collection('purchases')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .asyncMap((snapshot) async {
            if (snapshot.docs.isEmpty) return [];

            final Set<String> courseIds = {};
            for (var doc in snapshot.docs) {
              final data = doc.data();
              final items = (data['items'] as List<dynamic>?) ?? [];
              for (var item in items) {
                if (item['courseId'] != null) {
                  courseIds.add(item['courseId']);
                }
              }
            }

            if (courseIds.isEmpty) return [];

            List<StudyCourse> studyCourses = [];
            for (var courseId in courseIds) {
              try {
                final courseDoc = await _firestore.collection('courses').doc(courseId).get();
                if (!courseDoc.exists) continue;

                final courseData = courseDoc.data()!;
                final progressData = await _fetchProgress(userId, courseId);
                
                studyCourses.add(_mapToStudyCourse(courseId, courseData, progressData.progress, progressData.completed));
              } catch (e) {
                debugPrint('Error loading course $courseId: $e');
              }
            }
            return studyCourses;
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

  Future<({double progress, int completed})> _fetchProgress(String userId, String courseId) async {
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
              completed: pData['completedLectures'] as int? ?? 0
            );
        }
      } catch (e) {
        // ignore
      }
      return (progress: 0.0, completed: 0);
  }

  StudyCourse _mapToStudyCourse(String id, Map<String, dynamic> data, double progress, int completed) {
    List<Color> gradient = [const Color(0xFF4A90E2), const Color(0xFF002966)];
    if (data['gradientColors'] != null) {
      gradient = (data['gradientColors'] as List)
          .map((c) => Color(c as int))
          .toList();
    }

    return StudyCourse(
      id: id,
      title: data['title'] ?? 'Untitled Course',
      subtitle: data['subtitle'] ?? '',
      emoji: data['emoji'] ?? '🎓',
      gradientColors: gradient,
      totalLectures: data['totalLectures'] ?? 0, 
      completedLectures: completed,
      progress: progress,
    );
  }

  @override
  Future<List<StudyLecture>> getCourseLectures(String userId, String courseId) async {
    List<StudyLecture> allLectures = [];
    
    // 1. Fetch Course Level Lectures (Legacy)
    final courseSnapshot = await _firestore
        .collection('courses')
        .doc(courseId)
        .collection('lectures')
        .orderBy('order')
        .get();
        
    allLectures.addAll(await _mapLectures(courseSnapshot, userId, courseId, checkProgress: true));

    // 2. Fetch Batch Level Lectures (New)
    // iterate all batches
    final batchesSnap = await _firestore
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .get();
        
    for (var batchDoc in batchesSnap.docs) {
       final lessonsSnap = await batchDoc.reference
           .collection('lessons')
           .orderBy('orderIndex')
           .get();
           
       allLectures.addAll(await _mapLectures(lessonsSnap, userId, courseId, checkProgress: true));
    }

    return allLectures;
  }
  
  @override
  Stream<List<StudyLecture>> getCourseLecturesStream(String userId, String courseId) {
     // For stream, we'll just stick to the course level for now as combining streams dynamically is complex
     // or we could implementing a simplified CombineLatest if needed.
     // But since the UI primarily uses the Future method for the Detail screen, this is lower priority.
     return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('lectures')
        .orderBy('order')
        .snapshots()
        .asyncMap((snapshot) => _mapLectures(snapshot, userId, courseId, checkProgress: true));
  }

  Future<List<StudyLecture>> _mapLectures(QuerySnapshot snapshot, String userId, String courseId, {bool checkProgress = false}) async {
    List<StudyLecture> lectures = [];
    
    // If checking progress, we need to fetch user's watched status
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
      // Map Admin fields (storagePath, orderIndex) to Study fields (videoUrl, order)
      lectures.add(StudyLecture(
        id: doc.id,
        title: data['title'] ?? 'Untitled Lecture',
        videoUrl: data['videoUrl'] ?? data['storagePath'] ?? '',
        contentUrl: data['contentUrl'] ?? '',
        description: data['description'] ?? '',
        order: data['order'] ?? data['orderIndex'] ?? 0,
        isWatched: watchedStatus[doc.id] ?? false,
        duration: null, 
      ));
    }
    return lectures;
  }

  @override
  Future<void> markLectureWatched(String userId, String courseId, String lectureId, bool isWatched) async {
    final userRef = _firestore.collection('users').doc(userId);
    final courseProgressRef = userRef.collection('courseProgress').doc(courseId);
    final lectureProgressRef = courseProgressRef.collection('lectures').doc(lectureId);

    final batch = _firestore.batch();

    // 1. Update lecture status
    batch.set(lectureProgressRef, {
      'watched': isWatched,
      'watchedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2. Commit first to ensure consistency
    await batch.commit();

    // 3. Trigger recalculation of total progress
    await updateCourseProgress(userId, courseId);
  }

  @override
  Future<void> updateCourseProgress(String userId, String courseId) async {
    // 1. Get all course lectures count
    final courseRef = _firestore.collection('courses').doc(courseId);
    final courseSnap = await courseRef.get();
    if (!courseSnap.exists) return;
    
    // Trust the totalLectures field if accurate, or count subcollection (costly)
    // For now, let's assume 'totalLectures' field is maintained in Course document
    int total = courseSnap.data()?['totalLectures'] ?? 1;
    if (total == 0) total = 1; // Avoid div by zero

    // 2. Count watched lectures
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

    // 3. Update Course Progress doc
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('courseProgress')
        .doc(courseId)
        .set({
          'progressPercent': percent,
          'completedLectures': watchedCount,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Future<List<StudyQuiz>> getBatchQuizzes(String courseId, String batchId) async {
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
          durationMinutes: data['durationMinutes'] ?? 30, // Default or fetch if available
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching batch quizzes: $e');
      return [];
    }
  }
}
