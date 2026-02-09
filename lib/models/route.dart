import 'package:urban_quest/models/poi.dart';

enum RouteType {
  historic,
  food,
  cultural,
  scenic,
}

class RouteModel {
  final String id;
  final String name;
  final RouteType type;
  final List<Poi> pois;

  RouteModel({
    required this.id,
    required this.name,
    required this.type,
    required this.pois,
  });
}
