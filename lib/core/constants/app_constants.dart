class AppConstants {
  // Geolocalización
  static const double proximityRadiusMeters = 50.0; // Radio para considerar "cerca" de un POI
  static const double mapZoomLevel = 14.0;
  
  // Milan coordinates (centro)
  static const double milanLat = 45.4642;
  static const double milanLng = 9.1900;
  
  // Gamificación
  static const int xpPerPoi = 100;
  static const int xpPerRoute = 500;
  
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String poisCollection = 'pois';
  
  // Achievement IDs
  static const String achievementFirstVisit = 'first_visit';
  static const String achievement5Pois = 'visit_5_pois';
  static const String achievement10Pois = 'visit_10_pois';
  static const String achievementFirstRoute = 'first_route';
}