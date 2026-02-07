import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../core/constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crear perfil de usuario nuevo
  Future<void> createUserProfile({
    required String userId,
    required String email,
  }) async {
    try {
      final userProfile = UserProfile(
        userId: userId,
        email: email,
        experiencePoints: 0,
        visitedPoiIds: [],
        completedRouteIds: [],
        achievementIds: [],
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .set(userProfile.toFirestore());
    } catch (e) {
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
      throw 'Error al obtener perfil: $e';
    }
  }

  /// Stream del perfil de usuario (para actualizaciones en tiempo real)
  Stream<UserProfile?> userProfileStream(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromFirestore(doc.data()!, userId);
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
      throw 'Error al actualizar perfil: $e';
    }
  }
}