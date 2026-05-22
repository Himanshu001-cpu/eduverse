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

  Future<void> triggerRefund(String purchaseId, {bool unenrollUser = false}) async {
    // 1. Call the secure Cloud Function to trigger Razorpay refund first.
    // If the gateway refund fails, this will throw an exception, preventing local changes.
    final callable = _functions.httpsCallable('refundPurchase');
    final result = await callable.call({
      'purchaseId': purchaseId,
    });

    final gatewayRefundId = result.data != null ? result.data['refundId'] as String? : null;

    // 2. Get the purchase document
    final doc = await _db.collection('purchases').doc(purchaseId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final purchase = AdminPurchase.fromMap(data, doc.id);

    // 3. If unenrollUser is true, iterate over purchase.items and unenroll the student
    if (unenrollUser) {
      for (final item in purchase.items) {
        if (item.testSeriesId != null && item.testSeriesId!.isNotEmpty) {
          await manualUnenrollTestSeries(purchase.userId, item.testSeriesId!);
        } else if (item.courseId.isNotEmpty && item.batchId.isNotEmpty) {
          final enrollmentId = '${item.courseId}_${item.batchId}';
          await manualUnenrollUser(purchase.userId, enrollmentId);
        }
      }
    }

    // 4. Update the purchase document status to 'refunded'
    await _db.collection('purchases').doc(purchaseId).update({
      'status': 'refunded',
      'gatewayRefundId': gatewayRefundId,
    });

    // 5. Sync refund status to student's transactions subcollection
    // so the student sees accurate status in "My Transactions" page.
    // For new purchases: orderId in transactions == purchaseId
    // For migrated purchases: orderId in transactions == paymentId field
    try {
      final paymentId = data['paymentId'] as String? ?? '';
      final lookupIds = <String>{purchaseId};
      if (paymentId.isNotEmpty) lookupIds.add(paymentId);

      for (final lookupId in lookupIds) {
        final txQuery = await _db
            .collection('users')
            .doc(purchase.userId)
            .collection('transactions')
            .where('orderId', isEqualTo: lookupId)
            .get();

        for (final txDoc in txQuery.docs) {
          await txDoc.reference.update({
            'status': 'refunded',
            'refundedAt': FieldValue.serverTimestamp(),
            if (gatewayRefundId != null) 'gatewayRefundId': gatewayRefundId,
          });
        }
      }
    } catch (_) {
      // Non-critical: if transaction sync fails, the purchase is still refunded
    }

    // 6. Log audit action
    await _logAudit('refund_purchase', 'purchase', purchaseId, {
      'unenrollUser': unenrollUser,
      'userId': purchase.userId,
      'amount': purchase.amount,
      'gatewayRefundId': gatewayRefundId,
      'items': purchase.items.map((i) => i.toMap()).toList(),
    });
  }

  // Get all purchases stream (in-memory sort by date descending)
  Stream<List<AdminPurchase>> getAllPurchases() {
    return _db.collection('purchases').snapshots().map((snapshot) {
      final purchases = snapshot.docs
          .map((doc) => AdminPurchase.fromMap(doc.data(), doc.id))
          .toList();
      // Sort in memory by date descending to guarantee zero transaction omissions
      // without requiring complex Firestore heterogeneous indexing.
      purchases.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return purchases;
    });
  }

  // Migrate older user-specific transactions to top-level purchases collection
  Future<String> migrateUserTransactionsToPurchases() async {
    try {
      int migratedCount = 0;
      int alreadyExistsCount = 0;

      // 1. Get all users
      final usersSnap = await _db.collection('users').get();

      // 2. Query all existing purchases to prevent duplicates (by orderId/paymentId or unique key combination)
      final existingPurchasesSnap = await _db.collection('purchases').get();
      final Set<String> existingPaymentIds = {};
      final Set<String> existingKeys = {}; // user_amount_timestamp fallback

      for (final doc in existingPurchasesSnap.docs) {
        final data = doc.data();
        final paymentId = data['paymentId'] as String? ?? data['purchaseId'] as String?;
        if (paymentId != null && paymentId.isNotEmpty) {
          existingPaymentIds.add(paymentId);
        }
        
        final uId = data['userId'] as String?;
        final amt = (data['amount'] as num?)?.toDouble();
        final ts = data['createdAt'] ?? data['timestamp'];
        if (uId != null && amt != null && ts != null) {
          final String tsStr = ts is Timestamp ? ts.toDate().toIso8601String() : ts.toString();
          existingKeys.add('${uId}_${amt}_$tsStr');
        }
      }

      // 3. Loop through users and their transactions
      for (final userDoc in usersSnap.docs) {
        final userId = userDoc.id;
        final txsSnap = await _db
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .get();

        for (final txDoc in txsSnap.docs) {
          final txData = txDoc.data();
          final orderId = txData['orderId'] as String? ?? '';
          final amount = (txData['amount'] as num?)?.toDouble() ?? 0.0;
          final status = txData['status'] as String? ?? 'success';
          final paymentMethod = txData['paymentMethod'] as String? ?? 'unknown';
          final productTitle = txData['productTitle'] as String? ?? 'Course Enrollment';
          final date = txData['date'] ?? txData['timestamp'];

          // Skip if already in database
          bool alreadyExists = false;
          if (orderId.isNotEmpty && existingPaymentIds.contains(orderId)) {
            alreadyExists = true;
          } else if (date != null) {
            final String tsStr = date is Timestamp ? date.toDate().toIso8601String() : date.toString();
            if (existingKeys.contains('${userId}_${amount}_$tsStr')) {
              alreadyExists = true;
            }
          }

          if (alreadyExists) {
            alreadyExistsCount++;
            continue;
          }

          // Create purchase record in global collection
          final purchaseData = {
            'userId': userId,
            'amount': amount,
            'paymentId': orderId.isNotEmpty ? orderId : txDoc.id,
            'paymentMethod': paymentMethod,
            'status': status == 'completed' ? 'success' : status,
            'createdAt': date ?? FieldValue.serverTimestamp(),
            'timestamp': date ?? FieldValue.serverTimestamp(),
            'migratedFromTransactionId': txDoc.id,
            'items': [
              {
                'courseId': 'legacy_migrated',
                'batchId': 'legacy_migrated',
                'title': productTitle,
                'price': amount,
                'quantity': 1,
              }
            ],
          };

          await _db.collection('purchases').add(purchaseData);
          migratedCount++;
        }
      }

      // Log audit
      await _logAudit('migrate_legacy_transactions', 'system', 'all', {
        'migratedCount': migratedCount,
        'alreadyExistsCount': alreadyExistsCount,
      });

      return 'Migration complete: $migratedCount transactions migrated, $alreadyExistsCount already existed.';
    } catch (e) {
      rethrow;
    }
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
    final callable = _functions.httpsCallable('setAdminRole');
    await callable.call({
      'uid': userId,
      'role': newRole,
    });
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
    final ref = _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('quizzes')
        .doc(quiz.id);
    if (isNew) {
      await ref.set(data);
    } else {
      await ref.update(data);
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

  Future<void> deleteLiveClass(String liveClassId, {bool deleteAllLinked = false}) async {
    final docRef = _db.collection('free_live_classes').doc(liveClassId);
    final snap = await docRef.get();
    if (!snap.exists) {
      await docRef.delete();
      return;
    }

    final liveClass = AdminLiveClass.fromMap(snap.data()!, snap.id);

    if (deleteAllLinked) {
      // Delete from all target batches
      for (final lb in liveClass.linkedBatches) {
        final tCourseId = lb['courseId'] ?? '';
        final tBatchId = lb['batchId'] ?? '';
        if (tCourseId.isNotEmpty && tBatchId.isNotEmpty) {
          final querySnap = await _db
              .collection('courses')
              .doc(tCourseId)
              .collection('batches')
              .doc(tBatchId)
              .collection('live_classes')
              .where('linkedFrom.originalId', isEqualTo: liveClassId)
              .get();
          for (final doc in querySnap.docs) {
            await doc.reference.delete();
          }
        }
      }
    }

    await docRef.delete();
    await _logAudit('delete_live_class', 'free_live_classes', liveClassId, {
      'deleteAllLinked': deleteAllLinked,
    });
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
    String liveClassId, {
    bool deleteAllLinked = false,
  }) async {
    final docRef = _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('live_classes')
        .doc(liveClassId);

    final snap = await docRef.get();
    if (!snap.exists) {
      await docRef.delete();
      return;
    }

    final liveClass = AdminLiveClass.fromMap(snap.data()!, snap.id);
    final linkedFrom = snap.data()?['linkedFrom'] as Map<dynamic, dynamic>?;

    if (deleteAllLinked) {
      String originalId;
      String originalCourseId;
      String originalBatchId;
      bool isFreeOriginal = false;
      List<Map<String, String>> linkedBatchesList = [];

      if (linkedFrom != null) {
        originalId = linkedFrom['originalId'] as String? ?? '';
        originalCourseId = linkedFrom['courseId'] as String? ?? '';
        originalBatchId = linkedFrom['batchId'] as String? ?? '';
        isFreeOriginal = linkedFrom['source'] == 'free_live_classes';

        // Fetch original to get all linked batches
        DocumentSnapshot<Map<String, dynamic>> originalSnap;
        if (isFreeOriginal) {
          originalSnap = await _db.collection('free_live_classes').doc(originalId).get();
        } else {
          originalSnap = await _db
              .collection('courses')
              .doc(originalCourseId)
              .collection('batches')
              .doc(originalBatchId)
              .collection('live_classes')
              .doc(originalId)
              .get();
        }

        if (originalSnap.exists) {
          final originalClass = AdminLiveClass.fromMap(originalSnap.data()!, originalSnap.id);
          linkedBatchesList = originalClass.linkedBatches;
        }
      } else {
        originalId = liveClass.id;
        originalCourseId = courseId;
        originalBatchId = batchId;
        isFreeOriginal = false;
        linkedBatchesList = liveClass.linkedBatches;
      }

      // Delete from all target batches
      for (final lb in linkedBatchesList) {
        final tCourseId = lb['courseId'] ?? '';
        final tBatchId = lb['batchId'] ?? '';
        if (tCourseId.isNotEmpty && tBatchId.isNotEmpty) {
          final querySnap = await _db
              .collection('courses')
              .doc(tCourseId)
              .collection('batches')
              .doc(tBatchId)
              .collection('live_classes')
              .where('linkedFrom.originalId', isEqualTo: originalId)
              .get();
          for (final doc in querySnap.docs) {
            await doc.reference.delete();
          }
        }
      }

      // Delete the original class
      if (isFreeOriginal) {
        await _db.collection('free_live_classes').doc(originalId).delete();
      } else if (originalCourseId.isNotEmpty && originalBatchId.isNotEmpty) {
        await _db
            .collection('courses')
            .doc(originalCourseId)
            .collection('batches')
            .doc(originalBatchId)
            .collection('live_classes')
            .doc(originalId)
            .delete();
      }
    } else {
      // DELETE ONLY THIS INSTANCE
      // If it's a linked copy, remove this batch from the original class's linkedBatches list
      if (linkedFrom != null) {
        final originalId = linkedFrom['originalId'] as String? ?? '';
        final originalCourseId = linkedFrom['courseId'] as String? ?? '';
        final originalBatchId = linkedFrom['batchId'] as String? ?? '';
        final isFreeOriginal = linkedFrom['source'] == 'free_live_classes';

        if (isFreeOriginal) {
          await _db.collection('free_live_classes').doc(originalId).update({
            'linkedBatches': FieldValue.arrayRemove([
              {'courseId': courseId, 'batchId': batchId}
            ])
          });
        } else if (originalCourseId.isNotEmpty && originalBatchId.isNotEmpty) {
          await _db
              .collection('courses')
              .doc(originalCourseId)
              .collection('batches')
              .doc(originalBatchId)
              .collection('live_classes')
              .doc(originalId)
              .update({
            'linkedBatches': FieldValue.arrayRemove([
              {'courseId': courseId, 'batchId': batchId}
            ])
          });
        }
      }
    }

    // Finally delete the current instance document
    await docRef.delete();

    await _logAudit('delete_batch_live_class', 'live_class', liveClassId, {
      'courseId': courseId,
      'batchId': batchId,
      'deleteAllLinked': deleteAllLinked,
    });
  }

  // ============ LIVE CLASS LINKING ============

  /// Links an existing live class to a target batch by copying its data.
  /// Also updates the source class's linkedBatches array.
  Future<void> linkLiveClassToBatch({
    required AdminLiveClass sourceClass,
    required String sourceCourseId,
    required String sourceBatchId,
    required String targetCourseId,
    required String targetBatchId,
  }) async {
    final data = sourceClass.toMap();
    // Remove linkedBatches from the copy — each copy is standalone
    data.remove('linkedBatches');
    // Mark it as a linked copy so we know it was imported
    data['linkedFrom'] = {
      'courseId': sourceCourseId,
      'batchId': sourceBatchId,
      'originalId': sourceClass.id,
    };

    // 1. Write the class to the target batch
    await _db
        .collection('courses')
        .doc(targetCourseId)
        .collection('batches')
        .doc(targetBatchId)
        .collection('live_classes')
        .add(data);

    // 2. Update the source class's linkedBatches array
    // Find the source doc first
    final sourceRef = _getSourceLiveClassRef(
      sourceCourseId, sourceBatchId, sourceClass.id,
    );
    if (sourceRef != null) {
      // For batch-scoped classes
      await _db
          .collection('courses')
          .doc(sourceCourseId)
          .collection('batches')
          .doc(sourceBatchId)
          .collection('live_classes')
          .doc(sourceClass.id)
          .update({
        'linkedBatches': FieldValue.arrayUnion([
          {'courseId': targetCourseId, 'batchId': targetBatchId},
        ]),
      });
    }

    // 3. Send notification to enrolled users of target batch
    await _notificationRepo.createBatchNotification(
      title: '📺 New Live Class Linked',
      body: sourceClass.title,
      targetType: NotificationTargetType.liveClass,
      targetId: sourceClass.id,
      batchId: targetBatchId,
      courseId: targetCourseId,
    );

    await _logAudit('link_live_class', 'live_class', sourceClass.id, {
      'sourceCourse': sourceCourseId,
      'sourceBatch': sourceBatchId,
      'targetCourse': targetCourseId,
      'targetBatch': targetBatchId,
    });
  }

  /// Helper to validate source ref path (non-null means batch-scoped)
  String? _getSourceLiveClassRef(
    String courseId, String batchId, String classId,
  ) {
    if (courseId.isNotEmpty && batchId.isNotEmpty && classId.isNotEmpty) {
      return 'courses/$courseId/batches/$batchId/live_classes/$classId';
    }
    return null;
  }

  /// Links a free (global) live class to a target batch by copying its data.
  Future<void> linkFreeLiveClassToBatch({
    required AdminLiveClass sourceClass,
    required String targetCourseId,
    required String targetBatchId,
  }) async {
    final data = sourceClass.toMap();
    data.remove('linkedBatches');
    data['linkedFrom'] = {
      'courseId': '',
      'batchId': '',
      'originalId': sourceClass.id,
      'source': 'free_live_classes',
    };

    // 1. Write the class to the target batch
    await _db
        .collection('courses')
        .doc(targetCourseId)
        .collection('batches')
        .doc(targetBatchId)
        .collection('live_classes')
        .add(data);

    // 2. Update the source free class's linkedBatches
    await _db.collection('free_live_classes').doc(sourceClass.id).update({
      'linkedBatches': FieldValue.arrayUnion([
        {'courseId': targetCourseId, 'batchId': targetBatchId},
      ]),
    });

    await _logAudit('link_free_live_class', 'live_class', sourceClass.id, {
      'targetCourse': targetCourseId,
      'targetBatch': targetBatchId,
    });
  }

  /// Gets all live classes from ALL batches across all courses.
  /// Used in the "Link Existing Class" dialog.
  Future<List<Map<String, dynamic>>> getAllLiveClassesForLinking() async {
    final result = <Map<String, dynamic>>[];

    // 1. Get all free live classes
    final freeClassesSnap =
        await _db.collection('free_live_classes').orderBy('startTime').get();
    for (final doc in freeClassesSnap.docs) {
      result.add({
        'class': AdminLiveClass.fromMap(doc.data(), doc.id),
        'courseId': '',
        'batchId': '',
        'courseName': 'Free Classes',
        'batchName': 'Global',
      });
    }

    // 2. Get all courses, then each batch's live classes
    final coursesSnap = await _db.collection('courses').get();
    for (final courseDoc in coursesSnap.docs) {
      final courseName = courseDoc.data()['title'] ?? courseDoc.id;
      final batchesSnap =
          await courseDoc.reference.collection('batches').get();
      for (final batchDoc in batchesSnap.docs) {
        final batchName = batchDoc.data()['name'] ?? batchDoc.id;
        final classesSnap = await batchDoc.reference
            .collection('live_classes')
            .orderBy('startTime')
            .get();
        for (final classDoc in classesSnap.docs) {
          result.add({
            'class': AdminLiveClass.fromMap(classDoc.data(), classDoc.id),
            'courseId': courseDoc.id,
            'batchId': batchDoc.id,
            'courseName': courseName,
            'batchName': batchName,
          });
        }
      }
    }

    return result;
  }

  /// Gets all courses with their batches (for the link target picker).
  Future<List<Map<String, dynamic>>> getCoursesWithBatches() async {
    final result = <Map<String, dynamic>>[];
    final coursesSnap = await _db.collection('courses').get();
    for (final courseDoc in coursesSnap.docs) {
      final courseName = courseDoc.data()['title'] ?? courseDoc.id;
      final batchesSnap =
          await courseDoc.reference.collection('batches').get();
      final batches = batchesSnap.docs.map((b) {
        return {
          'id': b.id,
          'name': b.data()['name'] ?? b.id,
        };
      }).toList();
      result.add({
        'courseId': courseDoc.id,
        'courseName': courseName,
        'batches': batches,
      });
    }
    return result;
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

  // ============ COMBINATION PACKS ============
  Stream<List<AdminCombinationPack>> getCombinationPacks() {
    return _db
        .collection('combination_packs')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AdminCombinationPack.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> saveCombinationPack(
    AdminCombinationPack pack, {
    bool isNew = false,
  }) async {
    final data = pack.toMap();
    if (isNew) {
      await _db.collection('combination_packs').add(data);
    } else {
      await _db.collection('combination_packs').doc(pack.id).set(data, SetOptions(merge: true));
    }
    await _logAudit(
      isNew ? 'create_combination_pack' : 'update_combination_pack',
      'combination_pack',
      pack.id,
      data,
    );
  }

  Future<void> deleteCombinationPack(String id) async {
    await _db.collection('combination_packs').doc(id).delete();
    await _logAudit('delete_combination_pack', 'combination_pack', id, {});
  }

  // ============ RECURSIVE FOLDER PREFIX RENAME ============
  Future<void> recursivelyRenameFolder({
    required String courseId,
    required String batchId,
    required String subject,
    required String oldFolderPath,
    required String newFolderPath,
  }) async {
    final String oldPrefix = oldFolderPath.endsWith('/') ? oldFolderPath : '$oldFolderPath/';
    final String newPrefix = newFolderPath.endsWith('/') ? newFolderPath : '$newFolderPath/';

    final batch = _db.batch();

    // 1. Rename folder and lessons
    final lessonsSnap = await _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('lessons')
        .where('subject', isEqualTo: subject)
        .get();

    for (final doc in lessonsSnap.docs) {
      final ch = doc.data()['chapter'] as String? ?? '';
      if (ch == oldFolderPath) {
        batch.update(doc.reference, {'chapter': newFolderPath});
      } else if (ch.startsWith(oldPrefix)) {
        final remaining = ch.substring(oldPrefix.length);
        batch.update(doc.reference, {'chapter': '$newPrefix$remaining'});
      }
    }

    // 2. Rename notes
    final notesSnap = await _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('notes')
        .where('subject', isEqualTo: subject)
        .get();

    for (final doc in notesSnap.docs) {
      final ch = doc.data()['chapter'] as String? ?? '';
      if (ch == oldFolderPath) {
        batch.update(doc.reference, {'chapter': newFolderPath});
      } else if (ch.startsWith(oldPrefix)) {
        final remaining = ch.substring(oldPrefix.length);
        batch.update(doc.reference, {'chapter': '$newPrefix$remaining'});
      }
    }

    // 3. Rename DPPs
    final dppsSnap = await _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('dpps')
        .where('subject', isEqualTo: subject)
        .get();

    for (final doc in dppsSnap.docs) {
      final ch = doc.data()['chapter'] as String? ?? '';
      if (ch == oldFolderPath) {
        batch.update(doc.reference, {'chapter': newFolderPath});
      } else if (ch.startsWith(oldPrefix)) {
        final remaining = ch.substring(oldPrefix.length);
        batch.update(doc.reference, {'chapter': '$newPrefix$remaining'});
      }
    }

    await batch.commit();

    await _logAudit('rename_folder', 'folder', oldFolderPath, {
      'courseId': courseId,
      'batchId': batchId,
      'subject': subject,
      'oldFolderPath': oldFolderPath,
      'newFolderPath': newFolderPath,
    });
  }

  // ============ RECURSIVE FOLDER DELETE ============
  Future<void> recursivelyDeleteFolder({
    required String courseId,
    required String batchId,
    required String subject,
    required String folderPath,
  }) async {
    final String prefix = folderPath.endsWith('/') ? folderPath : '$folderPath/';
    final batch = _db.batch();

    // 1. Delete folder placeholders and lessons
    final lessonsSnap = await _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('lessons')
        .where('subject', isEqualTo: subject)
        .get();

    for (final doc in lessonsSnap.docs) {
      final ch = doc.data()['chapter'] as String? ?? '';
      if (ch == folderPath || ch.startsWith(prefix)) {
        batch.delete(doc.reference);
      }
    }

    // 2. Delete notes
    final notesSnap = await _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('notes')
        .where('subject', isEqualTo: subject)
        .get();

    for (final doc in notesSnap.docs) {
      final ch = doc.data()['chapter'] as String? ?? '';
      if (ch == folderPath || ch.startsWith(prefix)) {
        batch.delete(doc.reference);
      }
    }

    // 3. Delete DPPs
    final dppsSnap = await _db
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('dpps')
        .where('subject', isEqualTo: subject)
        .get();

    for (final doc in dppsSnap.docs) {
      final ch = doc.data()['chapter'] as String? ?? '';
      if (ch == folderPath || ch.startsWith(prefix)) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();

    await _logAudit('delete_folder_recursive', 'folder', folderPath, {
      'courseId': courseId,
      'batchId': batchId,
      'subject': subject,
      'folderPath': folderPath,
    });
  }
}
