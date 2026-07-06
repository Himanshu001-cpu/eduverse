import 'package:shared_preferences/shared_preferences.dart';

class StudyLocalStorage {
  static const String _keySelectedBatchId = 'selected_batch_id';
  static const String _keyFavoriteBatchIds = 'favorite_batch_ids';

  /// Save the last selected batch or combo pack ID
  Future<void> setSelectedBatchId(String batchId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedBatchId, batchId);
  }

  /// Get the last selected batch or combo pack ID
  Future<String?> getSelectedBatchId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelectedBatchId);
  }

  /// Cache the favorite batch IDs list
  Future<void> cacheFavoriteBatchIds(List<String> batchIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyFavoriteBatchIds, batchIds);
  }

  /// Get the cached list of favorite batch IDs
  Future<List<String>> getCachedFavoriteBatchIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyFavoriteBatchIds) ?? [];
  }

  /// Clear all cached study settings (e.g. on logout)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySelectedBatchId);
    await prefs.remove(_keyFavoriteBatchIds);
  }
}
