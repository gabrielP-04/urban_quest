import 'package:flutter/material.dart';
import '../../widgets/bottom_nav.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_profile.dart';
import 'account_security_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final userId = authService.currentUserId;

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

                // CAPA 2 - TARJETA 1: Progress Card
                _buildProgressCard(profile),

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
                _buildActivityCard(context, profile),

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
      bottomNavigationBar: const BottomNav(currentIndex: 3),
    );
  }

  // ============ CAPA 1: USER INFO CARD ============
  Widget _buildUserInfoCard(BuildContext context, UserProfile profile) {
  return Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.deepOrange.shade50,
          Colors.orange.shade50,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        // Avatar
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              profile.firstName.isNotEmpty
                  ? profile.firstName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Name and Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.fullName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A5A5A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '@${profile.username}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('🇮🇹', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    'Urban Explorer',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Edit button
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(profile: profile),
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
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
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
      ],
    ),
  );
}

  // ============ CAPA 2 - TARJETA 1: PROGRESS CARD ============
  Widget _buildProgressCard(UserProfile profile) {
    // Calcular nivel basado en XP
    final int level = (profile.experiencePoints / 250).floor() + 1;
    final int currentLevelXP = profile.experiencePoints % 250;
    final int nextLevelXP = 250;
    final double progress = currentLevelXP / nextLevelXP;

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
          // Level Title
          Row(
            children: [
              const Text('👑', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                'Level $level',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Urban Explorer',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF5A5A5A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress Bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.deepOrange,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$currentLevelXP / $nextLevelXP XP',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9E9E9E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Category Icons (placeholder - sin datos aún)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCategoryBadge('🏛️', locked: true),
              _buildCategoryBadge('🗺️', locked: true),
              _buildCategoryBadge('🍔', locked: true),
              _buildCategoryBadge('📸', locked: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String emoji, {bool locked = false}) {
    return Opacity(
      opacity: locked ? 0.3 : 1.0,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: locked ? Colors.grey.shade300 : Colors.deepOrange.shade200,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 26),
          ),
        ),
      ),
    );
  }

  // ============ CAPA 2 - TARJETA 2: ACTIVITY (Achievements, Ranking, Routes) ============
  Widget _buildActivityCard(BuildContext context, UserProfile profile) {
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Achievements coming soon!')),
              );
            },
            isFirst: true,
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
              color: const Color(0xFFFF9A56).withOpacity(0.3),
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
}
