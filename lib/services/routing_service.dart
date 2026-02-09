import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  static const _baseUrl = 'https://router.project-osrm.org';

  static Future<RouteSegment> getRoute(
    LatLng start,
    LatLng end,
  ) async {
    final url = '$_baseUrl/route/v1/foot/${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('OSRM routing failed');
    }

    final data = jsonDecode(response.body);
    final route = data['routes'][0];

    final coords = route['geometry']['coordinates'] as List;

    return RouteSegment(
      points: coords.map((c) => LatLng(c[1], c[0])).toList(),
      distanceMeters: (route['distance'] as num).toDouble(),
      durationSeconds: (route['duration'] as num).toDouble(),
    );
  }
}

class RouteSegment {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  RouteSegment({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}
