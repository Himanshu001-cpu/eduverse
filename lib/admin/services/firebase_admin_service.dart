
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/admin_models.dart';
import 'package:eduverse/core/notifications/notification_repository.dart';
import 'package:eduverse/core/notifications/notification_model.dart';
import 'package:eduverse/store/models/store_models.dart';

class FirebaseAdminService {
  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customDb;
  final FirebaseStorage? _customStorage;
  final FirebaseFunctions? _customFunctions;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _customDb ?? FirebaseFirestore.instance;
  FirebaseStorage get _storage => _customStorage ?? FirebaseStorage.instance;
  FirebaseFunctions get _functions => _customFunctions ?? FirebaseFunctions.instance;
  final NotificationRepository? _customNotificationRepo;
  NotificationRepository get _notificationRepo => _customNotificationRepo ?? NotificationRepository();

  FirebaseAdminService({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    FirebaseStorage? storage,
    FirebaseFunctions? functions,
    NotificationRepository? notificationRepo,
  })  : _customAuth = auth,
        _customDb = db,
        _customStorage = storage,
        _customFunctions = functions,
        _customNotificationRepo = notificationRepo;

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

  Stream<AdminCourse> getCourse(String courseId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .snapshots()
        .map((doc) => AdminCourse.fromMap(doc.data() ?? {}, doc.id));
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

  // Batches are deprecated. Collapsing directly to course lectures.
  Stream<List<AdminLecture>> getCourseLecturesCombined(String courseId) {
    return getLectures(courseId);
  }

  Stream<List<AdminNote>> getCourseNotesCombined(String courseId) {
    return getCourseNotes(courseId);
  }

  Stream<List<AdminDpp>> getCourseDppsCombined(String courseId) {
    return getCourseDpps(courseId);
  }

  // Lessons
  Stream<List<AdminLecture>> getLectures(String courseId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('lessons')
        .orderBy('orderIndex')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => AdminLecture.fromMap(d.data(), d.id)).toList(),
        );
  }

  Future<String> saveLecture(
    String courseId,
    AdminLecture lecture, {
    bool isNew = false,
  }) async {
    final data = lecture.toMap();
    if (isNew) {
      final docRef = _db
          .collection('courses')
          .doc(courseId)
          .collection('lessons')
          .doc();
      await docRef.set(data);

      // Send notification to enrolled users
      await _notificationRepo.createCourseNotification(
        title: '📚 New Lecture Added',
        body: lecture.title,
        targetType: NotificationTargetType.lecture,
        targetId: docRef.id,
        courseId: courseId,
      );
      return docRef.id;
    } else {
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('lessons')
          .doc(lecture.id)
          .update(data);
      return lecture.id;
    }
  }

  Future<void> deleteLecture(
    String courseId,
    String lectureId, {
    bool deleteAllLinked = false,
  }) async {
    final docRef = _db
        .collection('courses')
        .doc(courseId)
        .collection('lessons')
        .doc(lectureId);

    final snap = await docRef.get();
    if (!snap.exists) {
      await docRef.delete();
      return;
    }

    final data = snap.data()!;
    final linkedFrom = data['linkedFrom'] as Map<dynamic, dynamic>?;

    if (deleteAllLinked) {
      String originalId;
      String originalCourseId;
      List<dynamic> linkedCoursesList = [];

      if (linkedFrom != null) {
        originalId = linkedFrom['originalId'] as String? ?? '';
        originalCourseId = linkedFrom['courseId'] as String? ?? '';

        final originalSnap = await _db
            .collection('courses')
            .doc(originalCourseId)
            .collection('lessons')
            .doc(originalId)
            .get();

        if (originalSnap.exists) {
          linkedCoursesList = originalSnap.data()?['linkedCourses'] as List<dynamic>? ?? [];
        }
      } else {
        originalId = lectureId;
        originalCourseId = courseId;
        linkedCoursesList = data['linkedCourses'] as List<dynamic>? ?? [];
      }

      // Delete from all target courses
      for (final targetId in linkedCoursesList) {
        if (targetId is String && targetId.isNotEmpty) {
          await _db
              .collection('courses')
              .doc(targetId)
              .collection('lessons')
              .doc(originalId)
              .delete();
        }
      }

      // Delete the original lecture
      if (originalCourseId.isNotEmpty) {
        await _db
            .collection('courses')
            .doc(originalCourseId)
            .collection('lessons')
            .doc(originalId)
            .delete();
      }
    } else {
      // DELETE ONLY THIS INSTANCE
      // If it's a linked copy, remove this course from the original lecture's linkedCourses list
      if (linkedFrom != null) {
        final originalId = linkedFrom['originalId'] as String? ?? '';
        final originalCourseId = linkedFrom['courseId'] as String? ?? '';

        if (originalCourseId.isNotEmpty && originalId.isNotEmpty) {
          await _db
              .collection('courses')
              .doc(originalCourseId)
              .collection('lessons')
              .doc(originalId)
              .update({
            'linkedCourses': FieldValue.arrayRemove([courseId])
          });
        }
      }
    }

    // Finally delete the current instance document
    await docRef.delete();

    await _logAudit('delete_lecture', 'lecture', lectureId, {
      'courseId': courseId,
      'deleteAllLinked': deleteAllLinked,
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
  ) async {
    final callable = _functions.httpsCallable('enrollStudent');
    await callable.call({
      'userId': userId,
      'courseId': courseId,
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
        } else if (item.courseId.isNotEmpty) {
          final enrollmentId = item.courseId;
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
  ) async {
    final enrollmentId = courseId;

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
          'enrolledAt': FieldValue.serverTimestamp(),
          'status': 'active',
          'enrolledBy': 'admin_manual',
        }, SetOptions(merge: true));

    // Create a purchase record for tracking
    await _db.collection('purchases').add({
      'userId': userId,
      'courseId': courseId,
      'amount': 0.0,
      'status': 'manual_enrollment',
      'paymentMethod': 'admin_manual',
      'createdAt': FieldValue.serverTimestamp(),
      'enrolledByAdmin': currentUser?.uid,
      'items': [
        {'courseId': courseId, 'type': 'course_enrollment'},
      ],
    });

    await _logAudit('manual_enroll_user', 'user', userId, {
      'courseId': courseId,
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

  // Course Resources: Notes
  Stream<List<AdminNote>> getCourseNotes(String courseId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => AdminNote.fromMap(d.data(), d.id)).toList(),
        );
  }

  Future<void> saveCourseNote(
    String courseId,
    AdminNote note, {
    bool isNew = false,
  }) async {
    final data = note.toMap();
    if (isNew) {
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('notes')
          .add(data);
    } else {
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('notes')
          .doc(note.id)
          .update(data);
    }
  }

  Future<void> deleteCourseNote(
    String courseId,
    String noteId,
  ) async {
    await _db
        .collection('courses')
        .doc(courseId)
        .collection('notes')
        .doc(noteId)
        .delete();
  }

  // Course Resources: DPPs (Daily Practice Problems)
  Stream<List<AdminDpp>> getCourseDpps(String courseId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('dpps')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => AdminDpp.fromMap(d.data(), d.id)).toList(),
        );
  }

  Future<void> saveCourseDpp(
    String courseId,
    AdminDpp dpp, {
    bool isNew = false,
  }) async {
    final data = dpp.toMap();
    final ref = _db
        .collection('courses')
        .doc(courseId)
        .collection('dpps');
    if (isNew) {
      await ref.add(data);
    } else {
      await ref.doc(dpp.id).update(data);
    }
  }

  Future<void> deleteCourseDpp(
    String courseId,
    String dppId,
  ) async {
    await _db
        .collection('courses')
        .doc(courseId)
        .collection('dpps')
        .doc(dppId)
        .delete();
  }

  // Course Resources: Planner
  Stream<List<AdminPlannerItem>> getCoursePlanner(String courseId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('planner')
        .orderBy('date')
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => AdminPlannerItem.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  Future<void> saveCoursePlannerItem(
    String courseId,
    AdminPlannerItem item, {
    bool isNew = false,
  }) async {
    final data = item.toMap();
    if (isNew) {
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('planner')
          .add(data);
    } else {
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('planner')
          .doc(item.id)
          .update(data);
    }
  }

  Future<void> deleteCoursePlannerItem(
    String courseId,
    String itemId,
  ) async {
    await _db
        .collection('courses')
        .doc(courseId)
        .collection('planner')
        .doc(itemId)
        .delete();
  }

  // Course Resources: Quizzes
  Stream<List<AdminQuiz>> getCourseQuizzes(String courseId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('quizzes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => AdminQuiz.fromMap(d.data(), d.id)).toList(),
        );
  }

  Future<void> saveCourseQuiz(
    String courseId,
    AdminQuiz quiz, {
    bool isNew = false,
  }) async {
    final data = quiz.toMap();
    final ref = _db
        .collection('courses')
        .doc(courseId)
        .collection('quizzes')
        .doc(quiz.id);
    if (isNew) {
      await ref.set(data);
    } else {
      await ref.update(data);
    }
  }

  Future<void> deleteCourseQuiz(
    String courseId,
    String quizId,
  ) async {
    await _db
        .collection('courses')
        .doc(courseId)
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
      // Delete from all target courses
      for (final tCourseId in liveClass.linkedCourses) {
        if (tCourseId.isNotEmpty) {
          final querySnap = await _db
              .collection('courses')
              .doc(tCourseId)
              .collection('live_classes')
              .where('linkedFrom.originalId', isEqualTo: liveClassId)
              .get();
          for (final doc in querySnap.docs) {
            await doc.reference.delete();
          }
        }
      }
    }

    // Finally delete the current free class
    await docRef.delete();

    await _logAudit('delete_live_class', 'free_live_classes', liveClassId, {
      'deleteAllLinked': deleteAllLinked,
    });
  }

  // Course Live Classes (Scoped)
  Stream<List<AdminLiveClass>> getCourseLiveClasses(String courseId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('live_classes')
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AdminLiveClass.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> saveCourseLiveClass(
    String courseId,
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
        final lecture = AdminLecture(
          id: Uuid().v4(), // Generate new ID for lecture
          title: liveClass.title,
          description: liveClass.description,
          orderIndex: nextOrderIndex,
          type: 'video',
          storagePath: liveClass.youtubeUrl, // Mapping youtube link to storagePath/videoUrl
          isLocked: false,
          subject: liveClass.subject,
          chapter: liveClass.chapter,
          lectureNo: liveClass.lectureNo,
        );

        // 3. Add to lessons
        await _db
            .collection('courses')
            .doc(courseId)
            .collection('lessons')
            .add(lecture.toMap());

        // 4. Delete from live classes (if it existed previously)
        if (!isNew) {
          await _db
              .collection('courses')
              .doc(courseId)
              .collection('live_classes')
              .doc(liveClass.id)
              .delete();
        }

        // Log migration
        await _logAudit('migrate_live_to_lecture', 'lecture', lecture.id, {
          'from_live_class': liveClass.id,
          'courseId': courseId,
        });

        return; // Exit function as we've moved it
      } catch (e) {
        print('Error migrating live class to lecture: $e');
        rethrow;
      }
    }

    if (isNew) {
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('live_classes')
          .add(data);

      // Send notification to enrolled users
      await _notificationRepo.createCourseNotification(
        title: '📺 New Live Class Scheduled',
        body: liveClass.title,
        targetType: NotificationTargetType.liveClass,
        targetId: liveClass.id,
        courseId: courseId,
      );
    } else {
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('live_classes')
          .doc(liveClass.id)
          .update(data);
    }
    await _logAudit(
      isNew ? 'create_course_live_class' : 'update_course_live_class',
      'live_class',
      liveClass.id,
      {'courseId': courseId, ...data},
    );
  }

  Future<void> deleteCourseLiveClass(
    String courseId,
    String liveClassId, {
    bool deleteAllLinked = false,
  }) async {
    final docRef = _db
        .collection('courses')
        .doc(courseId)
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
      bool isFreeOriginal = false;
      List<String> linkedCoursesList = [];

      if (linkedFrom != null) {
        originalId = linkedFrom['originalId'] as String? ?? '';
        originalCourseId = linkedFrom['courseId'] as String? ?? '';
        isFreeOriginal = linkedFrom['source'] == 'free_live_classes';

        // Fetch original to get all linked courses
        DocumentSnapshot<Map<String, dynamic>> originalSnap;
        if (isFreeOriginal) {
          originalSnap = await _db.collection('free_live_classes').doc(originalId).get();
        } else {
          originalSnap = await _db
              .collection('courses')
              .doc(originalCourseId)
              .collection('live_classes')
              .doc(originalId)
              .get();
        }

        if (originalSnap.exists) {
          final originalClass = AdminLiveClass.fromMap(originalSnap.data()!, originalSnap.id);
          linkedCoursesList = originalClass.linkedCourses;
        }
      } else {
        originalId = liveClass.id;
        originalCourseId = courseId;
        isFreeOriginal = false;
        linkedCoursesList = liveClass.linkedCourses;
      }

      // Delete from all target courses
      for (final tCourseId in linkedCoursesList) {
        if (tCourseId.isNotEmpty) {
          final querySnap = await _db
              .collection('courses')
              .doc(tCourseId)
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
      } else if (originalCourseId.isNotEmpty) {
        await _db
            .collection('courses')
            .doc(originalCourseId)
            .collection('live_classes')
            .doc(originalId)
            .delete();
      }
    } else {
      // DELETE ONLY THIS INSTANCE
      // If it's a linked copy, remove this course from the original class's linkedCourses list
      if (linkedFrom != null) {
        final originalId = linkedFrom['originalId'] as String? ?? '';
        final originalCourseId = linkedFrom['courseId'] as String? ?? '';
        final isFreeOriginal = linkedFrom['source'] == 'free_live_classes';

        if (isFreeOriginal) {
          await _db.collection('free_live_classes').doc(originalId).update({
            'linkedCourses': FieldValue.arrayRemove([courseId])
          });
        } else if (originalCourseId.isNotEmpty) {
          await _db
              .collection('courses')
              .doc(originalCourseId)
              .collection('live_classes')
              .doc(originalId)
              .update({
            'linkedCourses': FieldValue.arrayRemove([courseId])
          });
        }
      }
    }

    // Finally delete the current instance document
    await docRef.delete();

    await _logAudit('delete_course_live_class', 'live_class', liveClassId, {
      'courseId': courseId,
      'deleteAllLinked': deleteAllLinked,
    });
  }

  // ============ LIVE CLASS LINKING ============

  /// Links an existing live class to a target course by copying its data.
  /// Also updates the source class's linkedCourses array.
  Future<void> linkLiveClassToCourse({
    required AdminLiveClass sourceClass,
    required String sourceCourseId,
    required String targetCourseId,
  }) async {
    // Fail-fast validation
    if (sourceCourseId.isEmpty || sourceClass.id.isEmpty) {
      throw ArgumentError('Source course and class IDs must not be empty');
    }
    if (targetCourseId.isEmpty) {
      throw ArgumentError('Target course ID must not be empty');
    }

    final data = sourceClass.toMap();
    // Remove linkedCourses from the copy — each copy is standalone
    data.remove('linkedCourses');
    // Mark it as a linked copy so we know it was imported
    data['linkedFrom'] = {
      'courseId': sourceCourseId,
      'originalId': sourceClass.id,
    };

    final batch = _db.batch();

    // 1. Write the class to the target course
    final newClassRef = _db
        .collection('courses')
        .doc(targetCourseId)
        .collection('live_classes')
        .doc();
    batch.set(newClassRef, data);

    // 2. Update the source class's linkedCourses array unconditionally (avoiding orphaned links)
    final sourceDocRef = _db
        .collection('courses')
        .doc(sourceCourseId)
        .collection('live_classes')
        .doc(sourceClass.id);
    batch.update(sourceDocRef, {
      'linkedCourses': FieldValue.arrayUnion([targetCourseId]),
    });

    await batch.commit();

    // 3. Send notification to enrolled users of target course
    try {
      await _notificationRepo.createCourseNotification(
        title: '📺 New Live Class Linked',
        body: sourceClass.title,
        targetType: NotificationTargetType.liveClass,
        targetId: sourceClass.id,
        courseId: targetCourseId,
      );
    } catch (e) {
      debugPrint('Non-critical: Failed to send link notification: $e');
    }

    // 4. Log audit for link (wrapped in try/catch to be resilient)
    try {
      await _logAudit('link_live_class', 'live_class', sourceClass.id, {
        'sourceCourse': sourceCourseId,
        'targetCourse': targetCourseId,
      });
    } catch (e) {
      debugPrint('Non-critical: Failed to log audit for link: $e');
    }
  }

  /// Links a free (global) live class to a target course by copying its data.
  Future<void> linkFreeLiveClassToCourse({
    required AdminLiveClass sourceClass,
    required String targetCourseId,
  }) async {
    final data = sourceClass.toMap();
    data.remove('linkedCourses');
    data['linkedFrom'] = {
      'courseId': '',
      'originalId': sourceClass.id,
      'source': 'free_live_classes',
    };

    final batch = _db.batch();

    // 1. Write the class to the target course
    final newClassRef = _db
        .collection('courses')
        .doc(targetCourseId)
        .collection('live_classes')
        .doc();
    batch.set(newClassRef, data);

    // 2. Update the source free class's linkedCourses
    final sourceFreeRef = _db.collection('free_live_classes').doc(sourceClass.id);
    batch.update(sourceFreeRef, {
      'linkedCourses': FieldValue.arrayUnion([targetCourseId]),
    });

    await batch.commit();

    await _logAudit('link_free_live_class', 'live_class', sourceClass.id, {
      'targetCourse': targetCourseId,
    });
  }

  /// Gets all live classes from ALL courses.
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
        'courseName': 'Free Classes',
      });
    }

    // 2. Fetch all courses to cache their names
    final coursesSnap = await _db.collection('courses').get();
    final courseCache = {
      for (final doc in coursesSnap.docs) doc.reference.path: doc.data()['title'] ?? doc.id
    };

    // 3. Fetch all course-scoped live classes in a single query
    final allClassesSnap = await _db
        .collectionGroup('live_classes')
        .orderBy('startTime')
        .get();

    for (final doc in allClassesSnap.docs) {
      final courseRef = doc.reference.parent.parent;
      if (courseRef == null) continue;

      final courseName = courseCache[courseRef.path] ?? courseRef.id;

      result.add({
        'class': AdminLiveClass.fromMap(doc.data(), doc.id),
        'courseId': courseRef.id,
        'courseName': courseName,
      });
    }

    return result;
  }

  /// Links an existing lecture to a target course by copying its data.
  /// Also updates the source lecture's linkedCourses array.
  Future<void> linkLectureToCourse({
    required AdminLecture sourceLecture,
    required String sourceCourseId,
    required String targetCourseId,
  }) async {
    // Fail-fast validation
    if (sourceCourseId.isEmpty || sourceLecture.id.isEmpty) {
      throw ArgumentError('Source course and lecture IDs must not be empty');
    }
    if (targetCourseId.isEmpty) {
      throw ArgumentError('Target course ID must not be empty');
    }

    final data = sourceLecture.toMap();
    // Remove linkedCourses from the copy — each copy is standalone
    data.remove('linkedCourses');
    // Mark it as a linked copy so we know it was imported
    data['linkedFrom'] = {
      'courseId': sourceCourseId,
      'originalId': sourceLecture.id,
    };

    final batch = _db.batch();

    // 1. Write the lecture to the target course's lessons
    final newLectureRef = _db
        .collection('courses')
        .doc(targetCourseId)
        .collection('lessons')
        .doc();
    batch.set(newLectureRef, data);

    // 2. Update the source lecture's linkedCourses array
    final sourceRef = _db
        .collection('courses')
        .doc(sourceCourseId)
        .collection('lessons')
        .doc(sourceLecture.id);
    batch.update(sourceRef, {
      'linkedCourses': FieldValue.arrayUnion([targetCourseId]),
    });

    await batch.commit();

    // 3. Send notification to enrolled users of target course (wrapped in try/catch to be resilient)
    try {
      await _notificationRepo.createCourseNotification(
        title: '📚 New Lecture Linked',
        body: sourceLecture.title,
        targetType: NotificationTargetType.lecture,
        targetId: sourceLecture.id,
        courseId: targetCourseId,
      );
    } catch (e) {
      debugPrint('Non-critical: Failed to send link notification: $e');
    }

    // 4. Log audit for link (wrapped in try/catch to be resilient)
    try {
      await _logAudit('link_lecture', 'lecture', sourceLecture.id, {
        'sourceCourse': sourceCourseId,
        'targetCourse': targetCourseId,
      });
    } catch (e) {
      debugPrint('Non-critical: Failed to log audit for link: $e');
    }
  }

  /// Legacy wrapper for linkLectureToBatch
  Future<void> linkLectureToBatch({
    required AdminLecture sourceLecture,
    required String sourceCourseId,
    required String sourceBatchId,
    required String targetCourseId,
    required String targetBatchId,
  }) async {
    return linkLectureToCourse(
      sourceLecture: sourceLecture,
      sourceCourseId: sourceCourseId,
      targetCourseId: targetCourseId,
    );
  }

  /// Gets all lectures from ALL batches across all courses.
  /// Used in the "Link Existing Lecture" dialog.
  Future<List<Map<String, dynamic>>> getAllLecturesForLinking() async {
    final result = <Map<String, dynamic>>[];

    // 1. Fetch all courses and batches to cache their names (exactly 2 queries)
    final coursesSnap = await _db.collection('courses').get();
    final courseCache = {
      for (final doc in coursesSnap.docs) doc.reference.path: doc.data()['title'] ?? doc.id
    };

    final batchesSnap = await _db.collectionGroup('batches').get();
    final batchCache = {
      for (final doc in batchesSnap.docs) doc.reference.path: doc.data()['name'] ?? doc.id
    };

    // 2. Fetch all batch-scoped lessons in a single query
    final allLecturesSnap = await _db
        .collectionGroup('lessons')
        .get();

    final lecturesList = allLecturesSnap.docs.map((doc) {
      final batchRef = doc.reference.parent.parent;
      final courseRef = batchRef?.parent.parent;

      final courseName = courseRef != null ? (courseCache[courseRef.path] ?? courseRef.id) : '';
      final batchName = batchRef != null ? (batchCache[batchRef.path] ?? batchRef.id) : '';

      return {
        'doc': doc,
        'lecture': AdminLecture.fromMap(doc.data(), doc.id),
        'courseId': courseRef?.id ?? '',
        'batchId': batchRef?.id ?? '',
        'courseName': courseName,
        'batchName': batchName,
      };
    }).toList();

    // 3. Sort lessons in-memory by orderIndex to keep them aligned
    lecturesList.sort((a, b) {
      final aIdx = (a['doc'] as QueryDocumentSnapshot).data() as Map<String, dynamic>;
      final bIdx = (b['doc'] as QueryDocumentSnapshot).data() as Map<String, dynamic>;
      final aOrder = aIdx['orderIndex'] as num? ?? 0;
      final bOrder = bIdx['orderIndex'] as num? ?? 0;
      return aOrder.compareTo(bOrder);
    });

    for (final item in lecturesList) {
      result.add({
        'lecture': item['lecture'],
        'courseId': item['courseId'],
        'batchId': item['batchId'],
        'courseName': item['courseName'],
        'batchName': item['batchName'],
      });
    }

    return result;
  }

  /// Gets all courses with their batches (for the link target picker).
  Future<List<Map<String, dynamic>>> getCoursesWithBatches() async {
    final result = <Map<String, dynamic>>[];
    final coursesSnap = await _db.collection('courses').get();
    for (final courseDoc in coursesSnap.docs) {
      final courseName = courseDoc.data()['title'] ?? courseDoc.id;
      final batches = [
        {
          'id': '',
          'name': 'Course Content',
        }
      ];
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

  // ============ COURSE ENROLLMENT QUERIES ============

  /// Get all users enrolled in a specific course.
  Future<List<AdminUser>> getEnrolledUsersForCourse(
    String courseId,
  ) async {
    final snapshot = await _db
        .collection('users')
        .where('enrolledCourses', arrayContains: courseId)
        .get();

    return snapshot.docs
        .map((doc) => AdminUser.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Get all users enrolled in a specific batch (legacy).
  Future<List<AdminUser>> getEnrolledUsersForBatch(
    String courseId,
    String batchId,
  ) async {
    return getEnrolledUsersForCourse('${courseId}_$batchId');
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
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      final docRef = await _db.collection('combination_packs').add(data);
      await _logAudit('create_combination_pack', 'combination_pack', docRef.id, data);
    } else {
      data.remove('createdAt'); // Prevent creation time overwrite
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _db.collection('combination_packs').doc(pack.id).set(data, SetOptions(merge: true));
      await _logAudit('update_combination_pack', 'combination_pack', pack.id, data);
    }
  }

  Future<void> deleteCombinationPack(String id) async {
    await _db.collection('combination_packs').doc(id).delete();
    await _logAudit('delete_combination_pack', 'combination_pack', id, {});
  }

  // ============ E-BOOKS ============
  Stream<List<Ebook>> getAdminEbooks() {
    return _db
        .collection('ebooks')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Ebook.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> saveEbook(
    Ebook ebook, {
    bool isNew = false,
  }) async {
    final data = ebook.toMap();
    if (isNew) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      final docRef = await _db.collection('ebooks').add(data);
      await _logAudit('create_ebook', 'ebook', docRef.id, data);
    } else {
      data.remove('createdAt');
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _db.collection('ebooks').doc(ebook.id).set(data, SetOptions(merge: true));
      await _logAudit('update_ebook', 'ebook', ebook.id, data);
    }
  }

  Future<void> deleteEbook(String id) async {
    await _db.collection('ebooks').doc(id).delete();
    await _logAudit('delete_ebook', 'ebook', id, {});
  }

  @visibleForTesting
  Future<void> commitInChunks(List<void Function(WriteBatch)> operations) async {
    const chunkSize = 400; // Leave 100 operations headroom
    for (var i = 0; i < operations.length; i += chunkSize) {
      final batch = _db.batch();
      final end = (i + chunkSize).clamp(0, operations.length);
      for (var j = i; j < end; j++) {
        operations[j](batch);
      }
      await batch.commit();
    }
  }

  // ============ RECURSIVE FOLDER PREFIX RENAME ============
  Future<void> recursivelyRenameFolder({
    required String courseId,
    required String subject,
    required String oldFolderPath,
    required String newFolderPath,
  }) async {
    final String oldPrefix = oldFolderPath.endsWith('/') ? oldFolderPath : '$oldFolderPath/';
    final String newPrefix = newFolderPath.endsWith('/') ? newFolderPath : '$newFolderPath/';

    final List<void Function(WriteBatch)> operations = [];

    // 1. Rename folder and lessons
    final lessonsSnap = await _db
        .collection('courses')
        .doc(courseId)
        .collection('lessons')
        .where('subject', isEqualTo: subject)
        .get();

    for (final doc in lessonsSnap.docs) {
      final ch = doc.data()['chapter'] as String? ?? '';
      if (ch == oldFolderPath) {
        operations.add((batch) => batch.update(doc.reference, {'chapter': newFolderPath}));
      } else if (ch.startsWith(oldPrefix)) {
        final remaining = ch.substring(oldPrefix.length);
        operations.add((batch) => batch.update(doc.reference, {'chapter': '$newPrefix$remaining'}));
      }
    }

    // 2. Rename notes
    final notesSnap = await _db
        .collection('courses')
        .doc(courseId)
        .collection('notes')
        .where('subject', isEqualTo: subject)
        .get();

    for (final doc in notesSnap.docs) {
      final ch = doc.data()['chapter'] as String? ?? '';
      if (ch == oldFolderPath) {
        operations.add((batch) => batch.update(doc.reference, {'chapter': newFolderPath}));
      } else if (ch.startsWith(oldPrefix)) {
        final remaining = ch.substring(oldPrefix.length);
        operations.add((batch) => batch.update(doc.reference, {'chapter': '$newPrefix$remaining'}));
      }
    }

    // 3. Rename DPPs
    final dppsSnap = await _db
        .collection('courses')
        .doc(courseId)
        .collection('dpps')
        .where('subject', isEqualTo: subject)
        .get();

    for (final doc in dppsSnap.docs) {
      final ch = doc.data()['chapter'] as String? ?? '';
      if (ch == oldFolderPath) {
        operations.add((batch) => batch.update(doc.reference, {'chapter': newFolderPath}));
      } else if (ch.startsWith(oldPrefix)) {
        final remaining = ch.substring(oldPrefix.length);
        operations.add((batch) => batch.update(doc.reference, {'chapter': '$newPrefix$remaining'}));
      }
    }

    await commitInChunks(operations);

    await _logAudit('rename_folder', 'folder', oldFolderPath, {
      'courseId': courseId,
      'subject': subject,
      'oldFolderPath': oldFolderPath,
      'newFolderPath': newFolderPath,
    });
  }

  // ============ RECURSIVE FOLDER DELETE ============
  Future<void> recursivelyDeleteFolder({
    required String courseId,
    required String subject,
    required String folderPath,
  }) async {
    final String prefix = folderPath.endsWith('/') ? folderPath : '$folderPath/';
    final List<void Function(WriteBatch)> operations = [];

    // 1. Delete folder placeholders and lessons
    final lessonsSnap = await _db
        .collection('courses')
        .doc(courseId)
        .collection('lessons')
        .where('subject', isEqualTo: subject)
        .get();

    for (final doc in lessonsSnap.docs) {
      final ch = doc.data()['chapter'] as String? ?? '';
      if (ch == folderPath || ch.startsWith(prefix)) {
        operations.add((batch) => batch.delete(doc.reference));
      }
    }

    // 2. Delete notes
    final notesSnap = await _db
        .collection('courses')
        .doc(courseId)
        .collection('notes')
        .where('subject', isEqualTo: subject)
        .get();

    for (final doc in notesSnap.docs) {
      final ch = doc.data()['chapter'] as String? ?? '';
      if (ch == folderPath || ch.startsWith(prefix)) {
        operations.add((batch) => batch.delete(doc.reference));
      }
    }

    // 3. Delete DPPs
    final dppsSnap = await _db
        .collection('courses')
        .doc(courseId)
        .collection('dpps')
        .where('subject', isEqualTo: subject)
        .get();

    for (final doc in dppsSnap.docs) {
      final ch = doc.data()['chapter'] as String? ?? '';
      if (ch == folderPath || ch.startsWith(prefix)) {
        operations.add((batch) => batch.delete(doc.reference));
      }
    }

    await commitInChunks(operations);

    await _logAudit('delete_folder_recursive', 'folder', folderPath, {
      'courseId': courseId,
      'subject': subject,
      'folderPath': folderPath,
    });
  }
}
