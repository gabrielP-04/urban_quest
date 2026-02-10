import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urban_quest/screens/auth/register_screen.dart';

/// Widget tests for RegisterScreen
/// 
/// Focuses on UI rendering, form field presence, validation messages,
/// password confirmation logic, and navigation back to login.
void main() {
  Widget createRegisterScreen() {
    return const MaterialApp(
      home: RegisterScreen(),
    );
  }

  group('RegisterScreen - Rendering', () {
    testWidgets('renders all required form fields', (tester) async {
      await tester.pumpWidget(createRegisterScreen());
      await tester.pumpAndSettle();

      // Full Name field
      expect(find.text('Full Name'), findsWidgets);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);

      // Email field
      expect(find.text('Email'), findsWidgets);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);

      // Password fields (2 lock icons: password + confirm)
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(2));
      expect(find.text('Password'), findsWidgets);
      expect(find.text('Confirm Password'), findsWidgets);
    });

    testWidgets('renders Create Account button', (tester) async {
      await tester.pumpWidget(createRegisterScreen());
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('renders Sign In navigation link', (tester) async {
      await tester.pumpWidget(createRegisterScreen());
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Already have an account?'), findsOneWidget);
    });
  });

  group('RegisterScreen - Form Validation', () {
    testWidgets('shows error when name is empty', (tester) async {
      await tester.pumpWidget(createRegisterScreen());
      await tester.pumpAndSettle();

      // Tap Create Account without filling anything
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your name'), findsOneWidget);
    });

    testWidgets('shows error when email is empty', (tester) async {
      await tester.pumpWidget(createRegisterScreen());
      await tester.pumpAndSettle();

      // Fill name but not email
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'Test User');

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your email'), findsOneWidget);
    });

    testWidgets('shows error for invalid email', (tester) async {
      await tester.pumpWidget(createRegisterScreen());
      await tester.pumpAndSettle();

      // Fill name
      await tester.enterText(find.byType(TextField).at(0), 'Test User');
      // Fill invalid email
      await tester.enterText(find.byType(TextField).at(1), 'notanemail');

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('shows error when password is empty', (tester) async {
      await tester.pumpWidget(createRegisterScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Test User');
      await tester.enterText(find.byType(TextField).at(1), 'test@test.com');
      // Leave password empty

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a password'), findsOneWidget);
    });

    testWidgets('shows error when password is too short', (tester) async {
      await tester.pumpWidget(createRegisterScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Test User');
      await tester.enterText(find.byType(TextField).at(1), 'test@test.com');
      await tester.enterText(find.byType(TextField).at(2), '123'); // < 6 chars

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('At least 6 characters'), findsOneWidget);
    });

    testWidgets('shows error when passwords do not match', (tester) async {
      await tester.pumpWidget(createRegisterScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Test User');
      await tester.enterText(find.byType(TextField).at(1), 'test@test.com');
      await tester.enterText(find.byType(TextField).at(2), 'password123');
      await tester.enterText(find.byType(TextField).at(3), 'different456');

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsWidgets);
    });

    testWidgets('shows error when confirm password is empty', (tester) async {
      await tester.pumpWidget(createRegisterScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Test User');
      await tester.enterText(find.byType(TextField).at(1), 'test@test.com');
      await tester.enterText(find.byType(TextField).at(2), 'password123');
      // Leave confirm empty

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm your password'), findsOneWidget);
    });
  });

  group('RegisterScreen - Password Visibility', () {
    testWidgets('both password fields are obscured by default', (tester) async {
      await tester.pumpWidget(createRegisterScreen());
      await tester.pumpAndSettle();

      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      final obscuredFields = textFields.where((tf) => tf.obscureText).toList();
      // Password + Confirm Password should both be obscured
      expect(obscuredFields.length, 2);
    });

    testWidgets('password visibility toggles work', (tester) async {
      await tester.pumpWidget(createRegisterScreen());
      await tester.pumpAndSettle();

      // Find all visibility_off icons (one per password field)
      final toggleIcons = find.byIcon(Icons.visibility_off);
      expect(toggleIcons, findsNWidgets(2));

      // Tap the first toggle (password field)
      await tester.tap(toggleIcons.first);
      await tester.pumpAndSettle();

      // Should now show visibility icon (not visibility_off) for that field
      final visibleIcons = find.byIcon(Icons.visibility);
      expect(visibleIcons, findsAtLeastNWidgets(1));
    });
  });

  group('RegisterScreen - Form Input', () {
    testWidgets('can fill all fields', (tester) async {
      await tester.pumpWidget(createRegisterScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Marco Rossi');
      await tester.enterText(find.byType(TextField).at(1), 'marco@test.com');
      await tester.enterText(find.byType(TextField).at(2), 'password123');
      await tester.enterText(find.byType(TextField).at(3), 'password123');
      await tester.pump();

      expect(find.text('Marco Rossi'), findsOneWidget);
      expect(find.text('marco@test.com'), findsOneWidget);
    });
  });

  group('RegisterScreen - Navigation', () {
    testWidgets('tapping Sign In pops back to LoginScreen', (tester) async {
      // Start from LoginScreen so there's a route to pop to
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              child: const Text('Go to Register'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Go to Register'));
      await tester.pumpAndSettle();

      // Now on RegisterScreen
      expect(find.text('Create Account'), findsOneWidget);

      // Tap "Sign In" to go back
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Should be back on previous screen
      expect(find.text('Go to Register'), findsOneWidget);
    });
  });
}
