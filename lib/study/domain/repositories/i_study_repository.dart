import 'package:eduverse/study/domain/models/study_entities.dart';

abstract class IStudyRepository {
  /// Stream of courses the user is enrolled in, including progress.
  Stream<List<StudyCourse>> getEnrolledCourses(String userId);

  /// Get list of lectures for a specific course.
  Future<List<StudyLecture>> getCourseLectures(String userId, String courseId);
  
  /// Stream of lectures for a specific course (real-time watched status).
  Stream<List<StudyLecture>> getCourseLecturesStream(String userId, String courseId);

  /// Mark a lecture as watched.
  Future<void> markLectureWatched(String userId, String courseId, String lectureId, bool isWatched);

  /// Update course progress (calculated usually on backend or client side agg).
  Future<void> updateCourseProgress(String userId, String courseId);
}
