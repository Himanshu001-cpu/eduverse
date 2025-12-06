import 'dart:async';
import 'package:flutter/material.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/domain/repositories/i_study_repository.dart';

class StudyController extends ChangeNotifier {
  final IStudyRepository _repository;
  final String _userId;

  StudyController({
    required IStudyRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId {
    _init();
  }

  // State
  List<StudyCourse> _enrolledCourses = [];
  bool _isLoading = true;
  String? _error;

  // Getters
  List<StudyCourse> get enrolledCourses => _enrolledCourses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StreamSubscription<List<StudyCourse>>? _coursesSubscription;

  void _init() {
    if (_userId.isEmpty) {
      _isLoading = false;
      _error = 'User not logged in';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _coursesSubscription = _repository.getEnrolledCourses(_userId).listen(
      (courses) {
        _enrolledCourses = courses;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  /// Get lectures for a specific course
  Future<List<StudyLecture>> getLectures(String courseId) async {
    try {
      return await _repository.getCourseLectures(_userId, courseId);
    } catch (e) {
      debugPrint('Error getting lectures: $e');
      rethrow;
    }
  }

  /// Mark lecture as watched and update UI
  Future<void> markLectureWatched(String courseId, String lectureId, bool isWatched) async {
    try {
      // Optimistic update if we were caching lectures list locally in controller, 
      // but here we just call repo. The separate Stream/Future for lectures will update.
      await _repository.markLectureWatched(_userId, courseId, lectureId, isWatched);
    } catch (e) {
      debugPrint('Error marking watched: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _coursesSubscription?.cancel();
    super.dispose();
  }
}
