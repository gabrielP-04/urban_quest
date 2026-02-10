import 'package:flutter/material.dart';
import '../models/gamification_models.dart';
import '../models/achievement.dart';
import 'experience_service.dart';
import 'momentum_service.dart';
import 'achievement_service.dart';
import '../services/poi_service.dart';

class GamificationController {
  final ExperienceService _experienceService;
  final MomentumService _momentumService;
  final AchievementService _achievementService;
  
  GamificationController({
    ExperienceService? experienceService,
    MomentumService? momentumService,
    AchievementService? achievementService,
  })  : _experienceService = experienceService ?? ExperienceService(),
        _momentumService = momentumService ?? MomentumService(),
        _achievementService = achievementService ?? AchievementService();

  Future<POIVisitResult> processPOIVisit({
    required String userId,
    required String poiId,
    required String poiName,
    String? poiCategory,
    bool isFirstVisit = true,
  }) async {
    try {
      
      final momentumState = await _momentumService.updateMomentum(userId);

      final xpResult = await _experienceService.awardPOIVisit(
        userId: userId,
        poiId: poiId,
        poiName: poiName,
        isFirstVisit: isFirstVisit,
        hasMomentum: momentumState.isActive,
        momentumMultiplier: momentumState.multiplier,
      );

      
      final gamificationData =
          await _experienceService.getUserGamificationData(userId);

      
      final userDoc = await _achievementService.firestore
          .collection('users')
          .doc(userId)
          .get();
      final userData = userDoc.data()!;

      final totalPois = (userData['visitedPoiIds'] as List?)?.length ?? 0;
      final totalRoutes =
          (userData['completedRouteIds'] as List?)?.length ?? 0;

      final categoryProgress = await _calculateCategoryProgress(userId);

      final newAchievements =
          await _achievementService.checkAndUnlockAchievements(
        userId: userId,
        totalPoisVisited: totalPois,
        totalRoutesCompleted: totalRoutes,
        currentLevel: gamificationData.level,
        categoryProgress: categoryProgress,
        momentumActivations:
            userData['totalMomentumActivations'] as int? ?? 0,
        hasReachedBlazingMomentum:
            userData['hasReachedBlazingMomentum'] as bool? ?? false,
      );

      return POIVisitResult(
        xpResult: xpResult,
        gamificationData: gamificationData,
        momentumState: momentumState,
        isFirstVisit: isFirstVisit,
        newAchievements: newAchievements,
      );
    } catch (e) {
      throw Exception('Error al procesar visita a POI: $e');
    }
  }

  Future<Map<String, int>> _calculateCategoryProgress(String userId) async {
    try {
      
      final userDoc = await _achievementService.firestore
          .collection('users')
          .doc(userId)
          .get();
      final visitedIds = List<String>.from(
        userDoc.data()?['visitedPoiIds'] as List? ?? [],
      );

      if (visitedIds.isEmpty) return {};

      
      final allPois = await PoiService.loadPois();

      
      final categoryCount = <String, int>{};
      for (final poi in allPois) {
        if (visitedIds.contains(poi.id)) {
          categoryCount[poi.category] =
              (categoryCount[poi.category] ?? 0) + 1;
        }
      }
 
      final mappedProgress = <String, int>{};

      
      mappedProgress['culture'] =
          (categoryCount['monument'] ?? 0) +
          (categoryCount['cultural'] ?? 0);

      
      mappedProgress['food'] = categoryCount['gastronomy'] ?? 0;

      mappedProgress.addAll(categoryCount);

      return mappedProgress;
    } catch (e) {
      debugPrint('Error calculating category progress: $e');
      return {};
    }
  }


  
  Future<RouteCompletionResult> processRouteCompletion({
    required String userId,
    required String routeId,
    required String routeName,
    required int poisVisited,
    bool isFirstTime = true,
  }) async {
    try {
      
      final momentumState = await _momentumService.getMomentumState(userId);
      
      final xpResult = await _experienceService.awardRouteCompletion(
        userId: userId,
        routeId: routeId,
        routeName: routeName,
        isFirstTime: isFirstTime,
        hasMomentum: momentumState.isActive,
        momentumMultiplier: momentumState.multiplier,
      );

      
      if (poisVisited >= 10) {
        await _experienceService.awardExperience(
          userId: userId,
          baseXP: 100,
          sourceType: XPSourceType.other,
          reason: 'Bonus: Long route completed',
        );
      }
  
      final gamificationData = await _experienceService.getUserGamificationData(userId);
        
      final userDoc = await _achievementService.firestore.collection('users').doc(userId).get();
      final userData = userDoc.data()!;
      
      final totalPois = (userData['visitedPoiIds'] as List?)?.length ?? 0;
      final totalRoutes = (userData['completedRouteIds'] as List?)?.length ?? 0;
      
      final newAchievements = await _achievementService.checkAndUnlockAchievements(
        userId: userId,
        totalPoisVisited: totalPois,
        totalRoutesCompleted: totalRoutes,
        currentLevel: gamificationData.level,
      );

      return RouteCompletionResult(
        xpResult: xpResult,
        gamificationData: gamificationData,
        momentumState: momentumState,
        poisVisited: poisVisited,
        isFirstTime: isFirstTime,
        newAchievements: newAchievements, 
      );
    } catch (e) {
      throw Exception('Error al procesar finalización de ruta: $e');
    }
  }
 
  Future<DailyLoginResult> processDailyLogin({
    required String userId,
  }) async {
    try {
      final xpResult = await _experienceService.awardDailyLogin(
        userId: userId,
      );

      final gamificationData = await _experienceService.getUserGamificationData(userId);
      final momentumState = await _momentumService.getMomentumState(userId);

      return DailyLoginResult(
        xpResult: xpResult,
        gamificationData: gamificationData,
        momentumState: momentumState,
      );
    } catch (e) {
      throw Exception('Error al procesar login diario: $e');
    }
  }
 
  Future<GamificationDashboard> getUserDashboard(String userId) async {
    try {
      final gamificationData =
          await _experienceService.getUserGamificationData(userId);
      final momentumState = await _momentumService.getMomentumState(userId);
      final sessionStats = await _momentumService.getSessionStats(userId);
      final xpStats = await _experienceService.getXPStatsBySource(userId);

      final nextRewardLevel =
          LevelRewardsSystem.getNextRewardLevel(gamificationData.level);
      final nextRewards = nextRewardLevel != null
          ? LevelRewardsSystem.getRewardsForLevel(nextRewardLevel)
          : <LevelReward>[];

      final userDoc = await _achievementService.firestore
          .collection('users')
          .doc(userId)
          .get();
      final userData = userDoc.data()!;
      final totalPois = (userData['visitedPoiIds'] as List?)?.length ?? 0;
      final totalRoutes =
          (userData['completedRouteIds'] as List?)?.length ?? 0;

      
      final categoryProgress = await _calculateCategoryProgress(userId);

      final achievementProgress =
          await _achievementService.getAchievementProgress(
        userId: userId,
        totalPoisVisited: totalPois,
        totalRoutesCompleted: totalRoutes,
        currentLevel: gamificationData.level,
        categoryProgress: categoryProgress, 
      );

      return GamificationDashboard(
        gamificationData: gamificationData,
        momentumState: momentumState,
        sessionStats: sessionStats,
        xpStatsBySource: xpStats,
        nextRewardLevel: nextRewardLevel,
        nextRewards: nextRewards,
        achievementProgress: achievementProgress,
      );
    } catch (e) {
      throw Exception('Error al obtener dashboard: $e');
    }
  }

  Future<LevelProgress> getLevelProgress(String userId) async {
    try {
      final gamificationData = await _experienceService.getUserGamificationData(userId);
      
      return LevelProgress(
        currentLevel: gamificationData.level,
        currentXP: gamificationData.currentLevelXP,
        xpNeeded: gamificationData.xpToNextLevel,
        progress: gamificationData.progressToNextLevel,
        totalXP: gamificationData.experiencePoints,
      );
    } catch (e) {
      throw Exception('Error al obtener progreso de nivel: $e');
    }
  }

  
  Future<List<AchievementProgress>> getAchievementProgress(String userId) async {
    try {
      final userDoc = await _achievementService.firestore.collection('users').doc(userId).get();
      final userData = userDoc.data()!;
      
      final totalPois = (userData['visitedPoiIds'] as List?)?.length ?? 0;
      final totalRoutes = (userData['completedRouteIds'] as List?)?.length ?? 0;
      final gamificationData = await _experienceService.getUserGamificationData(userId);
      
      return await _achievementService.getAchievementProgress(
        userId: userId,
        totalPoisVisited: totalPois,
        totalRoutesCompleted: totalRoutes,
        currentLevel: gamificationData.level,
      );
    } catch (e) {
      throw Exception('Error al obtener progreso de achievements: $e');
    }
  }

  
  Future<List<Achievement>> getUnlockedAchievements(String userId) async {
    return await _achievementService.getUnlockedAchievements(userId);
  }

  

  ExperienceService get experienceService => _experienceService;
  MomentumService get momentumService => _momentumService;
  AchievementService get achievementService => _achievementService; 
}

class POIVisitResult {
  final LevelUpResult xpResult;
  final GamificationData gamificationData;
  final MomentumState momentumState;
  final bool isFirstVisit;
  final List<Achievement> newAchievements; 

  POIVisitResult({
    required this.xpResult,
    required this.gamificationData,
    required this.momentumState,
    required this.isFirstVisit,
    this.newAchievements = const [], 
  });

  bool get didLevelUp => xpResult.didLevelUp;
  int get xpGained => xpResult.xpGained;
  bool get hasMomentum => momentumState.isActive;
  bool get hasNewAchievements => newAchievements.isNotEmpty; 
}


class RouteCompletionResult {
  final LevelUpResult xpResult;
  final GamificationData gamificationData;
  final MomentumState momentumState;
  final int poisVisited;
  final bool isFirstTime;
  final List<Achievement> newAchievements; 

  RouteCompletionResult({
    required this.xpResult,
    required this.gamificationData,
    required this.momentumState,
    required this.poisVisited,
    required this.isFirstTime,
    this.newAchievements = const [], 
  });

  bool get didLevelUp => xpResult.didLevelUp;
  int get xpGained => xpResult.xpGained;
  bool get hasMomentum => momentumState.isActive;
  bool get hasNewAchievements => newAchievements.isNotEmpty; 
}


class DailyLoginResult {
  final LevelUpResult xpResult;
  final GamificationData gamificationData;
  final MomentumState momentumState;

  DailyLoginResult({
    required this.xpResult,
    required this.gamificationData,
    required this.momentumState,
  });

  bool get didLevelUp => xpResult.didLevelUp;
  int get xpGained => xpResult.xpGained;
}


class GamificationDashboard {
  final GamificationData gamificationData;
  final MomentumState momentumState;
  final SessionStats sessionStats;
  final Map<XPSourceType, int> xpStatsBySource;
  final int? nextRewardLevel;
  final List<LevelReward> nextRewards;
  final List<AchievementProgress> achievementProgress; 

  GamificationDashboard({
    required this.gamificationData,
    required this.momentumState,
    required this.sessionStats,
    required this.xpStatsBySource,
    this.nextRewardLevel,
    required this.nextRewards,
    this.achievementProgress = const [], 
  });

  int get totalXP => gamificationData.experiencePoints;
  int get currentLevel => gamificationData.level;
  int get totalSessions => sessionStats.totalSessions;
  double get levelProgress => gamificationData.progressToNextLevel;
  int get xpFromPOIs => xpStatsBySource[XPSourceType.poiVisit] ?? 0;
  int get xpFromRoutes => xpStatsBySource[XPSourceType.routeComplete] ?? 0;
  
  
  int get totalAchievements => achievementProgress.length;
  int get unlockedAchievements => achievementProgress.where((a) => a.isUnlocked).length;
  double get achievementCompletionRate {
    if (totalAchievements == 0) return 0.0;
    return unlockedAchievements / totalAchievements;
  }

  Map<String, dynamic> toMap() {
    return {
      'totalXP': totalXP,
      'currentLevel': currentLevel,
      'totalSessions': totalSessions,
      'levelProgress': levelProgress,
      'xpFromPOIs': xpFromPOIs,
      'xpFromRoutes': xpFromRoutes,
      'nextRewardLevel': nextRewardLevel,
      'momentumState': momentumState.toMap(),
      'sessionStats': sessionStats.toMap(),
      'totalAchievements': totalAchievements,
      'unlockedAchievements': unlockedAchievements,
      'achievementCompletionRate': achievementCompletionRate,
    };
  }
}


class LevelProgress {
  final int currentLevel;
  final int currentXP;
  final int xpNeeded;
  final double progress;
  final int totalXP;

  LevelProgress({
    required this.currentLevel,
    required this.currentXP,
    required this.xpNeeded,
    required this.progress,
    required this.totalXP,
  });

  int get xpRemaining => xpNeeded - currentXP;
  double get progressPercentage => progress * 100;

  @override
  String toString() {
    return 'LevelProgress(Level $currentLevel: $currentXP/$xpNeeded XP, ${progressPercentage.toStringAsFixed(1)}%)';
  }
}