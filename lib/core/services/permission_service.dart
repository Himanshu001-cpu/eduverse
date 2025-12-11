import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to handle runtime permission requests
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Request storage permission for downloads
  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Request photos permission (Android 13+)
  Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request all media permissions for file picker/uploads
  Future<bool> requestMediaPermissions() async {
    final statuses = await [
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();

    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  /// Check if storage permission is granted
  Future<bool> hasStoragePermission() async {
    return await Permission.storage.isGranted;
  }

  /// Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  /// Show permission rationale dialog and request permission
  Future<bool> requestWithRationale(
    BuildContext context, {
    required Permission permission,
    required String title,
    required String message,
  }) async {
    // Check if already granted
    if (await permission.isGranted) return true;

    // Check if permanently denied
    if (await permission.isPermanentlyDenied) {
      final shouldOpenSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text('$message\n\nPlease enable this permission in app settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (shouldOpenSettings == true) {
        await openAppSettings();
      }
      return await permission.isGranted;
    }

    // Show rationale and request
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Deny'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    if (shouldRequest == true) {
      final status = await permission.request();
      return status.isGranted;
    }

    return false;
  }

  /// Request storage/media permission with rationale for downloads
  Future<bool> requestDownloadPermission(BuildContext context) async {
    return requestWithRationale(
      context,
      permission: Permission.storage,
      title: 'Storage Permission Required',
      message: 'The Eduverse needs storage access to download and save course materials, notes, and resources for offline use.',
    );
  }

  /// Request camera permission with rationale
  Future<bool> requestCameraWithRationale(BuildContext context) async {
    return requestWithRationale(
      context,
      permission: Permission.camera,
      title: 'Camera Permission Required',
      message: 'The Eduverse needs camera access to capture photos and videos for profile pictures and uploads.',
    );
  }

  /// Request photos/gallery permission with rationale
  Future<bool> requestPhotosWithRationale(BuildContext context) async {
    return requestWithRationale(
      context,
      permission: Permission.photos,
      title: 'Photo Library Permission Required',
      message: 'The Eduverse needs access to your photo library to select images and videos for uploads.',
    );
  }
}
