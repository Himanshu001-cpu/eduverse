import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/admin/screens/purchases_screen.dart';
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
        child: const PurchasesScreen(),
      ),
    );
  }

  group('PurchasesScreen Pagination Widget Tests', () {
    testWidgets('renders transactions with cached user name and displays metrics', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      fakeFirestore.setDoc('users/cust_1', {
        'name': 'Ada Lovelace',
        'email': 'ada@eduverse.com',
        'role': 'student',
        'disabled': false,
      });

      fakeFirestore.setDoc('purchases/p_1', {
        'userId': 'cust_1',
        'amount': 799.0,
        'status': 'success',
        'createdAt': Timestamp.fromDate(DateTime(2026, 3, 10, 10, 30)),
        'paymentMethod': 'upi',
        'items': [
          {
            'courseId': 'c_1',
            'batchId': 'b_1',
            'title': 'Advanced Algorithms',
            'price': 799.0,
            'quantity': 1,
          }
        ],
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify customer resolved from in-memory cache
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('ada@eduverse.com'), findsOneWidget);
      expect(find.text('Advanced Algorithms'), findsOneWidget);

      // Verify metrics dashboard
      expect(find.text('Total Revenue'), findsOneWidget);
      expect(find.text('Successful Payments'), findsOneWidget);
      expect(find.text('Total Transactions'), findsOneWidget);
    });

    testWidgets('date preset filter filters transactions by date bounds', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      fakeFirestore.setDoc('users/cust_1', {
        'name': 'Ada Lovelace',
        'email': 'ada@eduverse.com',
        'role': 'student',
        'disabled': false,
      });
      fakeFirestore.setDoc('users/cust_2', {
        'name': 'Alan Turing',
        'email': 'alan@eduverse.com',
        'role': 'student',
        'disabled': false,
      });

      final now = DateTime.now();
      fakeFirestore.setDoc('purchases/p_recent', {
        'userId': 'cust_1',
        'amount': 300.0,
        'status': 'success',
        'createdAt': Timestamp.fromDate(now),
        'paymentMethod': 'upi',
        'items': [
          {
            'courseId': 'c_1',
            'batchId': 'b_1',
            'title': 'Modern Flutter',
            'price': 300.0,
            'quantity': 1,
          }
        ],
      });
      fakeFirestore.setDoc('purchases/p_ancient', {
        'userId': 'cust_2',
        'amount': 500.0,
        'status': 'success',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 60))),
        'paymentMethod': 'card',
        'items': [
          {
            'courseId': 'c_2',
            'batchId': 'b_2',
            'title': 'Legacy Computing',
            'price': 500.0,
            'quantity': 1,
          }
        ],
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Initially All Time displays both
      expect(find.text('Modern Flutter'), findsOneWidget);
      expect(find.text('Legacy Computing'), findsOneWidget);

      // Select 'Last 30 Days' filter preset
      final last30DaysChip = find.widgetWithText(ChoiceChip, 'Last 30 Days');
      expect(last30DaysChip, findsOneWidget);
      await tester.tap(last30DaysChip);
      await tester.pumpAndSettle();

      // Only recent purchase within 30 days should remain
      expect(find.text('Modern Flutter'), findsOneWidget);
      expect(find.text('Legacy Computing'), findsNothing);
    });

    testWidgets('loads 20 transactions initially and appends next batch on Load More tap', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      fakeFirestore.setDoc('users/cust_bulk', {
        'name': 'Bulk Buyer',
        'email': 'buyer@eduverse.com',
        'role': 'student',
        'disabled': false,
      });

      final baseDate = DateTime(2026, 2, 1);
      for (int i = 0; i < 28; i++) {
        final pid = 'tx_${i.toString().padLeft(2, '0')}';
        fakeFirestore.setDoc('purchases/$pid', {
          'userId': 'cust_bulk',
          'amount': 100.0 + i,
          'status': 'success',
          'createdAt': Timestamp.fromDate(baseDate.add(Duration(hours: i))),
          'paymentMethod': 'upi',
          'items': [
            {
              'courseId': 'c_$i',
              'batchId': 'b_$i',
              'title': 'Course $i',
              'price': 100.0 + i,
              'quantity': 1,
            }
          ],
        });
      }

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // First batch of 20
      final initialTable = tester.widget<DataTable>(find.byType(DataTable));
      expect(initialTable.rows.length, 20);

      // Load More button should be present
      final loadMoreBtn = find.widgetWithText(OutlinedButton, 'Load More Transactions');
      expect(loadMoreBtn, findsOneWidget);

      // Tap Load More
      await tester.ensureVisible(loadMoreBtn);
      await tester.tap(loadMoreBtn);
      await tester.pumpAndSettle();

      // All 28 items loaded
      final fullTable = tester.widget<DataTable>(find.byType(DataTable));
      expect(fullTable.rows.length, 28);

      // Button gone after full load
      expect(find.widgetWithText(OutlinedButton, 'Load More Transactions'), findsNothing);
    });
  });
}
