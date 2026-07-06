import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// A reusable widget for uploading and displaying PDF documents
class PdfUploadWidget extends StatefulWidget {
  final String? currentUrl;
  final String storagePath; // e.g., 'ebooks/pdfs'
  final ValueChanged<String> onUploaded;
  final double height;
  final double width;

  const PdfUploadWidget({
    super.key,
    this.currentUrl,
    required this.storagePath,
    required this.onUploaded,
    this.height = 120,
    this.width = double.infinity,
  });

  @override
  State<PdfUploadWidget> createState() => _PdfUploadWidgetState();
}

class _PdfUploadWidgetState extends State<PdfUploadWidget> {
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _displayUrl;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    _displayUrl = widget.currentUrl;
    _fileName = _getFileNameFromUrl(_displayUrl);
  }

  @override
  void didUpdateWidget(PdfUploadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUrl != oldWidget.currentUrl) {
      _displayUrl = widget.currentUrl;
      _fileName = _getFileNameFromUrl(_displayUrl);
    }
  }

  String? _getFileNameFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    try {
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        return url;
      }
      // Extract file name from Firebase Storage URL
      // e.g. .../o/ebooks%2Fpdfs%2F123456_mybook.pdf?alt=media
      final decodedPath = Uri.decodeFull(url.split('/o/').last.split('?').first);
      final fullName = decodedPath.split('/').last;
      
      // Strip timestamp prefix if possible (e.g. 1719582123456_mybook.pdf -> mybook.pdf)
      final underscoreIdx = fullName.indexOf('_');
      if (underscoreIdx != -1 && underscoreIdx < 20) {
        final prefix = fullName.substring(0, underscoreIdx);
        if (RegExp(r'^\d+$').hasMatch(prefix)) {
          return fullName.substring(underscoreIdx + 1);
        }
      }
      return fullName;
    } catch (e) {
      return 'PDF Document';
    }
  }

  Future<void> _pickAndUploadPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      
      if (kIsWeb) {
        if (file.bytes == null) return;
      } else {
        if (file.path == null) return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgress = 0;
        _fileName = file.name;
      });

      // Store old URL to delete after successful upload
      final oldUrl = _displayUrl;

      // Generate unique filename
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final storageRef = FirebaseStorage.instance.ref().child('${widget.storagePath}/$fileName');

      // Upload file
      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = storageRef.putData(file.bytes!, SettableMetadata(contentType: 'application/pdf'));
      } else {
        uploadTask = storageRef.putFile(File(file.path!), SettableMetadata(contentType: 'application/pdf'));
      }

      // Track progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (mounted) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
      });

      // Wait for completion
      await uploadTask;

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();

      // Delete old PDF if it exists and is different
      if (oldUrl != null && oldUrl.isNotEmpty && oldUrl != downloadUrl) {
        await _deletePdfFromStorage(oldUrl);
      }

      if (mounted) {
        setState(() {
          _displayUrl = downloadUrl;
          _isUploading = false;
        });
        widget.onUploaded(downloadUrl);
      }
    } catch (e) {
      debugPrint('Error uploading PDF: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
          _fileName = _getFileNameFromUrl(_displayUrl);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deletePdfFromStorage(String url) async {
    try {
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        debugPrint('Skipping deletion of local/non-network URL: $url');
        return;
      }
      if (!url.contains('firebasestorage.googleapis.com') && !url.contains(':9199')) {
        debugPrint('Skipping deletion of non-firebase-storage URL: $url');
        return;
      }
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();
      debugPrint('Deleted old PDF: $url');
    } catch (e) {
      debugPrint('Failed to delete old PDF: $e');
    }
  }

  Future<void> _removePdf() async {
    final oldUrl = _displayUrl;
    setState(() {
      _displayUrl = null;
      _fileName = null;
    });
    widget.onUploaded('');
    
    if (oldUrl != null && oldUrl.isNotEmpty) {
      await _deletePdfFromStorage(oldUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PDF Document',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isUploading ? null : _pickAndUploadPdf,
          child: Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _isUploading
                ? _buildUploadingState()
                : _displayUrl != null && _displayUrl!.isNotEmpty
                    ? _buildPdfPreview()
                    : _buildPlaceholder(),
          ),
        ),
        if (_displayUrl != null && _displayUrl!.isNotEmpty && !_isUploading)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _pickAndUploadPdf,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Change'),
                ),
                TextButton.icon(
                  onPressed: _removePdf,
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  label: const Text('Remove', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.picture_as_pdf_outlined, size: 40, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          'Tap to upload PDF',
          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          'PDF up to 50MB',
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildUploadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(value: _uploadProgress),
              Text(
                '${(_uploadProgress * 100).toInt()}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Uploading ${widget.storagePath.contains('pdf') ? 'PDF' : 'file'}...',
          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildPdfPreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf, size: 40, color: Colors.red),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fileName ?? 'PDF Document',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Uploaded successfully',
                  style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.green[600], size: 24),
        ],
      ),
    );
  }
}
