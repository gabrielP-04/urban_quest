class UserProfile {
  final String userId;
  final String email;
  final String displayName;      // NUEVO
  final String username;         // NUEVO
  final String firstName;        // NUEVO
  final String lastName;         // NUEVO
  final String country;          // NUEVO
  final int experiencePoints;
  final List<String> visitedPoiIds;
  final List<String> completedRouteIds;
  final List<String> achievementIds;
  final DateTime createdAt;
  final DateTime lastActive;

  UserProfile({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.country,
    this.experiencePoints = 0,
    this.visitedPoiIds = const [],
    this.completedRouteIds = const [],
    this.achievementIds = const [],
    DateTime? createdAt,
    DateTime? lastActive,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastActive = lastActive ?? DateTime.now();

  // Desde Firestore
  factory UserProfile.fromFirestore(Map<String, dynamic> data, String userId) {
    return UserProfile(
      userId: userId,
      email: data['email'] as String,
      displayName: data['displayName'] as String? ?? '',
      username: data['username'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      country: data['country'] as String? ?? '',
      experiencePoints: data['experiencePoints'] as int? ?? 0,
      visitedPoiIds: List<String>.from(data['visitedPoiIds'] ?? []),
      completedRouteIds: List<String>.from(data['completedRouteIds'] ?? []),
      achievementIds: List<String>.from(data['achievementIds'] ?? []),
      createdAt: DateTime.parse(data['createdAt'] as String),
      lastActive: DateTime.parse(data['lastActive'] as String),
    );
  }

  // Hacia Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'country': country,
      'experiencePoints': experiencePoints,
      'visitedPoiIds': visitedPoiIds,
      'completedRouteIds': completedRouteIds,
      'achievementIds': achievementIds,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
    };
  }

  // Copiar con cambios
  UserProfile copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? username,
    String? firstName,
    String? lastName,
    String? country,
    int? experiencePoints,
    List<String>? visitedPoiIds,
    List<String>? completedRouteIds,
    List<String>? achievementIds,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      country: country ?? this.country,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      visitedPoiIds: visitedPoiIds ?? this.visitedPoiIds,
      completedRouteIds: completedRouteIds ?? this.completedRouteIds,
      achievementIds: achievementIds ?? this.achievementIds,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  int get totalPoisVisited => visitedPoiIds.length;
  int get totalRoutesCompleted => completedRouteIds.length;
  int get totalAchievements => achievementIds.length;
  
  // NUEVO: Nombre completo
  String get fullName => '$firstName $lastName'.trim();
}