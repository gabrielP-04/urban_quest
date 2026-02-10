import 'package:flutter_test/flutter_test.dart';
import 'package:urban_quest/models/gamification_data.dart';

void main() {
  group('GamificationData - calculateLevel', () {
    test('0 XP should be level 1', () {
      expect(GamificationData.calculateLevel(0), 1);
    });

    test('negative XP should return level 1', () {
      expect(GamificationData.calculateLevel(-100), 1);
    });

    test('99 XP should still be level 1', () {
      expect(GamificationData.calculateLevel(99), 1);
    });

    test('100 XP should be level 2', () {
      expect(GamificationData.calculateLevel(100), 2);
    });

    test('400 XP should be level 3', () {
      expect(GamificationData.calculateLevel(400), 3);
    });

    test('900 XP should be level 4', () {
      expect(GamificationData.calculateLevel(900), 4);
    });

    test('1600 XP should be level 5', () {
      expect(GamificationData.calculateLevel(1600), 5);
    });

    test('XP just below level threshold stays at previous level', () {
      // Level 3 requires 400 XP, so 399 should be level 2
      expect(GamificationData.calculateLevel(399), 2);
    });

    test('large XP values compute correct level', () {
      // Level 10 requires (10-1)^2 * 100 = 8100 XP
      expect(GamificationData.calculateLevel(8100), 10);
    });

    test('XP between level thresholds returns lower level', () {
      // Between level 4 (900) and level 5 (1600)
      expect(GamificationData.calculateLevel(1200), 4);
    });
  });

  group('GamificationData - xpRequiredForLevel', () {
    test('level 1 requires 0 XP', () {
      expect(GamificationData.xpRequiredForLevel(1), 0);
    });

    test('level 0 or below returns 0 XP', () {
      expect(GamificationData.xpRequiredForLevel(0), 0);
      expect(GamificationData.xpRequiredForLevel(-1), 0);
    });

    test('level 2 requires 100 XP', () {
      expect(GamificationData.xpRequiredForLevel(2), 100);
    });

    test('level 3 requires 400 XP', () {
      expect(GamificationData.xpRequiredForLevel(3), 400);
    });

    test('level 4 requires 900 XP', () {
      expect(GamificationData.xpRequiredForLevel(4), 900);
    });

    test('level 5 requires 1600 XP', () {
      expect(GamificationData.xpRequiredForLevel(5), 1600);
    });

    test('level 10 requires 8100 XP', () {
      expect(GamificationData.xpRequiredForLevel(10), 8100);
    });

    test('formula is (level-1)^2 * 100', () {
      for (int level = 1; level <= 20; level++) {
        final expected = (level - 1) * (level - 1) * 100;
        expect(GamificationData.xpRequiredForLevel(level), expected,
            reason: 'Failed for level $level');
      }
    });
  });

  group('GamificationData - xpNeededForNextLevel', () {
    test('from level 1 to 2 needs 100 XP', () {
      expect(GamificationData.xpNeededForNextLevel(1), 100);
    });

    test('from level 2 to 3 needs 300 XP', () {
      // Level 3 = 400, Level 2 = 100 → 300
      expect(GamificationData.xpNeededForNextLevel(2), 300);
    });

    test('from level 3 to 4 needs 500 XP', () {
      // Level 4 = 900, Level 3 = 400 → 500
      expect(GamificationData.xpNeededForNextLevel(3), 500);
    });

    test('XP needed increases with each level', () {
      int previousNeeded = 0;
      for (int level = 1; level <= 15; level++) {
        final needed = GamificationData.xpNeededForNextLevel(level);
        expect(needed > previousNeeded, true,
            reason: 'XP needed for level $level should be > level ${level - 1}');
        previousNeeded = needed;
      }
    });
  });

  group('GamificationData - levelsGainedFromXP', () {
    test('no XP gain means no level gain', () {
      expect(GamificationData.levelsGainedFromXP(0, 0), 0);
    });

    test('gaining 100 XP from 0 gains 1 level', () {
      expect(GamificationData.levelsGainedFromXP(0, 100), 1);
    });

    test('gaining 50 XP from 0 gains 0 levels', () {
      expect(GamificationData.levelsGainedFromXP(0, 50), 0);
    });

    test('gaining enough XP can skip multiple levels', () {
      // From 0 XP, gaining 1600 XP should go to level 5 (4 levels gained)
      expect(GamificationData.levelsGainedFromXP(0, 1600), 4);
    });

    test('gaining XP from mid-level works correctly', () {
      // At 350 XP (level 2), gaining 50 XP = 400 XP = level 3 → 1 level gained
      expect(GamificationData.levelsGainedFromXP(350, 50), 1);
    });
  });

  group('GamificationData - fromTotalXP factory', () {
    test('0 XP creates level 1 data with 0 progress', () {
      final data = GamificationData.fromTotalXP(0);
      expect(data.level, 1);
      expect(data.experiencePoints, 0);
      expect(data.currentLevelXP, 0);
      expect(data.xpToNextLevel, 100);
      expect(data.progressToNextLevel, 0.0);
    });

    test('150 XP creates level 2 data with correct progress', () {
      final data = GamificationData.fromTotalXP(150);
      expect(data.level, 2);
      expect(data.experiencePoints, 150);
      // currentLevelXP = 150 - 100 = 50
      expect(data.currentLevelXP, 50);
      // xpToNextLevel = 400 - 100 = 300
      expect(data.xpToNextLevel, 300);
      // progress = 50 / 300 ≈ 0.1667
      expect(data.progressToNextLevel, closeTo(50 / 300, 0.001));
    });

    test('exact level boundary shows 0 progress into new level', () {
      final data = GamificationData.fromTotalXP(400);
      expect(data.level, 3);
      expect(data.currentLevelXP, 0);
      expect(data.progressToNextLevel, 0.0);
    });

    test('progress is clamped between 0.0 and 1.0', () {
      final data = GamificationData.fromTotalXP(500);
      expect(data.progressToNextLevel, greaterThanOrEqualTo(0.0));
      expect(data.progressToNextLevel, lessThanOrEqualTo(1.0));
    });

    test('recent activities are preserved', () {
      final activities = [
        XPActivity(
          activityType: 'poi_visit',
          xpGained: 100,
          description: 'Visited Duomo',
          timestamp: DateTime(2026, 1, 1),
        ),
      ];
      final data = GamificationData.fromTotalXP(100, recentActivities: activities);
      expect(data.recentActivities.length, 1);
      expect(data.recentActivities.first.description, 'Visited Duomo');
    });
  });

  group('GamificationData - toMap / fromMap roundtrip', () {
    test('roundtrip preserves data', () {
      final original = GamificationData.fromTotalXP(550);
      final map = original.toMap();
      final restored = GamificationData.fromMap(map);

      expect(restored.experiencePoints, original.experiencePoints);
      expect(restored.level, original.level);
    });

    test('fromMap handles missing data gracefully', () {
      final data = GamificationData.fromMap({});
      expect(data.level, 1);
      expect(data.experiencePoints, 0);
    });
  });

  group('GamificationData - equality', () {
    test('same XP and level are equal', () {
      final a = GamificationData.fromTotalXP(500);
      final b = GamificationData.fromTotalXP(500);
      expect(a, equals(b));
    });

    test('different XP are not equal', () {
      final a = GamificationData.fromTotalXP(500);
      final b = GamificationData.fromTotalXP(600);
      expect(a, isNot(equals(b)));
    });
  });

  group('GamificationData - copyWith', () {
    test('copyWith preserves unchanged fields', () {
      final original = GamificationData.fromTotalXP(500);
      final copy = original.copyWith(experiencePoints: 600);
      expect(copy.experiencePoints, 600);
      expect(copy.level, original.level); // unchanged
    });
  });
}
