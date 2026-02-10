import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/poi.dart';

class PoiService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static Future<List<Poi>> loadPois() async {
    final jsonString = await rootBundle.loadString('assets/data/pois.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => Poi.fromJson(e)).toList();
  }
 
 static Future<Set<String>> getVisitedPoisFromFirestore() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return {};

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return {};

      final data = doc.data();
      
      final visitedPoiIds = data?['visitedPoiIds'] as List<dynamic>? ?? [];
      final visitedPOIsOld = data?['visitedPOIs'] as List<dynamic>? ?? [];

      return <String>{
        ...visitedPoiIds.cast<String>(),
        ...visitedPOIsOld.cast<String>(),
      };
    } catch (e) {
      print('Error loading visited POIs from Firestore: $e');
      return {};
    }
  }

  static Future<void> markPoiAsVisitedInFirestore(String poiId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'visitedPoiIds': FieldValue.arrayUnion([poiId]),
      });
    } catch (e) {
      print('Error saving visited POI to Firestore: $e');
      rethrow;
    }
  }

  static Future<Set<String>> syncVisitedPois(Set<String> localPois) async {
    final firestorePois = await getVisitedPoisFromFirestore();
    final combined = <String>{...localPois, ...firestorePois};

    if (combined.length > firestorePois.length) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        try {
          await _firestore.collection('users').doc(userId).update({
            'visitedPoiIds': combined.toList(),
          });
        } catch (e) {
          print('Error syncing POIs to Firestore: $e');
        }
      }
    }

    return combined;
  }

  
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

  
  static Future<bool> isPoiVisited(String poiId) async {
    final visitedPois = await getVisitedPoisFromFirestore();
    return visitedPois.contains(poiId);
  }

  
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