import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/domain/models/test_series_entities.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/store/services/test_series_repository.dart';
import 'package:eduverse/store/services/store_repository.dart';
import 'package:eduverse/study/domain/repositories/i_study_repository.dart';
import 'package:eduverse/study/data/repositories/study_local_storage.dart';
import 'package:eduverse/study/data/repositories/lecture_progress_repository.dart';
import 'package:eduverse/core/utils/youtube_utils.dart';
import 'package:eduverse/core/firebase/eduverse_firebase.dart';

class StudyController extends ChangeNotifier {
  final IStudyRepository _repository;
  final String _userId;
  final LectureProgressRepository _progressRepository = LectureProgressRepository();
  final StudyLocalStorage _localStorage = StudyLocalStorage();

  StudyController({
    required IStudyRepository repository,
    required String userId,
  }) : _repository = repository,
       _userId = userId {
    _init();
  }

  // State
  List<StudyBatch> _enrolledBatches = [];
  bool _isLoading = true;
  String? _error;

  String _currentTab = 'Courses';
  String? _selectedBatchId;
  String? _selectedRoomId;
  String _selectedRoomType = 'course';
  List<TestSeriesItem> _purchasedTestSeries = [];
  List<Ebook> _ownedEbooks = [];

  List<String> _favoriteBatchIds = [];
  String? _currentExamFilter;
  String _searchQuery = '';
  String _activeFilterChip = 'All';

  List<Map<String, dynamic>> _exams = [];
  List<StudyLecture> _lectures = [];
  List<StudyLiveClass> _allLiveClasses = [];

  // Getters
  List<StudyBatch> get enrolledBatches => _enrolledBatches;
  bool get isLoading => _isLoading;
  String? get error => _error;
  IStudyRepository get repository => _repository;

  String get currentTab => _currentTab;
  String? get selectedBatchId => _selectedRoomType == 'course' ? _selectedRoomId : null;
  String? get selectedRoomId => _selectedRoomId;
  String get selectedRoomType => _selectedRoomType;
  List<TestSeriesItem> get purchasedTestSeries => _purchasedTestSeries;
  List<Ebook> get ownedEbooks => _ownedEbooks;

  List<String> get favoriteBatchIds => _favoriteBatchIds;
  String? get currentExamFilter => _currentExamFilter;
  String get searchQuery => _searchQuery;
  String get activeFilterChip => _activeFilterChip;
  List<Map<String, dynamic>> get exams => _exams;
  List<StudyLecture> get lectures => _lectures;
  List<StudyLiveClass> get allLiveClasses => _allLiveClasses;

  Box<Map> get lectureProgressBox {
    return Hive.box<Map>('lecture_progress');
  }

  StreamSubscription<List<StudyBatch>>? _batchesSubscription;
  StreamSubscription<List<TestSeriesItem>>? _testSeriesSubscription;
  StreamSubscription<List<Ebook>>? _ebooksSubscription;
  StreamSubscription<QuerySnapshot>? _bookmarksSubscription;
  StreamSubscription<QuerySnapshot>? _examsSubscription;

  void _init() async {
    if (_userId.isEmpty) {
      _isLoading = false;
      _error = 'User not logged in';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    // Load initial selection from Local Storage
    final prefs = await SharedPreferences.getInstance();
    _selectedRoomId = prefs.getString('selected_room_id');
    _selectedRoomType = prefs.getString('selected_room_type') ?? 'course';
    if (_selectedRoomId == null) {
      _selectedRoomId = await _localStorage.getSelectedBatchId();
      _selectedRoomType = 'course';
    }
    _selectedBatchId = _selectedRoomType == 'course' ? _selectedRoomId : null;

    _favoriteBatchIds = await _localStorage.getCachedFavoriteBatchIds();

    // Listen to enrolled batches
    _batchesSubscription = _repository
        .getEnrolledBatches(_userId)
        .listen(
          (batches) async {
            _enrolledBatches = batches;
            await _syncAndVerifySelection(batches);

            await loadLecturesForSelectedBatch();
            await loadAllLiveClasses();

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

    // Listen to purchased test series
    _testSeriesSubscription = TestSeriesRepository()
        .getPurchasedTestSeries(_userId)
        .listen(
          (series) async {
            _purchasedTestSeries = series;
            if (_selectedRoomType == 'test_series') {
              await _syncAndVerifySelection(_enrolledBatches);
            }
            notifyListeners();
          },
          onError: (e) => debugPrint('Error streaming test series: $e'),
        );

    // Listen to owned e-books
    _ebooksSubscription = StoreRepository()
        .getEbooks()
        .listen(
          (ebooks) async {
            _ownedEbooks = ebooks.where((e) => e.isOwned == true).toList();
            if (_selectedRoomType == 'ebook') {
              await _syncAndVerifySelection(_enrolledBatches);
            }
            notifyListeners();
          },
          onError: (e) => debugPrint('Error streaming e-books: $e'),
        );

    // Sync selected batch backup from Firestore
    EduverseFirebase.firestore
        .collection('users')
        .doc(_userId)
        .snapshots()
        .listen((snap) async {
      if (snap.exists && snap.data() != null) {
        final data = snap.data()!;
        if (data.containsKey('selectedRoomId') && data.containsKey('selectedRoomType')) {
          final dbRoomId = data['selectedRoomId'] as String?;
          final dbRoomType = data['selectedRoomType'] as String? ?? 'course';
          if ((dbRoomId != _selectedRoomId || dbRoomType != _selectedRoomType) && dbRoomId != null) {
            _selectedRoomId = dbRoomId;
            _selectedRoomType = dbRoomType;
            _selectedBatchId = dbRoomType == 'course' ? dbRoomId : null;
            
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('selected_room_id', dbRoomId);
            await prefs.setString('selected_room_type', dbRoomType);
            if (dbRoomType == 'course') {
              await _localStorage.setSelectedBatchId(dbRoomId);
              await loadLecturesForSelectedBatch();
            }
            notifyListeners();
          }
        } else if (data.containsKey('selectedBatchId')) {
          final dbSelectedId = data['selectedBatchId'] as String?;
          if (dbSelectedId != _selectedRoomId && dbSelectedId != null) {
            _selectedRoomId = dbSelectedId;
            _selectedRoomType = 'course';
            _selectedBatchId = dbSelectedId;
            await _localStorage.setSelectedBatchId(dbSelectedId);
            await loadLecturesForSelectedBatch();
            notifyListeners();
          }
        }
      }
    });

    // Listen to course bookmarks (favorites)
    _bookmarksSubscription = EduverseFirebase.firestore
        .collection('users')
        .doc(_userId)
        .collection('courseBookmarks')
        .snapshots()
        .listen((snapshot) async {
      _favoriteBatchIds = snapshot.docs.map((doc) => doc.id).toList();
      await _localStorage.cacheFavoriteBatchIds(_favoriteBatchIds);
      notifyListeners();
    });

    // Listen to exams
    _examsSubscription = EduverseFirebase.firestore
        .collection('exams')
        .snapshots()
        .listen((snapshot) {
      _exams = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
      notifyListeners();
    });
  }

  Future<void> _syncAndVerifySelection(List<StudyBatch> batches) async {
    bool isValid = false;
    if (_selectedRoomId != null) {
      if (_selectedRoomType == 'course') {
        isValid = batches.any((b) => b.id == _selectedRoomId);
      } else if (_selectedRoomType == 'test_series') {
        isValid = _purchasedTestSeries.any((ts) => ts.id == _selectedRoomId);
      } else if (_selectedRoomType == 'ebook') {
        isValid = _ownedEbooks.any((eb) => eb.id == _selectedRoomId);
      }
    }

    if (!isValid) {
      if (batches.isNotEmpty) {
        final combo = batches.firstWhere((b) => b.isCombo, orElse: () => batches.first);
        _selectedRoomId = combo.id;
        _selectedRoomType = 'course';
        _selectedBatchId = combo.id;
      } else if (_purchasedTestSeries.isNotEmpty) {
        _selectedRoomId = _purchasedTestSeries.first.id;
        _selectedRoomType = 'test_series';
        _selectedBatchId = null;
      } else if (_ownedEbooks.isNotEmpty) {
        _selectedRoomId = _ownedEbooks.first.id;
        _selectedRoomType = 'ebook';
        _selectedBatchId = null;
      } else {
        _selectedRoomId = null;
        _selectedRoomType = 'course';
        _selectedBatchId = null;
      }

      final prefs = await SharedPreferences.getInstance();
      if (_selectedRoomId != null) {
        await prefs.setString('selected_room_id', _selectedRoomId!);
        await prefs.setString('selected_room_type', _selectedRoomType);
        if (_selectedRoomType == 'course') {
          await _localStorage.setSelectedBatchId(_selectedRoomId!);
        }
      } else {
        await prefs.remove('selected_room_id');
        await prefs.remove('selected_room_type');
        await prefs.remove('selected_batch_id');
      }
    }
  }

  Future<void> loadLecturesForSelectedBatch() async {
    if (_userId.isEmpty) return;

    StudyBatch? selectedBatch;
    try {
      selectedBatch = _enrolledBatches.firstWhere((b) => b.id == _selectedBatchId);
    } catch (_) {}

    final List<String> courseIdsToLoad = [];
    if (selectedBatch == null) {
      courseIdsToLoad.addAll(_enrolledBatches.expand((b) => b.courseIds ?? [b.courseId]));
    } else if (selectedBatch.isCombo) {
      courseIdsToLoad.addAll(selectedBatch.courseIds ?? []);
    } else {
      courseIdsToLoad.add(selectedBatch.courseId);
    }

    final List<StudyLecture> loadedLectures = [];
    for (final courseId in courseIdsToLoad) {
      try {
        final lecturesList = await getLectures(courseId, _selectedBatchId ?? courseId);
        loadedLectures.addAll(lecturesList);
      } catch (e) {
        debugPrint('Error loading lectures for course $courseId: $e');
      }
    }
    _lectures = loadedLectures;
    notifyListeners();
  }

  Future<void> loadAllLiveClasses() async {
    if (_userId.isEmpty) return;

    final List<StudyLiveClass> loadedLiveClasses = [];

    // For each enrolled batch, get its courseIds
    for (final batch in _enrolledBatches) {
      final List<String> courseIds = [];
      if (batch.isCombo) {
        courseIds.addAll(batch.courseIds ?? []);
      } else {
        courseIds.add(batch.courseId);
      }

      for (final courseId in courseIds) {
        try {
          final liveList = await getBatchLiveClasses(courseId, batch.id);
          // Attach courseId and batchId to each class
          final mapped = liveList.map((lc) => lc.copyWith(
            courseId: courseId,
            batchId: batch.id,
          )).toList();
          loadedLiveClasses.addAll(mapped);
        } catch (e) {
          debugPrint('Error loading live classes for course $courseId: $e');
        }
      }
    }

    // Sort: live first, then upcoming by start time
    loadedLiveClasses.sort((a, b) {
      final aLive = YouTubeUtils.shouldTreatAsLive(
        url: a.youtubeUrl ?? '',
        status: a.status,
        startTime: a.startTime,
        durationMinutes: a.durationMinutes,
      );
      final bLive = YouTubeUtils.shouldTreatAsLive(
        url: b.youtubeUrl ?? '',
        status: b.status,
        startTime: b.startTime,
        durationMinutes: b.durationMinutes,
      );

      if (aLive && !bLive) return -1;
      if (!aLive && bLive) return 1;

      return a.startTime.compareTo(b.startTime);
    });

    _allLiveClasses = loadedLiveClasses;
    notifyListeners();
  }

  void setTab(String tab) {
    _currentTab = tab;
    notifyListeners();
  }

  Future<void> selectStudyRoom(String roomId, String roomType) async {
    _selectedRoomId = roomId;
    _selectedRoomType = roomType;
    _selectedBatchId = roomType == 'course' ? roomId : null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_room_id', roomId);
    await prefs.setString('selected_room_type', roomType);
    if (roomType == 'course') {
      await _localStorage.setSelectedBatchId(roomId);
    }

    if (_userId.isNotEmpty) {
      await EduverseFirebase.firestore.collection('users').doc(_userId).set({
        'selectedRoomId': roomId,
        'selectedRoomType': roomType,
        'selectedBatchId': roomType == 'course' ? roomId : null,
      }, SetOptions(merge: true));
    }

    if (roomType == 'course') {
      await loadLecturesForSelectedBatch();
    }
    notifyListeners();
  }

  Future<void> selectBatch(String? batchId) async {
    if (batchId == null) {
      _selectedRoomId = null;
      _selectedRoomType = 'course';
      _selectedBatchId = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_room_id');
      await prefs.remove('selected_room_type');
      await prefs.remove('selected_batch_id');

      if (_userId.isNotEmpty) {
        await EduverseFirebase.firestore.collection('users').doc(_userId).set({
          'selectedRoomId': null,
          'selectedRoomType': null,
          'selectedBatchId': null,
        }, SetOptions(merge: true));
      }
      notifyListeners();
    } else {
      await selectStudyRoom(batchId, 'course');
    }
  }

  Future<void> toggleFavoriteBatch(String batchId) async {
    final cached = await _localStorage.getCachedFavoriteBatchIds();
    final updated = List<String>.from(cached);

    if (updated.contains(batchId)) {
      updated.remove(batchId);
    } else {
      updated.add(batchId);
    }
    await _localStorage.cacheFavoriteBatchIds(updated);
    _favoriteBatchIds = updated;
    notifyListeners();

    if (_userId.isNotEmpty) {
      final ref = EduverseFirebase.firestore
          .collection('users')
          .doc(_userId)
          .collection('courseBookmarks')
          .doc(batchId);

      final doc = await ref.get();
      if (doc.exists) {
        await ref.delete();
      } else {
        await ref.set({
          'bookmarkedAt': FieldValue.serverTimestamp(),
          'courseId': batchId,
        });
      }
    }
  }

  void setExamFilter(String? examId) {
    _currentExamFilter = examId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterChip(String chip) {
    _activeFilterChip = chip;
    notifyListeners();
  }

  Future<void> updateLectureProgress(
    String lectureId, {
    required int progressSeconds,
    required int totalDurationSeconds,
    required String lastOpened,
  }) async {
    await _progressRepository.saveProgress(
      lectureId: lectureId,
      progressSeconds: progressSeconds,
      totalDurationSeconds: totalDurationSeconds,
      lastOpened: lastOpened,
    );
    notifyListeners();
  }

  void refreshBatches() {
    _batchesSubscription?.cancel();
    _batchesSubscription = _repository
        .getEnrolledBatches(_userId)
        .listen(
          (batches) async {
            _enrolledBatches = batches;
            await loadLecturesForSelectedBatch();
            await loadAllLiveClasses();
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

  Future<List<StudyLecture>> getLectures(
    String courseId,
    String batchId,
  ) async {
    try {
      return await _repository.getBatchLectures(_userId, courseId, batchId);
    } catch (e) {
      debugPrint('Error getting lectures: $e');
      rethrow;
    }
  }

  Future<List<StudyQuiz>> getBatchQuizzes(
    String courseId,
    String batchId,
  ) async {
    try {
      return await _repository.getBatchQuizzes(courseId, batchId);
    } catch (e) {
      debugPrint('Error getting quizzes: $e');
      rethrow;
    }
  }

  Future<List<StudyNote>> getBatchNotes(String courseId, String batchId) async {
    try {
      return await _repository.getBatchNotes(courseId, batchId);
    } catch (e) {
      debugPrint('Error getting notes: $e');
      rethrow;
    }
  }

  Future<List<StudyPlannerItem>> getBatchPlanner(
    String courseId,
    String batchId,
  ) async {
    try {
      return await _repository.getBatchPlanner(courseId, batchId);
    } catch (e) {
      debugPrint('Error getting planner: $e');
      rethrow;
    }
  }

  Future<List<StudyLiveClass>> getBatchLiveClasses(
    String courseId,
    String batchId,
  ) async {
    try {
      return await _repository.getBatchLiveClasses(courseId, batchId);
    } catch (e) {
      debugPrint('Error getting live classes: $e');
      rethrow;
    }
  }

  Future<void> markLectureWatched(
    String courseId,
    String batchId,
    String lectureId,
    bool isWatched,
  ) async {
    try {
      await _repository.markLectureWatched(
        _userId,
        courseId,
        batchId,
        lectureId,
        isWatched,
      );
      refreshBatches();
    } catch (e) {
      debugPrint('Error marking watched: $e');
      rethrow;
    }
  }

  Stream<bool> isBatchBookmarked(String batchId) {
    return _repository.isBatchBookmarked(_userId, batchId);
  }

  Future<void> toggleBatchBookmark(String batchId) async {
    try {
      await _repository.toggleBatchBookmark(_userId, batchId);
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _batchesSubscription?.cancel();
    _bookmarksSubscription?.cancel();
    _examsSubscription?.cancel();
    _testSeriesSubscription?.cancel();
    _ebooksSubscription?.cancel();
    super.dispose();
  }
}
