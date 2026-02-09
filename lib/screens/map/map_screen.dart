import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:urban_quest/core/utils/predefined_routes.dart';
import 'package:urban_quest/models/poi.dart';
import 'package:urban_quest/models/route.dart';
import 'package:urban_quest/services/active_route_storage.dart';
import 'package:urban_quest/services/location_service.dart';
import 'package:urban_quest/services/poi_service.dart';
import 'package:urban_quest/services/route_service.dart';
import 'package:urban_quest/services/visited_poi_storage.dart';
import 'package:urban_quest/widgets/exploration_progress.dart';
import 'package:urban_quest/widgets/poi_marker.dart';
import 'package:urban_quest/widgets/route_list_sheet.dart';

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

  RouteModel? _activeRoute;

  bool get _hasActiveRoute => _activeRoute != null;

  int get _visitedCount {
    if (!_hasActiveRoute) {
      return _visitedPoiIds.length;
    }

    return _activeRoute!.pois
        .where((poi) => _visitedPoiIds.contains(poi.id))
        .length;
  }

  int get _totalPois {
    if (!_hasActiveRoute) {
      return _pois.length;
    }

    return _activeRoute!.pois.length;
  }

  double get _progressPercent =>
      _totalPois == 0 ? 0 : _visitedCount / _totalPois;

  final MapController _mapController = MapController();

  StreamSubscription<Position>? _positionSub;

  RouteModel? _currentRoute;

  List<RouteModel> _availableRoutes = [];

  bool _poiIsInActiveRoute(Poi poi) {
    if (_activeRoute == null) return true;

    return _activeRoute!.pois.any((p) => p.id == poi.id);
  }

  @override
  void initState() {
    super.initState();
    _loadPois();
    _loadVisitedPois();
    _startListeningToLocation();
  }

  void _startListeningToLocation() {
    _positionSub = LocationService.getPositionStream().listen((position) {
      setState(() {
        _userPosition = position;
      });
      _checkNearbyPoi();
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  void _openRouteList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RouteListSheet(
        routes: _availableRoutes,
        onSelect: (route) async {
          setState(() {
            _activeRoute = route;
          });

          await ActiveRouteStorage.saveActiveRouteId(route.id);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _centerMapOnRoute(route);
          });
        },
      ),
    );
  }

  void _centerMapOnRoute(RouteModel route) {
    if (route.pois.isEmpty) return;

    double minLat = route.pois.first.lat;
    double maxLat = route.pois.first.lat;
    double minLng = route.pois.first.lng;
    double maxLng = route.pois.first.lng;

    for (final poi in route.pois) {
      if (poi.lat < minLat) minLat = poi.lat;
      if (poi.lat > maxLat) maxLat = poi.lat;
      if (poi.lng < minLng) minLng = poi.lng;
      if (poi.lng > maxLng) maxLng = poi.lng;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  Future<void> _loadPois() async {
    final pois = await PoiService.loadPois();
    final routes = PredefinedRoutes.build(pois);
    final savedRouteId = await ActiveRouteStorage.loadActiveRouteId();

    RouteModel? restoredRoute;

    if (savedRouteId != null) {
      restoredRoute = routes.firstWhere(
        (r) => r.id == savedRouteId,
        orElse: () => routes.first,
      );
    }

    setState(() {
      _pois = pois;
      _availableRoutes = routes;
      _activeRoute = restoredRoute;
      _isLoading = false;
    });

    if (restoredRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerMapOnRoute(restoredRoute!);
      });
    }
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
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _milanCenter,
                      initialZoom: 13,
                      minZoom: 10,
                      maxZoom: 18,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.example.urbanquest',
                      ),
                      if (_activeRoute != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _activeRoute!.pois
                                  .map((p) => LatLng(p.lat, p.lng))
                                  .toList(),
                              strokeWidth: 4,
                              color: Colors.deepOrange,
                            ),
                          ],
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
                  if (_activeRoute != null)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: _buildActiveRouteCard(),
                    ),
                  _buildMapProgress(),
                  Positioned(
                    right: 16,
                    bottom: 120,
                    child: Column(
                      children: [
                        FloatingActionButton(
                          heroTag: 'zoom_in',
                          mini: true,
                          onPressed: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom + 1,
                            );
                          },
                          child: const Icon(Icons.add),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton(
                          heroTag: 'zoom_out',
                          mini: true,
                          onPressed: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom - 1,
                            );
                          },
                          child: const Icon(Icons.remove),
                        ),
                        FloatingActionButton(
                          heroTag: 'routes',
                          backgroundColor: Colors.deepOrange,
                          onPressed: _openRouteList,
                          child: const Icon(Icons.alt_route),
                        ),
                      ],
                    ),
                  ),
                ],
              ));
  }

  Widget _buildMapProgress() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: ExplorationProgress(
        visited: _visitedCount,
        total: _totalPois,
        compact: true,
      ),
    );
  }

  Marker _buildMarker(Poi poi) {
    final isVisited = _visitedPoiIds.contains(poi.id);
    final isNearby = _nearbyPoi?.id == poi.id;
    final isInRoute = _poiIsInActiveRoute(poi);

    return Marker(
      point: LatLng(poi.lat, poi.lng),
      width: 60,
      height: 60,
      child: GestureDetector(
        onTap: isInRoute || _activeRoute == null
            ? () => _showPoiDialog(poi)
            : null,
        child: Opacity(
          opacity: isInRoute ? 1.0 : 0.35,
          child: PoiMarker(
            icon: isVisited ? Icons.check : _iconForCategory(poi.category),
            color: isVisited
                ? Colors.grey
                : isInRoute
                    ? _colorForCategory(poi.category)
                    : Colors.grey,
            isActive: isNearby && isInRoute,
          ),
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'monument':
        return Icons.account_balance;
      case 'cultural':
        return Icons.museum;
      case 'gastronomy':
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
      case 'cultural':
        return Colors.blue;
      case 'gastronomy':
        return Colors.green;
      case 'viewpoint':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActiveRouteCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.deepOrange,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active route',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _activeRoute!.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_visitedCount / $_totalPois POIs',
                  style: const TextStyle(color: Colors.white),
                ),
                TextButton(
                  onPressed: _clearActiveRoute,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _clearActiveRoute() async {
    setState(() {
      _activeRoute = null;
    });

    await ActiveRouteStorage.clearActiveRoute();
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
                style: TextStyle(color: Colors.red),
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

    if (_hasActiveRoute && _visitedCount == _totalPois) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Route completed!'),
          backgroundColor: Colors.deepOrange,
        ),
      );

      setState(() {
        _activeRoute = null;
      });
    }

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
