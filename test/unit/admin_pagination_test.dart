import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/admin/services/firebase_admin_service.dart';
import '../e2e/harness/fake_firebase_firestore.dart';
import '../e2e/harness/fake_firebase_auth.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FakeFirebaseAuth fakeAuth;
  late FirebaseAdminService adminService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fakeAuth = FakeFirebaseAuth();

    // Default admin user authenticated
    fakeAuth.changeCurrentUser(FakeUser(
      uid: 'admin_1',
      email: 'admin@eduverse.com',
      displayName: 'System Admin',
    ));
    fakeFirestore.setDoc('users/admin_1', {
      'name': 'System Admin',
      'email': 'admin@eduverse.com',
      'role': 'admin',
      'disabled': false,
    });

    adminService = FirebaseAdminService(
      auth: fakeAuth,
      db: fakeFirestore,
    );
  });

  group('FirebaseAdminService - Cursor Pagination Tests', () {
    test('getUsersPaginated returns 20 items per page with deterministic cursor progression', () async {
      // Seed 35 users with progressive createdAt
      for (int i = 0; i < 35; i++) {
        final uid = 'user_${i.toString().padLeft(2, '0')}';
        fakeFirestore.setDoc('users/$uid', {
          'name': 'Student $i',
          'email': 'student$i@eduverse.com',
          'role': 'student',
          'disabled': false,
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1).add(Duration(hours: i))),
        });
      }

      // Page 1
      final page1 = await adminService.getUsersPaginated(limit: 20);
      expect(page1.items.length, 20);
      expect(page1.hasMore, isTrue);
      expect(page1.lastDocument, isNotNull);

      // Page 2 using lastDocument cursor
      final page2 = await adminService.getUsersPaginated(
        limit: 20,
        startAfter: page1.lastDocument,
      );
      // 35 seeded students + 1 admin user in setUp = 36 total users (page 1: 20, page 2: 16)
      expect(page2.items.length, 16);
      expect(page2.hasMore, isFalse);

      // Verify zero overlap between page 1 and page 2
      final page1Ids = page1.items.map((u) => u.uid).toSet();
      final page2Ids = page2.items.map((u) => u.uid).toSet();
      expect(page1Ids.intersection(page2Ids), isEmpty);
    });

    test('getUsersPaginated filters correctly by role and disabled status', () async {
      for (int i = 0; i < 5; i++) {
        fakeFirestore.setDoc('users/student_$i', {
          'name': 'Student $i',
          'email': 's$i@eduverse.com',
          'role': 'student',
          'disabled': false,
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1).add(Duration(hours: i))),
        });
      }
      for (int i = 0; i < 3; i++) {
        fakeFirestore.setDoc('users/teacher_$i', {
          'name': 'Teacher $i',
          'email': 't$i@eduverse.com',
          'role': 'teacher',
          'disabled': false,
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 2).add(Duration(hours: i))),
        });
      }
      fakeFirestore.setDoc('users/disabled_student', {
        'name': 'Disabled User',
        'email': 'disabled@eduverse.com',
        'role': 'student',
        'disabled': true,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 3)),
      });

      // Filter by role
      final teachers = await adminService.getUsersPaginated(roleFilter: 'teacher');
      expect(teachers.items.length, 3);
      expect(teachers.items.every((u) => u.role == 'teacher'), isTrue);

      // Filter disabled only
      final disabled = await adminService.getUsersPaginated(showDisabledOnly: true);
      expect(disabled.items.length, 1);
      expect(disabled.items.first.email, 'disabled@eduverse.com');
    });

    test('getPurchasesPaginated filters by date bounds and status', () async {
      final date1 = DateTime(2026, 3, 1, 10, 0);
      final date2 = DateTime(2026, 3, 10, 14, 0);
      final date3 = DateTime(2026, 3, 20, 18, 0);

      fakeFirestore.setDoc('purchases/p_1', {
        'userId': 'user_a',
        'amount': 49.99,
        'status': 'completed',
        'createdAt': Timestamp.fromDate(date1),
        'items': [],
      });
      fakeFirestore.setDoc('purchases/p_2', {
        'userId': 'user_b',
        'amount': 99.99,
        'status': 'completed',
        'createdAt': Timestamp.fromDate(date2),
        'items': [],
      });
      fakeFirestore.setDoc('purchases/p_3', {
        'userId': 'user_c',
        'amount': 29.99,
        'status': 'refunded',
        'createdAt': Timestamp.fromDate(date3),
        'items': [],
      });

      // Query date range encompassing only date2
      final bounded = await adminService.getPurchasesPaginated(
        startDate: DateTime(2026, 3, 5),
        endDate: DateTime(2026, 3, 15),
      );
      expect(bounded.items.length, 1);
      expect(bounded.items.first.id, 'p_2');
      expect(bounded.items.first.amount, 99.99);

      // Query by status
      final refunded = await adminService.getPurchasesPaginated(
        statusFilter: 'refunded',
      );
      expect(refunded.items.length, 1);
      expect(refunded.items.first.id, 'p_3');
    });

    test('FakeQuery count() computes correct aggregate total', () async {
      for (int i = 0; i < 8; i++) {
        fakeFirestore.setDoc('test_count/item_$i', {'order': i});
      }
      final aggregate = await fakeFirestore.collection('test_count').count().get();
      expect(aggregate.count, 8);
    });
  });

  group('T-04-01: Admin Authorization Security Controls', () {
    test('Unauthenticated session throws permission-denied', () async {
      fakeAuth.changeCurrentUser(null);

      expect(
        () => adminService.getUsersPaginated(),
        throwsA(isA<FirebaseException>().having((e) => e.code, 'code', 'permission-denied')),
      );

      expect(
        () => adminService.getPurchasesPaginated(),
        throwsA(isA<FirebaseException>().having((e) => e.code, 'code', 'permission-denied')),
      );
    });

    test('Non-admin user (student role) throws permission-denied', () async {
      fakeAuth.changeCurrentUser(FakeUser(
        uid: 'student_attacker',
        email: 'student@eduverse.com',
      ));
      fakeFirestore.setDoc('users/student_attacker', {
        'name': 'Student Attacker',
        'email': 'student@eduverse.com',
        'role': 'student',
      });

      expect(
        () => adminService.getUsersPaginated(),
        throwsA(isA<FirebaseException>().having((e) => e.code, 'code', 'permission-denied')),
      );

      expect(
        () => adminService.getPurchasesPaginated(),
        throwsA(isA<FirebaseException>().having((e) => e.code, 'code', 'permission-denied')),
      );
    });
  });
}
