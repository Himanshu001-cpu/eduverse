import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EduverseFirebase {
  static FirebaseFirestore? _mockFirestore;
  static FirebaseAuth? _mockAuth;

  static FirebaseFirestore get mockFirestore => _mockFirestore ?? FirebaseFirestore.instance;
  static set mockFirestore(FirebaseFirestore val) => _mockFirestore = val;

  static FirebaseAuth get mockAuth => _mockAuth ?? FirebaseAuth.instance;
  static set mockAuth(FirebaseAuth val) => _mockAuth = val;

  static FirebaseFirestore get firestore => mockFirestore;
  static FirebaseAuth get auth => mockAuth;
}
