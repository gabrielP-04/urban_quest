import 'package:flutter/material.dart';
import 'package:urban_quest/models/achievement.dart';
import 'package:urban_quest/screens/achievements/achievement_detail_sheet.dart';
import 'package:urban_quest/services/achievement_notifier.dart';

/// Mock data ONLY for development/testing.
/// Later, replace this with real data coming from your gamification layer.
final List<Achievement> mockAchievements = [
  Achievement(
    id: 'first_steps',
    title: 'First Steps',
    description: 'Visit your first point of interest',
    icon: Icons.directions_walk,
    unlocked: true,
  ),
  Achievement(
    id: 'explorer',
    title: 'Explorer',
    description: 'Visit 5 points of interest',
    icon: Icons.explore,
    unlocked: true,
  ),
  Achievement(
    id: 'food_lover',
    title: 'City Flavours',
    description: 'Discover 3 gastronomic places',
    icon: Icons.restaurant,
    unlocked: true,
  ),
  Achievement(
    id: 'urban_master',
    title: 'Urban Master',
    description: 'Visit 10 points of interest',
    icon: Icons.location_city,
    unlocked: false,
  ),
  Achievement(
    id: 'curious_explorer',
    title: 'Curious Explorer',
    description: 'Visit 3 optional places',
    icon: Icons.star,
    unlocked: false,
  ),
];

class AchievementsScreen extends StatelessWidget {
  final List<Achievement> achievements;

  const AchievementsScreen({
    super.key,
    required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = achievements.where((a) => a.unlocked).toList();
    final locked = achievements.where((a) => !a.unlocked).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(unlocked.length, achievements.length),
            const SizedBox(height: 24),
            _buildSectionTitle(
              'Unlocked achievements',
              '${unlocked.length} / ${achievements.length}',
            ),
            const SizedBox(height: 12),
            ...unlocked.map((a) => _buildAchievementTile(context, a)),
            const SizedBox(height: 24),
            _buildSectionTitle('Locked achievements', ''),
            const SizedBox(height: 12),
            ...locked.map((a) => _buildAchievementTile(context, a)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int unlocked, int total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Level 8 · Urban Explorer',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const LinearProgressIndicator(
            value: 0.62,
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.emoji_events, size: 18),
              const SizedBox(width: 6),
              Text('$unlocked achievements unlocked'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementTile(
    BuildContext context,
    Achievement achievement,
  ) {
    final isUnlocked = achievement.unlocked;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          isDismissible: true,
          enableDrag: true,
          builder: (context) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: Center(
                child: GestureDetector(
                  onTap: () {}, // prevents closing when tapping the card
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(24),
                      clipBehavior: Clip.antiAlias,
                      child: AchievementDetailSheet(
                        achievement: achievement,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? Colors.deepOrange.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                achievement.icon,
                color: isUnlocked ? Colors.deepOrange : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.black : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isUnlocked ? Icons.check_circle : Icons.lock,
              color: isUnlocked ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (trailing.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              trailing,
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }
}
