import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/admin_models.dart';

class FirebaseAdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Auth
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<Map<String, dynamic>> getAdminClaims() async {
    final user = _auth.currentUser;
    if (user == null) return {};
    final token = await user.getIdTokenResult(true);
    return token.claims ?? {};
  }

  // Courses
  Stream<List<AdminCourse>> getCourses() {
    return _db.collection('courses').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AdminCourse.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> saveCourse(AdminCourse course, {bool isNew = false}) async {
    final data = course.toMap();
    if (isNew) {
      // Let Firestore generate ID or use slug
      await _db.collection('courses').doc(course.id.isEmpty ? null : course.id).set(data);
    } else {
      await _db.collection('courses').doc(course.id).update(data);
    }
    await _logAudit('save_course', 'course', course.id, data);
  }

  Future<void> deleteCourse(String courseId) async {
    await _db.collection('courses').doc(courseId).update({'visibility': 'archived'});
    await _logAudit('archive_course', 'course', courseId, {});
  }

  // Batches
  Stream<List<AdminBatch>> getBatches(String courseId) {
    return _db.collection('courses').doc(courseId).collection('batches').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AdminBatch.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> saveBatch(String courseId, AdminBatch batch, {bool isNew = false}) async {
    final data = batch.toMap();
    if (isNew) {
      await _db.collection('courses').doc(courseId).collection('batches').add(data);
    } else {
      await _db.collection('courses').doc(courseId).collection('batches').doc(batch.id).update(data);
    }
    await _logAudit(isNew ? 'create_batch' : 'update_batch', 'batch', batch.id, data);
  }

  Future<void> deleteBatch(String courseId, String batchId) async {
    await _db.collection('courses').doc(courseId).collection('batches').doc(batchId).delete();
    await _logAudit('delete_batch', 'batch', batchId, {});
  }

  // Lessons
  Stream<List<AdminLecture>> getLectures(String courseId, String batchId) {
    return _db.collection('courses').doc(courseId).collection('batches').doc(batchId).collection('lessons')
        .orderBy('orderIndex')
        .snapshots()
        .map((s) => s.docs.map((d) => AdminLecture.fromMap(d.data(), d.id)).toList());
  }

  Future<void> saveLecture(String courseId, String batchId, AdminLecture lecture, {bool isNew = false}) async {
    final data = lecture.toMap();
    if (isNew) {
      await _db.collection('courses').doc(courseId).collection('batches').doc(batchId).collection('lessons').add(data);
    } else {
      await _db.collection('courses').doc(courseId).collection('batches').doc(batchId).collection('lessons').doc(lecture.id).update(data);
    }
  }

  // Storage
  Future<String> uploadMedia(String path, Uint8List data, String contentType) async {
    final ref = _storage.ref(path);
    final task = await ref.putData(data, SettableMetadata(contentType: contentType));
    return await task.ref.getDownloadURL();
  }

  // Functions
  Future<void> enrollStudent(String userId, String courseId, String batchId) async {
    final callable = _functions.httpsCallable('enrollStudent');
    await callable.call({
      'userId': userId,
      'courseId': courseId,
      'batchId': batchId,
    });
  }

  Future<void> triggerRefund(String purchaseId) async {
    // Stub for refund function
    // await _functions.httpsCallable('refundPurchase').call({'purchaseId': purchaseId});
    // For now, just update status manually as admin
    await _db.collection('purchases').doc(purchaseId).update({'status': 'refunded'});
    await _logAudit('refund_purchase', 'purchase', purchaseId, {});
  }

  // Audit
  Future<void> _logAudit(String action, String type, String id, Map<String, dynamic> diff) async {
    if (currentUser == null) return;
    await _db.collection('audits').add({
      'action': action,
      'adminId': currentUser!.uid,
      'entityType': type,
      'entityId': id,
      'timestamp': FieldValue.serverTimestamp(),
      'diff': diff,
    });
  }

  // ============ USER MANAGEMENT ============

  // Get all users stream
  Stream<List<AdminUser>> getUsers() {
    return _db.collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AdminUser.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Get single user by ID
  Future<AdminUser?> getUserById(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return AdminUser.fromMap(doc.data()!, doc.id);
  }

  // Search users by email or name
  Stream<List<AdminUser>> searchUsers(String query) {
    final lowerQuery = query.toLowerCase();
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AdminUser.fromMap(doc.data(), doc.id))
          .where((user) =>
              user.email.toLowerCase().contains(lowerQuery) ||
              user.name.toLowerCase().contains(lowerQuery))
          .toList();
    });
  }

  // Get users by role
  Stream<List<AdminUser>> getUsersByRole(String role) {
    return _db.collection('users')
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AdminUser.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Update user role
  Future<void> updateUserRole(String userId, String newRole) async {
    await _db.collection('users').doc(userId).update({
      'role': newRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _logAudit('update_user_role', 'user', userId, {'newRole': newRole});
  }

  // Toggle user disabled status
  Future<void> toggleUserDisabled(String userId, bool disabled) async {
    await _db.collection('users').doc(userId).update({
      'disabled': disabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _logAudit('toggle_user_disabled', 'user', userId, {'disabled': disabled});
  }

  // Update user profile
  Future<void> updateUser(AdminUser user) async {
    await _db.collection('users').doc(user.uid).update(user.toMap());
    await _logAudit('update_user', 'user', user.uid, user.toMap());
  }

  // Manual enrollment - add batch to user's enrolledCourses
  Future<void> manualEnrollUser(String userId, String courseId, String batchId) async {
    final enrollmentId = '${courseId}_$batchId';
    
    // Add to user's enrolled courses
    await _db.collection('users').doc(userId).update({
      'enrolledCourses': FieldValue.arrayUnion([enrollmentId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Create a purchase record for tracking
    await _db.collection('purchases').add({
      'userId': userId,
      'courseId': courseId,
      'batchId': batchId,
      'amount': 0.0,
      'status': 'manual_enrollment',
      'paymentMethod': 'admin_manual',
      'createdAt': FieldValue.serverTimestamp(),
      'enrolledByAdmin': currentUser?.uid,
    });
    
    await _logAudit('manual_enroll_user', 'user', userId, {
      'courseId': courseId,
      'batchId': batchId,
    });
  }

  // Manual unenrollment - remove batch from user's enrolledCourses
  Future<void> manualUnenrollUser(String userId, String enrollmentId) async {
    // Remove from user's enrolled courses
    await _db.collection('users').doc(userId).update({
      'enrolledCourses': FieldValue.arrayRemove([enrollmentId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Log audit
    await _logAudit('manual_unenroll_user', 'user', userId, {
      'enrollmentId': enrollmentId,
    });
  }

  // Get user's purchases
  Stream<List<AdminPurchase>> getUserPurchases(String userId) {
    return _db.collection('purchases')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AdminPurchase.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Batch Resources: Notes
  Stream<List<AdminNote>> getBatchNotes(String courseId, String batchId) {
    return _db.collection('courses').doc(courseId).collection('batches').doc(batchId).collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => AdminNote.fromMap(d.data(), d.id)).toList());
  }

  Future<void> saveBatchNote(String courseId, String batchId, AdminNote note, {bool isNew = false}) async {
    final data = note.toMap();
    if (isNew) {
      await _db.collection('courses').doc(courseId).collection('batches').doc(batchId).collection('notes').add(data);
    } else {
      await _db.collection('courses').doc(courseId).collection('batches').doc(batchId).collection('notes').doc(note.id).update(data);
    }
  }

  Future<void> deleteBatchNote(String courseId, String batchId, String noteId) async {
     await _db.collection('courses').doc(courseId).collection('batches').doc(batchId).collection('notes').doc(noteId).delete();
  }

  // Batch Resources: Planner
  Stream<List<AdminPlannerItem>> getBatchPlanner(String courseId, String batchId) {
    return _db.collection('courses').doc(courseId).collection('batches').doc(batchId).collection('planner')
        .orderBy('date')
        .snapshots()
        .map((s) => s.docs.map((d) => AdminPlannerItem.fromMap(d.data(), d.id)).toList());
  }

  Future<void> saveBatchPlannerItem(String courseId, String batchId, AdminPlannerItem item, {bool isNew = false}) async {
    final data = item.toMap();
    if (isNew) {
      await _db.collection('courses').doc(courseId).collection('batches').doc(batchId).collection('planner').add(data);
    } else {
      await _db.collection('courses').doc(courseId).collection('batches').doc(batchId).collection('planner').doc(item.id).update(data);
    }
  }

  Future<void> deleteBatchPlannerItem(String courseId, String batchId, String itemId) async {
     await _db.collection('courses').doc(courseId).collection('batches').doc(batchId).collection('planner').doc(itemId).delete();
  }

  // Batch Resources: Quizzes
  Stream<List<AdminQuiz>> getBatchQuizzes(String courseId, String batchId) {
    return _db.collection('courses').doc(courseId).collection('batches').doc(batchId).collection('quizzes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => AdminQuiz.fromMap(d.data(), d.id)).toList());
  }

  Future<void> saveBatchQuiz(String courseId, String batchId, AdminQuiz quiz, {bool isNew = false}) async {
    final data = quiz.toMap();
    if (isNew) {
      await _db.collection('courses').doc(courseId).collection('batches').doc(batchId).collection('quizzes').add(data);
    } else {
      await _db.collection('courses').doc(courseId).collection('batches').doc(batchId).collection('quizzes').doc(quiz.id).update(data);
    }
  }

  Future<void> deleteBatchQuiz(String courseId, String batchId, String quizId) async {
     await _db.collection('courses').doc(courseId).collection('batches').doc(batchId).collection('quizzes').doc(quizId).delete();
  }
}
