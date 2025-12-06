import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/core/firebase/firestore_paths.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUserProfile(String uid, String email, String name, {String? phone}) async {
    final userDoc = _firestore.collection(FirestorePaths.users).doc(uid);
    
    final snapshot = await userDoc.get();
    if (!snapshot.exists) {
      await userDoc.set({
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'role': 'student',
        'enrolledCourses': [],
        'cart': [],
      });
    } else {
      // If user exists (e.g. from previous login attempt), just update last login or merge missing info
      await userDoc.set({
        'email': email,
        'name': name, // Update name if changed
        if (phone != null) 'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection(FirestorePaths.users).doc(uid).update(data);
  }

  Future<Map<String, dynamic>?> getCurrentUserData(String uid) async {
    final snapshot = await _firestore.collection(FirestorePaths.users).doc(uid).get();
    return snapshot.data();
  }
}
