import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gamification_models.dart';

/// Servicio que gestiona la experiencia, niveles y recompensas
/// Este es el punto central para todo lo relacionado con gamificación
class ExperienceService {
  final FirebaseFirestore _firestore;
  
  ExperienceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ============ CONSTANTES DE XP ============
  
  /// XP base por visitar un POI
  static const int XP_POI_VISIT = 100;
  
  /// XP base por completar una ruta
  static const int XP_ROUTE_COMPLETE = 500;
  
  /// XP base por login diario
  static const int XP_DAILY_LOGIN = 20;
  
  /// XP por subir una foto
  static const int XP_PHOTO_UPLOAD = 50;
  
  /// XP por compartir en redes sociales
  static const int XP_SOCIAL_SHARE = 30;

  // ============ MULTIPLICADORES ============
  
  /// Bonus por primera vez (+50%)
  static const double FIRST_TIME_MULTIPLIER = 1.5;
  
  /// Bonus por momentum activo (variable según nivel)
  static const double MOMENTUM_MULTIPLIER = 1.3;
  
  /// Bonus por evento especial (variable)
  static const double SPECIAL_EVENT_MULTIPLIER = 1.3;

  // ============ MÉTODOS PRINCIPALES ============

  /// Otorga experiencia a un usuario y detecta level-ups
  /// 
  /// [userId] - ID del usuario en Firestore
  /// [baseXP] - Cantidad base de XP a otorgar
  /// [sourceType] - Tipo de actividad que genera el XP
  /// [reason] - Descripción de por qué se otorga el XP
  /// [isFirstTime] - Si es la primera vez que realiza esta acción
  /// [hasMomentum] - Si el usuario tiene momentum activo
  /// [momentumMultiplier] - Multiplicador del momentum (default 1.0)
  /// [additionalBonuses] - Bonificaciones adicionales a aplicar
  /// 
  /// Retorna un [LevelUpResult] con la información del resultado
  Future<LevelUpResult> awardExperience({
    required String userId,
    required int baseXP,
    required XPSourceType sourceType,
    String? reason,
    bool isFirstTime = false,
    bool hasMomentum = false,
    double momentumMultiplier = 1.0,
    List<XPBonus>? additionalBonuses,
  }) async {
    try {
      // 1. Obtener datos actuales del usuario
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado: $userId');
      }
      
      final userData = userDoc.data()!;
      final currentXP = userData['experiencePoints'] as int? ?? 0;
      final currentLevel = GamificationData.calculateLevel(currentXP);

      // 2. Calcular XP con bonificaciones
      final bonuses = <XPBonus>[];
      int finalXP = baseXP;
      
      // Aplicar bonus de primera vez
      if (isFirstTime) {
        final bonus = XPBonus.firstTime();
        finalXP = bonus.apply(finalXP);
        bonuses.add(bonus);
      }
      
      // Aplicar bonus de momentum
      if (hasMomentum && momentumMultiplier > 1.0) {
        final bonus = XPBonus(
          name: 'Momentum',
          value: momentumMultiplier,
          isMultiplier: true,
          description: 'Exploration momentum: +${((momentumMultiplier - 1) * 100).toInt()}%',
        );
        finalXP = bonus.apply(finalXP);
        bonuses.add(bonus);
      }
      
      // Aplicar bonificaciones adicionales
      if (additionalBonuses != null) {
        for (var bonus in additionalBonuses) {
          finalXP = bonus.apply(finalXP);
          bonuses.add(bonus);
        }
      }

      // 3. Calcular nuevo nivel
      final newXP = currentXP + finalXP;
      final newLevel = GamificationData.calculateLevel(newXP);
      final didLevelUp = newLevel > currentLevel;

      // 4. Preparar datos para actualizar
      final updateData = {
        'experiencePoints': newXP,
        'lastXPGain': {
          'amount': finalXP,
          'baseAmount': baseXP,
          'reason': reason ?? sourceType.displayName,
          'sourceType': sourceType.name,
          'timestamp': FieldValue.serverTimestamp(),
          'bonuses': bonuses.map((b) => b.toMap()).toList(),
        },
      };

      // Si hubo level-up, actualizar el nivel también
      if (didLevelUp) {
        updateData['level'] = newLevel;
        updateData['lastLevelUpDate'] = FieldValue.serverTimestamp();
      }

      // 5. Actualizar en Firestore
      await _firestore.collection('users').doc(userId).update(updateData);

      // 6. Si hubo level-up, otorgar recompensas
      if (didLevelUp) {
        await _grantLevelRewards(userId, currentLevel, newLevel);
      }

      // 7. Registrar actividad en historial (opcional)
      await _logXPActivity(userId, finalXP, sourceType, reason);

      // 8. Crear y retornar resultado
      final result = didLevelUp
          ? LevelUpResult.withLevelUp(
              xpGained: finalXP,
              newTotalXP: newXP,
              oldLevel: currentLevel,
              newLevel: newLevel,
              reason: reason,
              sourceType: sourceType,
              bonusesApplied: bonuses,
            )
          : LevelUpResult.noLevelUp(
              xpGained: finalXP,
              newTotalXP: newXP,
              currentLevel: currentLevel,
              reason: reason,
              sourceType: sourceType,
              bonusesApplied: bonuses,
            );

      return result;
    } catch (e) {
      throw Exception('Error al otorgar experiencia: $e');
    }
  }

  /// Otorga XP por visitar un POI
  Future<LevelUpResult> awardPOIVisit({
    required String userId,
    required String poiId,
    required String poiName,
    bool isFirstVisit = true,
    bool hasMomentum = false,
    double momentumMultiplier = 1.0,
  }) async {
    return awardExperience(
      userId: userId,
      baseXP: XP_POI_VISIT,
      sourceType: XPSourceType.poiVisit,
      reason: 'Visited $poiName',
      isFirstTime: isFirstVisit,
      hasMomentum: hasMomentum,
      momentumMultiplier: momentumMultiplier,
    );
  }

  /// Otorga XP por completar una ruta
  Future<LevelUpResult> awardRouteCompletion({
    required String userId,
    required String routeId,
    required String routeName,
    bool isFirstTime = true,
    bool hasMomentum = false,
    double momentumMultiplier = 1.0,
  }) async {
    return awardExperience(
      userId: userId,
      baseXP: XP_ROUTE_COMPLETE,
      sourceType: XPSourceType.routeComplete,
      reason: 'Completed $routeName',
      isFirstTime: isFirstTime,
      hasMomentum: hasMomentum,
      momentumMultiplier: momentumMultiplier,
    );
  }

  /// Otorga XP por login diario
  Future<LevelUpResult> awardDailyLogin({
    required String userId,
  }) async {
    return awardExperience(
      userId: userId,
      baseXP: XP_DAILY_LOGIN,
      sourceType: XPSourceType.dailyLogin,
      reason: 'Daily login',
    );
  }

  /// Otorga XP por subir una foto
  Future<LevelUpResult> awardPhotoUpload({
    required String userId,
    required String poiName,
  }) async {
    return awardExperience(
      userId: userId,
      baseXP: XP_PHOTO_UPLOAD,
      sourceType: XPSourceType.photoUpload,
      reason: 'Uploaded photo at $poiName',
    );
  }

  /// Otorga XP por compartir en redes sociales
  Future<LevelUpResult> awardSocialShare({
    required String userId,
  }) async {
    return awardExperience(
      userId: userId,
      baseXP: XP_SOCIAL_SHARE,
      sourceType: XPSourceType.socialShare,
      reason: 'Shared on social media',
    );
  }

  // ============ MÉTODOS DE CONSULTA ============

  /// Obtiene los datos de gamificación del usuario
  Future<GamificationData> getUserGamificationData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado: $userId');
      }
      
      final userData = userDoc.data()!;
      final totalXP = userData['experiencePoints'] as int? ?? 0;
      
      // Obtener actividades recientes (últimas 10)
      final activities = await _getRecentActivities(userId, limit: 10);
      
      return GamificationData.fromTotalXP(totalXP, recentActivities: activities);
    } catch (e) {
      throw Exception('Error al obtener datos de gamificación: $e');
    }
  }

  /// Calcula cuánta XP necesita el usuario para el siguiente nivel
  Future<int> getXPNeededForNextLevel(String userId) async {
    final data = await getUserGamificationData(userId);
    return data.xpToNextLevel - data.currentLevelXP;
  }

  // ============ MÉTODOS PRIVADOS ============

  /// Otorga las recompensas correspondientes a los niveles alcanzados
  Future<void> _grantLevelRewards(
    String userId,
    int oldLevel,
    int newLevel,
  ) async {
    try {
      // Obtener todas las recompensas de los niveles intermedios
      final rewardsToGrant = <LevelReward>[];
      for (int level = oldLevel + 1; level <= newLevel; level++) {
        final levelRewards = LevelRewardsSystem.getRewardsForLevel(level);
        rewardsToGrant.addAll(levelRewards);
      }

      if (rewardsToGrant.isEmpty) return;

      // Actualizar el documento del usuario con las nuevas recompensas
      final userRef = _firestore.collection('users').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) return;
        
        final userData = userDoc.data()!;
        final unlockedRewards = List<Map<String, dynamic>>.from(
          userData['unlockedRewards'] as List? ?? [],
        );

        // Agregar nuevas recompensas
        for (var reward in rewardsToGrant) {
          unlockedRewards.add({
            ...reward.toMap(),
            'unlockedAt': FieldValue.serverTimestamp(),
          });
        }

        transaction.update(userRef, {
          'unlockedRewards': unlockedRewards,
          'totalRewardsUnlocked': unlockedRewards.length,
        });
      });
    } catch (e) {
      // Log error pero no fallar la operación principal
      print('Error al otorgar recompensas de nivel: $e');
    }
  }

  /// Registra la actividad de XP en el historial del usuario
  Future<void> _logXPActivity(
    String userId,
    int xpGained,
    XPSourceType sourceType,
    String? reason,
  ) async {
    try {
      final activity = XPActivity(
        activityType: sourceType.name,
        xpGained: xpGained,
        description: reason ?? sourceType.displayName,
        timestamp: DateTime.now(),
      );

      // Guardar en subcolección de actividades
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('xp_history')
          .add(activity.toMap());
    } catch (e) {
      // Log error pero no fallar la operación principal
      print('Error al registrar actividad de XP: $e');
    }
  }

  /// Obtiene las actividades recientes del usuario
  Future<List<XPActivity>> _getRecentActivities(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('xp_history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => XPActivity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ============ MÉTODOS DE UTILIDAD ============

  /// Calcula el XP total obtenido en un rango de fechas
  Future<int> getTotalXPInDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('xp_history')
          .where('timestamp', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('timestamp', isLessThanOrEqualTo: endDate.toIso8601String())
          .get();

      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        total += data['xpGained'] as int? ?? 0;
      }

      return total;
    } catch (e) {
      return 0;
    }
  }

  /// Obtiene estadísticas de XP por fuente
  Future<Map<XPSourceType, int>> getXPStatsBySource(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('xp_history')
          .get();

      final Map<XPSourceType, int> stats = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final sourceTypeName = data['activityType'] as String;
        final xpGained = data['xpGained'] as int;
        
        final sourceType = XPSourceType.values.firstWhere(
          (e) => e.name == sourceTypeName,
          orElse: () => XPSourceType.other,
        );
        
        stats[sourceType] = (stats[sourceType] ?? 0) + xpGained;
      }

      return stats;
    } catch (e) {
      return {};
    }
  }

  /// Resetea la experiencia de un usuario (útil para testing)
  Future<void> resetUserExperience(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'experiencePoints': 0,
      'level': 1,
      'unlockedRewards': [],
      'totalRewardsUnlocked': 0,
    });

    // Eliminar historial de XP
    final historySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('xp_history')
        .get();

    for (var doc in historySnapshot.docs) {
      await doc.reference.delete();
    }
  }
}