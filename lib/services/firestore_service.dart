import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String firstName,
    required String lastName,
    required String username,
  }) async {
    try {
      
      final docRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);
      
      final docSnapshot = await docRef.get();
           
      if (docSnapshot.exists) {
        debugPrint('El perfil ya existe para el usuario $userId');
        return;
      }
     
      final displayName = '$firstName $lastName'.trim();
      
      final now = DateTime.now();
      final userProfile = {
        'email': email,
        'displayName': displayName,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'avatarId': 'avatar_1',           
        'bannerId': 'banner_1',           
        'profileTitle': 'Urban Explorer', 
        'experiencePoints': 0,
        'visitedPoiIds': [],
        'completedRouteIds': [],
        'achievementIds': [],
        'createdAt': now.toIso8601String(),
        'lastActive': now.toIso8601String(),
      };

      await docRef.set(userProfile);
      debugPrint('Perfil creado exitosamente para $displayName (@$username)');
    } catch (e) {
      debugPrint('Error al crear perfil en Firestore: $e');
      throw 'Error al crear perfil: $e';
    }
  }
 
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserProfile.fromFirestore(doc.data()!, userId);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener perfil: $e');
      return null;
    }
  }
  
  Stream<UserProfile?> userProfileStream(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        try {
          return UserProfile.fromFirestore(doc.data()!, userId);
        } catch (e) {
          debugPrint('Error al parsear perfil: $e');
          return null;
        }
      }
      return null;
    });
  }

  
  Future<void> updateUserEmail({
    required String userId,
    required String email,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'email': email,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error al actualizar email: $e');
      throw 'Error al actualizar email: $e';
    }
  }

  
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(profile.userId)
          .update(profile.toFirestore());
    } catch (e) {
      debugPrint('Error al actualizar perfil: $e');
      throw 'Error al actualizar perfil: $e';
    }
  }
}