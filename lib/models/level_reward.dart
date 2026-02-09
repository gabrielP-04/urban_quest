/// Representa una recompensa desbloqueada al alcanzar un nivel específico
class LevelReward {
  /// Nivel en el que se desbloquea esta recompensa
  final int level;
  
  /// Tipo de recompensa
  final RewardType type;
  
  /// ID del item desbloqueado (ej: achievement_id, badge_id)
  final String itemId;
  
  /// Nombre descriptivo de la recompensa
  final String name;
  
  /// Descripción de la recompensa
  final String description;
  
  /// Emoji o icono que representa la recompensa
  final String? icon;
  
  /// URL de imagen (si aplica)
  final String? imageUrl;

  LevelReward({
    required this.level,
    required this.type,
    required this.itemId,
    required this.name,
    required this.description,
    this.icon,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'type': type.name,
      'itemId': itemId,
      'name': name,
      'description': description,
      'icon': icon,
      'imageUrl': imageUrl,
    };
  }

  factory LevelReward.fromMap(Map<String, dynamic> map) {
    return LevelReward(
      level: map['level'] as int,
      type: RewardType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RewardType.other,
      ),
      itemId: map['itemId'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      icon: map['icon'] as String?,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  @override
  String toString() {
    return 'LevelReward(level: $level, $name - $description)';
  }
}

/// Tipos de recompensas disponibles
enum RewardType {
  /// Logro desbloqueado
  achievement('Achievement'),
  
  /// Insignia nueva
  badge('Badge'),
  
  /// Icono de perfil personalizado
  profileIcon('Profile Icon'),
  
  /// Marco de perfil decorativo
  profileFrame('Profile Frame'),
  
  /// Título especial
  title('Title'),
  
  /// Funcionalidad desbloqueada
  feature('Feature'),
  
  /// Otro tipo de recompensa
  other('Other');

  final String displayName;
  const RewardType(this.displayName);
}

/// Sistema de recompensas por nivel
/// Define qué se desbloquea en cada nivel
class LevelRewardsSystem {
  /// Mapa de niveles y sus recompensas
  static final Map<int, List<LevelReward>> _rewards = {
    // Nivel 2: Primera insignia
    2: [
      LevelReward(
        level: 2,
        type: RewardType.badge,
        itemId: 'badge_newcomer',
        name: 'Newcomer Badge',
        description: 'Welcome to UrbanQuest!',
        icon: '🌟',
      ),
    ],
    
    // Nivel 5: Explorer
    5: [
      LevelReward(
        level: 5,
        type: RewardType.achievement,
        itemId: 'achievement_explorer',
        name: 'City Explorer',
        description: 'Reached level 5',
        icon: '🗺️',
      ),
      LevelReward(
        level: 5,
        type: RewardType.badge,
        itemId: 'badge_bronze',
        name: 'Bronze Badge',
        description: 'First milestone achieved',
        icon: '🥉',
      ),
    ],
    
    // Nivel 10: Adventurer
    10: [
      LevelReward(
        level: 10,
        type: RewardType.achievement,
        itemId: 'achievement_adventurer',
        name: 'Urban Adventurer',
        description: 'Reached level 10',
        icon: '🎒',
      ),
      LevelReward(
        level: 10,
        type: RewardType.badge,
        itemId: 'badge_silver',
        name: 'Silver Badge',
        description: 'You\'re getting serious!',
        icon: '🥈',
      ),
      LevelReward(
        level: 10,
        type: RewardType.profileIcon,
        itemId: 'icon_compass',
        name: 'Compass Icon',
        description: 'Special profile icon unlocked',
        icon: '🧭',
      ),
    ],
    
    // Nivel 15: Specialist
    15: [
      LevelReward(
        level: 15,
        type: RewardType.achievement,
        itemId: 'achievement_specialist',
        name: 'Area Specialist',
        description: 'Reached level 15',
        icon: '🎯',
      ),
      LevelReward(
        level: 15,
        type: RewardType.profileIcon,
        itemId: 'icon_star',
        name: 'Star Icon',
        description: 'Shine bright!',
        icon: '⭐',
      ),
      LevelReward(
        level: 15,
        type: RewardType.profileFrame,
        itemId: 'frame_bronze',
        name: 'Bronze Frame',
        description: 'Special profile frame',
        icon: '🖼️',
      ),
    ],
    
    // Nivel 20: Master
    20: [
      LevelReward(
        level: 20,
        type: RewardType.achievement,
        itemId: 'achievement_master',
        name: 'City Master',
        description: 'Reached level 20',
        icon: '👑',
      ),
      LevelReward(
        level: 20,
        type: RewardType.badge,
        itemId: 'badge_gold',
        name: 'Gold Badge',
        description: 'Elite explorer status',
        icon: '🥇',
      ),
      LevelReward(
        level: 20,
        type: RewardType.title,
        itemId: 'title_master',
        name: 'Master Explorer',
        description: 'Special title for your profile',
        icon: '🏆',
      ),
    ],
    
    // Nivel 25: Legend
    25: [
      LevelReward(
        level: 25,
        type: RewardType.achievement,
        itemId: 'achievement_legend',
        name: 'Urban Legend',
        description: 'Reached level 25',
        icon: '💎',
      ),
      LevelReward(
        level: 25,
        type: RewardType.profileFrame,
        itemId: 'frame_gold',
        name: 'Gold Frame',
        description: 'Legendary profile frame',
        icon: '🌟',
      ),
    ],
    
    // Nivel 30: Elite
    30: [
      LevelReward(
        level: 30,
        type: RewardType.achievement,
        itemId: 'achievement_elite',
        name: 'Elite Explorer',
        description: 'Reached level 30',
        icon: '💫',
      ),
      LevelReward(
        level: 30,
        type: RewardType.badge,
        itemId: 'badge_platinum',
        name: 'Platinum Badge',
        description: 'Top tier achievement',
        icon: '🌟',
      ),
    ],
  };

  /// Obtiene las recompensas para un nivel específico
  static List<LevelReward> getRewardsForLevel(int level) {
    return _rewards[level] ?? [];
  }

  /// Verifica si un nivel tiene recompensas
  static bool hasRewards(int level) {
    return _rewards.containsKey(level) && _rewards[level]!.isNotEmpty;
  }

  /// Obtiene todas las recompensas hasta un nivel dado
  static List<LevelReward> getAllRewardsUpToLevel(int level) {
    final List<LevelReward> allRewards = [];
    for (int i = 1; i <= level; i++) {
      allRewards.addAll(getRewardsForLevel(i));
    }
    return allRewards;
  }

  /// Obtiene el próximo nivel con recompensas después del nivel actual
  static int? getNextRewardLevel(int currentLevel) {
    final rewardLevels = _rewards.keys.where((l) => l > currentLevel).toList()
      ..sort();
    return rewardLevels.isEmpty ? null : rewardLevels.first;
  }

  /// Obtiene todos los niveles que tienen recompensas
  static List<int> getAllRewardLevels() {
    return _rewards.keys.toList()..sort();
  }

  /// Obtiene un resumen de cuántas recompensas de cada tipo hay por nivel
  static Map<int, Map<RewardType, int>> getRewardsSummary() {
    final Map<int, Map<RewardType, int>> summary = {};
    
    _rewards.forEach((level, rewards) {
      final Map<RewardType, int> typeCounts = {};
      for (var reward in rewards) {
        typeCounts[reward.type] = (typeCounts[reward.type] ?? 0) + 1;
      }
      summary[level] = typeCounts;
    });
    
    return summary;
  }

  /// Añade una recompensa personalizada (útil para eventos especiales)
  static void addCustomReward(LevelReward reward) {
    if (_rewards.containsKey(reward.level)) {
      _rewards[reward.level]!.add(reward);
    } else {
      _rewards[reward.level] = [reward];
    }
  }
}