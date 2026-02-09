import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para gestionar POIs visitados en local storage
/// IMPORTANTE: Ahora guarda por usuario para evitar conflictos entre cuentas
class VisitedPoiStorage {
  static const String _keyPrefix = 'visited_poi_ids';

  /// Obtiene la key específica para el usuario actual
  /// Si no hay userId, usa una key por defecto (para backwards compatibility)
  static String _getKeyForUser(String? userId) {
    if (userId == null || userId.isEmpty) {
      return _keyPrefix; // Key legacy
    }
    return '${_keyPrefix}_$userId';
  }

  /// Guarda los IDs de POIs visitados para un usuario específico
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

  /// Carga los IDs de POIs visitados para un usuario específico
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

  /// Limpia los POIs visitados para un usuario específico
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

  /// Limpia TODOS los datos de POIs visitados (útil para testing)
  static Future<void> clearAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      // Eliminar todas las keys que empiecen con el prefijo
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

  /// Migra datos de la key legacy a la key específica del usuario
  /// Útil para usuarios existentes que usaban la versión anterior
  static Future<void> migrateLegacyData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Verificar si hay datos en la key legacy
      final legacyData = prefs.getStringList(_keyPrefix);
      if (legacyData == null || legacyData.isEmpty) {
        return; // No hay nada que migrar
      }

      // Guardar en la nueva key específica del usuario
      final newKey = _getKeyForUser(userId);
      if (!prefs.containsKey(newKey)) {
        await prefs.setStringList(newKey, legacyData);
        print('✅ Migrated ${legacyData.length} POIs to user-specific key');
      }

      // Opcionalmente, eliminar la key legacy
      // await prefs.remove(_keyPrefix);
    } catch (e) {
      print('❌ Error migrating legacy data: $e');
    }
  }

  /// Debug: Lista todas las keys de POIs guardadas
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