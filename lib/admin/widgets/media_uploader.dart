import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:mime/mime.dart';
import '../services/firebase_admin_service.dart';

class MediaUploader extends StatefulWidget {
  final String path;
  final Function(String url) onUploadComplete;

  const MediaUploader({super.key, required this.path, required this.onUploadComplete});

  @override
  State<MediaUploader> createState() => _MediaUploaderState();
}

class _MediaUploaderState extends State<MediaUploader> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true, // Optimistic: try to get bytes
    );

    if (!mounted) return;

    if (result != null && result.files.isNotEmpty) {
      setState(() => _uploading = true);
      try {
        final file = result.files.first;
        final service = context.read<FirebaseAdminService>();
        
        // 1. Get bytes (robust handling for Desktop/Web)
        var bytes = file.bytes;
        if (bytes == null && file.path != null) {
          // On Windows/Desktop, bytes might be null even with withData: true
          final ioFile = File(file.path!);
          bytes = await ioFile.readAsBytes();
        }

        if (bytes == null) {
          throw 'Could not read file data. bytes is null and path is ${file.path}';
        }

        debugPrint('Debug: File size: ${bytes.length} bytes');

        // 2. Detect Mime Type
        final mimeType = lookupMimeType(file.name) ?? 'application/octet-stream';
        debugPrint('Debug: Detected Mime Type: $mimeType');

        // 3. Upload
        debugPrint('Debug: Starting upload to ${widget.path}/${file.name}');
        final url = await service.uploadMedia(
          '${widget.path}/${file.name}',
          bytes,
          mimeType,
        );
        debugPrint('Debug: Upload successful, URL: $url');
        widget.onUploadComplete(url);
      } catch (e, stackTrace) {
        debugPrint('Error uploading: $e');
        debugPrint(stackTrace.toString());
        if(mounted) {
             showDialog(
               context: context,
               builder: (ctx) => AlertDialog(
                 title: const Text('Upload Failed'),
                 content: SingleChildScrollView(
                   child: SelectableText('Error: $e\n\nStack:\n$stackTrace'),
                 ),
                 actions: [
                   TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                 ],
               ),
             );
        }
      } finally {
        if (mounted) setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_uploading) const LinearProgressIndicator(),
        ElevatedButton.icon(
          onPressed: _uploading ? null : _pickAndUpload,
          icon: const Icon(Icons.cloud_upload),
          label: const Text('Upload Media'),
        ),
      ],
    );
  }
}
