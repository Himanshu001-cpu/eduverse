import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// A reusable widget for uploading and displaying thumbnail images with Media Picker support.
class ThumbnailUploadWidget extends StatefulWidget {
  final String? currentUrl;
  final String storagePath; // e.g., 'courses/thumbnails' or 'combination_packs/thumbnails'
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
      
      if (kIsWeb) {
        if (file.bytes == null) return;
      } else {
        if (file.path == null) return;
      }

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
      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = storageRef.putData(file.bytes!);
      } else {
        uploadTask = storageRef.putFile(File(file.path!));
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
      debugPrint('Deleted old thumbnail: $url');
    } catch (e) {
      debugPrint('Failed to delete old thumbnail: $e');
    }
  }

  Future<void> _removeImage() async {
    final oldUrl = _displayUrl;
    setState(() => _displayUrl = null);
    widget.onUploaded('');
    
    if (oldUrl != null && oldUrl.isNotEmpty) {
      await _deleteImageFromStorage(oldUrl);
    }
  }

  void _showMediaPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Media Picker',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.upload_file, color: Colors.indigo.shade700),
                ),
                title: const Text('Upload Local Media File'),
                subtitle: const Text('Select PNG/JPG image from your device'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.link, color: Colors.purple.shade700),
                ),
                title: const Text('Enter Media URL'),
                subtitle: const Text('Paste direct image link from network or storage'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showUrlInputDialog();
                },
              ),
              if (_displayUrl != null && _displayUrl!.isNotEmpty)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text('Remove Thumbnail', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removeImage();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUrlInputDialog() {
    final urlController = TextEditingController(text: _displayUrl ?? '');
    String previewUrl = urlController.text.trim();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.perm_media, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Media Picker - Enter URL'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: 'Image / Media URL',
                  hintText: 'https://example.com/image.jpg',
                  border: const OutlineInputBorder(),
                  suffixIcon: urlController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            urlController.clear();
                            setDialogState(() => previewUrl = '');
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  setDialogState(() => previewUrl = val.trim());
                },
              ),
              const SizedBox(height: 16),
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: previewUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          previewUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, color: Colors.red, size: 32),
                                SizedBox(height: 4),
                                Text('Invalid Image URL', style: TextStyle(color: Colors.red, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          'Image preview will appear here',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final url = urlController.text.trim();
                setState(() => _displayUrl = url.isEmpty ? null : url);
                widget.onUploaded(url);
                Navigator.pop(dialogCtx);
              },
              child: const Text('Set Thumbnail'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Thumbnail Image',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _showMediaPickerOptions,
              icon: const Icon(Icons.perm_media, size: 16),
              label: const Text('Media Picker', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isUploading ? null : _showMediaPickerOptions,
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
                  onPressed: _showMediaPickerOptions,
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
          'Tap for Media Picker / Upload',
          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload local file or enter Image URL',
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
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showMediaPickerOptions,
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
