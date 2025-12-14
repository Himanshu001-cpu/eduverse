import 'package:eduverse/study/domain/models/study_entities.dart';

abstract class IStudyRepository {
  /// Stream of batches the user is enrolled in, including progress.
  Stream<List<StudyBatch>> getEnrolledBatches(String userId);

  /// Get list of lectures for a specific batch.
  Future<List<StudyLecture>> getBatchLectures(String userId, String courseId, String batchId);
  
  /// Stream of lectures for a specific batch (real-time watched status).
  Stream<List<StudyLecture>> getBatchLecturesStream(String userId, String courseId, String batchId);

  /// Mark a lecture as watched.
  Future<void> markLectureWatched(String userId, String courseId, String batchId, String lectureId, bool isWatched);

  /// Update batch progress (calculated usually on backend or client side agg).
  Future<void> updateBatchProgress(String userId, String courseId, String batchId);

  /// Get list of quizzes for a specific batch.
  Future<List<StudyQuiz>> getBatchQuizzes(String courseId, String batchId);

  /// Get list of notes for a specific batch.
  Future<List<StudyNote>> getBatchNotes(String courseId, String batchId);

  /// Get list of planner items for a specific batch.
  Future<List<StudyPlannerItem>> getBatchPlanner(String courseId, String batchId);

  /// Get list of live classes for a specific batch.
  Future<List<StudyLiveClass>> getBatchLiveClasses(String courseId, String batchId);

  /// Get list of free live classes available to all users.
  Future<List<StudyLiveClass>> getFreeLiveClasses();
}
