import 'package:flutter/material.dart';
import '../models/achievement.dart';

/// Widget que muestra una notificación cuando se desbloquea un achievement
class AchievementUnlockedDialog extends StatelessWidget {
  final Achievement achievement;

  const AchievementUnlockedDialog({
    Key? key,
    required this.achievement,
  }) : super(key: key);

  /// Mostrar el diálogo de achievement desbloqueado
  static void show(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AchievementUnlockedDialog(
        achievement: achievement,
      ),
    );
  }

  /// Mostrar múltiples achievements desbloqueados
  static void showMultiple(BuildContext context, List<Achievement> achievements) {
    if (achievements.isEmpty) return;
    
    // Mostrar el primero
    show(context, achievements.first);
    
    // Si hay más, mostrarlos después
    if (achievements.length > 1) {
      Future.delayed(const Duration(seconds: 3), () {
        if (context.mounted) {
          Navigator.of(context).pop();
          showMultiple(context, achievements.skip(1).toList());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = Color(achievement.rarity.colorValue);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              rarityColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: rarityColor,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Confetti/Stars animation placeholder
            const Icon(
              Icons.celebration,
              size: 48,
              color: Colors.deepOrange,
            ),
            const SizedBox(height: 16),
            
            // "Achievement Unlocked" text
            Text(
              'Achievement Unlocked!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: rarityColor,
              ),
            ),
            const SizedBox(height: 20),
            
            // Achievement icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: rarityColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: rarityColor,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: rarityColor.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  achievement.emoji,
                  style: const TextStyle(fontSize: 56),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Achievement title
            Text(
              achievement.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Achievement description
            Text(
              achievement.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // XP reward
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber[700]!,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stars,
                    color: Colors.amber[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+${achievement.xpReward} XP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[900],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Awesome!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Notificación simple (SnackBar) para achievement desbloqueado
class AchievementUnlockedSnackBar extends SnackBar {
  AchievementUnlockedSnackBar({
    Key? key,
    required Achievement achievement,
    VoidCallback? onTap,
  }) : super(
          key: key,
          content: Row(
            children: [
              Text(
                achievement.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Achievement Unlocked!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      achievement.title,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              Text(
                '+${achievement.xpReward} XP',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.deepOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
          action: onTap != null
              ? SnackBarAction(
                  label: 'View',
                  textColor: Colors.white,
                  onPressed: onTap,
                )
              : null,
        );

  /// Mostrar SnackBar de achievement desbloqueado
  static void show(
    BuildContext context,
    Achievement achievement, {
    VoidCallback? onTap,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      AchievementUnlockedSnackBar(
        achievement: achievement,
        onTap: onTap,
      ),
    );
  }
}