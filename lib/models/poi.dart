class Poi {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String category;
  final String description;
  final bool isOptional;

  Poi({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.category,
    required this.description,
    required this.isOptional,
  });

  factory Poi.fromJson(Map<String, dynamic> json) {
    return Poi(
      id: json['id'],
      name: json['name'],
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      category: json['category'],
      description: json['description'],
      isOptional: json['isOptional'] ?? false,
    );
  }
}
