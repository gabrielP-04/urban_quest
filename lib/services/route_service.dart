import 'package:urban_quest/models/route.dart';
import 'package:uuid/uuid.dart';
import 'package:urban_quest/models/poi.dart';

class RouteService {
  static RouteModel createRoute({
    required String name,
    required RouteType type,
    required List<Poi> pois,
  }) {
    return RouteModel(
      id: const Uuid().v4(),
      name: name,
      type: type,
      pois: pois,
    );
  }
}
