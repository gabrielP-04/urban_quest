import 'dart:math';

class GamificationData {
  
  final int experiencePoints;
 
  final int level;
  
  final int currentLevelXP;
  
  final int xpToNextLevel;
 
  final double progressToNextLevel;
  
  final List<XPActivity> recentActivities;

  GamificationData({
    required this.experiencePoints,
    required this.level,
    required this.currentLevelXP,
    required this.xpToNextLevel,
    required this.progressToNextLevel,
    this.recentActivities = const [],
  });

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


  static int calculateLevel(int totalXP) {
    if (totalXP < 0) return 1;
    return (sqrt(totalXP / 100)).floor() + 1;
  }

  static int xpRequiredForLevel(int level) {
    if (level <= 1) return 0;
    return ((level - 1) * (level - 1) * 100);
  }

  static int xpNeededForNextLevel(int currentLevel) {
    final currentLevelXP = xpRequiredForLevel(currentLevel);
    final nextLevelXP = xpRequiredForLevel(currentLevel + 1);
    return nextLevelXP - currentLevelXP;
  }

 
  static int levelsGainedFromXP(int currentXP, int xpToAdd) {
    final currentLevel = calculateLevel(currentXP);
    final newLevel = calculateLevel(currentXP + xpToAdd);
    return newLevel - currentLevel;
  }

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


class XPActivity {

  final String activityType;

  final int xpGained;

  final String description;
  
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