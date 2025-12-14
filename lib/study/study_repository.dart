import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:eduverse/study/models/study_models.dart';
import 'package:eduverse/study/study_data.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // Stream of enrolled batches (user's purchased batches)
  Stream<List<StudyBatchModel>> getEnrolledBatches() {
    if (_userId.isEmpty) return Stream.value([]);

    return _firestore.collection('purchases')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .asyncMap((purchaseSnap) async {
          if (purchaseSnap.docs.isEmpty) {
            return <StudyBatchModel>[];
          }

          // Extract unique batch references (courseId + batchId)
          final List<({String courseId, String batchId})> batchRefs = [];
          for (var doc in purchaseSnap.docs) {
            final data = doc.data();
            final items = (data['items'] as List?) ?? [];
            for (var item in items) {
              final courseId = item['courseId'] as String?;
              final batchId = item['batchId'] as String?;
              if (courseId != null && batchId != null) {
                final exists = batchRefs.any((ref) => ref.courseId == courseId && ref.batchId == batchId);
                if (!exists) {
                  batchRefs.add((courseId: courseId, batchId: batchId));
                }
              }
            }
          }

          if (batchRefs.isEmpty) {
            return <StudyBatchModel>[];
          }

          final List<StudyBatchModel> batches = [];
          for (var ref in batchRefs) {
            try {
              // Fetch course data
              final courseDoc = await _firestore.collection('courses').doc(ref.courseId).get();
              if (!courseDoc.exists) continue;
              final courseData = courseDoc.data()!;

              // Fetch batch data
              final batchDoc = await courseDoc.reference.collection('batches').doc(ref.batchId).get();
              if (!batchDoc.exists) continue;

              batches.add(StudyBatchModel.fromMap(
                batchDoc.data()!,
                ref.batchId,
                courseData: {...courseData, 'id': ref.courseId},
              ));
            } catch (e) {
              debugPrint('Error fetching batch ${ref.batchId}: $e');
            }
          }
          return batches;
        });
  }

  // Legacy method - returns empty but keeps compatibility
  Stream<List<StudyCourseModel>> getEnrolledCourses() {
    if (_userId.isEmpty) return Stream.value([]);
    // Data comes from purchases/enrollments - use getEnrolledBatches() instead
    return Stream.value([]);
  }

  Stream<List<ContinueLearningModel>> getContinueLearning() {
     // Continue learning should be derived from user progress in Firestore
     return Stream.value([]);
  }

  Stream<List<LiveClassModel>> getLiveClasses() {
    return _firestore.collection('live_classes')
      .orderBy('dateTime')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => LiveClassModel.fromMap(doc.data(), doc.id))
            .toList();
      });
  }

  Future<StudyBatchModel?> getBatch(String batchId, {String? courseId}) async {
    try {
        if (courseId != null) {
            final doc = await _firestore
                .collection('courses')
                .doc(courseId)
                .collection('batches')
                .doc(batchId)
                .get();
            if (doc.exists) {
                // Fetch course data for complete model
                final courseDoc = await _firestore.collection('courses').doc(courseId).get();
                return StudyBatchModel.fromMap(doc.data()!, doc.id, courseData: courseDoc.data());
            }
        }
        // Fallback: This would need a Collection Group Index on 'id' matching documentId which isn't standard
        // For now, we rely on courseId being known.
        return null;
    } catch (e) {
        debugPrint('Error fetching batch $batchId: $e');
        return null;
    }
  }

  // --- LESSONS ---

  Stream<List<LessonModel>> getLessons(String courseId, String batchId) {
    return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('lessons')
        .snapshots()
        .asyncMap((snapshot) async {
          final List<LessonModel> lessons = [];
          if (_userId.isEmpty) {
             return snapshot.docs.map((doc) => LessonModel.fromMap(doc.data(), doc.id)).toList();
          }

          for (final doc in snapshot.docs) {
             bool isCompleted = false;
             try {
               final progressDoc = await _firestore
                   .collection('users')
                   .doc(_userId)
                   .collection('batchProgress')
                   .doc('${courseId}_$batchId')
                   .collection('lectures')
                   .doc(doc.id)
                   .get();
               if (progressDoc.exists && progressDoc.data()?['watched'] == true) {
                 isCompleted = true;
               }
             } catch (e) {
               // ignore
             }
             lessons.add(LessonModel.fromMap(doc.data(), doc.id, isCompleted: isCompleted));
          }
          return lessons;
        });
  }

  Future<void> updateLessonProgress(String courseId, String batchId, String lessonId, bool completed) async {
    if (_userId.isEmpty) return;
    
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('batchProgress')
        .doc('${courseId}_$batchId')
        .collection('lectures')
        .doc(lessonId)
        .set({
          'watched': completed,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  // --- TESTS ---

  Future<void> saveTestResult(String testId, int score) async {
    if (_userId.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('tests')
        .doc(testId)
        .set({
          'score': score,
          'completedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Stream<List<DailyPracticeModel>> getDailyPractice() {
    return _firestore.collection('daily_practice')
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          // Return UI constants for daily practice when Firestore is empty
          return StudyData.dailyPractice;
        }
        return snapshot.docs
            .map((doc) => DailyPracticeModel.fromMap(doc.data(), doc.id))
            .toList();
      });
  }

  Stream<List<TestModel>> getMockTests() {
    return _firestore.collection('mock_tests')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => TestModel.fromMap(doc.data(), doc.id))
            .toList();
      });
  }
  
  Stream<List<WorkbookModel>> getWorkbooks() {
     if (_userId.isEmpty) return Stream.value([]);
     
     return _firestore.collection('workbooks')
       .where('userId', isEqualTo: _userId)
       .snapshots()
       .map((snapshot) {
           return snapshot.docs
            .map((doc) => WorkbookModel.fromMap(doc.data(), doc.id))
            .toList();
       });
  }

  Stream<List<TopicNodeModel>> getTopics() {
    return _firestore.collection('topics')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => TopicNodeModel.fromMap(doc.data(), doc.id))
            .toList();
      });
  }

  // --- SEEDING (DEPRECATED) ---
  
  @Deprecated('Data is now managed via Admin Panel')
  Future<void> seedLiveClasses() async {
    debugPrint('seedLiveClasses is deprecated. Use Admin Panel.');
  }

  @Deprecated('Data is now managed via Admin Panel')
  Future<void> seedMockTests() async {
    debugPrint('seedMockTests is deprecated. Use Admin Panel.');
  }
}
