import 'package:cloud_firestore/cloud_firestore.dart';

class MomentumService {
  final FirebaseFirestore _firestore;

  MomentumService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  
  static const int SESSION_DURATION_HOURS = 6;
  
  static const int MIN_POIS_FOR_MOMENTUM = 3;
  
  static const double MOMENTUM_MULTIPLIER = 1.3; 
  
  static const double HIGH_MOMENTUM_MULTIPLIER = 1.5;  

  
  Future<MomentumState> updateMomentum(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado: $userId');
      }

      final userData = userDoc.data()!;
      final sessionStartTimestamp =
          userData['currentSessionStart'] as Timestamp?;
      final sessionPOIs = userData['currentSessionPOIs'] as int? ?? 0;

      final now = DateTime.now();

      
      if (sessionStartTimestamp == null ||
          _isSessionExpired(sessionStartTimestamp.toDate(), now)) {
        
        await userRef.update({
          'currentSessionStart': FieldValue.serverTimestamp(),
          'currentSessionPOIs': 1,
          'currentSessionXP': 0,
        });

        return MomentumState(
          isActive: false,
          sessionPOIsVisited: 1,
          sessionDuration: Duration.zero,
          multiplier: 1.0,
          level: MomentumLevel.none,
        );
      }

      
      final newSessionPOIs = sessionPOIs + 1;
      final sessionStart = sessionStartTimestamp.toDate();
      final sessionDuration = now.difference(sessionStart);

      
      final level = _calculateMomentumLevel(newSessionPOIs);
      final multiplier = _getMultiplier(level);

      
      if (level != MomentumLevel.none && sessionPOIs < MIN_POIS_FOR_MOMENTUM) {
        
        final userDoc = await userRef.get();
        final currentActivations =
            userDoc.data()?['totalMomentumActivations'] as int? ?? 0;

        await userRef.update({
          'totalMomentumActivations': currentActivations + 1,
        });
      }

      
      if (level == MomentumLevel.blazing) {
        await userRef.update({
          'hasReachedBlazingMomentum': true,
        });
      }

      await userRef.update({
        'currentSessionPOIs': newSessionPOIs,
        'lastActivityTime': FieldValue.serverTimestamp(),
      });

      return MomentumState(
        isActive: level != MomentumLevel.none,
        sessionPOIsVisited: newSessionPOIs,
        sessionDuration: sessionDuration,
        multiplier: multiplier,
        level: level,
      );
    } catch (e) {
      throw Exception('Error al actualizar momentum: $e');
    }
  }

  
  Future<bool> hasMomentum(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final sessionStartTimestamp =
          userData['currentSessionStart'] as Timestamp?;
      final sessionPOIs = userData['currentSessionPOIs'] as int? ?? 0;

      if (sessionStartTimestamp == null) return false;

      final sessionStart = sessionStartTimestamp.toDate();
      final isExpired = _isSessionExpired(sessionStart, DateTime.now());

      return !isExpired && sessionPOIs >= MIN_POIS_FOR_MOMENTUM;
    } catch (e) {
      return false;
    }
  }

  
  Future<MomentumState> getMomentumState(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return MomentumState(
          isActive: false,
          sessionPOIsVisited: 0,
          sessionDuration: Duration.zero,
          multiplier: 1.0,
          level: MomentumLevel.none,
        );
      }

      final userData = userDoc.data()!;
      final sessionStartTimestamp =
          userData['currentSessionStart'] as Timestamp?;
      final sessionPOIs = userData['currentSessionPOIs'] as int? ?? 0;

      if (sessionStartTimestamp == null) {
        return MomentumState(
          isActive: false,
          sessionPOIsVisited: 0,
          sessionDuration: Duration.zero,
          multiplier: 1.0,
          level: MomentumLevel.none,
        );
      }

      final sessionStart = sessionStartTimestamp.toDate();
      final now = DateTime.now();
      final isExpired = _isSessionExpired(sessionStart, now);

      if (isExpired) {
        return MomentumState(
          isActive: false,
          sessionPOIsVisited: 0,
          sessionDuration: Duration.zero,
          multiplier: 1.0,
          level: MomentumLevel.none,
        );
      }

      final sessionDuration = now.difference(sessionStart);
      final level = _calculateMomentumLevel(sessionPOIs);
      final multiplier = _getMultiplier(level);

      return MomentumState(
        isActive: level != MomentumLevel.none,
        sessionPOIsVisited: sessionPOIs,
        sessionDuration: sessionDuration,
        multiplier: multiplier,
        level: level,
      );
    } catch (e) {
      throw Exception('Error al obtener estado de momentum: $e');
    }
  }

  
  Future<SessionSummary> endSession(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado: $userId');
      }

      final userData = userDoc.data()!;
      final sessionStartTimestamp =
          userData['currentSessionStart'] as Timestamp?;
      final sessionPOIs = userData['currentSessionPOIs'] as int? ?? 0;
      final sessionXP = userData['currentSessionXP'] as int? ?? 0;

      if (sessionStartTimestamp == null) {
        return SessionSummary(
          poisVisited: 0,
          duration: Duration.zero,
          xpEarned: 0,
          hadMomentum: false,
        );
      }

      final sessionStart = sessionStartTimestamp.toDate();
      final sessionDuration = DateTime.now().difference(sessionStart);
      final hadMomentum = sessionPOIs >= MIN_POIS_FOR_MOMENTUM;

      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .add({
        'startTime': sessionStartTimestamp,
        'endTime': FieldValue.serverTimestamp(),
        'duration': sessionDuration.inMinutes,
        'poisVisited': sessionPOIs,
        'xpEarned': sessionXP,
        'hadMomentum': hadMomentum,
      });

      
      await userRef.update({
        'currentSessionStart': null,
        'currentSessionPOIs': 0,
        'currentSessionXP': 0,
        'lastSessionPOIs': sessionPOIs,
        'lastSessionDate': FieldValue.serverTimestamp(),
      });

      return SessionSummary(
        poisVisited: sessionPOIs,
        duration: sessionDuration,
        xpEarned: sessionXP,
        hadMomentum: hadMomentum,
      );
    } catch (e) {
      throw Exception('Error al finalizar sesión: $e');
    }
  }

  
  Future<SessionStats> getSessionStats(String userId) async {
    try {
      final sessionsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .orderBy('endTime', descending: true)
          .limit(20)
          .get();

      int totalSessions = sessionsSnapshot.docs.length;
      int totalPOIs = 0;
      int sessionsWithMomentum = 0;
      Duration totalDuration = Duration.zero;

      for (var doc in sessionsSnapshot.docs) {
        final data = doc.data();
        totalPOIs += data['poisVisited'] as int? ?? 0;
        totalDuration += Duration(minutes: data['duration'] as int? ?? 0);
        if (data['hadMomentum'] as bool? ?? false) {
          sessionsWithMomentum++;
        }
      }

      final avgPOIsPerSession =
          totalSessions > 0 ? totalPOIs / totalSessions : 0.0;
      final avgDuration = totalSessions > 0
          ? Duration(minutes: (totalDuration.inMinutes / totalSessions).round())
          : Duration.zero;

      return SessionStats(
        totalSessions: totalSessions,
        totalPOIsVisited: totalPOIs,
        averagePOIsPerSession: avgPOIsPerSession,
        averageSessionDuration: avgDuration,
        sessionsWithMomentum: sessionsWithMomentum,
      );
    } catch (e) {
      throw Exception('Error al obtener estadísticas de sesiones: $e');
    }
  }

  

  
  bool _isSessionExpired(DateTime sessionStart, DateTime now) {
    final hoursSinceStart = now.difference(sessionStart).inHours;
    return hoursSinceStart >= SESSION_DURATION_HOURS;
  }

  
  MomentumLevel _calculateMomentumLevel(int poisVisited) {
    if (poisVisited < MIN_POIS_FOR_MOMENTUM) {
      return MomentumLevel.none;
    } else if (poisVisited < 5) {
      return MomentumLevel.active;
    } else if (poisVisited < 8) {
      return MomentumLevel.high;
    } else {
      return MomentumLevel.blazing;
    }
  }

  
  double _getMultiplier(MomentumLevel level) {
    switch (level) {
      case MomentumLevel.none:
        return 1.0;
      case MomentumLevel.active:
        return 1.2; 
      case MomentumLevel.high:
        return 1.4; 
      case MomentumLevel.blazing:
        return 1.6; 
    }
  }

  

  
  Future<void> resetMomentum(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'currentSessionStart': null,
      'currentSessionPOIs': 0,
      'currentSessionXP': 0,
      'lastActivityTime': null,
    });
  }
}




enum MomentumLevel {
  none('No Momentum', ''),
  active('Active', '🔥'),
  high('High Momentum', '🔥🔥'),
  blazing('Blazing!', '🔥🔥🔥');

  final String displayName;
  final String icon;
  const MomentumLevel(this.displayName, this.icon);
}


class MomentumState {
  
  final bool isActive;

  
  final int sessionPOIsVisited;

  
  final Duration sessionDuration;

  
  final double multiplier;

  
  final MomentumLevel level;

  MomentumState({
    required this.isActive,
    required this.sessionPOIsVisited,
    required this.sessionDuration,
    required this.multiplier,
    required this.level,
  });

  
  String get statusMessage {
    if (!isActive) {
      return 'Visit ${MomentumService.MIN_POIS_FOR_MOMENTUM} POIs to activate momentum!';
    }
    return '${level.icon} ${level.displayName} - ${(multiplier * 100 - 100).toInt()}% XP Bonus!';
  }

  
  int get poisToNextLevel {
    switch (level) {
      case MomentumLevel.none:
        return MomentumService.MIN_POIS_FOR_MOMENTUM - sessionPOIsVisited;
      case MomentumLevel.active:
        return 5 - sessionPOIsVisited;
      case MomentumLevel.high:
        return 8 - sessionPOIsVisited;
      case MomentumLevel.blazing:
        return 0;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'isActive': isActive,
      'sessionPOIsVisited': sessionPOIsVisited,
      'sessionDurationMinutes': sessionDuration.inMinutes,
      'multiplier': multiplier,
      'level': level.name,
      'statusMessage': statusMessage,
    };
  }

  @override
  String toString() {
    return 'MomentumState(${level.displayName}, ${sessionPOIsVisited} POIs, x${multiplier.toStringAsFixed(1)})';
  }
}


class SessionSummary {
  final int poisVisited;
  final Duration duration;
  final int xpEarned;
  final bool hadMomentum;

  SessionSummary({
    required this.poisVisited,
    required this.duration,
    required this.xpEarned,
    required this.hadMomentum,
  });

  @override
  String toString() {
    return 'SessionSummary($poisVisited POIs, ${duration.inMinutes}min, $xpEarned XP${hadMomentum ? ' 🔥' : ''})';
  }
}


class SessionStats {
  final int totalSessions;
  final int totalPOIsVisited;
  final double averagePOIsPerSession;
  final Duration averageSessionDuration;
  final int sessionsWithMomentum;

  SessionStats({
    required this.totalSessions,
    required this.totalPOIsVisited,
    required this.averagePOIsPerSession,
    required this.averageSessionDuration,
    required this.sessionsWithMomentum,
  });

  
  double get momentumRate {
    return totalSessions > 0
        ? (sessionsWithMomentum / totalSessions) * 100
        : 0.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'totalSessions': totalSessions,
      'totalPOIsVisited': totalPOIsVisited,
      'averagePOIsPerSession': averagePOIsPerSession,
      'averageSessionDuration': averageSessionDuration.inMinutes,
      'sessionsWithMomentum': sessionsWithMomentum,
      'momentumRate': momentumRate,
    };
  }

  @override
  String toString() {
    return 'SessionStats($totalSessions sessions, avg ${averagePOIsPerSession.toStringAsFixed(1)} POIs/session)';
  }
}
