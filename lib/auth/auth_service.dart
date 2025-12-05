import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Authentication service for user login/register operations.
/// Supports email/password and phone number authentication.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Current user getter
  User? get currentUser => _auth.currentUser;

  // Auth state stream for reactive UI
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─────────────────────────────────────────────────────────────────
  // USER PROFILE STORAGE
  // ─────────────────────────────────────────────────────────────────

  /// Save user profile to Firestore after registration
  /// Call this after successful sign-up (email or phone)
  Future<void> saveUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? phone,
  }) async {
    try {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'displayName': displayName ?? '',
        'phone': phone ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'role': 'user', // Default role, set to 'admin' manually in console
      }, SetOptions(merge: true));
      debugPrint('User profile saved successfully for uid: $uid');
    } catch (e) {
      debugPrint('Failed to save user profile: $e');
      rethrow;
    }
  }

  /// Check if current user is an admin (superadmin, admin, content_manager, or support)
  Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;
    
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      final role = doc.data()?['role'] as String?;
      // Check for any admin-level role
      const adminRoles = ['superadmin', 'admin', 'content_manager', 'support'];
      return role != null && adminRoles.contains(role);
    } catch (e) {
      debugPrint('Failed to check admin status: $e');
      return false;
    }
  }

  /// Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('Failed to get user profile: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // EMAIL/PASSWORD AUTHENTICATION
  // ─────────────────────────────────────────────────────────────────

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.success(credential.user);
    } on FirebaseException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e.code ?? 'unknown'));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  /// Register with email and password
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
      }

      return AuthResult.success(credential.user);
    } on FirebaseException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e.code ?? 'unknown'));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  /// Send password reset email
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success(null, message: 'Password reset email sent');
    } on FirebaseException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e.code ?? 'unknown'));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // PHONE NUMBER AUTHENTICATION
  // ─────────────────────────────────────────────────────────────────

  String? _verificationId;
  int? _resendToken;

  /// Start phone number verification
  /// [phoneNumber] should be in E.164 format (e.g., +919876543210)
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on Android
          onAutoVerified(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(_mapFirebaseError(e.code));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      onError('Failed to verify phone number');
    }
  }

  /// Verify OTP and sign in
  Future<AuthResult> verifyOTP(String otp) async {
    if (_verificationId == null) {
      return AuthResult.failure('Verification session expired. Please resend OTP.');
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      return AuthResult.success(userCredential.user);
    } on FirebaseException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e.code ?? 'unknown'));
    } catch (e) {
      return AuthResult.failure('Invalid OTP. Please try again.');
    }
  }

  /// Sign in with auto-verified credential (Android only)
  Future<AuthResult> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      return AuthResult.success(userCredential.user);
    } on FirebaseException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e.code ?? 'unknown'));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // COMMON METHODS
  // ─────────────────────────────────────────────────────────────────

  /// Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Map Firebase error codes to user-friendly messages
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password should be at least 6 characters';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Check your connection';
      case 'invalid-verification-code':
        return 'Invalid OTP. Please check and try again';
      case 'invalid-phone-number':
        return 'Invalid phone number format';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later';
      case 'session-expired':
        return 'Session expired. Please resend OTP';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again';
      default:
        debugPrint('Unhandled Firebase error: $code');
        return 'Something went wrong. Please try again';
    }
  }
}

/// Result wrapper for auth operations
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;
  final String? successMessage;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
    this.successMessage,
  });

  factory AuthResult.success(User? user, {String? message}) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      successMessage: message,
    );
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(
      isSuccess: false,
      errorMessage: error,
    );
  }
}
