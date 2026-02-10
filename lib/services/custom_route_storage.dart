import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urban_quest/models/route.dart';
import 'package:urban_quest/models/poi.dart';

class CustomRouteStorage {
  static const _key = 'custom_routes';

  static Future<void> saveRoutes(List<RouteModel> routes) async {
    final prefs = await SharedPreferences.getInstance();

    final data = routes.map((r) {
      return {
        'id': r.id,
        'name': r.name,
        'type': r.type.name,
        'pois': r.pois.map((p) => p.id).toList(),
      };
    }).toList();

    await prefs.setString(_key, jsonEncode(data));
  }

  static Future<List<RouteModel>> loadRoutes(List<Poi> allPois) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];

    final decoded = jsonDecode(raw) as List;

    return decoded.map((e) {
      final poiIds = List<String>.from(e['pois']);

      return RouteModel(
        id: e['id'],
        name: e['name'],
        type: RouteType.cultural,
        isCustom: true,
        pois: allPois.where((p) => poiIds.contains(p.id)).toList(),
      );
    }).toList();
  }
}