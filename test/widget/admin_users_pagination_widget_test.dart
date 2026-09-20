import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/admin/screens/users_screen.dart';
import 'package:eduverse/admin/services/firebase_admin_service.dart';
import 'package:eduverse/core/firebase/eduverse_firebase.dart';
import '../e2e/harness/fake_firebase_firestore.dart';
import '../e2e/harness/fake_firebase_auth.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FakeFirebaseAuth fakeAuth;
  late FirebaseAdminService adminService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fakeAuth = FakeFirebaseAuth();

    EduverseFirebase.mockFirestore = fakeFirestore;
    EduverseFirebase.mockAuth = fakeAuth;

    fakeAuth.changeCurrentUser(FakeUser(
      uid: 'admin_1',
      email: 'admin@eduverse.com',
      displayName: 'Admin User',
    ));
    fakeFirestore.setDoc('users/admin_1', {
      'name': 'Admin User',
      'email': 'admin@eduverse.com',
      'role': 'admin',
      'disabled': false,
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
    });

    adminService = FirebaseAdminService(
      auth: fakeAuth,
      db: fakeFirestore,
    );
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Provider<FirebaseAdminService>.value(
        value: adminService,
        child: const UsersScreen(),
      ),
    );
  }

  group('UsersScreen Pagination Widget Tests', () {
    testWidgets('loads 20 users initially and appends next batch on Load More tap', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Seed 35 student users
      for (int i = 0; i < 35; i++) {
        final uid = 'user_${i.toString().padLeft(2, '0')}';
        fakeFirestore.setDoc('users/$uid', {
          'name': 'Student $i',
          'email': 'student$i@eduverse.com',
          'role': 'student',
          'disabled': false,
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 2).add(Duration(hours: i))),
        });
      }

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify table rendered first 20 rows
      final dataTable = tester.widget<DataTable>(find.byType(DataTable));
      expect(dataTable.rows.length, 20);

      // Verify "Load More" button is displayed
      final loadMoreBtn = find.widgetWithText(OutlinedButton, 'Load More');
      expect(loadMoreBtn, findsOneWidget);

      // Scroll to Load More button and tap
      await tester.ensureVisible(loadMoreBtn);
      await tester.tap(loadMoreBtn);
      await tester.pumpAndSettle();

      // Total 35 students + 1 admin = 36 users rendered
      final updatedTable = tester.widget<DataTable>(find.byType(DataTable));
      expect(updatedTable.rows.length, 36);

      // Load More button should now be gone because hasMore is false
      expect(find.widgetWithText(OutlinedButton, 'Load More'), findsNothing);
    });

    testWidgets('role filter resets pagination and shows matching users', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Seed students and teachers
      for (int i = 0; i < 5; i++) {
        fakeFirestore.setDoc('users/student_$i', {
          'name': 'Student $i',
          'email': 'student$i@eduverse.com',
          'role': 'student',
          'disabled': false,
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 2).add(Duration(hours: i))),
        });
      }
      for (int i = 0; i < 3; i++) {
        fakeFirestore.setDoc('users/teacher_$i', {
          'name': 'Teacher $i',
          'email': 'teacher$i@eduverse.com',
          'role': 'teacher',
          'disabled': false,
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 3).add(Duration(hours: i))),
        });
      }

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Open Role Dropdown
      final roleDropdown = find.text('All Roles');
      expect(roleDropdown, findsOneWidget);
      await tester.tap(roleDropdown);
      await tester.pumpAndSettle();

      // Select 'Teachers'
      final teachersItem = find.text('Teachers').last;
      await tester.tap(teachersItem);
      await tester.pumpAndSettle();

      // Only the 3 teachers should be in table
      final teacherTable = tester.widget<DataTable>(find.byType(DataTable));
      expect(teacherTable.rows.length, 3);
      expect(find.text('teacher0@eduverse.com'), findsOneWidget);
      expect(find.text('teacher1@eduverse.com'), findsOneWidget);
      expect(find.text('teacher2@eduverse.com'), findsOneWidget);
    });

    testWidgets('debounced search queries users matching name or email', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      fakeFirestore.setDoc('users/target_user', {
        'name': 'Archimedes Math',
        'email': 'archimedes@eduverse.com',
        'role': 'student',
        'disabled': false,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 5)),
      });
      fakeFirestore.setDoc('users/other_user', {
        'name': 'Galileo Science',
        'email': 'galileo@eduverse.com',
        'role': 'student',
        'disabled': false,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 5)),
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter search text
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Archimedes');
      // Wait for 400ms debounce
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Archimedes Math'), findsOneWidget);
      expect(find.text('Galileo Science'), findsNothing);
    });
  });
}
