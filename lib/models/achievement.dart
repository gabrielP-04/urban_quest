class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementCategory category;
  final int requiredProgress;
  final int xpReward;
  final AchievementRarity rarity;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    required this.requiredProgress,
    required this.xpReward,
    required this.rarity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'emoji': emoji,
      'category': category.name,
      'requiredProgress': requiredProgress,
      'xpReward': xpReward,
      'rarity': rarity.name,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      emoji: map['emoji'] as String,
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => AchievementCategory.exploration,
      ),
      requiredProgress: map['requiredProgress'] as int,
      xpReward: map['xpReward'] as int,
      rarity: AchievementRarity.values.firstWhere(
        (e) => e.name == map['rarity'],
        orElse: () => AchievementRarity.common,
      ),
    );
  }
}

enum AchievementCategory {
  exploration,  
  culture,      
  food,         
  routes,       
  social,       
  special,      
}

extension AchievementCategoryExtension on AchievementCategory {
  String get displayName {
    switch (this) {
      case AchievementCategory.exploration:
        return 'Exploration';
      case AchievementCategory.culture:
        return 'Culture';
      case AchievementCategory.food:
        return 'Food';
      case AchievementCategory.routes:
        return 'Routes';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.special:
        return 'Special';
    }
  }

  String get emoji {
    switch (this) {
      case AchievementCategory.exploration:
        return '🗺️';
      case AchievementCategory.culture:
        return '🏛️';
      case AchievementCategory.food:
        return '🍕';
      case AchievementCategory.routes:
        return '🚶';
      case AchievementCategory.social:
        return '👥';
      case AchievementCategory.special:
        return '✨';
    }
  }
}

enum AchievementRarity {
  common,    
  rare,      
  epic,      
  legendary, 
}

extension AchievementRarityExtension on AchievementRarity {
  String get displayName {
    switch (this) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }

  int get colorValue {
    switch (this) {
      case AchievementRarity.common:
        return 0xFFCD7F32; // Bronce
      case AchievementRarity.rare:
        return 0xFFC0C0C0; // Plata
      case AchievementRarity.epic:
        return 0xFFFFD700; // Oro
      case AchievementRarity.legendary:
        return 0xFFE5E4E2; // Platino
    }
  }
}

class AchievementProgress {
  final Achievement achievement;
  final int currentProgress;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementProgress({
    required this.achievement,
    required this.currentProgress,
    required this.isUnlocked,
    this.unlockedAt,
  });

  double get progressPercentage {
    if (isUnlocked) return 1.0;
    return (currentProgress / achievement.requiredProgress).clamp(0.0, 1.0);
  }

  int get remainingProgress {
    if (isUnlocked) return 0;
    return (achievement.requiredProgress - currentProgress).clamp(0, achievement.requiredProgress);
  }

  String get progressMessage {
    if (isUnlocked) {
      return 'Unlocked!';
    }
    if (remainingProgress == 1) {
      return '1 more to unlock';
    }
    return '$remainingProgress more to unlock';
  }

  AchievementProgress copyWith({
    Achievement? achievement,
    int? currentProgress,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return AchievementProgress(
      achievement: achievement ?? this.achievement,
      currentProgress: currentProgress ?? this.currentProgress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

class AchievementCheckResult {
  final List<Achievement> newlyUnlocked;
  final int totalXPRewarded;
  final int totalAchievements;

  AchievementCheckResult({
    required this.newlyUnlocked,
    required this.totalXPRewarded,
    required this.totalAchievements,
  });

  bool get hasNewAchievements => newlyUnlocked.isNotEmpty;

  String get summary {
    if (!hasNewAchievements) return 'No new achievements';
    if (newlyUnlocked.length == 1) {
      return '1 achievement unlocked! +$totalXPRewarded XP';
    }
    return '${newlyUnlocked.length} achievements unlocked! +$totalXPRewarded XP';
  }
}