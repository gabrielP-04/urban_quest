import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urban_quest/screens/auth/login_screen.dart';

/// Widget tests for LoginScreen
/// 
/// These tests verify UI rendering, form validation behavior, and
/// basic user interactions without requiring Firebase backend.
/// 
/// Note: Tests that trigger actual Firebase calls (signIn) are excluded
/// as they require integration-level mocking. These tests focus on the
/// presentation layer: correct widgets render, validation logic works,
/// and navigation elements are present.
void main() {
  // Helper to wrap LoginScreen with MaterialApp
  Widget createLoginScreen() {
    return const MaterialApp(
      home: LoginScreen(),
    );
  }

  group('LoginScreen - Rendering', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      // Check for email field
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.text('Email'), findsWidgets);

      // Check for password field
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('Password'), findsWidgets);
    });

    testWidgets('renders Sign In button', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('renders Sign Up navigation link', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text("Don't have an account yet?"), findsOneWidget);
    });

    testWidgets('renders Forgot password link', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      expect(find.text('Forgot your password?'), findsOneWidget);
    });

    testWidgets('renders UrbanQuest title/branding', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      // The login screen should have branding
      expect(find.textContaining('Urban'), findsWidgets);
    });
  });

  group('LoginScreen - Password Visibility Toggle', () {
    testWidgets('password is obscured by default', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      // Find TextField widgets and check obscureText
      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      final passwordField = textFields.where((tf) => tf.obscureText).toList();
      expect(passwordField.length, 1); // exactly one obscured field
    });

    testWidgets('tapping eye icon toggles password visibility', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      // Initially password is obscured
      var textFields = tester.widgetList<TextField>(find.byType(TextField));
      expect(textFields.where((tf) => tf.obscureText).length, 1);

      // Find and tap the visibility toggle icon
      final visibilityIcon = find.byIcon(Icons.visibility_off);
      if (visibilityIcon.evaluate().isNotEmpty) {
        await tester.tap(visibilityIcon);
        await tester.pumpAndSettle();

        // After toggle, password should be visible
        textFields = tester.widgetList<TextField>(find.byType(TextField));
        final stillObscured = textFields.where((tf) => tf.obscureText).length;
        expect(stillObscured, 0); // no longer obscured
      }
    });
  });

  group('LoginScreen - Form Input', () {
    testWidgets('can enter email text', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('can enter password text', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextField).last;
      await tester.enterText(passwordField, 'mypassword123');
      await tester.pump();

      expect(find.text('mypassword123'), findsOneWidget);
    });
  });

  group('LoginScreen - Form Validation', () {
    testWidgets('shows error when email is empty on submit', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      // Tap Sign In without entering anything
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Enter your email'), findsOneWidget);
    });

    testWidgets('shows error for invalid email format', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      // Enter invalid email
      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'invalidemail');
      
      // Tap Sign In
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('shows error when password is empty on submit', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      // Enter valid email but no password
      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'test@example.com');

      // Tap Sign In
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your password'), findsWidgets);
    });
  });

  group('LoginScreen - Navigation', () {
    testWidgets('tapping Sign Up navigates to RegisterScreen', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // After navigation, RegisterScreen should be visible
      // It should have the "Full Name" field and "Create Account" or similar
      expect(find.text('Full Name'), findsWidgets);
    });

    testWidgets('tapping Forgot password shows snackbar', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot your password?'));
      await tester.pumpAndSettle();

      expect(find.text('Password reset coming soon!'), findsOneWidget);
    });
  });
}
