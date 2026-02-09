import 'dart:math';

/// Modelo que representa los datos de gamificación de un usuario
/// Contiene la lógica para calcular niveles, experiencia y progreso
class GamificationData {
  /// Puntos de experiencia totales del usuario
  final int experiencePoints;
  
  /// Nivel actual calculado basado en XP
  final int level;
  
  /// XP acumulada dentro del nivel actual
  final int currentLevelXP;
  
  /// XP necesaria para alcanzar el siguiente nivel
  final int xpToNextLevel;
  
  /// Progreso hacia el siguiente nivel (0.0 a 1.0)
  final double progressToNextLevel;
  
  /// Lista de actividades recientes que otorgaron XP
  final List<XPActivity> recentActivities;

  GamificationData({
    required this.experiencePoints,
    required this.level,
    required this.currentLevelXP,
    required this.xpToNextLevel,
    required this.progressToNextLevel,
    this.recentActivities = const [],
  });

  /// Factory constructor que calcula automáticamente los valores derivados
  factory GamificationData.fromTotalXP(
    int totalXP, {
    List<XPActivity> recentActivities = const [],
  }) {
    final level = calculateLevel(totalXP);
    final xpForCurrentLevel = xpRequiredForLevel(level);
    final xpForNextLevel = xpRequiredForLevel(level + 1);
    
    final currentLevelXP = totalXP - xpForCurrentLevel;
    final xpToNextLevel = xpForNextLevel - xpForCurrentLevel;
    final progress = xpToNextLevel > 0 ? currentLevelXP / xpToNextLevel : 0.0;

    return GamificationData(
      experiencePoints: totalXP,
      level: level,
      currentLevelXP: currentLevelXP,
      xpToNextLevel: xpToNextLevel,
      progressToNextLevel: progress.clamp(0.0, 1.0),
      recentActivities: recentActivities,
    );
  }

  /// Calcula el nivel basado en la experiencia total
  /// 
  /// Fórmula: level = floor(sqrt(totalXP / 100)) + 1
  /// Esto crea una curva progresiva donde cada nivel requiere más XP que el anterior
  /// 
  /// Ejemplos:
  /// - 0 XP = Nivel 1
  /// - 100 XP = Nivel 2
  /// - 400 XP = Nivel 3
  /// - 900 XP = Nivel 4
  /// - 1600 XP = Nivel 5
  static int calculateLevel(int totalXP) {
    if (totalXP < 0) return 1;
    return (sqrt(totalXP / 100)).floor() + 1;
  }

  /// Calcula la experiencia total requerida para alcanzar un nivel específico
  /// 
  /// Fórmula inversa: totalXP = (level - 1)² × 100
  /// 
  /// Ejemplos:
  /// - Nivel 1: 0 XP
  /// - Nivel 2: 100 XP
  /// - Nivel 3: 400 XP
  /// - Nivel 4: 900 XP
  /// - Nivel 5: 1600 XP
  static int xpRequiredForLevel(int level) {
    if (level <= 1) return 0;
    return ((level - 1) * (level - 1) * 100);
  }

  /// Calcula la XP necesaria para subir del nivel actual al siguiente
  /// 
  /// Por ejemplo, de nivel 3 a 4 se necesitan 500 XP adicionales
  static int xpNeededForNextLevel(int currentLevel) {
    final currentLevelXP = xpRequiredForLevel(currentLevel);
    final nextLevelXP = xpRequiredForLevel(currentLevel + 1);
    return nextLevelXP - currentLevelXP;
  }

  /// Calcula cuántos niveles se pueden alcanzar con una cantidad de XP
  static int levelsGainedFromXP(int currentXP, int xpToAdd) {
    final currentLevel = calculateLevel(currentXP);
    final newLevel = calculateLevel(currentXP + xpToAdd);
    return newLevel - currentLevel;
  }

  /// Crea una copia del objeto con valores actualizados
  GamificationData copyWith({
    int? experiencePoints,
    int? level,
    int? currentLevelXP,
    int? xpToNextLevel,
    double? progressToNextLevel,
    List<XPActivity>? recentActivities,
  }) {
    return GamificationData(
      experiencePoints: experiencePoints ?? this.experiencePoints,
      level: level ?? this.level,
      currentLevelXP: currentLevelXP ?? this.currentLevelXP,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      progressToNextLevel: progressToNextLevel ?? this.progressToNextLevel,
      recentActivities: recentActivities ?? this.recentActivities,
    );
  }

  /// Convierte el objeto a un mapa para almacenamiento en Firestore
  Map<String, dynamic> toMap() {
    return {
      'experiencePoints': experiencePoints,
      'level': level,
      'currentLevelXP': currentLevelXP,
      'xpToNextLevel': xpToNextLevel,
      'progressToNextLevel': progressToNextLevel,
      'recentActivities': recentActivities.map((a) => a.toMap()).toList(),
    };
  }

  /// Crea un objeto desde un mapa de Firestore
  factory GamificationData.fromMap(Map<String, dynamic> map) {
    final totalXP = map['experiencePoints'] as int? ?? 0;
    final activities = (map['recentActivities'] as List<dynamic>?)
            ?.map((a) => XPActivity.fromMap(a as Map<String, dynamic>))
            .toList() ??
        [];

    return GamificationData.fromTotalXP(totalXP, recentActivities: activities);
  }

  @override
  String toString() {
    return 'GamificationData(level: $level, xp: $experiencePoints, progress: ${(progressToNextLevel * 100).toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GamificationData &&
        other.experiencePoints == experiencePoints &&
        other.level == level;
  }

  @override
  int get hashCode => Object.hash(experiencePoints, level);
}

/// Representa una actividad que otorgó experiencia al usuario
class XPActivity {
  /// Tipo de actividad (ej: 'poi_visit', 'route_complete')
  final String activityType;
  
  /// Cantidad de XP otorgada
  final int xpGained;
  
  /// Descripción legible de la actividad
  final String description;
  
  /// Timestamp de cuándo ocurrió la actividad
  final DateTime timestamp;

  XPActivity({
    required this.activityType,
    required this.xpGained,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'activityType': activityType,
      'xpGained': xpGained,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory XPActivity.fromMap(Map<String, dynamic> map) {
    return XPActivity(
      activityType: map['activityType'] as String,
      xpGained: map['xpGained'] as int,
      description: map['description'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  @override
  String toString() {
    return 'XPActivity($description: +$xpGained XP)';
  }
}