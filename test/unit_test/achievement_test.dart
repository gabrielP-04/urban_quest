import 'package:flutter_test/flutter_test.dart';
import 'package:urban_quest/models/achievement.dart';

void main() {
  // ============================================================
  // Achievement Model Tests
  // ============================================================
  group('Achievement - creation', () {
    test('creates achievement with all required fields', () {
      const achievement = Achievement(
        id: 'test_1',
        title: 'First Steps',
        description: 'Visit your first POI',
        emoji: '👣',
        category: AchievementCategory.exploration,
        requiredProgress: 1,
        xpReward: 50,
        rarity: AchievementRarity.common,
      );

      expect(achievement.id, 'test_1');
      expect(achievement.title, 'First Steps');
      expect(achievement.category, AchievementCategory.exploration);
      expect(achievement.requiredProgress, 1);
      expect(achievement.xpReward, 50);
      expect(achievement.rarity, AchievementRarity.common);
    });
  });

  group('Achievement - toMap / fromMap roundtrip', () {
    test('full roundtrip preserves all data', () {
      const original = Achievement(
        id: 'explore_10',
        title: 'Explorer',
        description: 'Visit 10 POIs',
        emoji: '🗺️',
        category: AchievementCategory.exploration,
        requiredProgress: 10,
        xpReward: 200,
        rarity: AchievementRarity.rare,
      );

      final map = original.toMap();
      final restored = Achievement.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.emoji, original.emoji);
      expect(restored.category, original.category);
      expect(restored.requiredProgress, original.requiredProgress);
      expect(restored.xpReward, original.xpReward);
      expect(restored.rarity, original.rarity);
    });

    test('fromMap handles unknown category gracefully', () {
      final map = {
        'id': 'test',
        'title': 'Test',
        'description': 'Test desc',
        'emoji': '🏆',
        'category': 'unknown_category',
        'requiredProgress': 1,
        'xpReward': 50,
        'rarity': 'common',
      };

      final achievement = Achievement.fromMap(map);
      expect(achievement.category, AchievementCategory.exploration); // default
    });

    test('fromMap handles unknown rarity gracefully', () {
      final map = {
        'id': 'test',
        'title': 'Test',
        'description': 'Test desc',
        'emoji': '🏆',
        'category': 'exploration',
        'requiredProgress': 1,
        'xpReward': 50,
        'rarity': 'mythical',
      };

      final achievement = Achievement.fromMap(map);
      expect(achievement.rarity, AchievementRarity.common); // default
    });
  });

  // ============================================================
  // AchievementCategory Tests
  // ============================================================
  group('AchievementCategory', () {
    test('all categories have displayNames', () {
      for (final cat in AchievementCategory.values) {
        expect(cat.displayName.isNotEmpty, true,
            reason: '${cat.name} should have a displayName');
      }
    });

    test('all categories have emojis', () {
      for (final cat in AchievementCategory.values) {
        expect(cat.emoji.isNotEmpty, true,
            reason: '${cat.name} should have an emoji');
      }
    });

    test('expected categories exist', () {
      final categoryNames =
          AchievementCategory.values.map((c) => c.name).toList();
      expect(categoryNames, contains('exploration'));
      expect(categoryNames, contains('culture'));
      expect(categoryNames, contains('food'));
      expect(categoryNames, contains('routes'));
      expect(categoryNames, contains('social'));
      expect(categoryNames, contains('special'));
    });
  });

  // ============================================================
  // AchievementRarity Tests
  // ============================================================
  group('AchievementRarity', () {
    test('all rarities have displayNames', () {
      for (final rarity in AchievementRarity.values) {
        expect(rarity.displayName.isNotEmpty, true,
            reason: '${rarity.name} should have a displayName');
      }
    });

    test('all rarities have color values', () {
      for (final rarity in AchievementRarity.values) {
        expect(rarity.colorValue, isNonZero,
            reason: '${rarity.name} should have a non-zero color value');
      }
    });

    test('rarities are ordered from common to legendary', () {
      expect(AchievementRarity.common.index,
          lessThan(AchievementRarity.rare.index));
      expect(AchievementRarity.rare.index,
          lessThan(AchievementRarity.epic.index));
      expect(AchievementRarity.epic.index,
          lessThan(AchievementRarity.legendary.index));
    });

    test('expected color values match design spec', () {
      expect(AchievementRarity.common.colorValue, 0xFFCD7F32); // Bronze
      expect(AchievementRarity.rare.colorValue, 0xFFC0C0C0); // Silver
      expect(AchievementRarity.epic.colorValue, 0xFFFFD700); // Gold
      expect(AchievementRarity.legendary.colorValue, 0xFFE5E4E2); // Platinum
    });
  });

  // ============================================================
  // AchievementProgress Tests
  // ============================================================
  group('AchievementProgress - progressPercentage', () {
    const testAchievement = Achievement(
      id: 'test_10',
      title: 'Visit 10 POIs',
      description: 'Explore 10 points of interest',
      emoji: '🗺️',
      category: AchievementCategory.exploration,
      requiredProgress: 10,
      xpReward: 200,
      rarity: AchievementRarity.rare,
    );

    test('0 progress gives 0.0 percentage', () {
      const progress = AchievementProgress(
        achievement: testAchievement,
        currentProgress: 0,
        isUnlocked: false,
      );
      expect(progress.progressPercentage, 0.0);
    });

    test('half progress gives 0.5 percentage', () {
      const progress = AchievementProgress(
        achievement: testAchievement,
        currentProgress: 5,
        isUnlocked: false,
      );
      expect(progress.progressPercentage, 0.5);
    });

    test('full progress gives 1.0 percentage when unlocked', () {
      const progress = AchievementProgress(
        achievement: testAchievement,
        currentProgress: 10,
        isUnlocked: true,
      );
      expect(progress.progressPercentage, 1.0);
    });

    test('progress is clamped to 1.0 even if over requirement', () {
      const progress = AchievementProgress(
        achievement: testAchievement,
        currentProgress: 15,
        isUnlocked: false,
      );
      expect(progress.progressPercentage, 1.0);
    });
  });

  group('AchievementProgress - remainingProgress', () {
    const testAchievement = Achievement(
      id: 'test_5',
      title: 'Visit 5 POIs',
      description: 'Explore 5 points of interest',
      emoji: '🗺️',
      category: AchievementCategory.exploration,
      requiredProgress: 5,
      xpReward: 100,
      rarity: AchievementRarity.common,
    );

    test('0 progress means full remaining', () {
      const progress = AchievementProgress(
        achievement: testAchievement,
        currentProgress: 0,
        isUnlocked: false,
      );
      expect(progress.remainingProgress, 5);
    });

    test('partial progress shows correct remaining', () {
      const progress = AchievementProgress(
        achievement: testAchievement,
        currentProgress: 3,
        isUnlocked: false,
      );
      expect(progress.remainingProgress, 2);
    });

    test('unlocked achievement has 0 remaining', () {
      const progress = AchievementProgress(
        achievement: testAchievement,
        currentProgress: 5,
        isUnlocked: true,
      );
      expect(progress.remainingProgress, 0);
    });

    test('remaining is clamped to 0 when over requirement', () {
      const progress = AchievementProgress(
        achievement: testAchievement,
        currentProgress: 10,
        isUnlocked: false,
      );
      expect(progress.remainingProgress, 0);
    });
  });

  group('AchievementProgress - progressMessage', () {
    const testAchievement = Achievement(
      id: 'test_3',
      title: 'Test',
      description: 'Test',
      emoji: '🏆',
      category: AchievementCategory.exploration,
      requiredProgress: 3,
      xpReward: 50,
      rarity: AchievementRarity.common,
    );

    test('unlocked shows "Unlocked!" message', () {
      const progress = AchievementProgress(
        achievement: testAchievement,
        currentProgress: 3,
        isUnlocked: true,
      );
      expect(progress.progressMessage, 'Unlocked!');
    });

    test('1 remaining shows singular message', () {
      const progress = AchievementProgress(
        achievement: testAchievement,
        currentProgress: 2,
        isUnlocked: false,
      );
      expect(progress.progressMessage, '1 more to unlock');
    });

    test('multiple remaining shows plural message', () {
      const progress = AchievementProgress(
        achievement: testAchievement,
        currentProgress: 0,
        isUnlocked: false,
      );
      expect(progress.progressMessage, '3 more to unlock');
    });
  });

  group('AchievementProgress - copyWith', () {
    const testAchievement = Achievement(
      id: 'test',
      title: 'Test',
      description: 'Test',
      emoji: '🏆',
      category: AchievementCategory.exploration,
      requiredProgress: 5,
      xpReward: 100,
      rarity: AchievementRarity.common,
    );

    test('copyWith preserves unchanged fields', () {
      const original = AchievementProgress(
        achievement: testAchievement,
        currentProgress: 3,
        isUnlocked: false,
      );

      final copy = original.copyWith(currentProgress: 4);

      expect(copy.currentProgress, 4);
      expect(copy.isUnlocked, false); // unchanged
      expect(copy.achievement.id, 'test'); // unchanged
    });

    test('copyWith can mark as unlocked', () {
      const original = AchievementProgress(
        achievement: testAchievement,
        currentProgress: 5,
        isUnlocked: false,
      );

      final unlocked = original.copyWith(
        isUnlocked: true,
        unlockedAt: DateTime(2026, 2, 10),
      );

      expect(unlocked.isUnlocked, true);
      expect(unlocked.unlockedAt, DateTime(2026, 2, 10));
    });
  });

  // ============================================================
  // AchievementCheckResult Tests
  // ============================================================
  group('AchievementCheckResult', () {
    test('no new achievements', () {
      final result = AchievementCheckResult(
        newlyUnlocked: [],
        totalXPRewarded: 0,
        totalAchievements: 10,
      );

      expect(result.hasNewAchievements, false);
      expect(result.summary, 'No new achievements');
    });

    test('single achievement unlocked', () {
      final result = AchievementCheckResult(
        newlyUnlocked: const [
          Achievement(
            id: 'test',
            title: 'Test',
            description: 'Test',
            emoji: '🏆',
            category: AchievementCategory.exploration,
            requiredProgress: 1,
            xpReward: 50,
            rarity: AchievementRarity.common,
          ),
        ],
        totalXPRewarded: 50,
        totalAchievements: 10,
      );

      expect(result.hasNewAchievements, true);
      expect(result.summary, contains('1 achievement'));
      expect(result.summary, contains('50 XP'));
    });

    test('multiple achievements unlocked', () {
      final result = AchievementCheckResult(
        newlyUnlocked: const [
          Achievement(
            id: 'a1',
            title: 'A1',
            description: 'A1',
            emoji: '🏆',
            category: AchievementCategory.exploration,
            requiredProgress: 1,
            xpReward: 50,
            rarity: AchievementRarity.common,
          ),
          Achievement(
            id: 'a2',
            title: 'A2',
            description: 'A2',
            emoji: '🎖️',
            category: AchievementCategory.routes,
            requiredProgress: 1,
            xpReward: 100,
            rarity: AchievementRarity.rare,
          ),
        ],
        totalXPRewarded: 150,
        totalAchievements: 10,
      );

      expect(result.hasNewAchievements, true);
      expect(result.summary, contains('2 achievements'));
      expect(result.summary, contains('150 XP'));
    });
  });
}
