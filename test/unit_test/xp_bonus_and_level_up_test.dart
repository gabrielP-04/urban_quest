import 'package:flutter_test/flutter_test.dart';
import 'package:urban_quest/models/level_up_result.dart';

void main() {
  // ============================================================
  // XPBonus Tests
  // ============================================================
  group('XPBonus - apply method', () {
    test('multiplier bonus applies correctly', () {
      final bonus = XPBonus(
        name: 'Test',
        value: 1.5,
        isMultiplier: true,
        description: 'Test multiplier',
      );
      expect(bonus.apply(100), 150);
    });

    test('fixed bonus adds to base XP', () {
      final bonus = XPBonus.fixed(50, 'Fixed bonus');
      expect(bonus.apply(100), 150);
    });

    test('firstTime bonus gives +50%', () {
      final bonus = XPBonus.firstTime();
      expect(bonus.isMultiplier, true);
      expect(bonus.value, 1.5);
      expect(bonus.apply(100), 150);
    });

    test('streak bonus gives +20%', () {
      final bonus = XPBonus.streak();
      expect(bonus.isMultiplier, true);
      expect(bonus.value, 1.2);
      expect(bonus.apply(100), 120);
    });

    test('special event bonus applies custom multiplier', () {
      final bonus = XPBonus.specialEvent(2.0, 'Double XP Weekend');
      expect(bonus.apply(100), 200);
    });

    test('multiplier rounds correctly', () {
      final bonus = XPBonus.firstTime(); // 1.5x
      // 75 * 1.5 = 112.5 → should round to 113
      expect(bonus.apply(75), 113);
    });

    test('multiplier of 1.0 returns same value', () {
      final bonus = XPBonus(
        name: 'No bonus',
        value: 1.0,
        isMultiplier: true,
        description: 'No change',
      );
      expect(bonus.apply(100), 100);
    });

    test('fixed bonus of 0 returns same value', () {
      final bonus = XPBonus.fixed(0, 'Zero bonus');
      expect(bonus.apply(100), 100);
    });

    test('chaining multiplier bonuses compounds correctly', () {
      final firstTime = XPBonus.firstTime(); // 1.5x
      final streak = XPBonus.streak(); // 1.2x

      int xp = 100;
      xp = firstTime.apply(xp); // 150
      xp = streak.apply(xp); // 150 * 1.2 = 180

      expect(xp, 180);
    });
  });

  group('XPBonus - toMap / fromMap roundtrip', () {
    test('multiplier bonus roundtrip', () {
      final original = XPBonus.firstTime();
      final map = original.toMap();
      final restored = XPBonus.fromMap(map);

      expect(restored.name, original.name);
      expect(restored.value, original.value);
      expect(restored.isMultiplier, original.isMultiplier);
      expect(restored.description, original.description);
    });

    test('fixed bonus roundtrip', () {
      final original = XPBonus.fixed(50, 'Test bonus');
      final map = original.toMap();
      final restored = XPBonus.fromMap(map);

      expect(restored.value, 50.0);
      expect(restored.isMultiplier, false);
    });
  });

  // ============================================================
  // LevelUpResult Tests
  // ============================================================
  group('LevelUpResult - noLevelUp factory', () {
    test('creates result without level change', () {
      final result = LevelUpResult.noLevelUp(
        xpGained: 100,
        newTotalXP: 200,
        currentLevel: 2,
        reason: 'Visited POI',
      );

      expect(result.didLevelUp, false);
      expect(result.xpGained, 100);
      expect(result.newTotalXP, 200);
      expect(result.oldLevel, 2);
      expect(result.newLevel, 2);
      expect(result.levelsGained, 0);
      expect(result.reason, 'Visited POI');
    });
  });

  group('LevelUpResult - withLevelUp factory', () {
    test('creates result with level change', () {
      final result = LevelUpResult.withLevelUp(
        xpGained: 150,
        newTotalXP: 400,
        oldLevel: 2,
        newLevel: 3,
        reason: 'Route completed',
      );

      expect(result.didLevelUp, true);
      expect(result.oldLevel, 2);
      expect(result.newLevel, 3);
      expect(result.levelsGained, 1);
    });

    test('can gain multiple levels', () {
      final result = LevelUpResult.withLevelUp(
        xpGained: 1600,
        newTotalXP: 1600,
        oldLevel: 1,
        newLevel: 5,
      );

      expect(result.levelsGained, 4);
    });
  });

  group('LevelUpResult - bonuses tracking', () {
    test('hadBonuses is false when no bonuses', () {
      final result = LevelUpResult.noLevelUp(
        xpGained: 100,
        newTotalXP: 100,
        currentLevel: 1,
      );
      expect(result.hadBonuses, false);
    });

    test('hadBonuses is true when bonuses applied', () {
      final result = LevelUpResult.noLevelUp(
        xpGained: 150,
        newTotalXP: 150,
        currentLevel: 2,
        bonusesApplied: [XPBonus.firstTime()],
      );
      expect(result.hadBonuses, true);
    });

    test('sourceType defaults to other', () {
      final result = LevelUpResult.noLevelUp(
        xpGained: 100,
        newTotalXP: 100,
        currentLevel: 1,
      );
      expect(result.sourceType, XPSourceType.other);
    });

    test('sourceType can be set', () {
      final result = LevelUpResult.noLevelUp(
        xpGained: 100,
        newTotalXP: 100,
        currentLevel: 1,
        sourceType: XPSourceType.poiVisit,
      );
      expect(result.sourceType, XPSourceType.poiVisit);
    });
  });

  group('LevelUpResult - toMap / fromMap roundtrip', () {
    test('full roundtrip preserves all fields', () {
      final original = LevelUpResult.withLevelUp(
        xpGained: 150,
        newTotalXP: 400,
        oldLevel: 2,
        newLevel: 3,
        reason: 'Route Complete',
        sourceType: XPSourceType.routeComplete,
        bonusesApplied: [XPBonus.firstTime()],
      );

      final map = original.toMap();
      final restored = LevelUpResult.fromMap(map);

      expect(restored.xpGained, original.xpGained);
      expect(restored.newTotalXP, original.newTotalXP);
      expect(restored.oldLevel, original.oldLevel);
      expect(restored.newLevel, original.newLevel);
      expect(restored.didLevelUp, original.didLevelUp);
      expect(restored.reason, original.reason);
      expect(restored.sourceType, original.sourceType);
      expect(restored.bonusesApplied.length, 1);
    });

    test('fromMap handles unknown sourceType gracefully', () {
      final map = {
        'xpGained': 100,
        'newTotalXP': 100,
        'oldLevel': 1,
        'newLevel': 1,
        'didLevelUp': false,
        'sourceType': 'unknown_type',
      };

      final result = LevelUpResult.fromMap(map);
      expect(result.sourceType, XPSourceType.other);
    });
  });

  group('LevelUpResult - equality', () {
    test('same values are equal', () {
      final a = LevelUpResult.noLevelUp(
        xpGained: 100,
        newTotalXP: 200,
        currentLevel: 2,
      );
      final b = LevelUpResult.noLevelUp(
        xpGained: 100,
        newTotalXP: 200,
        currentLevel: 2,
      );
      expect(a, equals(b));
    });

    test('different XP gained are not equal', () {
      final a = LevelUpResult.noLevelUp(
        xpGained: 100,
        newTotalXP: 200,
        currentLevel: 2,
      );
      final b = LevelUpResult.noLevelUp(
        xpGained: 150,
        newTotalXP: 250,
        currentLevel: 2,
      );
      expect(a, isNot(equals(b)));
    });
  });

  // ============================================================
  // XPSourceType Tests
  // ============================================================
  group('XPSourceType', () {
    test('all source types have displayNames', () {
      for (final type in XPSourceType.values) {
        expect(type.displayName.isNotEmpty, true,
            reason: '${type.name} should have a displayName');
      }
    });

    test('expected source types exist', () {
      expect(XPSourceType.values.contains(XPSourceType.poiVisit), true);
      expect(XPSourceType.values.contains(XPSourceType.routeComplete), true);
      expect(XPSourceType.values.contains(XPSourceType.dailyLogin), true);
      expect(XPSourceType.values.contains(XPSourceType.photoUpload), true);
      expect(XPSourceType.values.contains(XPSourceType.socialShare), true);
      expect(XPSourceType.values.contains(XPSourceType.streak), true);
      expect(XPSourceType.values.contains(XPSourceType.specialEvent), true);
      expect(XPSourceType.values.contains(XPSourceType.other), true);
    });
  });
}
