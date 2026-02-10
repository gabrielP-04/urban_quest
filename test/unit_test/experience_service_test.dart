import 'package:flutter_test/flutter_test.dart';
import 'package:urban_quest/services/experience_service.dart';
import 'package:urban_quest/models/gamification_data.dart';
import 'package:urban_quest/models/level_up_result.dart';

void main() {
  // ============================================================
  // ExperienceService - XP Constants
  // ============================================================
  group('ExperienceService - XP constants are valid', () {
    test('POI visit XP is positive', () {
      expect(ExperienceService.XP_POI_VISIT, greaterThan(0));
    });

    test('Route complete XP is higher than POI visit', () {
      expect(ExperienceService.XP_ROUTE_COMPLETE,
          greaterThan(ExperienceService.XP_POI_VISIT));
    });

    test('Daily login XP is positive but small', () {
      expect(ExperienceService.XP_DAILY_LOGIN, greaterThan(0));
      expect(ExperienceService.XP_DAILY_LOGIN,
          lessThan(ExperienceService.XP_POI_VISIT));
    });

    test('Photo upload XP is positive', () {
      expect(ExperienceService.XP_PHOTO_UPLOAD, greaterThan(0));
    });

    test('Social share XP is positive', () {
      expect(ExperienceService.XP_SOCIAL_SHARE, greaterThan(0));
    });

    test('XP values match documented constants', () {
      expect(ExperienceService.XP_POI_VISIT, 100);
      expect(ExperienceService.XP_ROUTE_COMPLETE, 500);
      expect(ExperienceService.XP_DAILY_LOGIN, 20);
      expect(ExperienceService.XP_PHOTO_UPLOAD, 50);
      expect(ExperienceService.XP_SOCIAL_SHARE, 30);
    });
  });

  // ============================================================
  // ExperienceService - Multiplier Constants
  // ============================================================
  group('ExperienceService - multiplier constants', () {
    test('first time multiplier gives bonus', () {
      expect(ExperienceService.FIRST_TIME_MULTIPLIER, greaterThan(1.0));
      expect(ExperienceService.FIRST_TIME_MULTIPLIER, 1.5);
    });

    test('momentum multiplier gives bonus', () {
      expect(ExperienceService.MOMENTUM_MULTIPLIER, greaterThan(1.0));
    });

    test('special event multiplier gives bonus', () {
      expect(ExperienceService.SPECIAL_EVENT_MULTIPLIER, greaterThan(1.0));
    });
  });

  // ============================================================
  // XP Calculation Scenarios (Pure Logic)
  // These test the calculation logic without Firestore
  // ============================================================
  group('XP Calculation Scenarios', () {
    test('basic POI visit: 100 XP', () {
      const baseXP = ExperienceService.XP_POI_VISIT;
      expect(baseXP, 100);
    });

    test('first-time POI visit: 100 * 1.5 = 150 XP', () {
      const baseXP = ExperienceService.XP_POI_VISIT;
      final firstTimeBonus = XPBonus.firstTime();
      final finalXP = firstTimeBonus.apply(baseXP);
      expect(finalXP, 150);
    });

    test('POI visit with active momentum (1.2x): 100 * 1.2 = 120 XP', () {
      const baseXP = ExperienceService.XP_POI_VISIT;
      final momentumBonus = XPBonus(
        name: 'Momentum',
        value: 1.2,
        isMultiplier: true,
        description: 'Active momentum',
      );
      final finalXP = momentumBonus.apply(baseXP);
      expect(finalXP, 120);
    });

    test('first-time POI + active momentum: 100 → 150 → 180 XP', () {
      int xp = ExperienceService.XP_POI_VISIT; // 100
      xp = XPBonus.firstTime().apply(xp); // 150
      xp = XPBonus(
        name: 'Momentum',
        value: 1.2,
        isMultiplier: true,
        description: 'Momentum',
      ).apply(xp); // 180
      expect(xp, 180);
    });

    test('first-time POI + blazing momentum (1.6x): 100 → 150 → 240 XP', () {
      int xp = ExperienceService.XP_POI_VISIT; // 100
      xp = XPBonus.firstTime().apply(xp); // 150
      xp = XPBonus(
        name: 'Blazing',
        value: 1.6,
        isMultiplier: true,
        description: 'Blazing momentum',
      ).apply(xp); // 240
      expect(xp, 240);
    });

    test('route completion: 500 XP base', () {
      const baseXP = ExperienceService.XP_ROUTE_COMPLETE;
      expect(baseXP, 500);
    });

    test('first-time route completion: 500 * 1.5 = 750 XP', () {
      const baseXP = ExperienceService.XP_ROUTE_COMPLETE;
      final finalXP = XPBonus.firstTime().apply(baseXP);
      expect(finalXP, 750);
    });

    test('daily login XP is modest', () {
      expect(ExperienceService.XP_DAILY_LOGIN, 20);
    });
  });

  // ============================================================
  // Level-up Scenarios (Pure Calculation)
  // ============================================================
  group('Level-up Scenarios', () {
    test('user at 0 XP, gains 100 XP → reaches level 2', () {
      const currentXP = 0;
      const xpGain = 100;
      final newLevel = GamificationData.calculateLevel(currentXP + xpGain);
      expect(newLevel, 2);
    });

    test('user at 90 XP, gains 10 XP → reaches level 2', () {
      const currentXP = 90;
      const xpGain = 10;
      final newLevel = GamificationData.calculateLevel(currentXP + xpGain);
      expect(newLevel, 2);
    });

    test('user at 90 XP, gains 9 XP → stays level 1', () {
      const currentXP = 90;
      const xpGain = 9;
      final oldLevel = GamificationData.calculateLevel(currentXP);
      final newLevel = GamificationData.calculateLevel(currentXP + xpGain);
      expect(oldLevel, 1);
      expect(newLevel, 1);
    });

    test('user at 350 XP, gains 150 first-time POI XP → reaches level 3', () {
      const currentXP = 350;
      final xpGain = XPBonus.firstTime().apply(ExperienceService.XP_POI_VISIT);
      // 150 XP gained, total = 500 → level 3 (needs 400)
      final newLevel = GamificationData.calculateLevel(currentXP + xpGain);
      expect(newLevel, 3);
    });

    test('route completion can cause multi-level jump', () {
      const currentXP = 0;
      // First-time route with blazing momentum: 500 * 1.5 * 1.6 = 1200
      int xpGain = ExperienceService.XP_ROUTE_COMPLETE;
      xpGain = XPBonus.firstTime().apply(xpGain); // 750
      xpGain = XPBonus(
        name: 'Blazing',
        value: 1.6,
        isMultiplier: true,
        description: 'Blazing',
      ).apply(xpGain); // 1200

      final oldLevel = GamificationData.calculateLevel(currentXP);
      final newLevel = GamificationData.calculateLevel(currentXP + xpGain);
      expect(oldLevel, 1);
      expect(newLevel, greaterThan(2)); // Should jump multiple levels
    });
  });

  // ============================================================
  // Progression Balance Tests
  // ============================================================
  group('Progression Balance', () {
    test('reaching level 2 requires 1 first-time POI visit', () {
      // Level 2 needs 100 XP, first-time POI = 150 XP
      final xpFromFirstPOI = XPBonus.firstTime().apply(ExperienceService.XP_POI_VISIT);
      expect(xpFromFirstPOI, greaterThanOrEqualTo(
          GamificationData.xpRequiredForLevel(2)));
    });

    test('reaching level 5 requires reasonable effort', () {
      // Level 5 needs 1600 XP
      final xpNeeded = GamificationData.xpRequiredForLevel(5);
      // At 100 XP per POI visit, that's 16 visits minimum
      final minVisits = (xpNeeded / ExperienceService.XP_POI_VISIT).ceil();
      expect(minVisits, greaterThan(5));
      expect(minVisits, lessThan(50));
    });

    test('daily login alone progresses slowly', () {
      // How many daily logins to reach level 2?
      final xpForLevel2 = GamificationData.xpRequiredForLevel(2);
      final loginsNeeded = (xpForLevel2 / ExperienceService.XP_DAILY_LOGIN).ceil();
      // Should take at least 5 days of just logging in
      expect(loginsNeeded, greaterThanOrEqualTo(5));
    });
  });
}
