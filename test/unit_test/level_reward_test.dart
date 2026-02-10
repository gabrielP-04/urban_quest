import 'package:flutter_test/flutter_test.dart';
import 'package:urban_quest/models/level_reward.dart';

void main() {
  // ============================================================
  // LevelReward Model Tests
  // ============================================================
  group('LevelReward - creation', () {
    test('creates reward with all fields', () {
      final reward = LevelReward(
        level: 5,
        type: RewardType.badge,
        itemId: 'badge_bronze',
        name: 'Bronze Badge',
        description: 'First milestone',
        icon: '🥉',
      );

      expect(reward.level, 5);
      expect(reward.type, RewardType.badge);
      expect(reward.itemId, 'badge_bronze');
      expect(reward.name, 'Bronze Badge');
      expect(reward.icon, '🥉');
    });

    test('optional fields default to null', () {
      final reward = LevelReward(
        level: 2,
        type: RewardType.badge,
        itemId: 'test',
        name: 'Test',
        description: 'Test',
      );

      expect(reward.icon, isNull);
      expect(reward.imageUrl, isNull);
    });
  });

  group('LevelReward - toMap / fromMap roundtrip', () {
    test('full roundtrip preserves all data', () {
      final original = LevelReward(
        level: 10,
        type: RewardType.profileIcon,
        itemId: 'icon_compass',
        name: 'Compass Icon',
        description: 'Special profile icon',
        icon: '🧭',
        imageUrl: 'https://example.com/icon.png',
      );

      final map = original.toMap();
      final restored = LevelReward.fromMap(map);

      expect(restored.level, original.level);
      expect(restored.type, original.type);
      expect(restored.itemId, original.itemId);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.icon, original.icon);
      expect(restored.imageUrl, original.imageUrl);
    });

    test('fromMap handles unknown RewardType gracefully', () {
      final map = {
        'level': 5,
        'type': 'unknown_type',
        'itemId': 'test',
        'name': 'Test',
        'description': 'Test',
      };

      final reward = LevelReward.fromMap(map);
      expect(reward.type, RewardType.other);
    });
  });

  // ============================================================
  // RewardType Tests
  // ============================================================
  group('RewardType', () {
    test('all reward types have displayNames', () {
      for (final type in RewardType.values) {
        expect(type.displayName.isNotEmpty, true,
            reason: '${type.name} should have a displayName');
      }
    });

    test('expected reward types exist', () {
      final typeNames = RewardType.values.map((t) => t.name).toList();
      expect(typeNames, contains('achievement'));
      expect(typeNames, contains('badge'));
      expect(typeNames, contains('profileIcon'));
      expect(typeNames, contains('profileFrame'));
      expect(typeNames, contains('title'));
      expect(typeNames, contains('feature'));
      expect(typeNames, contains('other'));
    });
  });

  // ============================================================
  // LevelRewardsSystem Tests
  // ============================================================
  group('LevelRewardsSystem - getRewardsForLevel', () {
    test('level 1 has no rewards', () {
      final rewards = LevelRewardsSystem.getRewardsForLevel(1);
      expect(rewards, isEmpty);
    });

    test('level 2 has rewards (Newcomer Badge)', () {
      final rewards = LevelRewardsSystem.getRewardsForLevel(2);
      expect(rewards, isNotEmpty);
      expect(rewards.any((r) => r.name.contains('Newcomer')), true);
    });

    test('level 5 has rewards (City Explorer + Bronze Badge)', () {
      final rewards = LevelRewardsSystem.getRewardsForLevel(5);
      expect(rewards.length, greaterThanOrEqualTo(2));
    });

    test('level 10 has rewards (Urban Adventurer + Silver Badge + Compass)', () {
      final rewards = LevelRewardsSystem.getRewardsForLevel(10);
      expect(rewards.length, greaterThanOrEqualTo(3));
    });

    test('level 20 has rewards (City Master + Gold Badge + Title)', () {
      final rewards = LevelRewardsSystem.getRewardsForLevel(20);
      expect(rewards.length, greaterThanOrEqualTo(3));
    });

    test('non-reward level returns empty list', () {
      final rewards = LevelRewardsSystem.getRewardsForLevel(3);
      expect(rewards, isEmpty);
    });

    test('all rewards at a level have matching level field', () {
      for (final level in [2, 5, 10, 15, 20, 25, 30]) {
        final rewards = LevelRewardsSystem.getRewardsForLevel(level);
        for (final reward in rewards) {
          expect(reward.level, level,
              reason: 'Reward "${reward.name}" at level $level has mismatched level field');
        }
      }
    });
  });

  group('LevelRewardsSystem - hasRewards', () {
    test('level 2 has rewards', () {
      expect(LevelRewardsSystem.hasRewards(2), true);
    });

    test('level 5 has rewards', () {
      expect(LevelRewardsSystem.hasRewards(5), true);
    });

    test('level 3 has no rewards', () {
      expect(LevelRewardsSystem.hasRewards(3), false);
    });

    test('level 7 has no rewards', () {
      expect(LevelRewardsSystem.hasRewards(7), false);
    });
  });

  group('LevelRewardsSystem - getAllRewardsUpToLevel', () {
    test('up to level 1 returns empty', () {
      final rewards = LevelRewardsSystem.getAllRewardsUpToLevel(1);
      expect(rewards, isEmpty);
    });

    test('up to level 2 includes level 2 rewards only', () {
      final rewards = LevelRewardsSystem.getAllRewardsUpToLevel(2);
      final level2Rewards = LevelRewardsSystem.getRewardsForLevel(2);
      expect(rewards.length, level2Rewards.length);
    });

    test('up to level 5 includes levels 2 and 5 rewards', () {
      final rewards = LevelRewardsSystem.getAllRewardsUpToLevel(5);
      final level2 = LevelRewardsSystem.getRewardsForLevel(2);
      final level5 = LevelRewardsSystem.getRewardsForLevel(5);
      expect(rewards.length, level2.length + level5.length);
    });

    test('rewards accumulate as level increases', () {
      int previousCount = 0;
      for (final level in [2, 5, 10, 15, 20, 25, 30]) {
        final rewards = LevelRewardsSystem.getAllRewardsUpToLevel(level);
        expect(rewards.length, greaterThanOrEqualTo(previousCount),
            reason: 'Rewards up to level $level should be >= previous');
        previousCount = rewards.length;
      }
    });
  });

  group('LevelRewardsSystem - getNextRewardLevel', () {
    test('from level 1, next reward is level 2', () {
      expect(LevelRewardsSystem.getNextRewardLevel(1), 2);
    });

    test('from level 2, next reward is level 5', () {
      expect(LevelRewardsSystem.getNextRewardLevel(2), 5);
    });

    test('from level 5, next reward is level 10', () {
      expect(LevelRewardsSystem.getNextRewardLevel(5), 10);
    });

    test('from level 3, next reward is level 5 (skips non-reward levels)', () {
      expect(LevelRewardsSystem.getNextRewardLevel(3), 5);
    });

    test('from max reward level, returns null', () {
      expect(LevelRewardsSystem.getNextRewardLevel(30), isNull);
    });

    test('from level above max, returns null', () {
      expect(LevelRewardsSystem.getNextRewardLevel(50), isNull);
    });
  });

  group('LevelRewardsSystem - getAllRewardLevels', () {
    test('returns sorted list of reward levels', () {
      final levels = LevelRewardsSystem.getAllRewardLevels();
      expect(levels, isNotEmpty);

      // Verify sorted
      for (int i = 1; i < levels.length; i++) {
        expect(levels[i], greaterThan(levels[i - 1]));
      }
    });

    test('includes known reward levels', () {
      final levels = LevelRewardsSystem.getAllRewardLevels();
      expect(levels, contains(2));
      expect(levels, contains(5));
      expect(levels, contains(10));
      expect(levels, contains(15));
      expect(levels, contains(20));
      expect(levels, contains(25));
      expect(levels, contains(30));
    });
  });

  group('LevelRewardsSystem - getRewardsSummary', () {
    test('summary includes all reward levels', () {
      final summary = LevelRewardsSystem.getRewardsSummary();
      expect(summary.keys, containsAll([2, 5, 10, 15, 20, 25, 30]));
    });

    test('each level summary has correct reward type counts', () {
      final summary = LevelRewardsSystem.getRewardsSummary();

      // Level 2 should have at least a badge
      expect(summary[2]!.containsKey(RewardType.badge), true);
    });
  });
}
