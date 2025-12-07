import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_filex/open_filex.dart';

/// Service for downloading and managing files
class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Dio _dio = Dio();
  final String _prefKey = 'my_downloads_list';

  /// Downloads a file from URL and saves it locally
  /// Returns the local file path on success
  Future<String?> downloadFile({
    required String url,
    required String fileName,
    required String title,
    required String type, // 'pdf', 'video', 'article'
    Function(double progress)? onProgress,
  }) async {
    try {
      // Get download directory
      final dir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${dir.path}/downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final filePath = '${downloadDir.path}/$fileName';
      final file = File(filePath);

      // Download with progress
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      // Save to downloads list
      await _addToDownloadsList(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        type: type,
        filePath: filePath,
        url: url,
        size: _formatFileSize(await file.length()),
      );

      return filePath;
    } catch (e) {
      debugPrint('Download error: $e');
      return null;
    }
  }

  /// Opens a file with the system default app
  Future<bool> openFile(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('Error opening file: $e');
      return false;
    }
  }

  /// Checks if a file is already downloaded
  Future<String?> getLocalPath(String url) async {
    final downloads = await _getDownloadsList();
    for (final download in downloads) {
      if (download['url'] == url) {
        final path = download['filePath'] as String?;
        if (path != null && await File(path).exists()) {
          return path;
        }
      }
    }
    return null;
  }

  Future<void> _addToDownloadsList({
    required String id,
    required String title,
    required String type,
    required String filePath,
    required String url,
    required String size,
  }) async {
    final downloads = await _getDownloadsList();
    
    // Remove existing entry with same URL if present
    downloads.removeWhere((d) => d['url'] == url);
    
    // Add new entry at the beginning
    downloads.insert(0, {
      'id': id,
      'title': title,
      'type': type,
      'size': size,
      'progress': 1.0,
      'status': 0, // 0 = completed (DownloadStatus.completed.index)
      'filePath': filePath,
      'url': url,
    });

    await _saveDownloadsList(downloads);
  }

  Future<List<Map<String, dynamic>>> _getDownloadsList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefKey);
      if (jsonString != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(jsonString));
      }
    } catch (e) {
      debugPrint('Error loading downloads: $e');
    }
    return [];
  }

  Future<void> _saveDownloadsList(List<Map<String, dynamic>> downloads) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(downloads));
    } catch (e) {
      debugPrint('Error saving downloads: $e');
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
