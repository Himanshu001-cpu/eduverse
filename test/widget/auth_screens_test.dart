import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eduverse/core/firebase/eduverse_firebase.dart';
import 'package:eduverse/auth/login_page.dart';
import 'package:eduverse/auth/phone_login_page.dart';
import 'package:eduverse/auth/register_page.dart';
import 'package:eduverse/auth/forgot_password_page.dart';
import 'package:eduverse/auth/privacy_policy_page.dart';
import 'package:eduverse/auth/phone_verify_dialog.dart';
import '../e2e/harness/fake_firebase_auth.dart';
import '../e2e/harness/fake_firebase_firestore.dart';

void main() {
  setUpAll(() {
    EduverseFirebase.mockAuth = FakeFirebaseAuth();
    EduverseFirebase.mockFirestore = FakeFirebaseFirestore();
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  testWidgets('LoginPage renders Academic Futurist header, fields, and buttons', (tester) async {
    await tester.pumpWidget(createTestWidget(const LoginPage()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('ASPIRANT PORTAL'), findsOneWidget);
    expect(find.text('Sign In to Portal'), findsOneWidget);
    expect(find.text('Email or Mobile Number'), findsOneWidget);
    expect(find.text('Master Password'), findsOneWidget);
    expect(find.text('Remember this Device'), findsOneWidget);
    expect(find.text('Login with OTP / Phone Number'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Register Now'), findsOneWidget);
  });

  testWidgets('PhoneLoginPage renders mobile number input, channel pills, and trust footer', (tester) async {
    await tester.pumpWidget(createTestWidget(const PhoneLoginPage()));
    await tester.pumpAndSettle();

    expect(find.text('Phone Login'), findsOneWidget);
    expect(find.text('MOBILE NUMBER'), findsOneWidget);
    expect(find.text('+91'), findsOneWidget);
    expect(find.text('Send via SMS'), findsOneWidget);
    expect(find.text('Send via WhatsApp'), findsOneWidget);
    expect(find.text('Request OTP Code'), findsOneWidget);
    expect(find.text('Login with Email & Password'), findsOneWidget);
    expect(find.textContaining('Secured by Eduverse Authentication Shield'), findsOneWidget);
  });

  testWidgets('RegisterPage renders branding, social proof, target exam dropdown, and terms', (tester) async {
    await tester.pumpWidget(createTestWidget(const RegisterPage()));
    await tester.pumpAndSettle();

    expect(find.text('ACADEMIC EXCELLENCE'), findsOneWidget);
    expect(find.text('The Eduverse'), findsOneWidget);
    expect(find.text('Begin Your Journey'), findsOneWidget);
    expect(find.text('18,450+ Active Aspirants'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Target Examination'), findsOneWidget);
    expect(find.text('Create Secure Password'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Sign Up with Google'), findsOneWidget);
    expect(find.text('Login here'), findsOneWidget);
  });

  testWidgets('ForgotPasswordPage renders emblem, segmented tabs, and advisory', (tester) async {
    await tester.pumpWidget(createTestWidget(const ForgotPasswordPage()));
    await tester.pumpAndSettle();

    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.text('Via Email'), findsOneWidget);
    expect(find.text('Via Mobile OTP'), findsOneWidget);
    expect(find.text('Institutional Email'), findsOneWidget);
    expect(find.text('Send Reset Link'), findsOneWidget);
    expect(find.text('Scholar Spam Advisory'), findsOneWidget);
    expect(find.text('256-Bit'), findsOneWidget);
    expect(find.text('Dean Desk 24/7'), findsOneWidget);
    expect(find.text('Back to Scholar Login'), findsOneWidget);

    // Switch to Mobile OTP tab
    await tester.tap(find.text('Via Mobile OTP'));
    await tester.pumpAndSettle();

    expect(find.text('Registered Mobile'), findsOneWidget);
    expect(find.text('Send Reset OTP'), findsOneWidget);
  });

  testWidgets('PrivacyPolicyPage renders protocol banner, navigation chips, and sections', (tester) async {
    await tester.pumpWidget(createTestWidget(const PrivacyPolicyPage()));
    await tester.pumpAndSettle();

    expect(find.text('THE EDUVERSE TRUST PROTOCOL'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsWidgets);
    expect(find.text('India DPDPA Compliant'), findsOneWidget);
    expect(find.text('1. Intro'), findsOneWidget);
    expect(find.text('2. Data Collected'), findsOneWidget);
    expect(find.text('Commitment to Privacy'), findsOneWidget);
    expect(find.text('Information We Collect'), findsOneWidget);
    expect(find.text('Knowledge Protected'), findsOneWidget);
  });

  testWidgets('PhoneVerifyDialog opens bottom sheet with 6 OTP boxes and verified pill', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  PhoneVerifyDialog.show(
                    context,
                    phoneNumber: '+919876543210',
                    title: 'Verify Mobile Number',
                  );
                },
                child: const Text('Open Sheet'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('eeScholar Auth'), findsOneWidget);
    expect(find.text('Verify Mobile Number'), findsOneWidget);
    expect(find.textContaining('+919876543210'), findsOneWidget);
    expect(find.text('VERIFY & CONTINUE'), findsOneWidget);
    expect(find.text('Wrong number? Edit'), findsOneWidget);
    expect(find.textContaining('End-to-End Encrypted Verification'), findsOneWidget);
  });
}
