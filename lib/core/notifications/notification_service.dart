import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eduverse/core/firebase/firestore_paths.dart';
import 'package:eduverse/core/services/deep_link_screens.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}

/// Service for Firebase Cloud Messaging (push notifications)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isInitialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Set the navigator key for navigation
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Initialize FCM and local notifications
  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (navigatorKey != null) {
      _navigatorKey = navigatorKey;
    }
    if (_isInitialized) return;

    // Skip FCM on web - Web Push is not reliably supported (especially iOS Safari)
    if (kIsWeb) {
      debugPrint('NotificationService: Skipping FCM on web platform');
      _isInitialized = true;
      return;
    }

    try {
      _messaging = FirebaseMessaging.instance;
      // Request permission
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('FCM authorization status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token and store it
        await _updateFcmToken();

        // Listen for token refresh
        _messaging!.onTokenRefresh.listen(_saveFcmToken);

        // Initialize local notifications for foreground
        await _initLocalNotifications();

        // Set up message handlers
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // Handle initial message (app launched from terminated state)
        _handleInitialMessage();

        _isInitialized = true;
        debugPrint('NotificationService initialized successfully');
      }
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Handle initial message when app is launched from terminated state
  Future<void> _handleInitialMessage() async {
    final initialMessage = await _messaging?.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App launched from terminated state via notification');
      // Delay navigation slightly to ensure navigator is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToTarget(initialMessage.data);
      });
    }
  }

  /// Initialize local notifications for foreground display
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'eduverse_channel',
      'Eduverse Notifications',
      description: 'Notifications from Eduverse app',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Get and save FCM token
  Future<void> _updateFcmToken() async {
    try {
      final token = await _messaging?.getToken();
      if (token != null) {
        await _saveFcmToken(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// Save FCM token and current app version to user document
  Future<void> _saveFcmToken(String token) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Get current app version
    String appVersion = '';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
    } catch (_) {}

    final data = <String, dynamic>{
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      if (appVersion.isNotEmpty) 'appVersion': appVersion,
    };

    try {
      await _firestore.collection(FirestorePaths.users).doc(userId).update(data);
      debugPrint('FCM token & appVersion ($appVersion) saved for user $userId');
    } catch (e) {
      // Document might not exist, try set with merge
      try {
        await _firestore.collection(FirestorePaths.users).doc(userId).set(
          data,
          SetOptions(merge: true),
        );
      } catch (e2) {
        debugPrint('Error saving FCM token: $e2');
      }
    }
  }

  /// Handle foreground message - show local notification
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.notification?.title}');

    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'Eduverse',
        body: notification.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Handle message when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.data}');
    _navigateToTarget(message.data);
  }

  /// Handle notification tap (for local notifications in foreground)
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _navigateToTarget(data);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// Navigate to the target screen based on notification data
  void _navigateToTarget(Map<String, dynamic> data) {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      debugPrint('Navigator not available for notification navigation');
      return;
    }

    final targetType = data['targetType'] as String?;
    final targetId = data['targetId'] as String?;

    debugPrint('Navigating to targetType: $targetType, targetId: $targetId');

    if (targetType == null || targetId == null) {
      debugPrint('Missing targetType or targetId in notification data');
      return;
    }

    switch (targetType) {
      case 'feedItem':
        navigator.push(
          MaterialPageRoute(
            builder: (context) => DeepLinkFeedScreen(feedId: targetId),
          ),
        );
        break;
      case 'course':
        navigator.push(
          MaterialPageRoute(
            builder: (context) => DeepLinkCourseScreen(courseId: targetId),
          ),
        );
        break;
      case 'batch':
        final courseId = data['courseId'] as String?;
        if (courseId != null) {
          navigator.push(
            MaterialPageRoute(
              builder: (context) => DeepLinkBatchScreen(
                courseId: courseId,
                batchId: targetId,
              ),
            ),
          );
        }
        break;
      default:
        debugPrint('Unknown targetType: $targetType');
    }
  }

  /// Show a local notification (for foreground)
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'eduverse_channel',
      'Eduverse Notifications',
      channelDescription: 'Notifications from Eduverse app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Subscribe to a topic (e.g., for batch-specific notifications)
  Future<void> subscribeToTopic(String topic) async {
    if (_messaging == null) return;
    try {
      await _messaging!.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (_messaging == null) return;
    try {
      await _messaging!.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }
}
