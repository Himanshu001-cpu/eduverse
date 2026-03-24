import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:eduverse/core/firebase/user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ─────────────────────────────────────────────────────────────────
  // EMAIL/PASSWORD AUTHENTICATION
  // ─────────────────────────────────────────────────────────────────

  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    // Quick fallback for development/testing
    if (user.email == 'admin@eduverse.com') return true;

    try {
      final userData = await _userService.getCurrentUserData(user.uid);
      debugPrint('Checking admin status for ${user.email}: role=${userData?['role']}');
      return userData?['role'] == 'admin';
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  Future<void> syncAdminRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _userService.updateUserProfile(user.uid, {'role': 'admin'});
    }
  }

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
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e.code));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred');
    }
  }

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

      // Create user profile in Firestore
      if (credential.user != null) {
        await _userService.createUserProfile(
          credential.user!.uid, 
          email, 
          displayName ?? 'User',
        );
        
        if (displayName != null) {
          await credential.user!.updateDisplayName(displayName);
        }
      }
      return AuthResult.success(credential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e.code));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success(null, message: 'Password reset email sent');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e.code));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // PUBLIC HELPERS (Legacy support)
  // ─────────────────────────────────────────────────────────────────
  
  // Expose saveUserProfile to allow specific UI calls if needed, but prefer signUpWithEmail handling it
  Future<void> saveUserProfile({required String uid, required String email, String? displayName, String? phone}) async {
    await _userService.createUserProfile(uid, email, displayName ?? 'User', phone: phone);
  }

  // ─────────────────────────────────────────────────────────────────
  // PHONE NUMBER AUTHENTICATION
  // ─────────────────────────────────────────────────────────────────

  String? _verificationId;
  int? _resendToken;

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
      // Note: For phone auth, we might need to ask for Name separately if it's a new user
      // But we can create a basic profile here
      if (userCredential.user != null) {
        // We don't have email/name here usually, so we might need a separate flow or update later
        // For now, minimal init if check not exists
        // We can't easily call _userService.createUserProfile without email/name
      }
      return AuthResult.success(userCredential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e.code));
    } catch (e) {
      return AuthResult.failure('Invalid OTP. Please try again.');
    }
  }

  Future<AuthResult> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      return AuthResult.success(userCredential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e.code));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred during phone sign-in');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─────────────────────────────────────────────────────────────────
  // PHONE LINKING & ACCOUNT UPDATES
  // ─────────────────────────────────────────────────────────────────

  /// Link a phone credential to the currently signed-in user.
  Future<AuthResult> linkPhoneToAccount(PhoneAuthCredential credential) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure('No user signed in');
      }
      await user.linkWithCredential(credential);
      return AuthResult.success(user, message: 'Phone number linked successfully');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        return AuthResult.failure('This phone number is already linked to another account');
      }
      return AuthResult.failure(_mapFirebaseError(e.code));
    } catch (e) {
      return AuthResult.failure('Failed to link phone number');
    }
  }

  /// Verify a phone number for linking or updating (not for sign-in).
  /// Returns the credential via callbacks, which can then be used with
  /// linkPhoneToAccount or updatePhoneNumber.
  String? _linkVerificationId;
  int? _linkResendToken;

  Future<void> verifyPhoneForLinking({
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
          onAutoVerified(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(_mapFirebaseError(e.code));
        },
        codeSent: (String verificationId, int? resendToken) {
          _linkVerificationId = verificationId;
          _linkResendToken = resendToken;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _linkVerificationId = verificationId;
        },
        forceResendingToken: _linkResendToken,
      );
    } catch (e) {
      onError('Failed to verify phone number');
    }
  }

  /// Verify an OTP for linking/updating (uses _linkVerificationId).
  PhoneAuthCredential? getLinkingCredential(String otp) {
    if (_linkVerificationId == null) return null;
    return PhoneAuthProvider.credential(
      verificationId: _linkVerificationId!,
      smsCode: otp,
    );
  }

  /// Update the email on the currently signed-in Firebase Auth user.
  Future<AuthResult> updateEmail(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure('No user signed in');
      }
      await user.verifyBeforeUpdateEmail(newEmail.trim());
      // Also update Firestore
      await _userService.updateUserProfile(user.uid, {
        'email': newEmail.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return AuthResult.success(user, message: 'Verification email sent to $newEmail. Please verify to complete the change.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return AuthResult.failure('Please re-login and try again');
      }
      return AuthResult.failure(_mapFirebaseError(e.code));
    } catch (e) {
      return AuthResult.failure('Failed to update email');
    }
  }

  /// Update the phone number on the currently signed-in Firebase Auth user.
  Future<AuthResult> updatePhoneNumber(PhoneAuthCredential credential, String phoneNumber) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure('No user signed in');
      }
      await user.updatePhoneNumber(credential);
      // Also update Firestore
      await _userService.updateUserProfile(user.uid, {
        'phone': phoneNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return AuthResult.success(user, message: 'Phone number updated successfully');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return AuthResult.failure('Please re-login and try again');
      }
      return AuthResult.failure(_mapFirebaseError(e.code));
    } catch (e) {
      return AuthResult.failure('Failed to update phone number');
    }
  }

  /// Re-authenticate the user with email/password (required before sensitive ops).
  Future<AuthResult> reauthenticateWithEmail(String email, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure('No user signed in');
      }
      final credential = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);
      return AuthResult.success(user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e.code));
    } catch (e) {
      return AuthResult.failure('Re-authentication failed');
    }
  }

  /// Check if a user document exists in Firestore.
  Future<bool> userProfileExists(String uid) async {
    final data = await _userService.getCurrentUserData(uid);
    return data != null && data['name'] != null && data['name'] != '';
  }

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
      case 'credential-already-in-use':
        return 'This credential is already linked to another account';
      case 'requires-recent-login':
        return 'Please re-login and try again';
      default:
        return 'Authentication error: $code';
    }
  }
}

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
