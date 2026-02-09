/// Resultado de una operación que otorga experiencia al usuario
/// Contiene información sobre el XP ganado y si hubo cambio de nivel
class LevelUpResult {
  /// Cantidad de XP ganada en esta operación
  final int xpGained;
  
  /// XP total del usuario después de la operación
  final int newTotalXP;
  
  /// Nivel del usuario antes de ganar XP
  final int oldLevel;
  
  /// Nivel del usuario después de ganar XP
  final int newLevel;
  
  /// Indica si el usuario subió de nivel
  final bool didLevelUp;
  
  /// Razón por la cual se otorgó el XP (ej: "Visited Duomo di Milano")
  final String? reason;
  
  /// Tipo de actividad que generó el XP
  final XPSourceType sourceType;
  
  /// Bonificaciones aplicadas (multiplicadores, bonus, etc)
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

  /// Número de niveles ganados (normalmente 0 o 1, pero podría ser más)
  int get levelsGained => newLevel - oldLevel;

  /// Indica si se aplicaron bonificaciones
  bool get hadBonuses => bonusesApplied.isNotEmpty;

  /// XP base antes de aplicar bonificaciones
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

  /// Crea un resultado sin cambio de nivel
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

  /// Crea un resultado con subida de nivel
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

  /// Convierte a mapa para logging o almacenamiento
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

/// Tipos de fuentes de experiencia
enum XPSourceType {
  /// Visitar un punto de interés
  poiVisit('POI Visit'),
  
  /// Completar una ruta
  routeComplete('Route Complete'),
  
  /// Login diario
  dailyLogin('Daily Login'),
  
  /// Subir una foto
  photoUpload('Photo Upload'),
  
  /// Compartir en redes sociales
  socialShare('Social Share'),
  
  /// Bonus de racha
  streak('Streak Bonus'),
  
  /// Recompensa por evento especial
  specialEvent('Special Event'),
  
  /// Otro tipo de actividad
  other('Other');

  final String displayName;
  const XPSourceType(this.displayName);
}

/// Representa un bonus o multiplicador aplicado al XP
class XPBonus {
  /// Nombre del bonus
  final String name;
  
  /// Valor del bonus (multiplicador o cantidad fija)
  final double value;
  
  /// Indica si es un multiplicador (true) o cantidad fija (false)
  final bool isMultiplier;
  
  /// Descripción del bonus
  final String description;

  XPBonus({
    required this.name,
    required this.value,
    required this.isMultiplier,
    required this.description,
  });

  /// Bonus por primera vez (+50%)
  factory XPBonus.firstTime() {
    return XPBonus(
      name: 'First Time',
      value: 1.5,
      isMultiplier: true,
      description: 'First time bonus: +50%',
    );
  }

  /// Bonus por racha de días consecutivos (+20%)
  factory XPBonus.streak() {
    return XPBonus(
      name: 'Streak',
      value: 1.2,
      isMultiplier: true,
      description: 'Streak bonus: +20%',
    );
  }

  /// Bonus por evento especial
  factory XPBonus.specialEvent(double multiplier, String eventName) {
    return XPBonus(
      name: 'Special Event',
      value: multiplier,
      isMultiplier: true,
      description: '$eventName: +${((multiplier - 1) * 100).toInt()}%',
    );
  }

  /// Bonus de cantidad fija
  factory XPBonus.fixed(int amount, String reason) {
    return XPBonus(
      name: 'Fixed Bonus',
      value: amount.toDouble(),
      isMultiplier: false,
      description: reason,
    );
  }

  /// Aplica el bonus a una cantidad de XP base
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