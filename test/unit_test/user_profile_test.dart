import 'package:flutter_test/flutter_test.dart';
import 'package:urban_quest/models/user_profile.dart';

void main() {
  // ============================================================
  // UserProfile - Creation and Defaults
  // ============================================================
  group('UserProfile - defaults', () {
    test('default values are set correctly', () {
      final profile = UserProfile(
        userId: 'uid_123',
        email: 'test@example.com',
        displayName: 'Test User',
        username: 'testuser',
        firstName: 'Test',
        lastName: 'User',
      );

      expect(profile.avatarId, 'avatar_1');
      expect(profile.bannerId, 'banner_1');
      expect(profile.profileTitle, 'Urban Explorer');
      expect(profile.experiencePoints, 0);
      expect(profile.visitedPoiIds, isEmpty);
      expect(profile.completedRouteIds, isEmpty);
      expect(profile.achievementIds, isEmpty);
    });

    test('createdAt and lastActive default to now', () {
      final before = DateTime.now();
      final profile = UserProfile(
        userId: 'uid_123',
        email: 'test@example.com',
        displayName: 'Test User',
        username: 'testuser',
        firstName: 'Test',
        lastName: 'User',
      );
      final after = DateTime.now();

      expect(profile.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), true);
      expect(profile.createdAt.isBefore(after.add(const Duration(seconds: 1))), true);
    });
  });

  // ============================================================
  // UserProfile - Firestore Serialization
  // ============================================================
  group('UserProfile - toFirestore / fromFirestore roundtrip', () {
    test('full roundtrip preserves all data', () {
      final original = UserProfile(
        userId: 'uid_456',
        email: 'user@urbanquest.com',
        displayName: 'Marco Rossi',
        username: 'marco_r',
        firstName: 'Marco',
        lastName: 'Rossi',
        avatarId: 'avatar_3',
        bannerId: 'banner_2',
        profileTitle: 'City Master',
        experiencePoints: 1500,
        visitedPoiIds: ['poi_1', 'poi_2', 'poi_3'],
        completedRouteIds: ['route_1'],
        achievementIds: ['ach_1', 'ach_2'],
        createdAt: DateTime(2026, 1, 1),
        lastActive: DateTime(2026, 2, 10),
      );

      final map = original.toFirestore();
      final restored = UserProfile.fromFirestore(map, 'uid_456');

      expect(restored.userId, original.userId);
      expect(restored.email, original.email);
      expect(restored.displayName, original.displayName);
      expect(restored.username, original.username);
      expect(restored.firstName, original.firstName);
      expect(restored.lastName, original.lastName);
      expect(restored.avatarId, original.avatarId);
      expect(restored.bannerId, original.bannerId);
      expect(restored.profileTitle, original.profileTitle);
      expect(restored.experiencePoints, original.experiencePoints);
      expect(restored.visitedPoiIds, original.visitedPoiIds);
      expect(restored.completedRouteIds, original.completedRouteIds);
      expect(restored.achievementIds, original.achievementIds);
      expect(restored.createdAt, original.createdAt);
      expect(restored.lastActive, original.lastActive);
    });

    test('fromFirestore handles missing optional fields with defaults', () {
      final map = {
        'email': 'test@test.com',
        'createdAt': '2026-01-01T00:00:00.000',
        'lastActive': '2026-02-10T00:00:00.000',
      };

      final profile = UserProfile.fromFirestore(map, 'uid_test');

      expect(profile.displayName, '');
      expect(profile.username, '');
      expect(profile.firstName, '');
      expect(profile.lastName, '');
      expect(profile.avatarId, 'avatar_1');
      expect(profile.bannerId, 'banner_1');
      expect(profile.profileTitle, 'Urban Explorer');
      expect(profile.experiencePoints, 0);
      expect(profile.visitedPoiIds, isEmpty);
      expect(profile.completedRouteIds, isEmpty);
      expect(profile.achievementIds, isEmpty);
    });
  });

  // ============================================================
  // UserProfile - Computed Properties
  // ============================================================
  group('UserProfile - computed stats', () {
    test('totalPoisVisited matches visitedPoiIds length', () {
      final profile = UserProfile(
        userId: 'uid',
        email: 'test@test.com',
        displayName: 'Test',
        username: 'test',
        firstName: 'Test',
        lastName: 'User',
        visitedPoiIds: ['poi_1', 'poi_2', 'poi_3'],
      );

      expect(profile.visitedPoiIds.length, 3);
    });

    test('totalRoutesCompleted matches completedRouteIds length', () {
      final profile = UserProfile(
        userId: 'uid',
        email: 'test@test.com',
        displayName: 'Test',
        username: 'test',
        firstName: 'Test',
        lastName: 'User',
        completedRouteIds: ['route_1', 'route_2'],
      );

      expect(profile.completedRouteIds.length, 2);
    });

    test('totalAchievements matches achievementIds length', () {
      final profile = UserProfile(
        userId: 'uid',
        email: 'test@test.com',
        displayName: 'Test',
        username: 'test',
        firstName: 'Test',
        lastName: 'User',
        achievementIds: ['ach_1'],
      );

      expect(profile.achievementIds.length, 1);
    });
  });

  // ============================================================
  // UserProfile - copyWith
  // ============================================================
  group('UserProfile - copyWith', () {
    final baseProfile = UserProfile(
      userId: 'uid_123',
      email: 'test@test.com',
      displayName: 'Test User',
      username: 'testuser',
      firstName: 'Test',
      lastName: 'User',
      experiencePoints: 500,
    );

    test('copyWith updates experience points', () {
      final updated = baseProfile.copyWith(experiencePoints: 1000);
      expect(updated.experiencePoints, 1000);
      expect(updated.email, baseProfile.email); // unchanged
    });

    test('copyWith updates avatar', () {
      final updated = baseProfile.copyWith(avatarId: 'avatar_5');
      expect(updated.avatarId, 'avatar_5');
      expect(updated.userId, baseProfile.userId); // unchanged
    });

    test('copyWith updates profile title', () {
      final updated = baseProfile.copyWith(profileTitle: 'City Master');
      expect(updated.profileTitle, 'City Master');
    });

    test('copyWith preserves all unchanged fields', () {
      final updated = baseProfile.copyWith(bannerId: 'banner_3');
      expect(updated.userId, baseProfile.userId);
      expect(updated.email, baseProfile.email);
      expect(updated.displayName, baseProfile.displayName);
      expect(updated.username, baseProfile.username);
      expect(updated.firstName, baseProfile.firstName);
      expect(updated.lastName, baseProfile.lastName);
      expect(updated.avatarId, baseProfile.avatarId);
      expect(updated.profileTitle, baseProfile.profileTitle);
      expect(updated.experiencePoints, baseProfile.experiencePoints);
      expect(updated.bannerId, 'banner_3'); // only this changed
    });
  });

  // ============================================================
  // UserProfile - toFirestore field completeness
  // ============================================================
  group('UserProfile - toFirestore completeness', () {
    test('toFirestore includes all expected fields', () {
      final profile = UserProfile(
        userId: 'uid',
        email: 'test@test.com',
        displayName: 'Test',
        username: 'test',
        firstName: 'First',
        lastName: 'Last',
      );

      final map = profile.toFirestore();

      expect(map.containsKey('email'), true);
      expect(map.containsKey('displayName'), true);
      expect(map.containsKey('username'), true);
      expect(map.containsKey('firstName'), true);
      expect(map.containsKey('lastName'), true);
      expect(map.containsKey('avatarId'), true);
      expect(map.containsKey('bannerId'), true);
      expect(map.containsKey('profileTitle'), true);
      expect(map.containsKey('experiencePoints'), true);
      expect(map.containsKey('visitedPoiIds'), true);
      expect(map.containsKey('completedRouteIds'), true);
      expect(map.containsKey('achievementIds'), true);
      expect(map.containsKey('createdAt'), true);
      expect(map.containsKey('lastActive'), true);
    });

    test('toFirestore does NOT include userId (stored as doc ID)', () {
      final profile = UserProfile(
        userId: 'uid',
        email: 'test@test.com',
        displayName: 'Test',
        username: 'test',
        firstName: 'First',
        lastName: 'Last',
      );

      final map = profile.toFirestore();
      expect(map.containsKey('userId'), false);
    });
  });
}
