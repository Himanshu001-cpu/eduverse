import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../firebase/storage_service.dart';

class UploadingImageItem {
  final String id;
  final XFile xFile;
  File? compressedFile;
  Uint8List? webBytes;
  double progress;
  String? uploadedUrl;
  bool isError;

  UploadingImageItem({
    required this.id,
    required this.xFile,
    this.compressedFile,
    this.webBytes,
    this.progress = 0.0,
    this.uploadedUrl,
    this.isError = false,
  });
}

class ImageAttachmentWidget extends StatefulWidget {
  final String storageFolder;
  final int maxImages;
  final ValueChanged<List<String>> onImagesUploaded;
  final ValueChanged<bool>? onUploadingStateChanged;

  const ImageAttachmentWidget({
    super.key,
    required this.storageFolder,
    this.maxImages = 3,
    required this.onImagesUploaded,
    this.onUploadingStateChanged,
  });

  static Widget buildAttachButton({
    required GlobalKey<ImageAttachmentWidgetState> key,
    Color iconColor = const Color(0xFF6C63FF),
  }) {
    return IconButton(
      icon: Icon(Icons.attach_file, color: iconColor),
      onPressed: () => key.currentState?.showPickerBottomSheet(),
    );
  }

  @override
  State<ImageAttachmentWidget> createState() => ImageAttachmentWidgetState();
}

class ImageAttachmentWidgetState extends State<ImageAttachmentWidget> {
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  final List<UploadingImageItem> _items = [];

  bool get isUploading => _items.any((item) => item.uploadedUrl == null && !item.isError);
  List<String> get uploadedUrls => _items
      .where((item) => item.uploadedUrl != null)
      .map((item) => item.uploadedUrl!)
      .toList();

  void clear() {
    setState(() {
      _items.clear();
    });
    widget.onImagesUploaded([]);
  }

  Future<void> pickImage(ImageSource source) async {
    if (_items.length >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum ${widget.maxImages} images allowed.')),
      );
      return;
    }

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (file == null) return;

      final item = UploadingImageItem(
        id: const Uuid().v4(),
        xFile: file,
      );

      setState(() {
        _items.add(item);
      });
      _notifyState();

      await _processAndUpload(item);
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void showPickerBottomSheet() {
    if (_items.length >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum ${widget.maxImages} images allowed.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF6C63FF)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF6C63FF)),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processAndUpload(UploadingImageItem item) async {
    try {
      String storagePath = '${widget.storageFolder}/${item.id}.jpg';
      UploadTask uploadTask;

      if (kIsWeb) {
        final bytes = await item.xFile.readAsBytes();
        item.webBytes = bytes;
        final ref = FirebaseStorage.instance.ref().child(storagePath);
        uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        // Compress image on mobile
        final filePath = item.xFile.path;
        final outPath = '${filePath}_compressed.jpg';
        final compressed = await FlutterImageCompress.compressAndGetFile(
          filePath,
          outPath,
          quality: 75,
          minWidth: 1200,
          minHeight: 1200,
        );

        final fileToUpload = compressed != null ? File(compressed.path) : File(filePath);
        item.compressedFile = fileToUpload;

        final ref = FirebaseStorage.instance.ref().child(storagePath);
        uploadTask = ref.putFile(fileToUpload, SettableMetadata(contentType: 'image/jpeg'));
      }

      uploadTask.snapshotEvents.listen((event) {
        if (mounted) {
          setState(() {
            item.progress = event.bytesTransferred / (event.totalBytes > 0 ? event.totalBytes : 1);
          });
        }
      });

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();

      if (mounted) {
        setState(() {
          item.uploadedUrl = url;
          item.progress = 1.0;
          item.isError = false;
        });
        _notifyState();
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      if (mounted) {
        setState(() {
          item.isError = true;
        });
        _notifyState();
      }
    }
  }

  void _removeItem(UploadingImageItem item) {
    setState(() {
      _items.removeWhere((i) => i.id == item.id);
    });
    _notifyState();
    if (item.uploadedUrl != null) {
      _storageService.deleteFile('${widget.storageFolder}/${item.id}.jpg');
    }
  }

  void _notifyState() {
    widget.onImagesUploaded(uploadedUrls);
    widget.onUploadingStateChanged?.call(isUploading);
  }

  Future<List<String>> uploadAllPending() async {
    for (var item in _items) {
      if (item.uploadedUrl == null && !item.isError) {
        await _processAndUpload(item);
      }
    }
    return uploadedUrls;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_items.isNotEmpty)
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Stack(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      margin: const EdgeInsets.only(right: 10, top: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        image: DecorationImage(
                          image: item.webBytes != null
                              ? MemoryImage(item.webBytes!) as ImageProvider
                              : FileImage(item.compressedFile ?? File(item.xFile.path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: item.uploadedUrl == null
                          ? Container(
                              color: Colors.black45,
                              child: Center(
                                child: item.isError
                                    ? IconButton(
                                        icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                                        onPressed: () => _processAndUpload(item),
                                      )
                                    : SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          value: item.progress > 0 ? item.progress : null,
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            )
                          : null,
                    ),

                    // Delete button
                    Positioned(
                      top: 0,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeItem(item),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget buildAttachButton({Color iconColor = const Color(0xFF6C63FF)}) {
    return IconButton(
      icon: Icon(Icons.attach_file, color: _items.length >= widget.maxImages ? Colors.grey : iconColor),
      onPressed: _items.length >= widget.maxImages ? null : showPickerBottomSheet,
    );
  }
}
