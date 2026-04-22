import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/admin_models.dart';
import 'package:eduverse/core/notifications/notification_repository.dart';
import 'package:eduverse/core/notifications/notification_model.dart';

class FirebaseAdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final NotificationRepository _notificationRepo = NotificationRepository();

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
    return _db
        .collection('courses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AdminCourse.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> saveCourse(AdminCourse course, {bool isNew = false}) async {
    final data = course.toMap();
    if (isNew) {
      // Let Firestore generate ID or use slug
      await _db
          .collection('courses')
          .doc(course.id.isEmpty ? null : course.id)
          .set(data);
    } else {
      await _db.collection('courses').doc(course.id).update(data);
    }
    await _logAudit('save_course', 'course', course.id, data);
  }

  Future<void> deleteCourse(String courseId) async {
    await _db.collection('courses').doc(courseId).update({
      'visibility': 'archived',
    });
    await _logAudit('archive_course', 'course', courseId, {});
  }

  /// Archive a course (soft delete - sets visibility to 'archived')
  Future<void> archiveCourse(String courseId) async {
    await _db.collection('courses').doc(courseId).update({
      'visibility': 'archived',
    });
    await _logAudit('archive_course', 'course', courseId, {});
  }

  /// Permanently delete a course and all its subcollections (batches, lessons, etc.)
  Future<void> permanentlyDeleteCourse(String courseId) async {
    // Delete all batches and their subcollections first
    final batchesSnapshot = await _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .get();

    for (final batchDoc in batchesSnapshot.docs) {
      // Delete lessons
      final lessonsSnapshot = await batchDoc.reference
          .collection('lessons')
          .get();
      for (final lessonDoc in lessonsSnapshot.docs) {
        await lessonDoc.reference.delete();
      }
      // Delete notes
      final notesSnapshot = await batchDoc.reference.collection('notes').get();
      for (final noteDoc in notesSnapshot.docs) {
        await noteDoc.reference.delete();
      }
      // Delete planner items
      final plannerSnapshot = await batchDoc.reference
          .collection('planner')
          .get();
      for (final plannerDoc in plannerSnapshot.docs) {
        await plannerDoc.reference.delete();
      }
      // Delete quizzes
      final quizzesSnapshot = await batchDoc.reference
          .collection('quizzes')
          .get();
      for (final quizDoc in quizzesSnapshot.docs) {
        await quizDoc.reference.delete();
      }
      // Delete live classes
      final liveClassesSnapshot = await batchDoc.reference
          .collection('live_classes')
          .get();
      for (final liveClassDoc in liveClassesSnapshot.docs) {
        await liveClassDoc.reference.delete();
      }
      // Delete the batch itself
      await batchDoc.reference.delete();
    }

    // Finally delete the course document
    await _db.collection('courses').doc(courseId).delete();
    await _logAudit('permanently_delete_course', 'course', courseId, {});
  }

  // Batches
  Stream<List<AdminBatch>> getBatches(String courseId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AdminBatch.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> saveBatch(
    String courseId,
    AdminBatch batch, {
    bool isNew = false,
  }) async {
    final data = batch.toMap();
    if (isNew) {
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('batches')
          .add(data);
    } else {
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('batches')
          .doc(batch.id)
          .update(data);
    }
    await _logAudit(
      isNew ? 'create_batch' : 'update_batch',
      'batch',
      batch.id,
      data,
    );
  }

  Future<void> deleteBatch(String courseId, String batchId) async {
    await _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .delete();
    await _logAudit('delete_batch', 'batch', batchId, {});
  }

  // Lessons
  Stream<List<AdminLecture>> getLectures(String courseId, String batchId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('lessons')
        .orderBy('orderIndex')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => AdminLecture.fromMap(d.data(), d.id)).toList(),
        );
  }

  Future<void> saveLecture(
    String courseId,
    String batchId,
    AdminLecture lecture, {
    bool isNew = false,
  }) async {
    final data = lecture.toMap();
    if (isNew) {
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('batches')
          .doc(batchId)
          .collection('lessons')
          .add(data);

      // Send notification to enrolled users
      await _notificationRepo.createBatchNotification(
        title: '📚 New Lecture Added',
        body: lecture.title,
        targetType: NotificationTargetType.lecture,
        targetId: lecture.id,
        batchId: batchId,
        courseId: courseId,
      );
    } else {
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('batches')
          .doc(batchId)
          .collection('lessons')
          .doc(lecture.id)
          .update(data);
    }
  }

  Future<void> deleteLecture(
    String courseId,
    String batchId,
    String lectureId,
  ) async {
    await _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('lessons')
        .doc(lectureId)
        .delete();
    await _logAudit('delete_lecture', 'lecture', lectureId, {
      'courseId': courseId,
      'batchId': batchId,
    });
  }

  // Storage
  Future<String> uploadMedia(
    String path,
    Uint8List data,
    String contentType,
  ) async {
    final ref = _storage.ref(path);
    final task = await ref.putData(
      data,
      SettableMetadata(contentType: contentType),
    );
    return await task.ref.getDownloadURL();
  }

  // Functions
  Future<void> enrollStudent(
    String userId,
    String courseId,
    String batchId,
  ) async {
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
    await _db.collection('purchases').doc(purchaseId).update({
      'status': 'refunded',
    });
    await _logAudit('refund_purchase', 'purchase', purchaseId, {});
  }

  // Audit
  Future<void> _logAudit(
    String action,
    String type,
    String id,
    Map<String, dynamic> diff,
  ) async {
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
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AdminUser.fromMap(doc.data(), doc.id))
              .toList();
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
          .where(
            (user) =>
                user.email.toLowerCase().contains(lowerQuery) ||
                user.name.toLowerCase().contains(lowerQuery),
          )
          .toList();
    });
  }

  // Get users by role
  Stream<List<AdminUser>> getUsersByRole(String role) {
    return _db
        .collection('users')
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AdminUser.fromMap(doc.data(), doc.id))
              .toList();
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
    await _logAudit('toggle_user_disabled', 'user', userId, {
      'disabled': disabled,
    });
  }

  // Update user profile
  Future<void> updateUser(AdminUser user) async {
    await _db.collection('users').doc(user.uid).update(user.toMap());
    await _logAudit('update_user', 'user', user.uid, user.toMap());
  }

  // Manual enrollment - add batch to user's enrolledCourses
  Future<void> manualEnrollUser(
    String userId,
    String courseId,
    String batchId,
  ) async {
    final enrollmentId = '${courseId}_$batchId';

    // Add to user's enrolled courses ARRAY (Legacy/Admin View Support)
    await _db.collection('users').doc(userId).update({
      'enrolledCourses': FieldValue.arrayUnion([enrollmentId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Add to user's enrolledCourses SUBCOLLECTION (New Study Fetch Logic)
    await _db
        .collection('users')
        .doc(userId)
        .collection('enrolledCourses')
        .doc(enrollmentId)
        .set({
          'courseId': courseId,
          'batchId': batchId,
          'enrolledAt': FieldValue.serverTimestamp(),
          'status': 'active',
          'enrolledBy': 'admin_manual',
        }, SetOptions(merge: true));

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
      'items': [
        {'courseId': courseId, 'batchId': batchId, 'type': 'batch_enrollment'},
      ],
    });

    await _logAudit('manual_enroll_user', 'user', userId, {
      'courseId': courseId,
      'batchId': batchId,
    });
  }

  // Manual unenrollment - remove batch from user's enrolledCourses
  Future<void> manualUnenrollUser(String userId, String enrollmentId) async {
    // Remove from user's enrolled courses ARRAY
    await _db.collection('users').doc(userId).update({
      'enrolledCourses': FieldValue.arrayRemove([enrollmentId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Remove from user's enrolledCourses SUBCOLLECTION
    await _db
        .collection('users')
        .doc(userId)
        .collection('enrolledCourses')
        .doc(enrollmentId)
        .delete();

    // Log audit
    await _logAudit('manual_unenroll_user', 'user', userId, {
      'enrollmentId': enrollmentId,
    });
  }

  // Manual Test Series enrollment - add tsId to user's purchasedTestSeries
  Future<void> manualEnrollTestSeries(String userId, String tsId) async {
    // Add to user's purchasedTestSeries ARRAY
    await _db.collection('users').doc(userId).update({
      'purchasedTestSeries': FieldValue.arrayUnion([tsId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Add to user's purchasedTestSeries SUBCOLLECTION
    await _db
        .collection('users')
        .doc(userId)
        .collection('purchasedTestSeries')
        .doc(tsId)
        .set({
          'testSeriesId': tsId,
          'enrolledAt': FieldValue.serverTimestamp(),
          'status': 'active',
          'enrolledBy': 'admin_manual',
        }, SetOptions(merge: true));

    // Create a purchase record for tracking
    await _db.collection('purchases').add({
      'userId': userId,
      'testSeriesId': tsId,
      'amount': 0.0,
      'status': 'manual_enrollment',
      'paymentMethod': 'admin_manual',
      'createdAt': FieldValue.serverTimestamp(),
      'enrolledByAdmin': currentUser?.uid,
      'items': [
        {'testSeriesId': tsId, 'type': 'test_series_enrollment'},
      ],
    });

    await _logAudit('manual_enroll_test_series', 'user', userId, {
      'testSeriesId': tsId,
    });
  }

  // Manual Test Series unenrollment - remove tsId from user's purchasedTestSeries
  Future<void> manualUnenrollTestSeries(String userId, String tsId) async {
    // Remove from user's purchasedTestSeries ARRAY
    await _db.collection('users').doc(userId).update({
      'purchasedTestSeries': FieldValue.arrayRemove([tsId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Remove from user's purchasedTestSeries SUBCOLLECTION
    await _db
        .collection('users')
        .doc(userId)
        .collection('purchasedTestSeries')
        .doc(tsId)
        .delete();

    // Log audit
    await _logAudit('manual_unenroll_test_series', 'user', userId, {
      'testSeriesId': tsId,
    });
  }

  // Get user's purchases
  Stream<List<AdminPurchase>> getUserPurchases(String userId) {
    return _db
        .collection('purchases')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AdminPurchase.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Batch Resources: Notes
  Stream<List<AdminNote>> getBatchNotes(String courseId, String batchId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => AdminNote.fromMap(d.data(), d.id)).toList(),
        );
  }

  Future<void> saveBatchNote(
    String courseId,
    String batchId,
    AdminNote note, {
    bool isNew = false,
  }) async {
    final data = note.toMap();
    if (isNew) {
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('batches')
          .doc(batchId)
          .collection('notes')
          .add(data);
    } else {
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('batches')
          .doc(batchId)
          .collection('notes')
          .doc(note.id)
          .update(data);
    }
  }

  Future<void> deleteBatchNote(
    String courseId,
    String batchId,
    String noteId,
  ) async {
    await _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('notes')
        .doc(noteId)
        .delete();
  }

  // Batch Resources: DPPs (Daily Practice Problems)
  Stream<List<AdminDpp>> getBatchDpps(String courseId, String batchId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('dpps')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => AdminDpp.fromMap(d.data(), d.id)).toList(),
        );
  }

  Future<void> saveBatchDpp(
    String courseId,
    String batchId,
    AdminDpp dpp, {
    bool isNew = false,
  }) async {
    final data = dpp.toMap();
    final ref = _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('dpps');
    if (isNew) {
      await ref.add(data);
    } else {
      await ref.doc(dpp.id).update(data);
    }
  }

  Future<void> deleteBatchDpp(
    String courseId,
    String batchId,
    String dppId,
  ) async {
    await _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('dpps')
        .doc(dppId)
        .delete();
  }

  // Batch Resources: Planner
  Stream<List<AdminPlannerItem>> getBatchPlanner(
    String courseId,
    String batchId,
  ) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('planner')
        .orderBy('date')
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => AdminPlannerItem.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  Future<void> saveBatchPlannerItem(
    String courseId,
    String batchId,
    AdminPlannerItem item, {
    bool isNew = false,
  }) async {
    final data = item.toMap();
    if (isNew) {
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('batches')
          .doc(batchId)
          .collection('planner')
          .add(data);
    } else {
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('batches')
          .doc(batchId)
          .collection('planner')
          .doc(item.id)
          .update(data);
    }
  }

  Future<void> deleteBatchPlannerItem(
    String courseId,
    String batchId,
    String itemId,
  ) async {
    await _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('planner')
        .doc(itemId)
        .delete();
  }

  // Batch Resources: Quizzes
  Stream<List<AdminQuiz>> getBatchQuizzes(String courseId, String batchId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('quizzes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => AdminQuiz.fromMap(d.data(), d.id)).toList(),
        );
  }

  Future<void> saveBatchQuiz(
    String courseId,
    String batchId,
    AdminQuiz quiz, {
    bool isNew = false,
  }) async {
    final data = quiz.toMap();
    if (isNew) {
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('batches')
          .doc(batchId)
          .collection('quizzes')
          .add(data);
    } else {
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('batches')
          .doc(batchId)
          .collection('quizzes')
          .doc(quiz.id)
          .update(data);
    }
  }

  Future<void> deleteBatchQuiz(
    String courseId,
    String batchId,
    String quizId,
  ) async {
    await _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('quizzes')
        .doc(quizId)
        .delete();
  }

  // Configuration Management
  Stream<Map<String, dynamic>> getGeneralConfig() {
    return _db.collection('config').doc('general').snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return {'maintenanceMode': false}; // Default config
      }
      return snapshot.data()!;
    });
  }

  Future<void> updateMaintenanceMode(bool isEnabled) async {
    await _db.collection('config').doc('general').set({
      'maintenanceMode': isEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUser?.uid,
    }, SetOptions(merge: true));

    await _logAudit('update_maintenance_mode', 'config', 'general', {
      'enabled': isEnabled,
    });
  }

  // Free Live Classes
  Stream<List<AdminLiveClass>> getLiveClasses() {
    return _db
        .collection('free_live_classes')
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AdminLiveClass.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> saveLiveClass(
    AdminLiveClass liveClass, {
    bool isNew = false,
  }) async {
    final data = liveClass.toMap();
    if (isNew) {
      await _db.collection('free_live_classes').add(data);
    } else {
      await _db.collection('free_live_classes').doc(liveClass.id).update(data);
    }
    await _logAudit('save_live_class', 'free_live_classes', liveClass.id, data);
  }

  Future<void> deleteLiveClass(String liveClassId) async {
    await _db.collection('free_live_classes').doc(liveClassId).delete();
    await _logAudit('delete_live_class', 'free_live_classes', liveClassId, {});
  }

  // Batch Live Classes (Scoped)
  Stream<List<AdminLiveClass>> getBatchLiveClasses(
    String courseId,
    String batchId,
  ) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('live_classes')
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AdminLiveClass.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> saveBatchLiveClass(
    String courseId,
    String batchId,
    AdminLiveClass liveClass, {
    bool isNew = false,
  }) async {
    final data = liveClass.toMap();

    // Check if status is completed - Move to Lessons
    if (liveClass.status == 'completed') {
      try {
        // 1. Get current max orderIndex
        final lessonsSnapshot = await _db
            .collection('courses')
            .doc(courseId)
            .collection('batches')
            .doc(batchId)
            .collection('lessons')
            .orderBy('orderIndex', descending: true)
            .limit(1)
            .get();

        int nextOrderIndex = 0;
        if (lessonsSnapshot.docs.isNotEmpty) {
          nextOrderIndex =
              (lessonsSnapshot.docs.first.data()['orderIndex'] ?? 0) + 1;
        }

        // 2. Create AdminLecture
        // ignore: unused_local_variable
        final _ = liveClass
            .id; // Keep same ID or generate new? New ID is safer to avoid confusion
        final lecture = AdminLecture(
          id: Uuid().v4(), // Generate new ID for lecture
          title: liveClass.title,
          description: liveClass.description,
          orderIndex: nextOrderIndex,
          type: 'video',
          storagePath: liveClass
              .youtubeUrl, // Mapping youtube link to storagePath/videoUrl
          isLocked: false,
          subject: liveClass.subject,
          chapter: liveClass.chapter,
          lectureNo: liveClass.lectureNo,
        );

        // 3. Add to lessons
        await _db
            .collection('courses')
            .doc(courseId)
            .collection('batches')
            .doc(batchId)
            .collection('lessons')
            .add(lecture.toMap());

        // 4. Delete from live classes (if it existed previously)
        if (!isNew) {
          await _db
              .collection('courses')
              .doc(courseId)
              .collection('batches')
              .doc(batchId)
              .collection('live_classes')
              .doc(liveClass.id)
              .delete();
        }

        // Log migration
        await _logAudit('migrate_live_to_lecture', 'lecture', lecture.id, {
          'from_live_class': liveClass.id,
          'courseId': courseId,
          'batchId': batchId,
        });

        return; // Exit function as we've moved it
      } catch (e) {
        // If migration fails, fallback to just saving as live class but maybe log error?
        // OR rethrow to let UI know.
        print('Error migrating live class to lecture: $e');
        rethrow;
      }
    }

    if (isNew) {
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('batches')
          .doc(batchId)
          .collection('live_classes')
          .add(data);

      // Send notification to enrolled users
      await _notificationRepo.createBatchNotification(
        title: ' New Live Class Scheduled',
        body: liveClass.title,
        targetType: NotificationTargetType.liveClass,
        targetId: liveClass.id,
        batchId: batchId,
        courseId: courseId,
      );
    } else {
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('batches')
          .doc(batchId)
          .collection('live_classes')
          .doc(liveClass.id)
          .update(data);
    }
    await _logAudit(
      isNew ? 'create_batch_live_class' : 'update_batch_live_class',
      'live_class',
      liveClass.id,
      {'courseId': courseId, 'batchId': batchId, ...data},
    );
  }

  Future<void> deleteBatchLiveClass(
    String courseId,
    String batchId,
    String liveClassId,
  ) async {
    await _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('live_classes')
        .doc(liveClassId)
        .delete();
    await _logAudit('delete_batch_live_class', 'live_class', liveClassId, {
      'courseId': courseId,
      'batchId': batchId,
    });
  }

  // ============ QUIZ SUBJECTS ============

  Stream<List<String>> getSubjects() {
    return _db.collection('quiz_subjects').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> addSubject(String name) async {
    final docId = name.trim();
    if (docId.isEmpty) return;

    await _db.collection('quiz_subjects').doc(docId).set({
      'name': docId,
      'chapters': [],
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _logAudit('add_quiz_subject', 'quiz_subjects', docId, {});
  }

  /// Returns a stream of chapters for the given subject.
  Stream<List<String>> getChaptersForSubject(String subject) {
    if (subject.isEmpty) return Stream.value([]);
    return _db
        .collection('quiz_subjects')
        .doc(subject)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return <String>[];
          final data = doc.data();
          if (data == null || data['chapters'] == null) return <String>[];
          return List<String>.from(data['chapters']);
        });
  }

  /// Adds a new chapter to the given subject's chapters array.
  Future<void> addChapterToSubject(String subject, String chapter) async {
    if (subject.isEmpty || chapter.trim().isEmpty) return;
    await _db.collection('quiz_subjects').doc(subject).update({
      'chapters': FieldValue.arrayUnion([chapter.trim()]),
    });
    await _logAudit('add_chapter_to_subject', 'quiz_subjects', subject, {
      'chapter': chapter.trim(),
    });
  }

  Future<void> deleteSubject(String name) async {
    await _db.collection('quiz_subjects').doc(name).delete();
    await _logAudit('delete_quiz_subject', 'quiz_subjects', name, {});
  }

  // ============ QUIZ POOL (Global Library) ============

  /// Saves or updates a quiz in the top-level [quizzes_pool] collection.
  /// Uses the quiz's [id] as the Firestore document ID so that subsequent
  /// calls with the same quiz overwrite instead of duplicating.
  Future<void> saveToQuizPool(AdminQuiz quiz) async {
    final data = quiz.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db
        .collection('quizzes_pool')
        .doc(quiz.id)
        .set(data, SetOptions(merge: true));
    await _logAudit('save_to_quiz_pool', 'quizzes_pool', quiz.id, {
      'title': quiz.title,
      'questionCount': quiz.questions.length,
    });
  }

  /// Returns a live stream of all quizzes in [quizzes_pool], newest first.
  Stream<List<AdminQuiz>> getQuizPool() {
    return _db
        .collection('quizzes_pool')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AdminQuiz.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Permanently removes a quiz from the global [quizzes_pool] library.
  Future<void> deleteFromQuizPool(String quizId) async {
    await _db.collection('quizzes_pool').doc(quizId).delete();
    await _logAudit('delete_from_quiz_pool', 'quizzes_pool', quizId, {});
  }

  // ============ BATCH ENROLLMENT QUERIES ============

  /// Get all users enrolled in a specific batch.
  /// Queries users where enrolledCourses array contains '{courseId}_{batchId}'.
  Future<List<AdminUser>> getEnrolledUsersForBatch(
    String courseId,
    String batchId,
  ) async {
    final enrollmentId = '${courseId}_$batchId';
    final snapshot = await _db
        .collection('users')
        .where('enrolledCourses', arrayContains: enrollmentId)
        .get();

    return snapshot.docs
        .map((doc) => AdminUser.fromMap(doc.data(), doc.id))
        .toList();
  }
}
