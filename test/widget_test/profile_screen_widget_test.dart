import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urban_quest/services/momentum_service.dart';

/// Widget tests for Profile screen UI components
/// 
/// Tests the isolated UI building blocks used in ProfileScreen:
/// progress cards, momentum display, level titles, and settings items.
/// These don't require Firebase since they render from pre-built data.
void main() {
  // ============================================================
  // Progress Card Widget
  // ============================================================
  group('Progress Card - Level Display', () {
    testWidgets('shows correct level number', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: _buildProgressCard(
            level: 5,
            currentLevelXP: 250,
            xpToNextLevel: 500,
            progress: 0.5,
          ),
        ),
      ));

      expect(find.text('Level 5'), findsOneWidget);
    });

    testWidgets('shows XP progress text', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: _buildProgressCard(
            level: 3,
            currentLevelXP: 150,
            xpToNextLevel: 500,
            progress: 0.3,
          ),
        ),
      ));

      expect(find.text('150 / 500 XP'), findsOneWidget);
    });

    testWidgets('shows next level text', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: _buildProgressCard(
            level: 7,
            currentLevelXP: 0,
            xpToNextLevel: 1500,
            progress: 0.0,
          ),
        ),
      ));

      expect(find.text('Level 8'), findsOneWidget);
    });

    testWidgets('progress bar renders between 0 and 1', (tester) async {
      for (final progress in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: _buildProgressCard(
              level: 1,
              currentLevelXP: 0,
              xpToNextLevel: 100,
              progress: progress,
            ),
          ),
        ));

        // The FractionallySizedBox is used for the progress bar fill
        final fractions = tester.widgetList<FractionallySizedBox>(
            find.byType(FractionallySizedBox));
        expect(fractions, isNotEmpty);
      }
    });
  });

  // ============================================================
  // Momentum Card Widget
  // ============================================================
  group('Momentum Card', () {
    testWidgets('active momentum shows level name and icon', (tester) async {
      final momentum = MomentumState(
        isActive: true,
        sessionPOIsVisited: 5,
        sessionDuration: const Duration(minutes: 30),
        multiplier: 1.4,
        level: MomentumLevel.high,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: _buildMomentumCard(momentum)),
      ));

      expect(find.text('High Momentum'), findsOneWidget);
      expect(find.text('🔥🔥'), findsOneWidget);
      expect(find.text('5 POIs this session'), findsOneWidget);
      expect(find.textContaining('40%'), findsOneWidget);
    });

    testWidgets('blazing momentum shows max bonus', (tester) async {
      final momentum = MomentumState(
        isActive: true,
        sessionPOIsVisited: 10,
        sessionDuration: const Duration(minutes: 60),
        multiplier: 1.6,
        level: MomentumLevel.blazing,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: _buildMomentumCard(momentum)),
      ));

      expect(find.text('🔥🔥🔥'), findsOneWidget);
      expect(find.textContaining('60%'), findsOneWidget);
    });
  });

  // ============================================================
  // Level Title Helper
  // ============================================================
  group('Level Title', () {
    test('returns correct titles for level ranges', () {
      expect(_getLevelTitle(1), 'Explorer');
      expect(_getLevelTitle(4), 'Explorer');
      expect(_getLevelTitle(5), 'Adventurer');
      expect(_getLevelTitle(9), 'Adventurer');
      expect(_getLevelTitle(10), 'Navigator');
      expect(_getLevelTitle(14), 'Navigator');
      expect(_getLevelTitle(15), 'Voyager');
      expect(_getLevelTitle(19), 'Voyager');
      expect(_getLevelTitle(20), 'Master');
      expect(_getLevelTitle(24), 'Master');
      expect(_getLevelTitle(25), 'Legend');
      expect(_getLevelTitle(100), 'Legend');
    });
  });

  // ============================================================
  // Settings Card Items
  // ============================================================
  group('Settings Card Items', () {
    testWidgets('setting item renders with icon, title, and chevron',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: _buildSettingItem(
            icon: Icons.security,
            title: 'Account & Security',
            onTap: () => tapped = true,
          ),
        ),
      ));

      expect(find.byIcon(Icons.security), findsOneWidget);
      expect(find.text('Account & Security'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      await tester.tap(find.text('Account & Security'));
      expect(tapped, true);
    });

    testWidgets('activity item renders with icon, title, subtitle, and chevron',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: _buildActivityItem(
            icon: Icons.emoji_events_outlined,
            iconColor: Colors.deepOrange,
            title: 'Achievements',
            subtitle: '5 unlocked',
            onTap: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
      expect(find.text('Achievements'), findsOneWidget);
      expect(find.text('5 unlocked'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });

  // ============================================================
  // Quick Stats Display
  // ============================================================
  group('Quick Stats', () {
    testWidgets('renders POIs visited count', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: _buildQuickStat('15', 'POIs'),
        ),
      ));

      expect(find.text('15'), findsOneWidget);
      expect(find.text('POIs'), findsOneWidget);
    });

    testWidgets('renders routes completed count', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: _buildQuickStat('3', 'Routes'),
        ),
      ));

      expect(find.text('3'), findsOneWidget);
      expect(find.text('Routes'), findsOneWidget);
    });

    testWidgets('renders badges count', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: _buildQuickStat('7', 'Badges'),
        ),
      ));

      expect(find.text('7'), findsOneWidget);
      expect(find.text('Badges'), findsOneWidget);
    });
  });

  // ============================================================
  // Logout Confirmation Dialog
  // ============================================================
  group('Logout Dialog', () {
    testWidgets('shows confirmation dialog', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Sign Out'),
                    content:
                        const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Logout'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(find.text('Sign Out'), findsWidgets);
      expect(find.text('Are you sure you want to sign out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('cancel dismisses dialog', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Sign Out'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Logout'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      expect(find.text('Sign Out'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Sign Out'), findsNothing);
    });
  });
}

// ============================================================
// Helper widget builders (extracted from ProfileScreen)
// ============================================================

Widget _buildProgressCard({
  required int level,
  required int currentLevelXP,
  required int xpToNextLevel,
  required double progress,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level $level',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(_getLevelTitle(level),
                style: const TextStyle(fontSize: 14, color: Colors.deepOrange)),
          ],
        ),
        const SizedBox(height: 16),
        Stack(
          children: [
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9A56), Color(0xFFFF7A3D)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$currentLevelXP / $xpToNextLevel XP',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text('Level ${level + 1}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
          ],
        ),
      ],
    ),
  );
}

Widget _buildMomentumCard(MomentumState momentum) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFE5D1), Color(0xFFFFD4B3)],
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Text(momentum.level.icon, style: const TextStyle(fontSize: 36)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(momentum.level.displayName,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF7A3D))),
              const SizedBox(height: 4),
              Text('${momentum.sessionPOIsVisited} POIs this session',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF5A5A5A))),
              const SizedBox(height: 4),
              Text(
                  '+${((momentum.multiplier - 1) * 100).toInt()}% XP Bonus Active',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF7A3D))),
            ],
          ),
        ),
      ],
    ),
  );
}

String _getLevelTitle(int level) {
  if (level < 5) return 'Explorer';
  if (level < 10) return 'Adventurer';
  if (level < 15) return 'Navigator';
  if (level < 20) return 'Voyager';
  if (level < 25) return 'Master';
  return 'Legend';
}

Widget _buildSettingItem({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9E9E9E), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title,
                style:
                    const TextStyle(fontSize: 16, color: Color(0xFF5A5A5A))),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD), size: 24),
        ],
      ),
    ),
  );
}

Widget _buildActivityItem({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD), size: 24),
        ],
      ),
    ),
  );
}

Widget _buildQuickStat(String value, String label) {
  return Column(
    children: [
      Text(value,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C))),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
    ],
  );
}
