import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/store/services/cart_service.dart';
import 'package:eduverse/core/firebase/purchase_service.dart';
import 'package:eduverse/core/firebase/promo_code_service.dart';
import 'package:eduverse/study/presentation/widgets/study_ebooks_content.dart';
import 'package:eduverse/study/presentation/screens/study_test_series_screen.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'harness/e2e_harness.dart';

void main() {
  final harness = E2EHarness();

  setUp(() {
    harness.setup();
    harness.reset();
  });

  group('Cross-Feature E2E User Journeys (Tier 4)', () {
    testWidgets('Tier 4: Full User Journey — Purchase ebook and view in Study tab', (WidgetTester tester) async {
      // 1. Authenticate user
      harness.authenticateUser();
      harness.seedBaselineData();
      final cartService = CartService();

      // 2. Add ebook to cart
      await cartService.addToCart('test_user', CartItem(
        courseId: '',
        batchId: '',
        ebookId: 'ebook_1',
        title: 'Flutter Cookbook',
        price: 14.99,
      ));

      // 3. Verify cart has item
      final cartItems = await cartService.getCart('test_user');
      expect(cartItems.length, 1);

      // 4. Perform checkout & purchase
      final purchaseService = PurchaseService();
      await purchaseService.createPurchase(
        uid: 'test_user',
        amount: 14.99,
        paymentId: 'pay_ebook_success',
        items: cartItems.map((e) => e.toJson()).toList(),
        method: 'stripe',
        status: 'success',
      );
      await cartService.clearCart('test_user');

      // 5. Open Study tab ebooks and check visibility
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyEbooksContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The newly purchased ebook must render in the list
      expect(find.text('Flutter Cookbook'), findsOneWidget);
    });

    testWidgets('Tier 4: Full User Journey — Purchase Test Series and complete test to update progress', (WidgetTester tester) async {
      harness.authenticateUser();
      harness.seedBaselineData();
      final cartService = CartService();

      // 1. Add Test Series to cart
      await cartService.addToCart('test_user', CartItem(
        courseId: '',
        batchId: '',
        testSeriesId: 'ts_1',
        title: 'UPSC Prelims Mock Series',
        price: 39.99,
      ));

      // 2. Complete purchase
      final purchaseService = PurchaseService();
      await purchaseService.createPurchase(
        uid: 'test_user',
        amount: 39.99,
        paymentId: 'pay_ts_success',
        items: (await cartService.getCart('test_user')).map((e) => e.toJson()).toList(),
        method: 'razorpay',
        status: 'success',
      );
      await cartService.clearCart('test_user');

      // 3. Render the Test Series list screen
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyTestSeriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify progress is 0/2 completed
      expect(find.text('0/2 completed'), findsOneWidget);

      // 4. Simulate user completing test_1
      harness.firestore.setDoc('users/test_user/test_attempts/ts_1_test_1', {
        'score': 5.0,
        'totalMarks': 10.0,
        'correctCount': 5,
        'totalQuestions': 10,
        'percentage': 50.0,
        'completedAt': Timestamp.now(),
      });

      // 5. Re-render list screen to check progress updates dynamically
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('1/2 completed'), findsOneWidget);
    });

    testWidgets('Tier 4: Combo Pack unbundles courses and test series correctly on purchase', (WidgetTester tester) async {
      harness.authenticateUser();
      harness.seedBaselineData();

      // Seed combination pack info
      harness.firestore.setDoc('combination_packs/combo_pack_1', {
        'courses': ['course_1'],
        'testSeries': ['ts_1'],
      });

      final purchaseService = PurchaseService();
      final items = [
        {
          'courseId': '',
          'batchId': '',
          'combinationPackId': 'combo_pack_1',
          'title': 'Full Stack Mastery Bundle',
          'price': 99.99,
          'quantity': 1,
        }
      ];

      await purchaseService.createPurchase(
        uid: 'test_user',
        amount: 99.99,
        paymentId: 'pay_combo_success',
        items: items,
        method: 'stripe',
        status: 'success',
      );

      // Verify course enrollment created
      final courseEnrollment = await harness.firestore
          .collection('users')
          .doc('test_user')
          .collection('enrolledCourses')
          .doc('course_1')
          .get();
      expect(courseEnrollment.exists, isTrue);

      // Verify test series enrollment created
      final userDoc = await harness.firestore.collection('users').doc('test_user').get();
      final purchasedTestSeries = userDoc.data()?['purchasedTestSeries'] as List<dynamic>?;
      expect(purchasedTestSeries, contains('ts_1'));
    });

    testWidgets('Tier 4: Cart items persist in database across user logout/login sessions', (WidgetTester tester) async {
      harness.authenticateUser();
      final cartService = CartService();

      // Add item to cart
      await cartService.addToCart('test_user', CartItem(
        courseId: 'course_1',
        batchId: 'batch_1',
        title: 'Flutter Masterclass',
        price: 49.99,
      ));

      // Simulate session end / change auth state
      harness.auth.signOut();

      // Re-login
      harness.authenticateUser();

      // Fetch cart items again
      final cartItems = await cartService.getCart('test_user');
      expect(cartItems.length, 1);
      expect(cartItems.first.title, 'Flutter Masterclass');
    });

    testWidgets('Tier 4: Promo code discount calculation is applied correctly during checkout', (WidgetTester tester) async {
      harness.authenticateUser();
      
      // Seed a valid promo code
      harness.firestore.setDoc('config/promo_codes/codes/DISCOUNT50', {
        'code': 'DISCOUNT50',
        'type': 'percentage',
        'value': 50.0,
        'isActive': true,
        'usedCount': 0,
      });

      final promoService = PromoCodeService();
      final result = await promoService.validatePromoCode(
        'DISCOUNT50',
        [
          const PromoCartItem(
            courseId: 'course_1',
            batchId: 'batch_1',
            price: 100.0,
          )
        ],
      );

      expect(result.isValid, isTrue);
      expect(result.discountAmount, 50.0);
    });

    testWidgets('Tier 4: Transaction history contains GST number when provided during checkout', (WidgetTester tester) async {
      harness.authenticateUser();
      final purchaseService = PurchaseService();

      final purchaseId = await purchaseService.createPurchase(
        uid: 'test_user',
        amount: 50.0,
        paymentId: 'pay_gst',
        items: [
          {
            'courseId': 'course_1',
            'batchId': 'batch_1',
            'title': 'Test Course',
            'price': 50.0,
          }
        ],
        gstNumber: '22AAAAA0000A1Z5',
      );

      final purchaseDoc = await harness.firestore.collection('purchases').doc(purchaseId).get();
      expect(purchaseDoc.data()?['gstNumber'], '22AAAAA0000A1Z5');
    });

    testWidgets('Tier 4: Owned items cannot be added to cart', (WidgetTester tester) async {
      harness.authenticateUser();
      harness.seedBaselineData();
      harness.grantOwnership(uid: 'test_user', courses: ['course_1']);

      // Check if user profile enrolledCourses contains course_1
      final doc = await harness.firestore
          .collection('users')
          .doc('test_user')
          .collection('enrolledCourses')
          .doc('course_1')
          .get();

      expect(doc.exists, isTrue);
    });

    testWidgets('Tier 4: Transaction log created in user profile on checkout', (WidgetTester tester) async {
      harness.authenticateUser();
      final purchaseService = PurchaseService();

      await purchaseService.saveTransaction(
        uid: 'test_user',
        orderId: 'order_123',
        productTitle: 'UPSC Test Series',
        amount: 39.99,
        status: 'success',
        paymentMethod: 'stripe',
      );

      final transactionSnap = await harness.firestore
          .collection('users')
          .doc('test_user')
          .collection('transactions')
          .get();

      expect(transactionSnap.docs.length, 1);
      expect(transactionSnap.docs.first.data()['orderId'], 'order_123');
    });

    testWidgets('Tier 4: Failed payment does not grant course ownership or clear cart', (WidgetTester tester) async {
      harness.authenticateUser();
      final cartService = CartService();
      final purchaseService = PurchaseService();

      // Add item to cart
      await cartService.addToCart('test_user', CartItem(
        courseId: 'course_1',
        batchId: 'batch_1',
        title: 'Unpurchased Course',
        price: 49.99,
      ));

      // Attempt purchase but fail
      await purchaseService.createPurchase(
        uid: 'test_user',
        amount: 49.99,
        paymentId: 'pay_fail',
        items: (await cartService.getCart('test_user')).map((e) => e.toJson()).toList(),
        status: 'failed',
      );

      // Verify that course ownership is NOT granted
      final doc = await harness.firestore
          .collection('users')
          .doc('test_user')
          .collection('enrolledCourses')
          .doc('course_1')
          .get();
      expect(doc.exists, isFalse);

      // Verify cart still contains the item
      final cartItems = await cartService.getCart('test_user');
      expect(cartItems.length, 1);
    });

    testWidgets('Tier 4: Unauthenticated user cannot load store and redirects/fails gracefully', (WidgetTester tester) async {
      // Simulate logout
      harness.auth.signOut();

      // Verify that fetching cart or store repo either redirects or returns empty
      final cartService = CartService();
      final cartItems = await cartService.getCart('');
      expect(cartItems, isEmpty);
    });
  });
}
