import 'package:flutter/material.dart';

class ProfileAssets {
  // Avatares predefinidos
  static const List<AvatarOption> avatars = [
    AvatarOption(id: 'avatar_1', emoji: '😊', color: Color(0xFFFFB74D)),
    AvatarOption(id: 'avatar_2', emoji: '🚀', color: Color(0xFF64B5F6)),
    AvatarOption(id: 'avatar_3', emoji: '🎨', color: Color(0xFFBA68C8)),
    AvatarOption(id: 'avatar_4', emoji: '🌟', color: Color(0xFFFFD54F)),
    AvatarOption(id: 'avatar_5', emoji: '🎭', color: Color(0xFFE57373)),
    AvatarOption(id: 'avatar_6', emoji: '🎸', color: Color(0xFF81C784)),
    AvatarOption(id: 'avatar_7', emoji: '⚡', color: Color(0xFFFFB74D)),
    AvatarOption(id: 'avatar_8', emoji: '🔥', color: Color(0xFFFF7043)),
    AvatarOption(id: 'avatar_9', emoji: '💎', color: Color(0xFF4FC3F7)),
    AvatarOption(id: 'avatar_10', emoji: '🌈', color: Color(0xFF9575CD)),
    AvatarOption(id: 'avatar_11', emoji: '🎯', color: Color(0xFFEF5350)),
    AvatarOption(id: 'avatar_12', emoji: '🏆', color: Color(0xFFFFCA28)),
  ];

  // Banners predefinidos
  static const List<BannerOption> banners = [
    BannerOption(
      id: 'banner_1',
      gradient: LinearGradient(
        colors: [Color(0xFFFF9A56), Color(0xFFFFD54F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    BannerOption(
      id: 'banner_2',
      gradient: LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    BannerOption(
      id: 'banner_3',
      gradient: LinearGradient(
        colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    BannerOption(
      id: 'banner_4',
      gradient: LinearGradient(
        colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    BannerOption(
      id: 'banner_5',
      gradient: LinearGradient(
        colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    BannerOption(
      id: 'banner_6',
      gradient: LinearGradient(
        colors: [Color(0xFFfa709a), Color(0xFFfee140)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    BannerOption(
      id: 'banner_7',
      gradient: LinearGradient(
        colors: [Color(0xFF30cfd0), Color(0xFF330867)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    BannerOption(
      id: 'banner_8',
      gradient: LinearGradient(
        colors: [Color(0xFFa8edea), Color(0xFFfed6e3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  static AvatarOption getAvatar(String id) {
    return avatars.firstWhere(
      (avatar) => avatar.id == id,
      orElse: () => avatars[0],
    );
  }

  static BannerOption getBanner(String id) {
    return banners.firstWhere(
      (banner) => banner.id == id,
      orElse: () => banners[0],
    );
  }
}

class AvatarOption {
  final String id;
  final String emoji;
  final Color color;

  const AvatarOption({
    required this.id,
    required this.emoji,
    required this.color,
  });
}

class BannerOption {
  final String id;
  final Gradient gradient;

  const BannerOption({
    required this.id,
    required this.gradient,
  });
}