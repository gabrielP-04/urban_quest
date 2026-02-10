import 'package:flutter/material.dart';
import 'package:urban_quest/screens/main_scaffold.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_profile.dart';
import '../../core/utils/profile_assets.dart';
import 'package:urban_quest/models/gamification_models.dart';
import 'package:urban_quest/services/gamification_services.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final gamificationController = GamificationController();

    final currentUserId = authService.currentUserId;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<UserProfile?>(
          stream: firestoreService.userProfileStream(currentUserId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.deepOrange),
              );
            }

            final profile = snapshot.data;
            if (profile == null) {
              return const Center(child: Text('Profile not found'));
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // ⬇️ ESPERAMOS a GamificationData
                    FutureBuilder<GamificationData>(
                      future: gamificationController.experienceService
                          .getUserGamificationData(currentUserId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(
                              color: Colors.deepOrange,
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const SizedBox(); // o Text de error si quieres
                        }

                        return _ProfileHeader(
                          profile: profile,
                          data: snapshot.data!,
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    _MapCard(profile: profile),
                    const SizedBox(height: 16),
                    _StatsCard(profile: profile),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ==================== PROFILE HEADER ====================
class _ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final GamificationData data;

  const _ProfileHeader({
    required this.profile,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = ProfileAssets.getAvatar(profile.avatarId);

    final int level = data.level;
    final double progress = data.progressToNextLevel;
    final int xp = profile.experiencePoints;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar con nivel REAL
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatar.color,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: avatar.color.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    avatar.emoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),

              // Badge de nivel
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    'Lv $level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Info del usuario
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, ${profile.firstName.isNotEmpty ? profile.firstName : profile.username}!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                Text(
                  profile.fullName.isNotEmpty
                      ? profile.fullName
                      : profile.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Barra de progreso REAL
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nivel $level',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$xp XP',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            const AlwaysStoppedAnimation(Colors.deepOrange),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== MAP CARD ====================
class _MapCard extends StatelessWidget {
  final UserProfile profile;

  const _MapCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    // Calcular progreso del mapa (ejemplo basado en POIs visitados)
    final totalPois = 50; // Esto debería venir de tu configuración
    final discoveredPercent =
        ((profile.totalPoisVisited / totalPois) * 100).clamp(0, 100).round();

    return GestureDetector(
      onTap: () {
        MainScaffold.of(context)?.changeTab(1);
      },
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Fondo del mapa
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade200,
                        Colors.blue.shade100,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // Icono de mapa decorativo
              Positioned.fill(
                child: Opacity(
                  opacity: 0.15,
                  child: Icon(
                    Icons.map_outlined,
                    size: 200,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              // Indicador de ubicación central
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.deepOrange,
                    size: 32,
                  ),
                ),
              ),
              // Marcadores decorativos (POIs simulados)
              Positioned(
                top: 50,
                left: 80,
                child: _MapMarker(Icons.restaurant, Colors.orange.shade700),
              ),
              Positioned(
                top: 70,
                right: 70,
                child: _MapMarker(Icons.account_balance, Colors.blue.shade700),
              ),
              Positioned(
                bottom: 100,
                left: 60,
                child: _MapMarker(Icons.camera_alt, Colors.purple.shade700),
              ),
              Positioned(
                bottom: 80,
                right: 90,
                child: _MapMarker(Icons.park, Colors.green.shade700),
              ),
              // Indicador de progreso
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D3748),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.explore,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mapa Descubierto: $discoveredPercent%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                height: 6,
                                child: LinearProgressIndicator(
                                  value: discoveredPercent / 100,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.3),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Colors.deepOrange,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _MapMarker(this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }
}

// ==================== STATS CARD ====================
class _StatsCard extends StatelessWidget {
  final UserProfile profile;

  const _StatsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    // Calcular progreso del mapa
    final totalPois = 50;
    final discoveredPercent =
        ((profile.totalPoisVisited / totalPois) * 100).clamp(0, 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.place,
              color: Colors.blue,
              label: 'Lugares\nVisitados',
              value: '${profile.totalPoisVisited}',
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.grey.shade200,
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.check_circle,
              color: Colors.green,
              label: 'Rutas\nCompletadas',
              value: '${profile.totalRoutesCompleted}',
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.grey.shade200,
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.emoji_events,
              color: Colors.amber,
              label: 'Logros',
              value: '${profile.totalAchievements}',
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.grey.shade200,
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.map,
              color: Colors.deepOrange,
              label: 'Mapa',
              value: '$discoveredPercent%',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
