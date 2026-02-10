class LevelUpResult {
  
  final int xpGained;
  
  final int newTotalXP;
  
  final int oldLevel;
  
  final int newLevel;
  
  final bool didLevelUp;

  final String? reason;  
  
  final XPSourceType sourceType;
  
  final List<XPBonus> bonusesApplied;

  LevelUpResult({
    required this.xpGained,
    required this.newTotalXP,
    required this.oldLevel,
    required this.newLevel,
    required this.didLevelUp,
    this.reason,
    this.sourceType = XPSourceType.other,
    this.bonusesApplied = const [],
  });

  
  int get levelsGained => newLevel - oldLevel;

  
  bool get hadBonuses => bonusesApplied.isNotEmpty;

  
  int get baseXP {
    if (bonusesApplied.isEmpty) return xpGained;
    
    int base = xpGained;
    for (var bonus in bonusesApplied) {
      if (bonus.isMultiplier) {
        base = (base / bonus.value).round();
      } else {
        base -= bonus.value.round();
      }
    }
    return base;
  }

  
  factory LevelUpResult.noLevelUp({
    required int xpGained,
    required int newTotalXP,
    required int currentLevel,
    String? reason,
    XPSourceType sourceType = XPSourceType.other,
    List<XPBonus> bonusesApplied = const [],
  }) {
    return LevelUpResult(
      xpGained: xpGained,
      newTotalXP: newTotalXP,
      oldLevel: currentLevel,
      newLevel: currentLevel,
      didLevelUp: false,
      reason: reason,
      sourceType: sourceType,
      bonusesApplied: bonusesApplied,
    );
  }

  
  factory LevelUpResult.withLevelUp({
    required int xpGained,
    required int newTotalXP,
    required int oldLevel,
    required int newLevel,
    String? reason,
    XPSourceType sourceType = XPSourceType.other,
    List<XPBonus> bonusesApplied = const [],
  }) {
    return LevelUpResult(
      xpGained: xpGained,
      newTotalXP: newTotalXP,
      oldLevel: oldLevel,
      newLevel: newLevel,
      didLevelUp: true,
      reason: reason,
      sourceType: sourceType,
      bonusesApplied: bonusesApplied,
    );
  }

  
  Map<String, dynamic> toMap() {
    return {
      'xpGained': xpGained,
      'newTotalXP': newTotalXP,
      'oldLevel': oldLevel,
      'newLevel': newLevel,
      'didLevelUp': didLevelUp,
      'levelsGained': levelsGained,
      'reason': reason,
      'sourceType': sourceType.name,
      'bonusesApplied': bonusesApplied.map((b) => b.toMap()).toList(),
    };
  }

  factory LevelUpResult.fromMap(Map<String, dynamic> map) {
    return LevelUpResult(
      xpGained: map['xpGained'] as int,
      newTotalXP: map['newTotalXP'] as int,
      oldLevel: map['oldLevel'] as int,
      newLevel: map['newLevel'] as int,
      didLevelUp: map['didLevelUp'] as bool,
      reason: map['reason'] as String?,
      sourceType: XPSourceType.values.firstWhere(
        (e) => e.name == map['sourceType'],
        orElse: () => XPSourceType.other,
      ),
      bonusesApplied: (map['bonusesApplied'] as List<dynamic>?)
              ?.map((b) => XPBonus.fromMap(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  String toString() {
    if (didLevelUp) {
      return 'LevelUpResult(+$xpGained XP, Level $oldLevel → $newLevel${reason != null ? ', $reason' : ''})';
    }
    return 'LevelUpResult(+$xpGained XP, Level $oldLevel${reason != null ? ', $reason' : ''})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LevelUpResult &&
        other.xpGained == xpGained &&
        other.newTotalXP == newTotalXP &&
        other.oldLevel == oldLevel &&
        other.newLevel == newLevel;
  }

  @override
  int get hashCode => Object.hash(xpGained, newTotalXP, oldLevel, newLevel);
}


enum XPSourceType {
  
  poiVisit('POI Visit'),
  
  
  routeComplete('Route Complete'),
  
  
  dailyLogin('Daily Login'),
  
  
  photoUpload('Photo Upload'),
  
  
  socialShare('Social Share'),
  
  
  streak('Streak Bonus'),
  
  
  specialEvent('Special Event'),
  
  
  other('Other');

  final String displayName;
  const XPSourceType(this.displayName);
}


class XPBonus {
  
  final String name;
  
  
  final double value;
  
  
  final bool isMultiplier;
  
  
  final String description;

  XPBonus({
    required this.name,
    required this.value,
    required this.isMultiplier,
    required this.description,
  });

  
  factory XPBonus.firstTime() {
    return XPBonus(
      name: 'First Time',
      value: 1.5,
      isMultiplier: true,
      description: 'First time bonus: +50%',
    );
  }

  
  factory XPBonus.streak() {
    return XPBonus(
      name: 'Streak',
      value: 1.2,
      isMultiplier: true,
      description: 'Streak bonus: +20%',
    );
  }

  
  factory XPBonus.specialEvent(double multiplier, String eventName) {
    return XPBonus(
      name: 'Special Event',
      value: multiplier,
      isMultiplier: true,
      description: '$eventName: +${((multiplier - 1) * 100).toInt()}%',
    );
  }

  
  factory XPBonus.fixed(int amount, String reason) {
    return XPBonus(
      name: 'Fixed Bonus',
      value: amount.toDouble(),
      isMultiplier: false,
      description: reason,
    );
  }

  
  int apply(int baseXP) {
    if (isMultiplier) {
      return (baseXP * value).round();
    } else {
      return baseXP + value.round();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'value': value,
      'isMultiplier': isMultiplier,
      'description': description,
    };
  }

  factory XPBonus.fromMap(Map<String, dynamic> map) {
    return XPBonus(
      name: map['name'] as String,
      value: (map['value'] as num).toDouble(),
      isMultiplier: map['isMultiplier'] as bool,
      description: map['description'] as String,
    );
  }

  @override
  String toString() => description;
}