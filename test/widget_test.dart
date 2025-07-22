// This is a basic Flutter widget test for RASEED app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:figma_flutter/main.dart';

void main() {
  testWidgets('Onboarding screen loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RaseedApp());

    // Verify that the onboarding screen loads with expected content
    expect(find.text('Snap, Scan, and Simplify.'), findsOneWidget);
    expect(
      find.text(
        'Instantly turn any receipt—paper, email, or photo—into smart, organized data.',
      ),
      findsOneWidget,
    );

    // Verify Skip button is present
    expect(find.text('Skip'), findsOneWidget);

    // Verify Next button is present
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('Page navigation works correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RaseedApp());

    // Verify we're on the first page
    expect(find.text('Snap, Scan, and Simplify.'), findsOneWidget);

    // Tap the Next button
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Verify we're now on the second page
    expect(find.text('Never Miss a Deadline.'), findsOneWidget);
    expect(
      find.text(
        'From product warranties to recurring subscriptions, get timely reminders before it\'s too late.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Skip button navigates to auth screen', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RaseedApp());

    // Tap the Skip button
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Verify we're now on the auth screen
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });

  testWidgets('Auth screen loads correctly', (WidgetTester tester) async {
    // Build our app and navigate to auth screen
    await tester.pumpWidget(const RaseedApp());
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Verify auth screen elements are present
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('Home screen loads after successful authentication', (
    WidgetTester tester,
  ) async {
    // Build our app and navigate to auth screen
    await tester.pumpWidget(const RaseedApp());
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Tap Google Sign In button
    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle(
      const Duration(seconds: 3),
    ); // Wait for auth simulation

    // Verify we're now on the home screen
    expect(find.text('Welcome back, Akash'), findsOneWidget);
    expect(find.text('Smart Insights'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
  });
}
