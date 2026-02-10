import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests for AuthWrapper behavior patterns
/// 
/// Since AuthWrapper depends on FirebaseAuth.authStateChanges() stream,
/// these tests verify the UI patterns used in the wrapper using mock
/// StreamBuilder scenarios rather than actual Firebase calls.
/// 
/// This tests the 3 states the AuthWrapper handles:
/// 1. ConnectionState.waiting → shows loading spinner
/// 2. hasError → shows error UI
/// 3. hasData (null) → shows login screen
/// 4. hasData (user) → shows main scaffold
void main() {
  group('AuthWrapper Pattern - Loading State', () {
    testWidgets('shows CircularProgressIndicator while waiting', (tester) async {
      // Simulate the waiting state pattern used in AuthWrapper
      await tester.pumpWidget(MaterialApp(
        home: StreamBuilder<String?>(
          // Never-completing stream simulates waiting
          stream: const Stream<String?>.empty(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return const Scaffold(body: Text('Loaded'));
          },
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('AuthWrapper Pattern - Error State', () {
    testWidgets('shows error icon and message when stream has error',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: StreamBuilder<String?>(
          stream: Stream<String?>.error('Connection failed'),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const Scaffold(body: Text('OK'));
          },
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('Error'), findsOneWidget);
    });
  });

  group('AuthWrapper Pattern - No User (null data)', () {
    testWidgets('shows login content when user is null', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: StreamBuilder<String?>(
          stream: Stream<String?>.value(null),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.data == null) {
              return const Scaffold(
                body: Center(child: Text('Login Screen')),
              );
            }
            return const Scaffold(
              body: Center(child: Text('Main App')),
            );
          },
        ),
      ));

      await tester.pumpAndSettle();
      expect(find.text('Login Screen'), findsOneWidget);
    });
  });

  group('AuthWrapper Pattern - Authenticated User', () {
    testWidgets('shows main app when user is present', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: StreamBuilder<String?>(
          stream: Stream<String?>.value('user_123'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasData && snapshot.data != null) {
              return const Scaffold(
                body: Center(child: Text('Main App')),
              );
            }
            return const Scaffold(
              body: Center(child: Text('Login Screen')),
            );
          },
        ),
      ));

      await tester.pumpAndSettle();
      expect(find.text('Main App'), findsOneWidget);
    });
  });

  group('AuthWrapper Pattern - State Transitions', () {
    testWidgets('transitions from loading to content', (tester) async {
      // Use a stream controller to simulate state changes
      final controller = Stream<String?>.fromFuture(
        Future.delayed(const Duration(milliseconds: 100), () => 'user_123'),
      );

      await tester.pumpWidget(MaterialApp(
        home: StreamBuilder<String?>(
          stream: controller,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasData && snapshot.data != null) {
              return const Scaffold(
                body: Center(child: Text('Welcome!')),
              );
            }
            return const Scaffold(
              body: Center(child: Text('Login')),
            );
          },
        ),
      ));

      // Initially loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // After stream emits
      await tester.pumpAndSettle();
      expect(find.text('Welcome!'), findsOneWidget);
    });
  });
}
