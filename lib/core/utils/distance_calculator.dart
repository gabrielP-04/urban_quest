import 'dart:math';

class DistanceCalculator {
  /// Calcula la distancia entre dos puntos geográficos usando la fórmula de Haversine
  /// Retorna la distancia en metros
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusMeters = 6371000;

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  /// Verifica si un punto está dentro del radio especificado
  static bool isWithinRadius(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
    double radiusMeters,
  ) {
    return calculateDistance(lat1, lon1, lat2, lon2) <= radiusMeters;
  }

  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
}