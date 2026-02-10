import 'package:flutter/material.dart';

import '../models/gamification_models.dart';
import '../models/achievement.dart';
import 'experience_service.dart';
import 'momentum_service.dart';
import 'achievement_service.dart';
import '../services/poi_service.dart';

/// Controlador principal que coordina todos los servicios de gamificación
/// Versión extendida con soporte para Achievements
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

  // ============ MÉTODOS DE ALTO NIVEL CON ACHIEVEMENTS ============

  /// Procesa la visita de un usuario a un POI (con achievements)
  /// Maneja toda la lógica de gamificación relacionada
  Future<POIVisitResult> processPOIVisit({
    required String userId,
    required String poiId,
    required String poiName,
    String? poiCategory,
    bool isFirstVisit = true,
  }) async {
    try {
      // 1. Actualizar momentum
      final momentumState = await _momentumService.updateMomentum(userId);

      // 2. Otorgar experiencia por la visita
      final xpResult = await _experienceService.awardPOIVisit(
        userId: userId,
        poiId: poiId,
        poiName: poiName,
        isFirstVisit: isFirstVisit,
        hasMomentum: momentumState.isActive,
        momentumMultiplier: momentumState.multiplier,
      );

      // 3. Obtener información actualizada del usuario
      final gamificationData =
          await _experienceService.getUserGamificationData(userId);

      // 4. Verificar achievements desbloqueados
      final userDoc = await _achievementService.firestore
          .collection('users')
          .doc(userId)
          .get();
      final userData = userDoc.data()!;

      final totalPois = (userData['visitedPoiIds'] as List?)?.length ?? 0;
      final totalRoutes =
          (userData['completedRouteIds'] as List?)?.length ?? 0;

      // =====================================================
      // FIX: Calculate REAL category progress from ALL visited POIs
      // =====================================================
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

/// Calculates the real category progress by cross-referencing
  /// the user's visitedPoiIds with the local POI data (pois.json).
  Future<Map<String, int>> _calculateCategoryProgress(String userId) async {
    try {
      // 1. Get user's visited POI IDs from Firestore
      final userDoc = await _achievementService.firestore
          .collection('users')
          .doc(userId)
          .get();
      final visitedIds = List<String>.from(
        userDoc.data()?['visitedPoiIds'] as List? ?? [],
      );

      if (visitedIds.isEmpty) return {};

      // 2. Load all POIs from local JSON to get their categories
      final allPois = await PoiService.loadPois();

      // 3. Count visited POIs per category
      final categoryCount = <String, int>{};
      for (final poi in allPois) {
        if (visitedIds.contains(poi.id)) {
          categoryCount[poi.category] =
              (categoryCount[poi.category] ?? 0) + 1;
        }
      }

      // 4. Map POI categories to achievement categories
      //    POI categories: "monument", "gastronomy", "cultural", "viewpoint"
      //    Achievement expects: "culture", "food"
      final mappedProgress = <String, int>{};

      // Culture achievements: count "monument" + "cultural" POIs
      mappedProgress['culture'] =
          (categoryCount['monument'] ?? 0) +
          (categoryCount['cultural'] ?? 0);

      // Food achievements: count "gastronomy" POIs
      mappedProgress['food'] = categoryCount['gastronomy'] ?? 0;

      // Also pass the raw categories in case you add more achievements later
      mappedProgress.addAll(categoryCount);

      return mappedProgress;
    } catch (e) {
      debugPrint('Error calculating category progress: $e');
      return {};
    }
  }


  /// Procesa la finalización de una ruta (con achievements)
  Future<RouteCompletionResult> processRouteCompletion({
    required String userId,
    required String routeId,
    required String routeName,
    required int poisVisited,
    bool isFirstTime = true,
  }) async {
    try {
      // 1. Obtener estado de momentum
      final momentumState = await _momentumService.getMomentumState(userId);
      
      // 2. Otorgar XP por completar la ruta
      final xpResult = await _experienceService.awardRouteCompletion(
        userId: userId,
        routeId: routeId,
        routeName: routeName,
        isFirstTime: isFirstTime,
        hasMomentum: momentumState.isActive,
        momentumMultiplier: momentumState.multiplier,
      );

      // 3. Bonus adicional por número de POIs
      if (poisVisited >= 10) {
        await _experienceService.awardExperience(
          userId: userId,
          baseXP: 100,
          sourceType: XPSourceType.other,
          reason: 'Bonus: Long route completed',
        );
      }

      // 4. Obtener información actualizada
      final gamificationData = await _experienceService.getUserGamificationData(userId);
      
      // 5. NUEVO: Verificar achievements
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
        newAchievements: newAchievements, // NUEVO
      );
    } catch (e) {
      throw Exception('Error al procesar finalización de ruta: $e');
    }
  }

  /// Procesa el login diario del usuario
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

  // ============ MÉTODOS DE CONSULTA CON ACHIEVEMENTS ============

  /// Obtiene el dashboard completo de gamificación del usuario (con achievements)
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

      // FIX: Use real category progress
      final categoryProgress = await _calculateCategoryProgress(userId);

      final achievementProgress =
          await _achievementService.getAchievementProgress(
        userId: userId,
        totalPoisVisited: totalPois,
        totalRoutesCompleted: totalRoutes,
        currentLevel: gamificationData.level,
        categoryProgress: categoryProgress, // ← NOW PASSES REAL DATA
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






  /// Verifica el progreso hacia el siguiente nivel
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

  /// NUEVO: Obtiene el progreso de achievements
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

  /// NUEVO: Obtiene solo achievements desbloqueados
  Future<List<Achievement>> getUnlockedAchievements(String userId) async {
    return await _achievementService.getUnlockedAchievements(userId);
  }

  // ============ ACCESO DIRECTO A SERVICIOS ============

  ExperienceService get experienceService => _experienceService;
  MomentumService get momentumService => _momentumService;
  AchievementService get achievementService => _achievementService; // NUEVO
}

// ============ MODELOS DE RESULTADO EXTENDIDOS ============

/// Resultado de procesar una visita a POI (CON ACHIEVEMENTS)
class POIVisitResult {
  final LevelUpResult xpResult;
  final GamificationData gamificationData;
  final MomentumState momentumState;
  final bool isFirstVisit;
  final List<Achievement> newAchievements; // NUEVO

  POIVisitResult({
    required this.xpResult,
    required this.gamificationData,
    required this.momentumState,
    required this.isFirstVisit,
    this.newAchievements = const [], // NUEVO
  });

  bool get didLevelUp => xpResult.didLevelUp;
  int get xpGained => xpResult.xpGained;
  bool get hasMomentum => momentumState.isActive;
  bool get hasNewAchievements => newAchievements.isNotEmpty; // NUEVO
}

/// Resultado de completar una ruta (CON ACHIEVEMENTS)
class RouteCompletionResult {
  final LevelUpResult xpResult;
  final GamificationData gamificationData;
  final MomentumState momentumState;
  final int poisVisited;
  final bool isFirstTime;
  final List<Achievement> newAchievements; // NUEVO

  RouteCompletionResult({
    required this.xpResult,
    required this.gamificationData,
    required this.momentumState,
    required this.poisVisited,
    required this.isFirstTime,
    this.newAchievements = const [], // NUEVO
  });

  bool get didLevelUp => xpResult.didLevelUp;
  int get xpGained => xpResult.xpGained;
  bool get hasMomentum => momentumState.isActive;
  bool get hasNewAchievements => newAchievements.isNotEmpty; // NUEVO
}

/// Resultado de login diario
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

/// Dashboard de gamificación (CON ACHIEVEMENTS)
class GamificationDashboard {
  final GamificationData gamificationData;
  final MomentumState momentumState;
  final SessionStats sessionStats;
  final Map<XPSourceType, int> xpStatsBySource;
  final int? nextRewardLevel;
  final List<LevelReward> nextRewards;
  final List<AchievementProgress> achievementProgress; // NUEVO

  GamificationDashboard({
    required this.gamificationData,
    required this.momentumState,
    required this.sessionStats,
    required this.xpStatsBySource,
    this.nextRewardLevel,
    required this.nextRewards,
    this.achievementProgress = const [], // NUEVO
  });

  int get totalXP => gamificationData.experiencePoints;
  int get currentLevel => gamificationData.level;
  int get totalSessions => sessionStats.totalSessions;
  double get levelProgress => gamificationData.progressToNextLevel;
  int get xpFromPOIs => xpStatsBySource[XPSourceType.poiVisit] ?? 0;
  int get xpFromRoutes => xpStatsBySource[XPSourceType.routeComplete] ?? 0;
  
  // NUEVO: Estadísticas de achievements
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

/// Progreso hacia el siguiente nivel
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