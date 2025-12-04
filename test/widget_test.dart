// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eduverse/main.dart';

void main() {
  testWidgets('App launch smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LearningApp());

    // Verify that the Feed page is shown (or at least the app builds).
    // Since we have a NavigationBar, we can look for icons.
    expect(find.byIcon(Icons.home_outlined), findsOneWidget); // Feed icon
    expect(find.byIcon(Icons.school_outlined), findsOneWidget); // Study icon
  });
}
