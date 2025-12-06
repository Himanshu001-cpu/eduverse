import 'package:firebase_auth/firebase_auth.dart';
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
