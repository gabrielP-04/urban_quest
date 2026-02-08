import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crear perfil de usuario nuevo con información completa
  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String firstName,
    required String lastName,
    required String username,
    required String country,
  }) async {
    try {
      // Verificar si ya existe el perfil
      final docRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);
      
      final docSnapshot = await docRef.get();
      
      // Si ya existe, no hacer nada
      if (docSnapshot.exists) {
        debugPrint('El perfil ya existe para el usuario $userId');
        return;
      }

      // Crear nombre completo para display
      final displayName = '$firstName $lastName'.trim();

      // Crear nuevo perfil
      final now = DateTime.now();
      final userProfile = {
        'email': email,
        'displayName': displayName,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'country': country,
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

  /// Obtener perfil de usuario
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

  /// Stream del perfil de usuario
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

  /// Actualizar perfil de usuario
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