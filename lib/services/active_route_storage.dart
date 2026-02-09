import 'package:shared_preferences/shared_preferences.dart';

class ActiveRouteStorage {
  static const _routeIdKey = 'active_route_id';

  static Future<void> saveActiveRouteId(String routeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_routeIdKey, routeId);
  }

  static Future<String?> loadActiveRouteId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_routeIdKey);
  }

  static Future<void> clearActiveRoute() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_routeIdKey);
  }
}
