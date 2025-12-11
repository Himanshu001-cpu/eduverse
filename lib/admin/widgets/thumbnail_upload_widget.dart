import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// A reusable widget for uploading and displaying thumbnail images
class ThumbnailUploadWidget extends StatefulWidget {
  final String? currentUrl;
  final String storagePath; // e.g., 'courses/thumbnails' or 'batches/thumbnails'
  final ValueChanged<String> onUploaded;
  final double height;
  final double width;

  const ThumbnailUploadWidget({
    super.key,
    this.currentUrl,
    required this.storagePath,
    required this.onUploaded,
    this.height = 150,
    this.width = double.infinity,
  });

  @override
  State<ThumbnailUploadWidget> createState() => _ThumbnailUploadWidgetState();
}

class _ThumbnailUploadWidgetState extends State<ThumbnailUploadWidget> {
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _displayUrl;

  @override
  void initState() {
    super.initState();
    _displayUrl = widget.currentUrl;
  }

  @override
  void didUpdateWidget(ThumbnailUploadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUrl != oldWidget.currentUrl) {
      _displayUrl = widget.currentUrl;
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0;
      });

      // Store old URL to delete after successful upload
      final oldUrl = _displayUrl;

      // Generate unique filename
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final storageRef = FirebaseStorage.instance.ref().child('${widget.storagePath}/$fileName');

      // Upload file
      final uploadTask = storageRef.putFile(File(file.path!));

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

      // Delete old image if it exists and is different
      if (oldUrl != null && oldUrl.isNotEmpty && oldUrl != downloadUrl) {
        await _deleteImageFromStorage(oldUrl);
      }

      if (mounted) {
        setState(() {
          _displayUrl = downloadUrl;
          _isUploading = false;
        });
        widget.onUploaded(downloadUrl);
      }
    } catch (e) {
      debugPrint('Error uploading thumbnail: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteImageFromStorage(String url) async {
    try {
      // Extract reference from URL and delete
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();
      debugPrint('Deleted old thumbnail: $url');
    } catch (e) {
      // Log but don't fail - the old file might not exist or be inaccessible
      debugPrint('Failed to delete old thumbnail: $e');
    }
  }

  Future<void> _removeImage() async {
    final oldUrl = _displayUrl;
    setState(() => _displayUrl = null);
    widget.onUploaded('');
    
    // Delete from storage
    if (oldUrl != null && oldUrl.isNotEmpty) {
      await _deleteImageFromStorage(oldUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thumbnail Image',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isUploading ? null : _pickAndUploadImage,
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
                    ? _buildImagePreview()
                    : _buildPlaceholder(),
          ),
        ),
        if (_displayUrl != null && _displayUrl!.isNotEmpty && !_isUploading)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _pickAndUploadImage,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Change'),
                ),
                TextButton.icon(
                  onPressed: _removeImage,
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
        Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          'Tap to upload image',
          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          'PNG, JPG up to 5MB',
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
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(value: _uploadProgress),
              Text(
                '${(_uploadProgress * 100).toInt()}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Uploading...',
          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _displayUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('Failed to load image', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ));
            },
          ),
          // Overlay for tap feedback
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _pickAndUploadImage,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Edit icon
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                ],
              ),
              child: const Icon(Icons.edit, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
