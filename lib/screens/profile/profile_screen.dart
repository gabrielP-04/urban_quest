import 'package:flutter/material.dart';
import 'package:urban_quest/screens/achievements/achievement_screen.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_profile.dart';
import '../../core/utils/profile_assets.dart';
import 'account_security_screen.dart';
import 'edit_profile_screen.dart';

// NUEVO: Importar gamificación
import 'package:urban_quest/services/gamification_services.dart';
import 'package:urban_quest/models/gamification_models.dart';

class ProfileScreen extends StatelessWidget {
  final bool showBottomNav;

  const ProfileScreen({
    Key? key,
    this.showBottomNav = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final userId = authService.currentUserId;
    
    // NUEVO: Controller de gamificación
    final gamificationController = GamificationController();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<UserProfile?>(
        stream: firestoreService.userProfileStream(userId!),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            );
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          // No profile found
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Profile not found'),
            );
          }

          final profile = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CAPA 1: User Info Card
                _buildUserInfoCard(context, profile),

                const SizedBox(height: 10),

                // CAPA 2 - TARJETA 1: Progress Card (ACTUALIZADA con gamificación real)
                _buildProgressCard(profile, userId, gamificationController),

                const SizedBox(height: 20),

                // Subtítulo antes de Stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Your Activity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),

                const SizedBox(height: 12),

                // CAPA 2 - TARJETA 2: Achievements, Ranking, Routes
                _buildActivityCard(context, profile, userId, gamificationController),

                const SizedBox(height: 20),

                // NUEVO: Estadísticas de gamificación
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Statistics',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),

                const SizedBox(height: 12),

                _buildStatisticsCard(userId, gamificationController),

                const SizedBox(height: 20),

                // Subtítulo Settings
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),

                const SizedBox(height: 12),

                // CAPA 2 - TARJETA 3: Settings Options
                _buildSettingsCard(context),

                const SizedBox(height: 24),

                // Logout Button
                _buildLogoutButton(context, authService),

                const SizedBox(height: 100), // Space for bottom nav
              ],
            ),
          );
        },
      ),
    );
  }

  // ============ CAPA 1: USER INFO CARD CON BANNER Y AVATAR PERSONALIZADO ============
  Widget _buildUserInfoCard(BuildContext context, UserProfile profile) {
    // Obtener el avatar y banner personalizados del usuario
    final avatar = ProfileAssets.getAvatar(profile.avatarId);
    final banner = ProfileAssets.getBanner(profile.bannerId);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Stack con banner y avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Banner con gradiente personalizado
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: banner.gradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),

              // Avatar circular personalizado sobre el banner
              Positioned(
                bottom: -40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: avatar.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        avatar.emoji,
                        style: const TextStyle(fontSize: 44),
                      ),
                    ),
                  ),
                ),
              ),

              // Botón de editar
              Positioned(
                right: 12,
                top: 12,
                child: Material(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditProfileScreen(profile: profile),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Información del usuario (debajo del avatar, sobre fondo blanco)
          const SizedBox(height: 50), // Espacio para el avatar que sobresale

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Nombre completo
                Text(
                  profile.fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // Username
                Text(
                  '@${profile.username}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF9E9E9E),
                  ),
                ),

                const SizedBox(height: 16),

                // Stats rápidas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickStat('${profile.totalPoisVisited}', 'POIs'),
                    _buildVerticalDivider(),
                    _buildQuickStat('${profile.totalRoutesCompleted}', 'Routes'),
                    _buildVerticalDivider(),
                    _buildQuickStat('${profile.totalAchievements}', 'Badges'),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.shade300,
    );
  }

  // ============ CAPA 2 - TARJETA 1: PROGRESS CARD (ACTUALIZADA) ============
  Widget _buildProgressCard(UserProfile profile, String userId, GamificationController controller) {
    return FutureBuilder<GamificationData>(
      future: controller.experienceService.getUserGamificationData(userId),
      builder: (context, snapshot) {
        // Si está cargando o hay error, mostrar versión simplificada
        if (!snapshot.hasData) {
          final level = (profile.experiencePoints / 250).floor() + 1;
          final currentLevelXP = profile.experiencePoints % 250;
          final nextLevelXP = 250;
          final progress = currentLevelXP / nextLevelXP;

          return _buildProgressCardContent(level, currentLevelXP, nextLevelXP, progress, null);
        }

        final data = snapshot.data!;
        
        // NUEVO: Obtener momentum si está activo
        return FutureBuilder<MomentumState>(
          future: controller.momentumService.getMomentumState(userId),
          builder: (context, momentumSnapshot) {
            final momentum = momentumSnapshot.data;
            
            return Column(
              children: [
                _buildProgressCardContent(
                  data.level,
                  data.currentLevelXP,
                  data.xpToNextLevel,
                  data.progressToNextLevel,
                  momentum,
                ),
                
                // NUEVO: Card de momentum activo (solo si está activo)
                if (momentum != null && momentum.isActive) ...[
                  const SizedBox(height: 12),
                  _buildMomentumCard(momentum),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProgressCardContent(
    int level,
    int currentLevelXP,
    int xpToNextLevel,
    double progress,
    MomentumState? momentum,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level Title con icono
          Row(
            children: [
              const Text('👑', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                'Level $level',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const Spacer(),
              Text(
                _getLevelTitle(level),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Bar con gradiente
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9A56), Color(0xFFFF7A3D)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // XP Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currentLevelXP / $xpToNextLevel XP',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5A5A5A),
                ),
              ),
              Text(
                'Level ${level + 1}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // NUEVO: Card de momentum activo
  Widget _buildMomentumCard(MomentumState momentum) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE5D1), Color(0xFFFFD4B3)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF9A56),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Text(
            momentum.level.icon,
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  momentum.level.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF7A3D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${momentum.sessionPOIsVisited} POIs this session',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5A5A5A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+${((momentum.multiplier - 1) * 100).toInt()}% XP Bonus Active',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF7A3D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLevelTitle(int level) {
    if (level < 5) return 'Explorer';
    if (level < 10) return 'Adventurer';
    if (level < 15) return 'Navigator';
    if (level < 20) return 'Voyager';
    if (level < 25) return 'Master';
    return 'Legend';
  }

  // ============ CAPA 2 - TARJETA 2: ACTIVITY (Achievements, Ranking, Routes) ============
  Widget _buildActivityCard(BuildContext context, UserProfile profile, String userId, GamificationController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActivityItem(
            icon: Icons.emoji_events_outlined,
            iconColor: Colors.deepOrange,
            title: 'Achievements',
            subtitle: '${profile.totalAchievements} unlocked',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AchievementsScreen(achievements: mockAchievements),
                ),
              );
            },
            isFirst: true,
          ),
          _buildDivider(),
          // NUEVO: Item de recompensas
          FutureBuilder<List<LevelReward>>(
            future: _getUnlockedRewards(userId, controller),
            builder: (context, snapshot) {
              final rewardCount = snapshot.data?.length ?? 0;
              return _buildActivityItem(
                icon: Icons.card_giftcard_outlined,
                iconColor: Colors.purple,
                title: 'Rewards',
                subtitle: '$rewardCount unlocked',
                onTap: () => _showRewardsDialog(context, userId, controller),
              );
            },
          ),
          _buildDivider(),
          _buildActivityItem(
            icon: Icons.leaderboard_outlined,
            iconColor: Colors.green,
            title: 'Ranking',
            subtitle: 'See your position',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ranking coming soon!')),
              );
            },
          ),
          _buildDivider(),
          _buildActivityItem(
            icon: Icons.route_outlined,
            iconColor: Colors.deepOrange,
            title: 'My Routes',
            subtitle: '${profile.totalRoutesCompleted} completed',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Routes coming soon!')),
              );
            },
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(20) : Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5A5A5A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFBDBDBD),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // NUEVO: Card de estadísticas
  Widget _buildStatisticsCard(String userId, GamificationController controller) {
    return FutureBuilder<GamificationDashboard>(
      future: controller.getUserDashboard(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final dashboard = snapshot.data!;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildStatRow('✨', 'Total XP Earned', '${dashboard.totalXP}'),
              const SizedBox(height: 16),
              _buildStatRow('🎯', 'Sessions Completed', '${dashboard.sessionStats.totalSessions}'),
              const SizedBox(height: 16),
              _buildStatRow('📊', 'Avg POIs / Session', dashboard.sessionStats.averagePOIsPerSession.toStringAsFixed(1)),
              const SizedBox(height: 16),
              _buildStatRow('🔥', 'Sessions w/ Momentum', '${dashboard.sessionStats.sessionsWithMomentum}'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String emoji, String label, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF5A5A5A),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF7A3D),
          ),
        ),
      ],
    );
  }

  // ============ CAPA 2 - TARJETA 3: SETTINGS OPTIONS ============
  Widget _buildSettingsCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Notifications settings coming soon!')),
              );
            },
            isFirst: true,
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.shield_outlined,
            title: 'Account & Security',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountSecurityScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.chat_bubble_outline,
            title: 'Suggestions & Help',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help center coming soon!')),
              );
            },
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(20) : Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF9E9E9E), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF5A5A5A),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFBDBDBD),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // Divider helper
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.shade200,
      ),
    );
  }

  // ============ LOGOUT BUTTON ============
  Widget _buildLogoutButton(BuildContext context, AuthService authService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9A56), Color(0xFFFF7A3D)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9A56).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text('Sign Out'),
                content: const Text('Are you sure you want to sign out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(color: Colors.deepOrange),
                    ),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await authService.signOut();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Sign Out',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ============ HELPER METHODS ============

  Future<List<LevelReward>> _getUnlockedRewards(String userId, GamificationController controller) async {
    final dashboard = await controller.getUserDashboard(userId);
    return LevelRewardsSystem.getAllRewardsUpToLevel(dashboard.currentLevel);
  }

  void _showRewardsDialog(BuildContext context, String userId, GamificationController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('🏆 Unlocked Rewards'),
        content: FutureBuilder<List<LevelReward>>(
          future: _getUnlockedRewards(userId, controller),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No rewards unlocked yet. Keep exploring!');
            }

            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final reward = snapshot.data![index];
                  return ListTile(
                    leading: Text(
                      reward.icon ?? '🏆',
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(reward.name),
                    subtitle: Text('Level ${reward.level}'),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}