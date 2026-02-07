class POI {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String category;
  final String description;
  final String? imageUrl;

  POI({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.description,
    this.imageUrl,
  });

  // Desde JSON (para cargar desde archivo)
  factory POI.fromJson(Map<String, dynamic> json) {
    return POI(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      category: json['category'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  // Hacia JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  @override
  String toString() {
    return 'POI(id: $id, name: $name, category: $category)';
  }
}