import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urban_quest/models/achievement.dart';
import 'package:urban_quest/widgets/achievement_unlocked_dialog.dart';

/// Widget tests for AchievementUnlockedDialog
/// 
/// This is a self-contained widget that doesn't depend on Firebase,
/// making it ideal for widget testing. Tests verify correct rendering
/// of achievement details, rarity styling, and dismiss behavior.
void main() {
  const testAchievement = Achievement(
    id: 'test_explorer',
    title: 'City Explorer',
    description: 'Visit 10 points of interest',
    emoji: '🗺️',
    category: AchievementCategory.exploration,
    requiredProgress: 10,
    xpReward: 200,
    rarity: AchievementRarity.rare,
  );

  const legendaryAchievement = Achievement(
    id: 'test_legend',
    title: 'Urban Legend',
    description: 'Reach level 25',
    emoji: '💎',
    category: AchievementCategory.special,
    requiredProgress: 25,
    xpReward: 1000,
    rarity: AchievementRarity.legendary,
  );

  Widget createDialogTestApp(Achievement achievement) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AchievementUnlockedDialog.show(context, achievement),
            child: const Text('Show Dialog'),
          ),
        ),
      ),
    );
  }

  group('AchievementUnlockedDialog - Rendering', () {
    testWidgets('displays "Achievement Unlocked!" title', (tester) async {
      await tester.pumpWidget(createDialogTestApp(testAchievement));
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Achievement Unlocked!'), findsOneWidget);
    });

    testWidgets('displays achievement title', (tester) async {
      await tester.pumpWidget(createDialogTestApp(testAchievement));
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('City Explorer'), findsOneWidget);
    });

    testWidgets('displays achievement description', (tester) async {
      await tester.pumpWidget(createDialogTestApp(testAchievement));
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Visit 10 points of interest'), findsOneWidget);
    });

    testWidgets('displays achievement emoji', (tester) async {
      await tester.pumpWidget(createDialogTestApp(testAchievement));
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('🗺️'), findsOneWidget);
    });

    testWidgets('displays XP reward', (tester) async {
      await tester.pumpWidget(createDialogTestApp(testAchievement));
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('+200 XP'), findsOneWidget);
    });

    testWidgets('displays celebration icon', (tester) async {
      await tester.pumpWidget(createDialogTestApp(testAchievement));
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.celebration), findsOneWidget);
    });

    testWidgets('displays rarity badge', (tester) async {
      await tester.pumpWidget(createDialogTestApp(testAchievement));
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Rare'), findsOneWidget);
    });

    testWidgets('displays dismiss button', (tester) async {
      await tester.pumpWidget(createDialogTestApp(testAchievement));
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Should have an "Awesome!" or similar dismiss button
      expect(find.byType(ElevatedButton), findsWidgets);
    });
  });

  group('AchievementUnlockedDialog - Different Rarities', () {
    testWidgets('common achievement renders correctly', (tester) async {
      const common = Achievement(
        id: 'common_test',
        title: 'First Steps',
        description: 'Visit your first POI',
        emoji: '👣',
        category: AchievementCategory.exploration,
        requiredProgress: 1,
        xpReward: 50,
        rarity: AchievementRarity.common,
      );

      await tester.pumpWidget(createDialogTestApp(common));
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('First Steps'), findsOneWidget);
      expect(find.text('+50 XP'), findsOneWidget);
      expect(find.text('Common'), findsOneWidget);
    });

    testWidgets('legendary achievement renders correctly', (tester) async {
      await tester.pumpWidget(createDialogTestApp(legendaryAchievement));
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Urban Legend'), findsOneWidget);
      expect(find.text('💎'), findsOneWidget);
      expect(find.text('+1000 XP'), findsOneWidget);
      expect(find.text('Legendary'), findsOneWidget);
    });
  });

  group('AchievementUnlockedDialog - Interaction', () {
    testWidgets('dialog can be dismissed with button', (tester) async {
      await tester.pumpWidget(createDialogTestApp(testAchievement));
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.text('Achievement Unlocked!'), findsOneWidget);

      // Find and tap dismiss button (usually "Awesome!" or similar)
      final buttons = find.byType(ElevatedButton);
      // Tap the last button (dismiss) in the dialog
      await tester.tap(buttons.last);
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('Achievement Unlocked!'), findsNothing);
    });
  });

  group('AchievementUnlockedDialog - Direct Widget Test', () {
    testWidgets('renders as a Dialog widget', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AchievementUnlockedDialog(achievement: testAchievement),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('displays all key information', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AchievementUnlockedDialog(achievement: testAchievement),
        ),
      ));
      await tester.pumpAndSettle();

      // All essential info present
      expect(find.text('Achievement Unlocked!'), findsOneWidget);
      expect(find.text('City Explorer'), findsOneWidget);
      expect(find.text('Visit 10 points of interest'), findsOneWidget);
      expect(find.text('🗺️'), findsOneWidget);
      expect(find.textContaining('200'), findsWidgets);
    });
  });

  group('AchievementUnlockedDialog.showMultiple', () {
    testWidgets('shows first achievement from list', (tester) async {
      const achievements = [testAchievement, legendaryAchievement];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  AchievementUnlockedDialog.showMultiple(context, achievements),
              child: const Text('Show Multiple'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Multiple'));
      await tester.pumpAndSettle();

      // First achievement should be displayed
      expect(find.text('City Explorer'), findsOneWidget);
    });

    testWidgets('does nothing with empty list', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  AchievementUnlockedDialog.showMultiple(context, []),
              child: const Text('Show Empty'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Empty'));
      await tester.pumpAndSettle();

      // No dialog should appear
      expect(find.text('Achievement Unlocked!'), findsNothing);
    });
  });
}
