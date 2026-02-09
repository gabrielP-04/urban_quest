import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/poi.dart';

class PoiService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ============ MÉTODO ORIGINAL ============
  
  /// Carga los POIs desde el archivo JSON local (TU MÉTODO ORIGINAL)
  static Future<List<Poi>> loadPois() async {
    final jsonString = await rootBundle.loadString('assets/data/pois.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => Poi.fromJson(e)).toList();
  }
  
  // ============ MÉTODOS NUEVOS PARA GAMIFICACIÓN ============

  /// Marca un POI como visitado en Firestore
  /// Esto sincroniza el progreso del usuario en la nube
  static Future<void> markPoiAsVisitedInFirestore(String poiId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('User not authenticated, cannot save to Firestore');
      return;
    }

    try {
      // IMPORTANTE: Verificar que no esté ya marcado para evitar duplicados
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final currentVisited = userDoc.data()?['visitedPOIs'] as List<dynamic>? ?? [];
      
      if (currentVisited.contains(poiId)) {
        print('POI $poiId already marked as visited, skipping');
        return;
      }

      await _firestore.collection('users').doc(userId).set({
        'visitedPOIs': FieldValue.arrayUnion([poiId]),
        'totalPOIsVisited': FieldValue.increment(1),
        'lastVisitDate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('POI $poiId marked as visited in Firestore');
    } catch (e) {
      print('Error saving visited POI to Firestore: $e');
      rethrow;
    }
  }

  /// Obtiene la lista de POIs visitados desde Firestore
  static Future<Set<String>> getVisitedPoisFromFirestore() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('User not authenticated, cannot load from Firestore');
      return {};
    }

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        print('User document does not exist in Firestore');
        return {};
      }

      final data = doc.data();
      final visitedList = data?['visitedPOIs'] as List<dynamic>?;
      
      if (visitedList == null) {
        return {};
      }

      return visitedList.cast<String>().toSet();
    } catch (e) {
      print('Error loading visited POIs from Firestore: $e');
      return {};
    }
  }

  /// Sincroniza POIs visitados: combina local y Firestore
  /// Retorna el set combinado y lo guarda en ambos lugares
  static Future<Set<String>> syncVisitedPois(Set<String> localPois) async {
    final firestorePois = await getVisitedPoisFromFirestore();
    
    // Combinar ambos sets
    final combined = <String>{...localPois, ...firestorePois};
    
    // Si hay diferencias, actualizar Firestore
    if (combined.length > firestorePois.length) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        try {
          await _firestore.collection('users').doc(userId).update({
            'visitedPOIs': combined.toList(),
            'totalPOIsVisited': combined.length,
          });
        } catch (e) {
          print('Error syncing POIs to Firestore: $e');
        }
      }
    }
    
    return combined;
  }

  /// Obtiene el total de POIs visitados del usuario
  static Future<int> getTotalVisitedCount() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 0;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return 0;

      final data = doc.data();
      return data?['totalPOIsVisited'] as int? ?? 0;
    } catch (e) {
      print('Error getting total visited count: $e');
      return 0;
    }
  }

  /// Verifica si un POI específico ha sido visitado
  static Future<bool> isPoiVisited(String poiId) async {
    final visitedPois = await getVisitedPoisFromFirestore();
    return visitedPois.contains(poiId);
  }

  /// Obtiene estadísticas de visitas por categoría
  static Future<Map<String, int>> getVisitStatsByCategory(List<Poi> allPois) async {
    final visitedIds = await getVisitedPoisFromFirestore();
    final stats = <String, int>{};

    for (final poi in allPois) {
      if (visitedIds.contains(poi.id)) {
        stats[poi.category] = (stats[poi.category] ?? 0) + 1;
      }
    }

    return stats;
  }
}