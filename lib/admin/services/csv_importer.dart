import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../models/admin_models.dart';

class CsvImporter {
  Future<List<AdminBatch>> pickAndParseBatches(String courseId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return [];

    final bytes = result.files.first.bytes;
    if (bytes == null) return [];

    final content = utf8.decode(bytes);
    final lines = content.split('\n');
    final batches = <AdminBatch>[];

    // Skip header, start from 1
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = line.split(',');
      if (parts.length < 5) continue;

      // Simple CSV parsing (name, price, seats, startDate, endDate)
      batches.add(AdminBatch(
        id: '', // New batch
        courseId: courseId,
        name: parts[0].trim(),
        price: double.tryParse(parts[1]) ?? 0.0,
        seatsTotal: int.tryParse(parts[2]) ?? 0,
        seatsLeft: int.tryParse(parts[2]) ?? 0,
        startDate: DateTime.tryParse(parts[3]) ?? DateTime.now(),
        endDate: DateTime.tryParse(parts[4]) ?? DateTime.now(),
        isActive: true,
      ));
    }
    return batches;
  }
}
