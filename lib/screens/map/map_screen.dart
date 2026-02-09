import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:urban_quest/models/poi.dart';
import 'package:urban_quest/services/auth_service.dart';
import 'package:urban_quest/services/location_service.dart';
import 'package:urban_quest/services/poi_service.dart';
import 'package:urban_quest/services/visited_poi_storage.dart';
import 'package:urban_quest/widgets/exploration_progress.dart';
import 'package:urban_quest/widgets/poi_marker.dart';

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

  int get _visitedCount => _visitedPoiIds.length;

  int get _totalPois => _pois.length;

  final MapController _mapController = MapController();

  double get _progressPercent =>
      _totalPois == 0 ? 0 : _visitedCount / _totalPois;

  StreamSubscription<Position>? _positionSub;
  
  final GamificationController _gamificationController = GamificationController();

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
    try {
      // Cargar desde storage local
      final localIds = await VisitedPoiStorage.loadVisitedPoiIds(userId: userId);
      
      // NUEVO: Cargar desde Firestore
      final firestoreIds = await PoiService.getVisitedPoisFromFirestore();
      
      setState(() {
        _visitedPoiIds.clear(); // Limpiar primero
        _visitedPoiIds.addAll(localIds);
        _visitedPoiIds.addAll(firestoreIds);
      });
      
      // Sincronizar - guardar la unión en local
      await VisitedPoiStorage.saveVisitedPoiIds(_visitedPoiIds);
      
      debugPrint('Loaded ${_visitedPoiIds.length} visited POIs');
    } catch (e) {
      debugPrint('Error loading visited POIs: $e');
    }
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
                  
                  // NUEVO: Indicador de momentum (arriba)
                  _buildMomentumIndicator(),
                  
                  // Tu widget de progreso original
                  _buildMapProgress(),
                  
                  // TUS BOTONES ORIGINALES - SIN CAMBIOS
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
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepOrange.shade700,
                    Colors.orange.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrange.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    snapshot.data!.level.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          snapshot.data!.level.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '+${((snapshot.data!.multiplier - 1) * 100).toInt()}% XP Bonus',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${snapshot.data!.sessionPOIsVisited} POIs',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
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
        if (_nearbyPoi?.id != poi.id) {
          debugPrint('📍 [MAP] User is near: ${poi.name} (${distance.toStringAsFixed(1)}m)');
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
  void _markPoiAsVisited(Poi poi) async {
    debugPrint('🔵 [MAP] markPoiAsVisited called for: ${poi.name} (${poi.id})');
    
    final isFirstVisit = !_visitedPoiIds.contains(poi.id);
    debugPrint('🔵 [MAP] Is first visit: $isFirstVisit');
    
    // 1. Actualizar UI local (tu código original)
    setState(() {
      _visitedPoiIds.add(poi.id);
      _nearbyPoi = null;
    });
    debugPrint('🔵 [MAP] Added to local set. Total visited: ${_visitedPoiIds.length}');

    // 2. Guardar localmente (tu código original)
    await VisitedPoiStorage.saveVisitedPoiIds(_visitedPoiIds);
    debugPrint('🔵 [MAP] Saved to local storage');
    
    // 3. NUEVO: Guardar en Firestore
    await PoiService.markPoiAsVisitedInFirestore(poi.id);
    debugPrint('🔵 [MAP] Saved to Firestore');

    // 4. NUEVO: Procesar gamificación
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        debugPrint('🔵 [MAP] Processing gamification for user: $userId');
        final result = await _gamificationController.processPOIVisit(
          userId: userId,
          poiId: poi.id,
          poiName: poi.name,
          isFirstVisit: isFirstVisit,
        );

        _showGamificationFeedback(result, poi);
      } else {
        debugPrint('⚠️ [MAP] No user authenticated, showing simple snackbar');
        _showOriginalSnackbar(poi.name);
      }
    } catch (e) {
      debugPrint('❌ [MAP] Error en gamificación: $e');
      _showOriginalSnackbar(poi.name);
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
                            Text(reward.icon ?? '🏆', style: const TextStyle(fontSize: 20)),
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

    // Tu SnackBar original con el color actualizado
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
            Text('${momentum.level.icon} ', style: const TextStyle(fontSize: 20)),
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

  // Tu SnackBar original para fallback
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
      return await _gamificationController.momentumService.getMomentumState(userId);
    } catch (e) {
      debugPrint('Error getting momentum state: $e');
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