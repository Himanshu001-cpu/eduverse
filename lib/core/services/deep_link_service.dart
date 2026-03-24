import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';

/// Service to handle deep links and navigate to appropriate screens.
/// 
/// Supports routes:
/// - `/app/course/{courseId}` → Course Detail Page
/// - `/app/batch/{courseId}/{batchId}` → Batch Section Page
/// - `/app/feed/{feedId}` → Feed Detail Page
/// - `/delete-account` → Delete Account Page
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  GlobalKey<NavigatorState>? _navigatorKey;
  bool _isInitialized = false;

  /// Initialize the deep link service with a navigator key.
  /// Call this in your main app widget's initState.
  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_isInitialized) return;
    
    _navigatorKey = navigatorKey;
    _isInitialized = true;

    // Handle the case where the app is started by a deep link
    await _handleInitialLink();

    // Listen for deep links while the app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleUri(uri);
      },
      onError: (error) {
        debugPrint('Deep link error: $error');
      },
    );
  }

  /// Handle the initial link when app is cold-started via deep link.
  Future<void> _handleInitialLink() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        // Small delay to ensure navigation context is ready
        await Future.delayed(const Duration(milliseconds: 500));
        _handleUri(initialUri);
      }
    } catch (e) {
      debugPrint('Error getting initial deep link: $e');
    }
  }

  /// Parse the URI and navigate to the appropriate screen.
  void _handleUri(Uri uri) {
    debugPrint('Deep link received: $uri');
    
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      debugPrint('Navigator not available for deep link navigation');
      return;
    }

    final pathSegments = uri.pathSegments;
    
    if (pathSegments.isEmpty) {
      debugPrint('Empty path segments in deep link');
      return;
    }

    // Handle different route patterns
    if (pathSegments.first == 'app' && pathSegments.length >= 2) {
      final routeType = pathSegments[1];
      
      switch (routeType) {
        case 'course':
          if (pathSegments.length >= 3) {
            final courseId = pathSegments[2];
            _navigateToCourse(navigator, courseId);
          }
          break;
          
        case 'batch':
          if (pathSegments.length >= 4) {
            final courseId = pathSegments[2];
            final batchId = pathSegments[3];
            _navigateToBatch(navigator, courseId, batchId);
          }
          break;
          
        case 'feed':
          if (pathSegments.length >= 3) {
            final feedId = pathSegments[2];
            _navigateToFeed(navigator, feedId);
          }
          break;
          
        default:
          debugPrint('Unknown deep link route: $routeType');
      }
    } else if (pathSegments.first == 'delete-account') {
      navigator.pushNamed('/delete-account');
    } else {
      debugPrint('Unhandled deep link path: ${uri.path}');
    }
  }

  /// Navigate to course detail page.
  void _navigateToCourse(NavigatorState navigator, String courseId) {
    debugPrint('Deep link navigating to course: $courseId');
    navigator.pushNamed('/course', arguments: courseId);
  }

  /// Navigate to batch section page.
  void _navigateToBatch(NavigatorState navigator, String courseId, String batchId) {
    debugPrint('Deep link navigating to batch: $courseId/$batchId');
    navigator.pushNamed('/batch', arguments: {
      'courseId': courseId,
      'batchId': batchId,
    });
  }

  /// Navigate to feed detail page.
  void _navigateToFeed(NavigatorState navigator, String feedId) {
    debugPrint('Deep link navigating to feed: $feedId');
    navigator.pushNamed('/feed', arguments: feedId);
  }

  /// Dispose of the service. Call when the app is being destroyed.
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _isInitialized = false;
  }
}
