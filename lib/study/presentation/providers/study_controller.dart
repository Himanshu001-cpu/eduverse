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
  List<StudyBatch> _enrolledBatches = [];
  bool _isLoading = true;
  String? _error;

  // Getters
  List<StudyBatch> get enrolledBatches => _enrolledBatches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StreamSubscription<List<StudyBatch>>? _batchesSubscription;

  void _init() {
    if (_userId.isEmpty) {
      _isLoading = false;
      _error = 'User not logged in';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _batchesSubscription = _repository.getEnrolledBatches(_userId).listen(
      (batches) {
        _enrolledBatches = batches;
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

  /// Refresh batches to get updated progress
  void refreshBatches() {
    _batchesSubscription?.cancel();
    _batchesSubscription = _repository.getEnrolledBatches(_userId).listen(
      (batches) {
        _enrolledBatches = batches;
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

  /// Get lectures for a specific batch
  Future<List<StudyLecture>> getLectures(String courseId, String batchId) async {
    try {
      return await _repository.getBatchLectures(_userId, courseId, batchId);
    } catch (e) {
      debugPrint('Error getting lectures: $e');
      rethrow;
    }
  }

  /// Get quizzes for a specific batch
  Future<List<StudyQuiz>> getBatchQuizzes(String courseId, String batchId) async {
    try {
      return await _repository.getBatchQuizzes(courseId, batchId);
    } catch (e) {
      debugPrint('Error getting quizzes: $e');
      rethrow;
    }
  }

  /// Get notes for a specific batch
  Future<List<StudyNote>> getBatchNotes(String courseId, String batchId) async {
    try {
      return await _repository.getBatchNotes(courseId, batchId);
    } catch (e) {
      debugPrint('Error getting notes: $e');
      rethrow;
    }
  }

  /// Get planner items for a specific batch
  Future<List<StudyPlannerItem>> getBatchPlanner(String courseId, String batchId) async {
    try {
      return await _repository.getBatchPlanner(courseId, batchId);
    } catch (e) {
      debugPrint('Error getting planner: $e');
      rethrow;
    }
  }

  /// Mark lecture as watched and refresh progress
  Future<void> markLectureWatched(String courseId, String batchId, String lectureId, bool isWatched) async {
    try {
      await _repository.markLectureWatched(_userId, courseId, batchId, lectureId, isWatched);
      // Refresh batches to get updated progress
      refreshBatches();
    } catch (e) {
      debugPrint('Error marking watched: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _batchesSubscription?.cancel();
    super.dispose();
  }
}
