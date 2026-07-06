import 'package:hive/hive.dart';

class LectureProgressRepository {
  static const String _boxName = 'lecture_progress';

  Box<Map> _getBox() {
    return Hive.box<Map>(_boxName);
  }

  /// Save or update progress for a lecture
  Future<void> saveProgress({
    required String lectureId,
    required int progressSeconds,
    required int totalDurationSeconds,
    String? lastOpened,
  }) async {
    final box = _getBox();
    final isCompleted = totalDurationSeconds > 0
        ? (progressSeconds / totalDurationSeconds) >= 0.95
        : false;

    if (isCompleted) {
      await box.delete(lectureId);
    } else {
      await box.put(lectureId, {
        'progressSeconds': progressSeconds,
        'totalDurationSeconds': totalDurationSeconds,
        'lastOpened': lastOpened ?? DateTime.now().toIso8601String(),
        'isCompleted': false,
      });
    }
  }

  /// Get progress map for a lecture ID
  Map<String, dynamic>? getProgress(String lectureId) {
    final box = _getBox();
    final data = box.get(lectureId);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  /// Delete a lecture's progress from cache
  Future<void> deleteProgress(String lectureId) async {
    final box = _getBox();
    await box.delete(lectureId);
  }

  /// Retrieve all lectures currently in progress
  List<Map<String, dynamic>> getAllProgress() {
    final box = _getBox();
    final results = <Map<String, dynamic>>[];
    for (var key in box.keys) {
      final value = box.get(key);
      if (value != null) {
        results.add({
          'lectureId': key.toString(),
          ...Map<String, dynamic>.from(value),
        });
      }
    }
    // Sort so most recently viewed is first
    results.sort((a, b) {
      final aDate = DateTime.tryParse(a['lastOpened'] ?? '') ?? DateTime(0);
      final bDate = DateTime.tryParse(b['lastOpened'] ?? '') ?? DateTime(0);
      return bDate.compareTo(aDate);
    });
    return results;
  }

  /// Clear the database (e.g., on logout)
  Future<void> clearAll() async {
    final box = _getBox();
    await box.clear();
  }
}
