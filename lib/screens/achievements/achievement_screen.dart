import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/achievement.dart';
import '../../services/achievement_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  final _achievementService = AchievementService();
  late TabController _tabController;

  bool _isLoading = true;
  List<AchievementProgress> _allProgress = [];
  AchievementCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAchievements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAchievements() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Obtener datos del usuario desde Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      final userData = userDoc.data()!;
      final totalPois = (userData['visitedPoiIds'] as List?)?.length ?? 0;
      final totalRoutes = (userData['completedRouteIds'] as List?)?.length ?? 0;
      final experiencePoints = userData['experiencePoints'] as int? ?? 0;

      // Calcular nivel
      final currentLevel = (experiencePoints / 250).floor() + 1;

      // Obtener progreso de achievements
      final progress = await _achievementService.getAchievementProgress(
        userId: userId,
        totalPoisVisited: totalPois,
        totalRoutesCompleted: totalRoutes,
        currentLevel: currentLevel,
        momentumActivations: userData['totalMomentumActivations'] as int? ?? 0,
        hasReachedBlazingMomentum:
            userData['hasReachedBlazingMomentum'] as bool? ?? false,
      );

      setState(() {
        _allProgress = progress;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading achievements: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF5A5A5A)),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Achievements',
        style: TextStyle(
          color: Color(0xFF5A5A5A),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      shadowColor: Colors.black.withOpacity(0.1),
      backgroundColor: Colors.white,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.deepOrange,
            indicatorWeight: 3,
            labelColor: Colors.deepOrange,
            unselectedLabelColor: Colors.grey.shade600,
            labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.normal,
            ),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Unlocked'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildStatsHeader(),
        _buildCategoryFilter(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAllAchievements(),
              _buildUnlockedAchievements(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader() {
    final totalAchievements = _allProgress.length;
    final unlockedCount = _allProgress.where((a) => a.isUnlocked).length;
    final percentage = totalAchievements > 0
        ? (unlockedCount / totalAchievements * 100).round()
        : 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepOrange, Colors.orangeAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Achievement Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$unlockedCount / $totalAchievements',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$percentage% Complete',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryChip('All', null),
          _buildCategoryChip(
              '🗺️ Exploration', AchievementCategory.exploration),
          _buildCategoryChip('🏛️ Culture', AchievementCategory.culture),
          _buildCategoryChip('🍕 Food', AchievementCategory.food),
          _buildCategoryChip('🚶 Routes', AchievementCategory.routes),
          _buildCategoryChip('👥 Social', AchievementCategory.social),
          _buildCategoryChip('✨ Special', AchievementCategory.special),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, AchievementCategory? category) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
        },
        selectedColor: Colors.deepOrange.withOpacity(0.2),
        checkmarkColor: Colors.deepOrange,
        labelStyle: TextStyle(
          color: isSelected ? Colors.deepOrange : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildAllAchievements() {
    final filtered = _selectedCategory == null
        ? _allProgress
        : _allProgress
            .where((ap) => ap.achievement.category == _selectedCategory)
            .toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text('No achievements in this category'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildAchievementCard(filtered[index]);
      },
    );
  }

  Widget _buildUnlockedAchievements() {
    final unlocked = _allProgress.where((ap) => ap.isUnlocked).toList();

    final filtered = _selectedCategory == null
        ? unlocked
        : unlocked
            .where((ap) => ap.achievement.category == _selectedCategory)
            .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No achievements unlocked yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep exploring to unlock your first achievement!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildAchievementCard(filtered[index]);
      },
    );
  }

  Widget _buildAchievementCard(AchievementProgress progress) {
    final achievement = progress.achievement;
    final isUnlocked = progress.isUnlocked;
    final rarityColor = Color(achievement.rarity.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? rarityColor.withOpacity(0.3) : Colors.grey[300]!,
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: [
          if (isUnlocked)
            BoxShadow(
              color: rarityColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildAchievementIcon(achievement, isUnlocked, rarityColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? Colors.black : Colors.grey[600],
                          ),
                        ),
                      ),
                      _buildRarityBadge(achievement.rarity),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!isUnlocked) _buildProgressBar(progress),
                  if (isUnlocked) _buildUnlockedInfo(achievement),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementIcon(
    Achievement achievement,
    bool isUnlocked,
    Color rarityColor,
  ) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: isUnlocked ? rarityColor.withOpacity(0.15) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked ? rarityColor : Colors.grey[400]!,
          width: 2,
        ),
      ),
      child: Center(
        child: isUnlocked
            ? Text(
                achievement.emoji,
                style: const TextStyle(fontSize: 32),
              )
            : Icon(
                Icons.lock_outline,
                size: 32,
                color: Colors.grey[400],
              ),
      ),
    );
  }

  Widget _buildRarityBadge(AchievementRarity rarity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(rarity.colorValue).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        rarity.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(rarity.colorValue),
        ),
      ),
    );
  }

  Widget _buildProgressBar(AchievementProgress progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.progressPercentage,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.deepOrange,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${progress.currentProgress}/${progress.achievement.requiredProgress}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          progress.progressMessage,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildUnlockedInfo(Achievement achievement) {
    return Row(
      children: [
        Icon(
          Icons.stars,
          size: 16,
          color: Colors.amber[700],
        ),
        const SizedBox(width: 4),
        Text(
          '+${achievement.xpReward} XP',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.amber[700],
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          Icons.check_circle,
          size: 16,
          color: Colors.green[600],
        ),
        const SizedBox(width: 4),
        Text(
          'Unlocked',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.green[600],
          ),
        ),
      ],
    );
  }
}
