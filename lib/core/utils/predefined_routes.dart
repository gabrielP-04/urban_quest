import 'package:urban_quest/models/route.dart';
import 'package:urban_quest/models/poi.dart';
import 'package:uuid/uuid.dart';

class PredefinedRoutes {
  static List<RouteModel> build(List<Poi> allPois) {
    final byCategory = <String, List<Poi>>{};

    for (final poi in allPois) {
      byCategory.putIfAbsent(poi.category, () => []).add(poi);
    }

    return [
      RouteModel(
        id: const Uuid().v4(),
        name: 'Historic Milan Walk',
        type: RouteType.historic,
        pois: byCategory['monument']?.take(6).toList() ?? [],
      ),
      RouteModel(
        id: const Uuid().v4(),
        name: 'Taste of Milan',
        type: RouteType.food,
        pois: byCategory['gastronomy']?.take(5).toList() ?? [],
      ),
      RouteModel(
        id: const Uuid().v4(),
        name: 'Cultural Highlights',
        type: RouteType.cultural,
        pois: byCategory['cultural']?.take(5).toList() ?? [],
      ),
      RouteModel(
        id: const Uuid().v4(),
        name: 'Best Viewpoints',
        type: RouteType.scenic,
        pois: byCategory['viewpoint']?.take(4).toList() ?? [],
      ),
    ];
  }
}
