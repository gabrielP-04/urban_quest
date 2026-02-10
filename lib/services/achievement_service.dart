import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/achievement.dart';

class AchievementService {
  final FirebaseFirestore firestore;

  AchievementService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  static List<Achievement> getAllAchievements() {
    return [
      const Achievement(
        id: 'first_visit',
        title: 'First Steps',
        description: 'Visit your first point of interest',
        emoji: '👣',
        category: AchievementCategory.exploration,
        requiredProgress: 1,
        xpReward: 50,
        rarity: AchievementRarity.common,
      ),
      const Achievement(
        id: 'visit_5_pois',
        title: 'Explorer',
        description: 'Visit 5 different places',
        emoji: '🗺️',
        category: AchievementCategory.exploration,
        requiredProgress: 5,
        xpReward: 150,
        rarity: AchievementRarity.common,
      ),
      const Achievement(
        id: 'visit_10_pois',
        title: 'City Expert',
        description: 'Visit 10 different places',
        emoji: '🏆',
        category: AchievementCategory.exploration,
        requiredProgress: 10,
        xpReward: 300,
        rarity: AchievementRarity.rare,
      ),
      const Achievement(
        id: 'visit_25_pois',
        title: 'Urban Master',
        description: 'Visit 25 different places',
        emoji: '👑',
        category: AchievementCategory.exploration,
        requiredProgress: 25,
        xpReward: 750,
        rarity: AchievementRarity.epic,
      ),
      const Achievement(
        id: 'visit_50_pois',
        title: 'Legend of Milan',
        description: 'Visit 50 different places',
        emoji: '🌟',
        category: AchievementCategory.exploration,
        requiredProgress: 50,
        xpReward: 2000,
        rarity: AchievementRarity.legendary,
      ),
      const Achievement(
        id: 'culture_5',
        title: 'Culture Lover',
        description: 'Visit 5 cultural monuments',
        emoji: '🏛️',
        category: AchievementCategory.culture,
        requiredProgress: 5,
        xpReward: 200,
        rarity: AchievementRarity.rare,
      ),
      const Achievement(
        id: 'culture_10',
        title: 'Historian',
        description: 'Visit 10 cultural monuments',
        emoji: '📚',
        category: AchievementCategory.culture,
        requiredProgress: 10,
        xpReward: 500,
        rarity: AchievementRarity.epic,
      ),
      const Achievement(
        id: 'food_5',
        title: 'Foodie',
        description: 'Discover 5 gastronomic places',
        emoji: '🍕',
        category: AchievementCategory.food,
        requiredProgress: 5,
        xpReward: 200,
        rarity: AchievementRarity.rare,
      ),
      const Achievement(
        id: 'food_10',
        title: 'Gourmet',
        description: 'Discover 10 gastronomic places',
        emoji: '⭐',
        category: AchievementCategory.food,
        requiredProgress: 10,
        xpReward: 500,
        rarity: AchievementRarity.epic,
      ),
      const Achievement(
        id: 'first_route',
        title: 'Route Starter',
        description: 'Complete your first route',
        emoji: '🚶',
        category: AchievementCategory.routes,
        requiredProgress: 1,
        xpReward: 250,
        rarity: AchievementRarity.common,
      ),
      const Achievement(
        id: 'complete_5_routes',
        title: 'Navigator',
        description: 'Complete 5 routes',
        emoji: '🧭',
        category: AchievementCategory.routes,
        requiredProgress: 5,
        xpReward: 750,
        rarity: AchievementRarity.rare,
      ),
      const Achievement(
        id: 'complete_10_routes',
        title: 'Path Master',
        description: 'Complete 10 routes',
        emoji: '🗺️',
        category: AchievementCategory.routes,
        requiredProgress: 10,
        xpReward: 1500,
        rarity: AchievementRarity.epic,
      ),
      const Achievement(
        id: 'reach_level_5',
        title: 'Rising Star',
        description: 'Reach level 5',
        emoji: '⭐',
        category: AchievementCategory.social,
        requiredProgress: 5,
        xpReward: 100,
        rarity: AchievementRarity.common,
      ),
      const Achievement(
        id: 'reach_level_10',
        title: 'Elite Explorer',
        description: 'Reach level 10',
        emoji: '💎',
        category: AchievementCategory.social,
        requiredProgress: 10,
        xpReward: 500,
        rarity: AchievementRarity.rare,
      ),
      const Achievement(
        id: 'reach_level_20',
        title: 'Champion',
        description: 'Reach level 20',
        emoji: '🏅',
        category: AchievementCategory.social,
        requiredProgress: 20,
        xpReward: 1000,
        rarity: AchievementRarity.epic,
      ),
      const Achievement(
        id: 'momentum_master',
        title: 'Momentum Master',
        description: 'Activate momentum 10 times',
        emoji: '🔥',
        category: AchievementCategory.special,
        requiredProgress: 10,
        xpReward: 400,
        rarity: AchievementRarity.rare,
      ),
      const Achievement(
        id: 'blazing_explorer',
        title: 'Blazing Explorer',
        description: 'Reach Blazing momentum level',
        emoji: '🔥🔥🔥',
        category: AchievementCategory.special,
        requiredProgress: 1,
        xpReward: 500,
        rarity: AchievementRarity.epic,
      ),
    ];
  }

  Future<List<Achievement>> checkAndUnlockAchievements({
    required String userId,
    required int totalPoisVisited,
    required int totalRoutesCompleted,
    required int currentLevel,
    Map<String, int>? categoryProgress,
    int? momentumActivations,
    bool? hasReachedBlazingMomentum,
    int? photosUploaded,
    int? socialShares,
  }) async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado: $userId');
      }

      final userData = userDoc.data()!;
      final currentAchievements = List<String>.from(
        userData['achievementIds'] as List? ?? [],
      );

      final newlyUnlocked = <Achievement>[];
      final allAchievements = getAllAchievements();

      for (final achievement in allAchievements) {
        if (currentAchievements.contains(achievement.id)) continue;

        final currentProgress = _calculateProgress(
          achievement,
          totalPoisVisited: totalPoisVisited,
          totalRoutesCompleted: totalRoutesCompleted,
          currentLevel: currentLevel,
          categoryProgress: categoryProgress,
          momentumActivations: momentumActivations,
          hasReachedBlazingMomentum: hasReachedBlazingMomentum,
          photosUploaded: photosUploaded,
          socialShares: socialShares,
        );

        if (currentProgress >= achievement.requiredProgress) {
          newlyUnlocked.add(achievement);
        }
      }

      if (newlyUnlocked.isNotEmpty) {
        await _unlockAchievements(userId, newlyUnlocked, currentAchievements);
      }

      return newlyUnlocked;
    } catch (e) {
      debugPrint('Error al verificar achievements: $e');
      return [];
    }
  }

  Future<List<AchievementProgress>> getAchievementProgress({
    required String userId,
    required int totalPoisVisited,
    required int totalRoutesCompleted,
    required int currentLevel,
    Map<String, int>? categoryProgress,
    int? momentumActivations,
    bool? hasReachedBlazingMomentum,
    int? photosUploaded,
    int? socialShares,
  }) async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return [];
      }

      final userData = userDoc.data()!;
      final unlockedIds = List<String>.from(
        userData['achievementIds'] as List? ?? [],
      );

      final allAchievements = getAllAchievements();

      return allAchievements.map((achievement) {
        final isUnlocked = unlockedIds.contains(achievement.id);
        final currentProgress = _calculateProgress(
          achievement,
          totalPoisVisited: totalPoisVisited,
          totalRoutesCompleted: totalRoutesCompleted,
          currentLevel: currentLevel,
          categoryProgress: categoryProgress,
          momentumActivations: momentumActivations,
          hasReachedBlazingMomentum: hasReachedBlazingMomentum,
          photosUploaded: photosUploaded,
          socialShares: socialShares,
        );

        return AchievementProgress(
          achievement: achievement,
          currentProgress: currentProgress,
          isUnlocked: isUnlocked,
          unlockedAt: isUnlocked ? DateTime.now() : null,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error al obtener progreso de achievements: $e');
      return [];
    }
  }

  Future<List<Achievement>> getUnlockedAchievements(String userId) async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return [];

      final userData = userDoc.data()!;
      final unlockedIds = List<String>.from(
        userData['achievementIds'] as List? ?? [],
      );

      return getAllAchievements()
          .where((a) => unlockedIds.contains(a.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  int _calculateProgress(
    Achievement achievement, {
    required int totalPoisVisited,
    required int totalRoutesCompleted,
    required int currentLevel,
    Map<String, int>? categoryProgress,
    int? momentumActivations,
    bool? hasReachedBlazingMomentum,
    int? photosUploaded,
    int? socialShares,
  }) {
    switch (achievement.category) {
      case AchievementCategory.exploration:
        return totalPoisVisited;

      case AchievementCategory.culture:
        return categoryProgress?['culture'] ?? 0;

      case AchievementCategory.food:
        return categoryProgress?['food'] ?? 0;

      case AchievementCategory.routes:
        return totalRoutesCompleted;

      case AchievementCategory.social:
        return currentLevel;

      case AchievementCategory.special:
        if (achievement.id == 'momentum_master') {
          return momentumActivations ?? 0;
        }
        if (achievement.id == 'blazing_explorer') {
          return (hasReachedBlazingMomentum ?? false) ? 1 : 0;
        }
        if (achievement.id == 'photo_enthusiast') {
          return photosUploaded ?? 0;
        }
        if (achievement.id == 'social_butterfly') {
          return socialShares ?? 0;
        }
        return 0;
    }
  }

  Future<void> _unlockAchievements(
    String userId,
    List<Achievement> achievements,
    List<String> currentAchievements,
  ) async {
    try {
      final newIds = [
        ...currentAchievements,
        ...achievements.map((a) => a.id),
      ];

      final totalXPReward = achievements.fold<int>(
        0,
        (sum, achievement) => sum + achievement.xpReward,
      );

      await firestore.runTransaction((transaction) async {
        final userRef = firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) return;

        final userData = userDoc.data()!;
        final currentXP = userData['experiencePoints'] as int? ?? 0;

        transaction.update(userRef, {
          'achievementIds': newIds,
          'experiencePoints': currentXP + totalXPReward,
        });

        for (final achievement in achievements) {
          transaction.set(
            userRef.collection('unlocked_achievements').doc(achievement.id),
            {
              'achievementId': achievement.id,
              'unlockedAt': FieldValue.serverTimestamp(),
              'xpRewarded': achievement.xpReward,
            },
          );
        }
      });

      debugPrint('✨ Desbloqueados ${achievements.length} achievements!');
      debugPrint('💰 +$totalXPReward XP por achievements');
    } catch (e) {
      debugPrint('Error al desbloquear achievements: $e');
    }
  }
}