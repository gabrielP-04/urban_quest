import 'package:flutter_test/flutter_test.dart';
import 'package:urban_quest/services/momentum_service.dart';

void main() {
  // ============================================================
  // MomentumLevel Tests
  // ============================================================
  group('MomentumLevel', () {
    test('all levels have display names', () {
      for (final level in MomentumLevel.values) {
        expect(level.displayName.isNotEmpty, true,
            reason: '${level.name} should have a displayName');
      }
    });

    test('levels are ordered correctly', () {
      expect(MomentumLevel.none.index, lessThan(MomentumLevel.active.index));
      expect(MomentumLevel.active.index, lessThan(MomentumLevel.high.index));
      expect(MomentumLevel.high.index, lessThan(MomentumLevel.blazing.index));
    });

    test('active and above have fire icons', () {
      expect(MomentumLevel.none.icon, '');
      expect(MomentumLevel.active.icon, '🔥');
      expect(MomentumLevel.high.icon, '🔥🔥');
      expect(MomentumLevel.blazing.icon, '🔥🔥🔥');
    });
  });

  // ============================================================
  // MomentumState Tests
  // ============================================================
  group('MomentumState - inactive state', () {
    test('inactive state has correct defaults', () {
      final state = MomentumState(
        isActive: false,
        sessionPOIsVisited: 0,
        sessionDuration: Duration.zero,
        multiplier: 1.0,
        level: MomentumLevel.none,
      );

      expect(state.isActive, false);
      expect(state.multiplier, 1.0);
      expect(state.level, MomentumLevel.none);
    });

    test('statusMessage shows activation hint when inactive', () {
      final state = MomentumState(
        isActive: false,
        sessionPOIsVisited: 0,
        sessionDuration: Duration.zero,
        multiplier: 1.0,
        level: MomentumLevel.none,
      );

      expect(state.statusMessage,
          contains('${MomentumService.MIN_POIS_FOR_MOMENTUM}'));
    });
  });

  group('MomentumState - active states', () {
    test('active momentum at base level', () {
      final state = MomentumState(
        isActive: true,
        sessionPOIsVisited: 3,
        sessionDuration: const Duration(minutes: 30),
        multiplier: 1.2,
        level: MomentumLevel.active,
      );

      expect(state.isActive, true);
      expect(state.multiplier, 1.2);
      expect(state.level, MomentumLevel.active);
      expect(state.statusMessage, contains('Active'));
      expect(state.statusMessage, contains('20%'));
    });

    test('high momentum gives 40% bonus', () {
      final state = MomentumState(
        isActive: true,
        sessionPOIsVisited: 6,
        sessionDuration: const Duration(minutes: 60),
        multiplier: 1.4,
        level: MomentumLevel.high,
      );

      expect(state.multiplier, 1.4);
      expect(state.statusMessage, contains('40%'));
    });

    test('blazing momentum gives 60% bonus', () {
      final state = MomentumState(
        isActive: true,
        sessionPOIsVisited: 10,
        sessionDuration: const Duration(minutes: 90),
        multiplier: 1.6,
        level: MomentumLevel.blazing,
      );

      expect(state.multiplier, 1.6);
      expect(state.statusMessage, contains('60%'));
    });
  });

  group('MomentumState - poisToNextLevel', () {
    test('none level shows POIs needed to activate', () {
      final state = MomentumState(
        isActive: false,
        sessionPOIsVisited: 1,
        sessionDuration: Duration.zero,
        multiplier: 1.0,
        level: MomentumLevel.none,
      );

      expect(state.poisToNextLevel,
          MomentumService.MIN_POIS_FOR_MOMENTUM - 1);
    });

    test('active level shows POIs to high', () {
      final state = MomentumState(
        isActive: true,
        sessionPOIsVisited: 3,
        sessionDuration: const Duration(minutes: 20),
        multiplier: 1.2,
        level: MomentumLevel.active,
      );

      // Active → High requires 5 POIs
      expect(state.poisToNextLevel, 5 - 3);
    });

    test('high level shows POIs to blazing', () {
      final state = MomentumState(
        isActive: true,
        sessionPOIsVisited: 6,
        sessionDuration: const Duration(minutes: 40),
        multiplier: 1.4,
        level: MomentumLevel.high,
      );

      // High → Blazing requires 8 POIs
      expect(state.poisToNextLevel, 8 - 6);
    });

    test('blazing level returns 0 (max level)', () {
      final state = MomentumState(
        isActive: true,
        sessionPOIsVisited: 10,
        sessionDuration: const Duration(minutes: 60),
        multiplier: 1.6,
        level: MomentumLevel.blazing,
      );

      expect(state.poisToNextLevel, 0);
    });
  });

  group('MomentumState - toMap', () {
    test('toMap includes all fields', () {
      final state = MomentumState(
        isActive: true,
        sessionPOIsVisited: 5,
        sessionDuration: const Duration(minutes: 45),
        multiplier: 1.4,
        level: MomentumLevel.high,
      );

      final map = state.toMap();

      expect(map['isActive'], true);
      expect(map['sessionPOIsVisited'], 5);
      expect(map['sessionDurationMinutes'], 45);
      expect(map['multiplier'], 1.4);
      expect(map['level'], 'high');
      expect(map.containsKey('statusMessage'), true);
    });
  });

  group('MomentumState - toString', () {
    test('toString includes relevant info', () {
      final state = MomentumState(
        isActive: true,
        sessionPOIsVisited: 5,
        sessionDuration: const Duration(minutes: 30),
        multiplier: 1.4,
        level: MomentumLevel.high,
      );

      final str = state.toString();
      expect(str, contains('High Momentum'));
      expect(str, contains('5 POIs'));
      expect(str, contains('x1.4'));
    });
  });

  // ============================================================
  // SessionSummary Tests
  // ============================================================
  group('SessionSummary', () {
    test('creates summary with correct values', () {
      final summary = SessionSummary(
        poisVisited: 7,
        duration: const Duration(minutes: 60),
        xpEarned: 850,
        hadMomentum: true,
      );

      expect(summary.poisVisited, 7);
      expect(summary.duration.inMinutes, 60);
      expect(summary.xpEarned, 850);
      expect(summary.hadMomentum, true);
    });

    test('toString includes fire emoji when momentum was active', () {
      final summary = SessionSummary(
        poisVisited: 5,
        duration: const Duration(minutes: 30),
        xpEarned: 500,
        hadMomentum: true,
      );

      expect(summary.toString(), contains('🔥'));
    });

    test('toString has no fire emoji without momentum', () {
      final summary = SessionSummary(
        poisVisited: 2,
        duration: const Duration(minutes: 15),
        xpEarned: 200,
        hadMomentum: false,
      );

      expect(summary.toString(), isNot(contains('🔥')));
    });
  });

  // ============================================================
  // SessionStats Tests
  // ============================================================
  group('SessionStats - momentumRate', () {
    test('momentum rate is 0 when no sessions', () {
      final stats = SessionStats(
        totalSessions: 0,
        totalPOIsVisited: 0,
        averagePOIsPerSession: 0,
        averageSessionDuration: Duration.zero,
        sessionsWithMomentum: 0,
      );

      expect(stats.momentumRate, 0.0);
    });

    test('momentum rate is calculated correctly', () {
      final stats = SessionStats(
        totalSessions: 10,
        totalPOIsVisited: 50,
        averagePOIsPerSession: 5.0,
        averageSessionDuration: const Duration(minutes: 30),
        sessionsWithMomentum: 7,
      );

      expect(stats.momentumRate, closeTo(70.0, 0.1));
    });

    test('momentum rate is 1.0 when all sessions had momentum', () {
      final stats = SessionStats(
        totalSessions: 5,
        totalPOIsVisited: 25,
        averagePOIsPerSession: 5.0,
        averageSessionDuration: const Duration(minutes: 40),
        sessionsWithMomentum: 5,
      );

      expect(stats.momentumRate, 100.0);
    });
  });

  // ============================================================
  // Momentum Level Calculation Logic Tests
  // (Testing the private logic thresholds as documented)
  // ============================================================
  group('Momentum Level Thresholds', () {
    // These test the documented thresholds:
    // none: < MIN_POIS_FOR_MOMENTUM (3)
    // active: 3-4 POIs
    // high: 5-7 POIs
    // blazing: 8+ POIs

    test('MIN_POIS_FOR_MOMENTUM constant is 3', () {
      expect(MomentumService.MIN_POIS_FOR_MOMENTUM, 3);
    });

    test('SESSION_DURATION_HOURS constant is reasonable', () {
      // Session should last between 1 and 24 hours
      expect(MomentumService.SESSION_DURATION_HOURS, greaterThanOrEqualTo(1));
      expect(MomentumService.SESSION_DURATION_HOURS, lessThanOrEqualTo(24));
    });
  });
}