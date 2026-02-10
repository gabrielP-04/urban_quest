import 'package:shared_preferences/shared_preferences.dart';

class VisitedPoiStorage {
  static const String _keyPrefix = 'visited_poi_ids';

  static String _getKeyForUser(String? userId) {
    if (userId == null || userId.isEmpty) {
      return _keyPrefix; 
    }
    return '${_keyPrefix}_$userId';
  }

  
  static Future<void> saveVisitedPoiIds(
    Set<String> poiIds, {
    String? userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKeyForUser(userId);
      await prefs.setStringList(key, poiIds.toList());
      print('✅ Saved ${poiIds.length} visited POIs for user: ${userId ?? "default"}');
    } catch (e) {
      print('❌ Error saving visited POIs: $e');
    }
  }

  
  static Future<Set<String>> loadVisitedPoiIds({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKeyForUser(userId);
      final list = prefs.getStringList(key) ?? [];
      print('✅ Loaded ${list.length} visited POIs for user: ${userId ?? "default"}');
      return list.toSet();
    } catch (e) {
      print('❌ Error loading visited POIs: $e');
      return {};
    }
  }

  
  static Future<void> clearVisitedPoiIds({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKeyForUser(userId);
      await prefs.remove(key);
      print('✅ Cleared visited POIs for user: ${userId ?? "default"}');
    } catch (e) {
      print('❌ Error clearing visited POIs: $e');
    }
  }

  
  static Future<void> clearAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      
      for (final key in keys) {
        if (key.startsWith(_keyPrefix)) {
          await prefs.remove(key);
          print('✅ Cleared key: $key');
        }
      }
      print('✅ Cleared all visited POI data');
    } catch (e) {
      print('❌ Error clearing all data: $e');
    }
  }

  
  static Future<void> migrateLegacyData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      
      final legacyData = prefs.getStringList(_keyPrefix);
      if (legacyData == null || legacyData.isEmpty) {
        return; 
      }

      
      final newKey = _getKeyForUser(userId);
      if (!prefs.containsKey(newKey)) {
        await prefs.setStringList(newKey, legacyData);
        print('✅ Migrated ${legacyData.length} POIs to user-specific key');
      }

    } catch (e) {
      print('❌ Error migrating legacy data: $e');
    }
  }

  
  static Future<Map<String, int>> debugListAllKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final result = <String, int>{};
      
      for (final key in keys) {
        if (key.startsWith(_keyPrefix)) {
          final list = prefs.getStringList(key) ?? [];
          result[key] = list.length;
        }
      }
      
      return result;
    } catch (e) {
      print('❌ Error listing keys: $e');
      return {};
    }
  }
}