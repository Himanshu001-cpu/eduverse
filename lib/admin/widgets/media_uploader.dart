import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/firebase_admin_service.dart';

class MediaUploader extends StatefulWidget {
  final String path;
  final Function(String url) onUploadComplete;

  const MediaUploader({Key? key, required this.path, required this.onUploadComplete}) : super(key: key);

  @override
  State<MediaUploader> createState() => _MediaUploaderState();
}

class _MediaUploaderState extends State<MediaUploader> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _uploading = true);
      try {
        final file = result.files.first;
        final service = context.read<FirebaseAdminService>();
        final url = await service.uploadMedia(
          '${widget.path}/${file.name}',
          file.bytes!,
          'application/octet-stream',
        );
        widget.onUploadComplete(url);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      } finally {
        setState(() => _uploading = false);
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
