import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PdfCacheService {
  Future<Directory> _getCacheDirectory() async {
    final docDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(p.join(docDir.path, '.cached_ebooks'));
    return cacheDir;
  }

  String _getFileName(String url) {
    final hash = md5.convert(utf8.encode(url)).toString();
    return '$hash.dat';
  }

  Future<String?> getCachedFilePath(String url) async {
    final cacheDir = await _getCacheDirectory();
    final file = File(p.join(cacheDir.path, _getFileName(url)));
    if (file.existsSync()) {
      return file.path;
    }
    return null;
  }

  Future<String> cachePdfFile(String url, List<int> bytes) async {
    final cacheDir = await _getCacheDirectory();
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
    final file = File(p.join(cacheDir.path, _getFileName(url)));
    file.writeAsBytesSync(bytes, flush: true);
    return file.path;
  }

  Future<void> clearCache() async {
    final cacheDir = await _getCacheDirectory();
    if (cacheDir.existsSync()) {
      cacheDir.deleteSync(recursive: true);
    }
  }
}
