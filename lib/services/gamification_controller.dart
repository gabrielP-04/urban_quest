import '../models/gamification_models.dart';
import 'experience_service.dart';
import 'momentum_service.dart';

/// Controlador principal que coordina todos los servicios de gamificación
/// Este es el punto de entrada recomendado para interactuar con el sistema
class GamificationController {
  final ExperienceService _experienceService;
  final MomentumService _momentumService;
  
  GamificationController({
    ExperienceService? experienceService,
    MomentumService? momentumService,
  })  : _experienceService = experienceService ?? ExperienceService(),
        _momentumService = momentumService ?? MomentumService();

  // ============ MÉTODOS DE ALTO NIVEL ============

  /// Procesa la visita de un usuario a un POI
  /// Maneja toda la lógica de gamificación relacionada
  Future<POIVisitResult> processPOIVisit({
    required String userId,
    required String poiId,
    required String poiName,
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

      // 3. Obtener información actualizada
      final gamificationData = await _experienceService.getUserGamificationData(userId);

      return POIVisitResult(
        xpResult: xpResult,
        gamificationData: gamificationData,
        momentumState: momentumState,
        isFirstVisit: isFirstVisit,
      );
    } catch (e) {
      throw Exception('Error al procesar visita a POI: $e');
    }
  }

  /// Procesa la finalización de una ruta
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

      // 3. Bonus adicional por número de POIs (opcional)
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

      return RouteCompletionResult(
        xpResult: xpResult,
        gamificationData: gamificationData,
        momentumState: momentumState,
        poisVisited: poisVisited,
        isFirstTime: isFirstTime,
      );
    } catch (e) {
      throw Exception('Error al procesar finalización de ruta: $e');
    }
  }

  /// Procesa el login diario del usuario (bonus simple)
  Future<DailyLoginResult> processDailyLogin({
    required String userId,
  }) async {
    try {
      // Otorgar XP por login diario
      final xpResult = await _experienceService.awardDailyLogin(
        userId: userId,
      );

      // Obtener información actualizada
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

  // ============ MÉTODOS DE CONSULTA ============

  /// Obtiene el dashboard completo de gamificación del usuario
  Future<GamificationDashboard> getUserDashboard(String userId) async {
    try {
      final gamificationData = await _experienceService.getUserGamificationData(userId);
      final momentumState = await _momentumService.getMomentumState(userId);
      final sessionStats = await _momentumService.getSessionStats(userId);
      final xpStats = await _experienceService.getXPStatsBySource(userId);
      
      // Calcular estadísticas adicionales
      final nextRewardLevel = LevelRewardsSystem.getNextRewardLevel(gamificationData.level);
      final nextRewards = nextRewardLevel != null
          ? LevelRewardsSystem.getRewardsForLevel(nextRewardLevel)
          : <LevelReward>[];

      return GamificationDashboard(
        gamificationData: gamificationData,
        momentumState: momentumState,
        sessionStats: sessionStats,
        xpStatsBySource: xpStats,
        nextRewardLevel: nextRewardLevel,
        nextRewards: nextRewards,
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

  // ============ ACCESO DIRECTO A SERVICIOS ============

  /// Acceso al servicio de experiencia para operaciones avanzadas
  ExperienceService get experienceService => _experienceService;

  /// Acceso al servicio de momentum para operaciones avanzadas
  MomentumService get momentumService => _momentumService;
}

// ============ MODELOS DE RESULTADO ============

/// Resultado de procesar una visita a POI
class POIVisitResult {
  final LevelUpResult xpResult;
  final GamificationData gamificationData;
  final MomentumState momentumState;
  final bool isFirstVisit;

  POIVisitResult({
    required this.xpResult,
    required this.gamificationData,
    required this.momentumState,
    required this.isFirstVisit,
  });

  bool get didLevelUp => xpResult.didLevelUp;
  int get xpGained => xpResult.xpGained;
  bool get hasMomentum => momentumState.isActive;
}

/// Resultado de completar una ruta
class RouteCompletionResult {
  final LevelUpResult xpResult;
  final GamificationData gamificationData;
  final MomentumState momentumState;
  final int poisVisited;
  final bool isFirstTime;

  RouteCompletionResult({
    required this.xpResult,
    required this.gamificationData,
    required this.momentumState,
    required this.poisVisited,
    required this.isFirstTime,
  });

  bool get didLevelUp => xpResult.didLevelUp;
  int get xpGained => xpResult.xpGained;
  bool get hasMomentum => momentumState.isActive;
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

/// Dashboard de gamificación
class GamificationDashboard {
  final GamificationData gamificationData;
  final MomentumState momentumState;
  final SessionStats sessionStats;
  final Map<XPSourceType, int> xpStatsBySource;
  final int? nextRewardLevel;
  final List<LevelReward> nextRewards;

  GamificationDashboard({
    required this.gamificationData,
    required this.momentumState,
    required this.sessionStats,
    required this.xpStatsBySource,
    this.nextRewardLevel,
    required this.nextRewards,
  });

  /// Total de XP ganada
  int get totalXP => gamificationData.experiencePoints;

  /// Nivel actual
  int get currentLevel => gamificationData.level;

  /// Sesiones completadas
  int get totalSessions => sessionStats.totalSessions;

  /// Progreso hacia el siguiente nivel (0.0 - 1.0)
  double get levelProgress => gamificationData.progressToNextLevel;

  /// XP obtenida por visitas a POIs
  int get xpFromPOIs => xpStatsBySource[XPSourceType.poiVisit] ?? 0;

  /// XP obtenida por completar rutas
  int get xpFromRoutes => xpStatsBySource[XPSourceType.routeComplete] ?? 0;

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

  /// XP restante para el siguiente nivel
  int get xpRemaining => xpNeeded - currentXP;

  /// Porcentaje de progreso (0-100)
  double get progressPercentage => progress * 100;

  @override
  String toString() {
    return 'LevelProgress(Level $currentLevel: $currentXP/$xpNeeded XP, ${progressPercentage.toStringAsFixed(1)}%)';
  }
}