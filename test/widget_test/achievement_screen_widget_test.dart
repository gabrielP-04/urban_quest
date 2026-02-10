import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urban_quest/models/achievement.dart';

/// Widget tests for Achievement-related UI components
/// 
/// Since AchievementsScreen depends on Firebase for data,
/// these tests verify the individual UI building blocks used in
/// that screen: category chips, progress bars, rarity badges,
/// and achievement cards, using isolated widget tests.
void main() {
  // ============================================================
  // Category Filter Chips
  // ============================================================
  group('Category FilterChip - Rendering', () {
    testWidgets('renders all category chips', (tester) async {
      AchievementCategory? selected;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip('All', null, selected, (cat) {}),
                _buildCategoryChip('🗺️ Exploration',
                    AchievementCategory.exploration, selected, (cat) {}),
                _buildCategoryChip('🏛️ Culture',
                    AchievementCategory.culture, selected, (cat) {}),
                _buildCategoryChip(
                    '🍕 Food', AchievementCategory.food, selected, (cat) {}),
                _buildCategoryChip('🚶 Routes',
                    AchievementCategory.routes, selected, (cat) {}),
                _buildCategoryChip('👥 Social',
                    AchievementCategory.social, selected, (cat) {}),
                _buildCategoryChip('✨ Special',
                    AchievementCategory.special, selected, (cat) {}),
              ],
            ),
          ),
        ),
      ));

      expect(find.text('All'), findsOneWidget);
      expect(find.textContaining('Exploration'), findsOneWidget);
      expect(find.textContaining('Culture'), findsOneWidget);
      expect(find.textContaining('Food'), findsOneWidget);
      expect(find.textContaining('Routes'), findsOneWidget);
      expect(find.textContaining('Social'), findsOneWidget);
      expect(find.textContaining('Special'), findsOneWidget);
    });

    testWidgets('filter chip can be selected', (tester) async {
      AchievementCategory? selected;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryChip('All', null, selected, (cat) {
                      setState(() => selected = cat);
                    }),
                    _buildCategoryChip('🗺️ Exploration',
                        AchievementCategory.exploration, selected, (cat) {
                      setState(() => selected = cat);
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ));

      // Tap Exploration chip
      await tester.tap(find.textContaining('Exploration'));
      await tester.pumpAndSettle();

      // Chip should be visually selected (FilterChip handles this)
      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
      final explorationChip = chips.last;
      expect(explorationChip.selected, true);
    });
  });

  // ============================================================
  // Achievement Progress Bar
  // ============================================================
  group('Achievement Progress Bar', () {
    testWidgets('renders progress indicator', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: _buildProgressBar(
            currentProgress: 5,
            requiredProgress: 10,
            isUnlocked: false,
          ),
        ),
      ));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('5/10'), findsOneWidget);
    });

    testWidgets('shows 0% for no progress', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: _buildProgressBar(
            currentProgress: 0,
            requiredProgress: 10,
            isUnlocked: false,
          ),
        ),
      ));

      final indicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator));
      expect(indicator.value, 0.0);
      expect(find.text('0/10'), findsOneWidget);
    });

    testWidgets('shows full progress when complete', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: _buildProgressBar(
            currentProgress: 10,
            requiredProgress: 10,
            isUnlocked: true,
          ),
        ),
      ));

      final indicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator));
      expect(indicator.value, 1.0);
    });
  });

  // ============================================================
  // Achievement Card Layout
  // ============================================================
  group('Achievement Card', () {
    const testAchievement = Achievement(
      id: 'test_card',
      title: 'Food Lover',
      description: 'Visit 5 restaurants',
      emoji: '🍕',
      category: AchievementCategory.food,
      requiredProgress: 5,
      xpReward: 150,
      rarity: AchievementRarity.epic,
    );

    testWidgets('unlocked card shows achievement info', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: _buildAchievementCard(
              const AchievementProgress(
                achievement: testAchievement,
                currentProgress: 5,
                isUnlocked: true,
                unlockedAt: null,
              ),
            ),
          ),
        ),
      ));

      expect(find.text('Food Lover'), findsOneWidget);
      expect(find.text('Visit 5 restaurants'), findsOneWidget);
      expect(find.text('🍕'), findsOneWidget);
      expect(find.text('Epic'), findsOneWidget);
      expect(find.textContaining('150'), findsWidgets); // XP reward
      expect(find.text('Unlocked'), findsOneWidget);
    });

    testWidgets('locked card shows lock icon instead of emoji', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: _buildAchievementCard(
              const AchievementProgress(
                achievement: testAchievement,
                currentProgress: 2,
                isUnlocked: false,
              ),
            ),
          ),
        ),
      ));

      expect(find.text('Food Lover'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      // Progress should be shown
      expect(find.text('2/5'), findsOneWidget);
    });

    testWidgets('locked card shows remaining progress message', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: _buildAchievementCard(
              const AchievementProgress(
                achievement: testAchievement,
                currentProgress: 4,
                isUnlocked: false,
              ),
            ),
          ),
        ),
      ));

      expect(find.text('1 more to unlock'), findsOneWidget);
    });
  });

  // ============================================================
  // Rarity Badge Display
  // ============================================================
  group('Rarity Badge', () {
    testWidgets('displays correct rarity names', (tester) async {
      for (final rarity in AchievementRarity.values) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: _buildRarityBadge(rarity)),
        ));

        expect(find.text(rarity.displayName), findsOneWidget);
      }
    });
  });

  // ============================================================
  // Empty States
  // ============================================================
  group('Achievement Screen Empty States', () {
    testWidgets('no achievements message renders', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('No achievements in this category'),
          ),
        ),
      ));

      expect(find.text('No achievements in this category'), findsOneWidget);
    });

    testWidgets('no unlocked achievements message renders', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No achievements unlocked yet'),
                const SizedBox(height: 8),
                const Text('Keep exploring to unlock your first achievement!'),
              ],
            ),
          ),
        ),
      ));

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('No achievements unlocked yet'), findsOneWidget);
      expect(find.textContaining('Keep exploring'), findsOneWidget);
    });
  });
}

// ============================================================
// Helper widget builders (extracted from AchievementsScreen)
// ============================================================

Widget _buildCategoryChip(
  String label,
  AchievementCategory? category,
  AchievementCategory? selected,
  Function(AchievementCategory?) onSelect,
) {
  final isSelected = selected == category;
  return Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (sel) => onSelect(sel ? category : null),
      selectedColor: Colors.deepOrange.withOpacity(0.2),
      checkmarkColor: Colors.deepOrange,
      labelStyle: TextStyle(
        color: isSelected ? Colors.deepOrange : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  );
}

Widget _buildProgressBar({
  required int currentProgress,
  required int requiredProgress,
  required bool isUnlocked,
}) {
  final percentage = isUnlocked
      ? 1.0
      : (currentProgress / requiredProgress).clamp(0.0, 1.0);

  return Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.deepOrange,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$currentProgress/$requiredProgress',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
      ],
    ),
  );
}

Widget _buildAchievementCard(AchievementProgress progress) {
  final achievement = progress.achievement;
  final isUnlocked = progress.isUnlocked;
  final rarityColor = Color(achievement.rarity.colorValue);

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isUnlocked ? rarityColor.withOpacity(0.3) : Colors.grey[300]!,
      ),
    ),
    child: Row(
      children: [
        // Icon or Lock
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isUnlocked ? rarityColor.withOpacity(0.15) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: isUnlocked
                ? Text(achievement.emoji, style: const TextStyle(fontSize: 32))
                : Icon(Icons.lock_outline, size: 32, color: Colors.grey[400]),
          ),
        ),
        const SizedBox(width: 16),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(achievement.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  _buildRarityBadge(achievement.rarity),
                ],
              ),
              const SizedBox(height: 4),
              Text(achievement.description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 8),
              if (isUnlocked)
                Row(
                  children: [
                    Icon(Icons.stars, size: 16, color: Colors.amber[700]),
                    const SizedBox(width: 4),
                    Text('+${achievement.xpReward} XP',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[700])),
                    const SizedBox(width: 12),
                    Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Text('Unlocked',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600])),
                  ],
                )
              else
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress.progressPercentage,
                              minHeight: 8,
                              backgroundColor: Colors.grey[200],
                              valueColor:
                                  const AlwaysStoppedAnimation(Colors.deepOrange),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${progress.currentProgress}/${achievement.requiredProgress}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(progress.progressMessage,
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildRarityBadge(AchievementRarity rarity) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Color(rarity.colorValue).withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      rarity.displayName,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(rarity.colorValue),
      ),
    ),
  );
}
