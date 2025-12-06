import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:eduverse/core/firebase/firebase_options.dart';

class FirebaseInitializer {
  static Future<void> init() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        debugPrint('Firebase already initialized');
        return;
      }
      
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully');
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        debugPrint('Firebase already initialized (duplicate-app caught)');
      } else {
        debugPrint('Firebase initialization failed: ${e.message}');
        rethrow;
      }
    } catch (e) {
      // Fallback check for string message in case it's not a FirebaseException on some platforms
      if (e.toString().contains('duplicate-app')) {
        debugPrint('Firebase already initialized (duplicate-app string caught)');
      } else {
        debugPrint('Firebase initialization failed: $e');
        rethrow;
      }
    }
  }
}
