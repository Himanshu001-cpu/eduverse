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

    // 1. Listen to purchases collection
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

          // 2. Fetch Course details and Progress
          // Note: Ideally, we should batch fetch or use a separate 'enrollments' collection for better query perf.
          // For now, we fetch details individually or based on cache. 
          // Optimization: Create a 'users/{uid}/enrollments' collection which denormalizes this data.
          // BUT, adhering to "Use my existing project structure" -> keeping it simple logic here.
          
          List<StudyCourse> studyCourses = [];

          for (var courseId in courseIds) {
            try {
              // Fetch course details
              final courseDoc = await _firestore.collection('courses').doc(courseId).get();
              if (!courseDoc.exists) continue;

              final courseData = courseDoc.data()!;
              
              // Fetch progress
              final progressDoc = await _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('courseProgress')
                  .doc(courseId)
                  .get();
                  
              double progress = 0.0;
              int completed = 0;
              
              if (progressDoc.exists) {
                final pData = progressDoc.data()!;
                progress = (pData['progressPercent'] as num?)?.toDouble() ?? 0.0;
                completed = pData['completedLectures'] as int? ?? 0;
              }

              // Map to StudyCourse
              studyCourses.add(_mapToStudyCourse(courseDoc.id, courseData, progress, completed));
              
            } catch (e) {
              debugPrint('Error loading course $courseId: $e');
            }
          }
          
          return studyCourses;
        });
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
    final snapshot = await _firestore
        .collection('courses')
        .doc(courseId)
        .collection('lectures')
        .orderBy('order')
        .get();

    return _mapLectures(snapshot, userId, courseId, checkProgress: true);
  }
  
  @override
  Stream<List<StudyLecture>> getCourseLecturesStream(String userId, String courseId) {
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
      lectures.add(StudyLecture(
        id: doc.id,
        title: data['title'] ?? 'Untitled Lecture',
        videoUrl: data['videoUrl'] ?? '',
        contentUrl: data['contentUrl'] ?? '',
        description: data['description'] ?? '',
        order: data['order'] ?? 0,
        isWatched: watchedStatus[doc.id] ?? false,
        duration: null, // Parse duration if stored
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
}
