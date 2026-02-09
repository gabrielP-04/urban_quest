import 'package:shared_preferences/shared_preferences.dart';

class VisitedPoiStorage {
  static const _key = 'visited_poi_ids';

  static Future<Set<String>> loadVisitedPoiIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.toSet();
  }

  static Future<void> saveVisitedPoiIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.toList());
  }
}
