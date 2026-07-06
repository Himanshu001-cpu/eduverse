import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  User? _currentUser;
  final StreamController<User?> _authStateController = StreamController<User?>.broadcast();

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> authStateChanges() => _authStateController.stream;

  @override
  Stream<User?> idTokenChanges() => _authStateController.stream;

  @override
  Stream<User?> userChanges() => _authStateController.stream;

  void changeCurrentUser(User? user) {
    _currentUser = user;
    _authStateController.add(user);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final fakeUser = FakeUser(uid: email.split('@').first, email: email);
    changeCurrentUser(fakeUser);
    return FakeUserCredential(fakeUser);
  }

  @override
  Future<void> signOut() async {
    changeCurrentUser(null);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final fakeUser = FakeUser(uid: email.split('@').first, email: email);
    changeCurrentUser(fakeUser);
    return FakeUserCredential(fakeUser);
  }
}

class FakeUser extends Fake implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String displayName;
  @override
  final String? phoneNumber;

  FakeUser({required this.uid, this.email, this.displayName = 'Test User', this.phoneNumber});
}

class FakeUserCredential extends Fake implements UserCredential {
  @override
  final User? user;

  FakeUserCredential(this.user);
}
