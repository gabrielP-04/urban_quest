import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:urban_quest/core/utils/predefined_routes.dart';
import 'package:urban_quest/models/poi.dart';
import 'package:urban_quest/services/auth_service.dart';
import 'package:urban_quest/models/route.dart';
import 'package:urban_quest/services/active_route_storage.dart';
import 'package:urban_quest/services/custom_route_storage.dart';
import 'package:urban_quest/services/location_service.dart';
import 'package:urban_quest/services/poi_service.dart';
import 'package:urban_quest/services/routing_service.dart';
import 'package:urban_quest/services/visited_poi_storage.dart';
import 'package:urban_quest/widgets/exploration_progress.dart';
import 'package:urban_quest/widgets/poi_marker.dart';
import 'package:urban_quest/widgets/route_list_sheet.dart';
import '../../widgets/achievement_unlocked_dialog.dart';

import 'package:urban_quest/services/gamification_services.dart';
import 'package:urban_quest/models/gamification_models.dart';

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
  final authService = AuthService();
  String? get userId => authService.currentUserId;

  static const LatLng _milanCenter = LatLng(45.4642, 9.1900);
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

  final MapController _mapController = MapController();

  StreamSubscription<Position>? _positionSub;

  final GamificationController _gamificationController =
      GamificationController();

  List<RouteModel> _availableRoutes = [];

  bool _poiIsInActiveRoute(Poi poi) {
    if (_activeRoute == null) return true;

    return _activeRoute!.pois.any((p) => p.id == poi.id);
  }

  bool _isCreatingRoute = false;
  List<Poi> _selectedPois = [];

  bool _isPoiSelected(Poi poi) {
    return _selectedPois.any((p) => p.id == poi.id);
  }

  List<LatLng> _realRoutePoints = [];
  double _routeDistanceMeters = 0;
  double _routeDurationSeconds = 0;
  bool _isBuildingRoute = false;

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

          await _buildRealRoute(route);

          await ActiveRouteStorage.saveActiveRouteId(route.id);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _centerMapOnRoute(route);
          });
        },
        onDelete: _deleteCustomRoute,
        onEdit: _editCustomRoute,
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

  Future<void> _deleteCustomRoute(RouteModel route) async {
    if (!route.isCustom) return;

    setState(() {
      _availableRoutes.removeWhere((r) => r.id == route.id);

      if (_activeRoute?.id == route.id) {
        _activeRoute = null;
        _realRoutePoints.clear();
        _routeDistanceMeters = 0;
        _routeDurationSeconds = 0;
      }
    });

    await CustomRouteStorage.saveRoutes(
      _availableRoutes.where((r) => r.isCustom).toList(),
    );
  }

  Future<String?> _editCustomRoute(RouteModel route) async {
    final controller = TextEditingController(text: route.name);
    String? newName;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit route name'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = controller.text.trim();
              if (value.isEmpty) return;

              setState(() {
                final index =
                    _availableRoutes.indexWhere((r) => r.id == route.id);
                if (index != -1) {
                  _availableRoutes[index] =
                      _availableRoutes[index].copyWith(name: value);
                }
              });

              await CustomRouteStorage.saveRoutes(
                _availableRoutes.where((r) => r.isCustom).toList(),
              );

              newName = value;
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    return newName;
  }

  Future<void> _loadPois() async {
    final pois = await PoiService.loadPois();
    final predefinedRoutes = PredefinedRoutes.build(pois);
    final customRoutes = await CustomRouteStorage.loadRoutes(pois);
    final savedRouteId = await ActiveRouteStorage.loadActiveRouteId();

    RouteModel? restoredRoute;

    if (savedRouteId != null) {
      final allRoutes = [...predefinedRoutes, ...customRoutes];

      final found = allRoutes.firstWhere(
        (r) => r.id == savedRouteId,
        orElse: () => allRoutes.first,
      );

      restoredRoute = found;
    }

    setState(() {
      _pois = pois;
      _availableRoutes = [
        ...predefinedRoutes,
        ...customRoutes,
      ];
      _activeRoute = restoredRoute;
      _isLoading = false;
    });

    if (restoredRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _buildRealRoute(restoredRoute!);
        _centerMapOnRoute(restoredRoute!);
      });
    }
  }

  Future<void> _loadVisitedPois() async {
    try {
      final uid = userId;
      if (uid == null) return;

      // 1. Load from SharedPreferences (local backup)
      final localIds = await VisitedPoiStorage.loadVisitedPoiIds(userId: uid);

      // 2. Load from Firestore (source of truth) - read "visitedPoiIds"
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final firestoreIds = <String>{};
      if (userDoc.exists) {
        final data = userDoc.data();
        final list = data?['visitedPoiIds'] as List<dynamic>? ?? [];
        firestoreIds.addAll(list.cast<String>());
      }

      // 3. Combine both sources
      final combined = <String>{...localIds, ...firestoreIds};

      setState(() {
        _visitedPoiIds.clear();
        _visitedPoiIds.addAll(combined);
      });

      // 4. Sync back to local
      await VisitedPoiStorage.saveVisitedPoiIds(combined, userId: uid);

      // 5. Sync back to Firestore if local had extra
      if (combined.length > firestoreIds.length) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'visitedPoiIds': combined.toList(),
        });
      }

      debugPrint('✅ Loaded ${combined.length} visited POIs');
    } catch (e) {
      debugPrint('❌ Error loading visited POIs: $e');
    }
  }

  Future<void> _buildRealRoute(RouteModel route) async {
    setState(() {
      _isBuildingRoute = true;
      _realRoutePoints.clear();
      _routeDistanceMeters = 0;
      _routeDurationSeconds = 0;
    });

    final orderedPois = _optimizePoisOrder(route.pois);

    for (int i = 0; i < orderedPois.length - 1; i++) {
      final start = LatLng(orderedPois[i].lat, orderedPois[i].lng);
      final end = LatLng(orderedPois[i + 1].lat, orderedPois[i + 1].lng);

      final segment = await RoutingService.getRoute(start, end);

      _realRoutePoints.addAll(segment.points);
      _routeDistanceMeters += segment.distanceMeters;
      _routeDurationSeconds += segment.durationSeconds;
    }

    setState(() {
      _isBuildingRoute = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'Map',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: const MapOptions(
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
                      if (_realRoutePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _realRoutePoints,
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
                  _buildMapProgress(),

                  // Botones zoom in - zoom out
                  Positioned(
                    right: 16,
                    bottom: 120,
                    child: Column(
                      children: [
                        FloatingActionButton(
                          heroTag: 'zoom_in',
                          backgroundColor: Colors.deepOrange,
                          onPressed: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom + 1,
                            );
                          },
                          child: const Icon(Icons.add),
                        ),
                        const SizedBox(height: 12),
                        FloatingActionButton(
                          heroTag: 'zoom_out',
                          backgroundColor: Colors.deepOrange,
                          onPressed: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom - 1,
                            );
                          },
                          child: const Icon(Icons.remove),
                        ),
                        const SizedBox(height: 24),
                        FloatingActionButton(
                          heroTag: 'routes',
                          backgroundColor: Colors.deepOrange,
                          onPressed: _openRouteList,
                          child: const Icon(Icons.alt_route),
                        ),
                        if (_isCreatingRoute && _selectedPois.length >= 2) ...[
                          const SizedBox(height: 12),
                          FloatingActionButton(
                            heroTag: 'generate_route',
                            backgroundColor: Colors.green,
                            onPressed: _generateAndSaveRoute,
                            child: const Icon(Icons.check),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ));
  }

  // NUEVO: Indicador de momentum (solo aparece cuando está activo)
  Widget _buildMomentumIndicator() {
    return Positioned(
      left: 16,
      right: 16,
      top: 16,
      child: FutureBuilder<MomentumState>(
        future: _getMomentumState(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isActive) {
            return _buildMomentumBanner(snapshot.data!);
          }
          return const SizedBox();
        },
      ),
    );
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
    final isSelected = _isPoiSelected(poi);

    return Marker(
      point: LatLng(poi.lat, poi.lng),
      width: 60,
      height: 60,
      child: GestureDetector(
        onTap: () => _showPoiDialog(poi),
        child: Opacity(
          opacity: isInRoute ? 1.0 : 0.35,
          child: PoiMarker(
            icon: isSelected
                ? Icons.star
                : isVisited
                    ? Icons.check
                    : _iconForCategory(poi.category),
            color: isSelected
                ? const Color.fromARGB(255, 219, 52, 52)
                : isVisited
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

  List<Poi> _optimizePoisOrder(List<Poi> pois) {
    if (pois.isEmpty) return [];

    final remaining = List<Poi>.from(pois);
    final ordered = <Poi>[];

    double currentLat;
    double currentLng;

    if (_userPosition != null) {
      currentLat = _userPosition!.latitude;
      currentLng = _userPosition!.longitude;
    } else {
      final first = remaining.removeAt(0);
      ordered.add(first);
      currentLat = first.lat;
      currentLng = first.lng;
    }

    while (remaining.isNotEmpty) {
      Poi nearest = remaining.first;
      double minDistance = double.infinity;

      for (final poi in remaining) {
        final distance = Geolocator.distanceBetween(
          currentLat,
          currentLng,
          poi.lat,
          poi.lng,
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearest = poi;
        }
      }

      ordered.add(nearest);
      remaining.remove(nearest);
      currentLat = nearest.lat;
      currentLng = nearest.lng;
    }

    return ordered;
  }

  Future<void> _generateAndSaveRoute() async {
    if (_selectedPois.length < 2) return;

    final orderedPois = _optimizePoisOrder(_selectedPois);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Route name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'My custom route',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              final route = RouteModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                type: RouteType.cultural,
                isCustom: true,
                pois: orderedPois,
              );

              setState(() {
                _activeRoute = route;
                _availableRoutes.add(route);
                _selectedPois.clear();
                _isCreatingRoute = false;
              });

              await CustomRouteStorage.saveRoutes(
                _availableRoutes.where((r) => r.isCustom).toList(),
              );

              await _buildRealRoute(route);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _centerMapOnRoute(route);
              });

              Navigator.pop(context);
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _clearActiveRoute() async {
    setState(() {
      _activeRoute = null;
      _realRoutePoints.clear();
      _routeDistanceMeters = 0;
      _routeDurationSeconds = 0;
    });

    await ActiveRouteStorage.clearActiveRoute();
  }

  void _showPoiDialog(Poi poi) {
    final isNearby = _nearbyPoi?.id == poi.id;
    final isVisited = _visitedPoiIds.contains(poi.id);
    final isSelected = _isPoiSelected(poi);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.asset(
                  poi.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TITLE
                    Text(
                      poi.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // CATEGORY CHIP
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _colorForCategory(poi.category).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        poi.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _colorForCategory(poi.category),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // DESCRIPTION
                    Text(
                      poi.description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // STATUS
                    if (isVisited)
                      const Text(
                        '✔ Already visited',
                        style: TextStyle(color: Colors.green),
                      )
                    else if (!isNearby)
                      const Text(
                        'Move closer to visit this place',
                        style: TextStyle(color: Colors.red),
                      ),

                    const SizedBox(height: 16),

                    // ACTIONS
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isCreatingRoute = true;
                                isSelected
                                    ? _selectedPois
                                        .removeWhere((p) => p.id == poi.id)
                                    : _selectedPois.add(poi);
                              });
                              Navigator.pop(context);
                            },
                            child: Text(
                              isSelected ? 'Remove from route' : 'Add to route',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (isNearby && !isVisited)
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _markPoiAsVisited(poi);
                              },
                              child: const Text('Mark as visited',
                                  style: TextStyle(
                                      color:
                                          Color.fromARGB(255, 255, 255, 255))),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
        if (_nearbyPoi?.id != poi.id) {
          debugPrint(
              '📍 [MAP] User is near: ${poi.name} (${distance.toStringAsFixed(1)}m)');
        }
        setState(() {
          _nearbyPoi = poi;
        });
        return;
      }
    }

    if (_nearbyPoi != null) {
      debugPrint('📍 [MAP] User left proximity of POI');
    }
    setState(() {
      _nearbyPoi = null;
    });
  }

  // MODIFICADO: Integración con gamificación
  Future<void> _markPoiAsVisited(Poi poi) async {
    final uid = userId;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    if (_visitedPoiIds.contains(poi.id)) {
      return;
    }

    // Update UI immediately
    setState(() {
      _visitedPoiIds.add(poi.id);
      _nearbyPoi = null;
    });

    try {
      // 1. Save to Firestore (source of truth)
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'visitedPoiIds': FieldValue.arrayUnion([poi.id]),
      });

      // 2. Process gamification (XP, momentum, achievements)
      final result = await _gamificationController.processPOIVisit(
        userId: uid,
        poiId: poi.id,
        poiName: poi.name,
        poiCategory: poi.category,
        isFirstVisit: true,
      );

      // 3. Save to SharedPreferences (local backup WITH userId)
      await VisitedPoiStorage.saveVisitedPoiIds(_visitedPoiIds, userId: uid);

      if (!mounted) return;

      // 4. Show XP snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${poi.name} visited! +${result.xpGained} XP'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // 5. Show achievements if unlocked
      await Future.delayed(const Duration(milliseconds: 500));
      if (result.hasNewAchievements && mounted) {
        AchievementUnlockedDialog.showMultiple(
          context,
          result.newAchievements,
        );
      }

      // 6. Show level-up if applicable
      if (result.didLevelUp && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 Level Up! You are now level ${result.gamificationData.level}',
            ),
            backgroundColor: Colors.deepOrange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error marking POI as visited: $e');
      setState(() {
        _visitedPoiIds.remove(poi.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NUEVO: Mostrar feedback de gamificación
  void _showGamificationFeedback(POIVisitResult result, Poi poi) {
    if (result.didLevelUp) {
      _showLevelUpDialog(result);
    } else {
      _showXPSnackbar(result, poi);
    }

    // Banner de momentum solo cuando se activa por primera vez
    if (result.hasMomentum && result.momentumState.sessionPOIsVisited == 3) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _showMomentumActivatedBanner();
      });
    }

    // Celebrar niveles altos de momentum
    if (result.momentumState.level == MomentumLevel.high ||
        result.momentumState.level == MomentumLevel.blazing) {
      Future.delayed(const Duration(milliseconds: 800), () {
        _showMomentumLevelBanner(result.momentumState);
      });
    }
  }

  void _showLevelUpDialog(POIVisitResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Text('🎉 '),
            Text('LEVEL UP!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Level ${result.xpResult.oldLevel} → ${result.xpResult.newLevel}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '+${result.xpGained} XP',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            // Mostrar recompensas si las hay
            FutureBuilder<List<LevelReward>>(
              future: _getRewardsForLevel(result.xpResult.newLevel),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return Column(
                    children: [
                      const Divider(),
                      const Text(
                        'Rewards Unlocked:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...snapshot.data!.map((reward) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(reward.icon ?? '🏆',
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                Flexible(child: Text(reward.name)),
                              ],
                            ),
                          )),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  void _showXPSnackbar(POIVisitResult result, Poi poi) {
    final message = StringBuffer('${poi.name} visited! ');
    message.write('+${result.xpGained} XP');

    if (result.isFirstVisit) {
      message.write(' (First visit bonus!)');
    }

    if (result.hasMomentum) {
      message.write(' ${result.momentumState.level.icon}');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.toString()),
        backgroundColor: result.hasMomentum ? Colors.deepOrange : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showMomentumActivatedBanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Text('🔥 ', style: TextStyle(fontSize: 20)),
            Expanded(
              child: Text(
                'Momentum Activated! Keep exploring!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showMomentumLevelBanner(MomentumState momentum) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text('${momentum.level.icon} ',
                style: const TextStyle(fontSize: 20)),
            Expanded(
              child: Text(
                momentum.statusMessage,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepOrange.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildMomentumBanner(MomentumState momentum) {
    if (!momentum.isActive) return const SizedBox.shrink();

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9A56), Color(0xFFFF7A3D)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9A56).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              momentum.level.icon,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    momentum.level.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${momentum.sessionPOIsVisited} POIs this session',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
           
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+${((momentum.multiplier - 1) * 100).toInt()}% XP',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOriginalSnackbar(String poiName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$poiName visited!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<List<LevelReward>> _getRewardsForLevel(int level) async {
    return LevelRewardsSystem.getRewardsForLevel(level);
  }

  Future<MomentumState> _getMomentumState() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return MomentumState(
        isActive: false,
        sessionPOIsVisited: 0,
        sessionDuration: Duration.zero,
        multiplier: 1.0,
        level: MomentumLevel.none,
      );
    }

    try {
      return await _gamificationController.momentumService
          .getMomentumState(userId);
    } catch (e) {
      return MomentumState(
        isActive: false,
        sessionPOIsVisited: 0,
        sessionDuration: Duration.zero,
        multiplier: 1.0,
        level: MomentumLevel.none,
      );
    }
  }
}
