import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:urban_quest/models/poi.dart';
import 'package:urban_quest/services/location_service.dart';
import 'package:urban_quest/services/poi_service.dart';
import 'package:urban_quest/services/visited_poi_storage.dart';
import 'package:urban_quest/widgets/exploration_progress.dart';
import 'package:urban_quest/widgets/poi_marker.dart';

class MapScreen extends StatefulWidget {
  final bool showBottomNav;

  const MapScreen({
    Key? key,
    this.showBottomNav = true,
  }) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static final LatLng _milanCenter = LatLng(45.4642, 9.1900);
  Position? _userPosition;
  Poi? _nearbyPoi;

  List<Poi> _pois = [];
  bool _isLoading = true;

  final Set<String> _visitedPoiIds = {};

  int get _visitedCount => _visitedPoiIds.length;

  int get _totalPois => _pois.length;

  double get _progressPercent =>
      _totalPois == 0 ? 0 : _visitedCount / _totalPois;

  @override
  void initState() {
    super.initState();
    _loadPois();
    _loadUserLocation();
    _loadVisitedPois();
  }

  Future<void> _loadPois() async {
    final pois = await PoiService.loadPois();
    setState(() {
      _pois = pois;
      _isLoading = false;
    });
  }

  Future<void> _loadUserLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();
      setState(() {
        _userPosition = position;
      });
      _checkNearbyPoi();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _loadVisitedPois() async {
    final ids = await VisitedPoiStorage.loadVisitedPoiIds();
    setState(() {
      _visitedPoiIds.addAll(ids);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _milanCenter,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.example.urbanquest',
                    ),
                    if (_userPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              _userPosition!.latitude,
                              _userPosition!.longitude,
                            ),
                            width: 30,
                            height: 30,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: _pois.map(_buildMarker).toList(),
                    ),
                  ],
                ),
                _buildMapProgress(),
              ],
            ),
    );
  }

  Widget _buildMapProgress() {
  return Positioned(
    left: 16,
    right: 16,
    bottom: 24,
    child: ExplorationProgress(
      visited: _visitedPoiIds.length,
      total: _pois.length,
      compact: true,
    ),
  );
}


  Marker _buildMarker(Poi poi) {
    final isVisited = _visitedPoiIds.contains(poi.id);
    final isNearby = _nearbyPoi?.id == poi.id;

    return Marker(
      point: LatLng(poi.lat, poi.lng),
      width: 60,
      height: 60,
      child: GestureDetector(
        onTap: () => _showPoiDialog(poi),
        child: PoiMarker(
          icon: isVisited ? Icons.check : _iconForCategory(poi.category),
          color: isVisited ? Colors.grey : _colorForCategory(poi.category),
          isActive: isNearby,
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'monument':
        return Icons.account_balance;
      case 'culture':
        return Icons.museum;
      case 'food':
        return Icons.restaurant;
      case 'viewpoint':
        return Icons.visibility;
      default:
        return Icons.place;
    }
  }

  Color _colorForCategory(String category) {
    switch (category) {
      case 'monument':
        return Colors.deepOrange;
      case 'culture':
        return Colors.blue;
      case 'food':
        return Colors.green;
      case 'viewpoint':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showPoiDialog(Poi poi) {
    final isNearby = _nearbyPoi?.id == poi.id;
    final isVisited = _visitedPoiIds.contains(poi.id);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(poi.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(poi.description),
            const SizedBox(height: 12),
            if (isVisited)
              const Text(
                '✔ Already visited',
                style: TextStyle(color: Colors.green),
              ),
            if (!isVisited && !isNearby)
              const Text(
                'Move closer to visit this place',
                style: TextStyle(color: Colors.orange),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (isNearby && !isVisited)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _markPoiAsVisited(poi);
              },
              child: const Text('Mark as visited'),
            ),
        ],
      ),
    );
  }

  void _checkNearbyPoi() {
    if (_userPosition == null || _pois.isEmpty) return;

    for (final poi in _pois) {
      final distance = Geolocator.distanceBetween(
        _userPosition!.latitude,
        _userPosition!.longitude,
        poi.lat,
        poi.lng,
      );

      if (distance <= 50) {
        setState(() {
          _nearbyPoi = poi;
        });
        return;
      }
    }

    setState(() {
      _nearbyPoi = null;
    });
  }

  void _markPoiAsVisited(Poi poi) async {
    setState(() {
      _visitedPoiIds.add(poi.id);
      _nearbyPoi = null;
    });

    await VisitedPoiStorage.saveVisitedPoiIds(_visitedPoiIds);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${poi.name} visited!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
