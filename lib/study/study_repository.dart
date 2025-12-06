import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:eduverse/study/models/study_models.dart';
import 'package:eduverse/study/study_data.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // Stream of enrolled courses
  Stream<List<StudyCourseModel>> getEnrolledCourses() {
    if (_userId.isEmpty) return Stream.value([]);

    return _firestore.collection('purchases')
        .where('userId', isEqualTo: _userId)
        // .where('status', isEqualTo: 'success') // Uncomment if 'success' status is strictly enforced
        .snapshots()
        .asyncMap((purchaseSnap) async {
          if (purchaseSnap.docs.isEmpty) {
            return StudyData.userCourses; // Fallback for dev/demo if no purchases
          }

          final Set<String> courseIds = {};
          for (var doc in purchaseSnap.docs) {
            final data = doc.data();
            final items = (data['items'] as List?) ?? [];
            for (var item in items) {
              // CartItem item
              if (item['courseId'] != null) {
                courseIds.add(item['courseId']);
              }
            }
          }

          if (courseIds.isEmpty) {
             return StudyData.userCourses;
          }

          final List<StudyCourseModel> courses = [];
          for (var id in courseIds) {
            try {
              final courseDoc = await _firestore.collection('courses').doc(id).get();
              if (courseDoc.exists) {
                // Map Store Course data to StudyCourseModel
                // Store course has 'gradientColors' as List<int> usually
                courses.add(StudyCourseModel.fromMap(courseDoc.data()!, courseDoc.id));
              }
            } catch (e) {
              debugPrint('Error fetching course $id: $e');
            }
          }
           
          // If we found real courses, return them. If purely errors or none found, fallback?
          // Better to return what we found.
          if (courses.isEmpty) return StudyData.userCourses; 
          
          return courses;
        });
  }

  Stream<List<ContinueLearningModel>> getContinueLearning() {
     // TODO: Implement progress tracking in Firestore
     return Stream.value(StudyData.continueLearning);
  }

  Stream<List<LiveClassModel>> getLiveClasses() {
    return _firestore.collection('live_classes')
      .orderBy('dateTime')
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          return StudyData.liveClasses; // Fallback to mock
        }
        return snapshot.docs
            .map((doc) => LiveClassModel.fromMap(doc.data(), doc.id))
            .toList();
      });
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
             // Check progress for each lesson
             // This is N+1, but for lessons in a batch (usually <50) it's acceptable for MVP.
             // Ideally fetch all progress for user once.
             bool isCompleted = false;
             try {
               final progressDoc = await _firestore
                   .collection('users')
                   .doc(_userId)
                   .collection('progress')
                   .doc(doc.id)
                   .get();
               if (progressDoc.exists && progressDoc.data()?['completed'] == true) {
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

  Future<void> updateLessonProgress(String lessonId, bool completed) async {
    if (_userId.isEmpty) return;
    
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('progress')
        .doc(lessonId)
        .set({
          'completed': completed,
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
          return StudyData.dailyPractice; // Fallback
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
        if (snapshot.docs.isEmpty) {
           return StudyData.mockTests; // Fallback
        }
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
          if (snapshot.docs.isEmpty) {
             return StudyData.workbooks; // Fallback
          }
           return snapshot.docs
            .map((doc) => WorkbookModel.fromMap(doc.data(), doc.id))
            .toList();
       });
  }

  Stream<List<TopicNodeModel>> getTopics() {
    return _firestore.collection('topics')
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          return StudyData.mapTopics; // Fallback
        }
        return snapshot.docs
            .map((doc) => TopicNodeModel.fromMap(doc.data(), doc.id))
            .toList();
      });
  }

  // --- SEEDING ---
  // One-time functions to push mock data to Firestore
  
  Future<void> seedLiveClasses() async {
    final classes = await _firestore.collection('live_classes').get();
    if (classes.docs.isNotEmpty) return;

    for (var item in StudyData.liveClasses) {
      await _firestore.collection('live_classes').add(item.toMap());
    }
  }

  Future<void> seedMockTests() async {
     final tests = await _firestore.collection('mock_tests').get();
    if (tests.docs.isNotEmpty) return;
    
    for (var item in StudyData.mockTests) {
      await _firestore.collection('mock_tests').add(item.toMap());
    }
  }
}
