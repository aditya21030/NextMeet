import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../core/cities.dart';
import '../../core/constants.dart';
import '../../core/models/memory_model.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/location_search_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import '../profile/edit_location_screen.dart';
import 'memories_screen.dart';
import 'new_memory_screen.dart';

/// NextMeet Shared Places & Live Map Screen
/// Strictly following NextMeet Redesign.pdf (Page 25)
class SharedMapScreen extends StatefulWidget {
  final String? relId;
  final Stream<RelationshipModel?>? relationshipStream;
  final Stream<List<MemoryModel>> Function(String relId)? memoriesStreamBuilder;
  final String? currentUidOverride;
  final TileProvider? tileProvider;

  const SharedMapScreen({
    super.key,
    this.relId,
    this.relationshipStream,
    this.memoriesStreamBuilder,
    this.currentUidOverride,
    this.tileProvider,
  });

  /// Returns true if `(lat, lng)` are valid finite Earth coordinates other than the unset (0, 0) sentinel.
  static bool hasValidCoordinates(double? lat, double? lng) {
    return lat != null &&
        lng != null &&
        lat.isFinite &&
        lng.isFinite &&
        lat >= -90.0 &&
        lat <= 90.0 &&
        lng >= -180.0 &&
        lng <= 180.0 &&
        !(lat == 0.0 && lng == 0.0);
  }

  /// Finds matching coordinates from [extraCache] or [CityData.majorCities] without short-token false positives.
  static LatLng? findKnownCityPoint(String cityName, {Map<String, LatLng>? extraCache}) {
    final clean = cityName.toLowerCase().trim();
    if (clean.isEmpty || clean == 'your city' || clean == 'partner city') return null;
    if (extraCache != null && extraCache.containsKey(clean)) {
      return extraCache[clean];
    }
    final primary = clean.split(',').first.trim();
    if (extraCache != null && primary.isNotEmpty && extraCache.containsKey(primary)) {
      return extraCache[primary];
    }
    for (final c in CityData.majorCities) {
      final cName = c.name.toLowerCase();
      if (primary == cName ||
          clean.contains(cName) ||
          (primary.length >= 3 && cName.startsWith(primary))) {
        return LatLng(c.lat, c.lng);
      }
    }
    return null;
  }

  /// Resolves explicit coordinates first, then known cities / cache, else [defaultFallback].
  static LatLng resolveCityPoint(
    String cityName,
    double? lat,
    double? lng,
    LatLng defaultFallback, {
    Map<String, LatLng>? extraCache,
  }) {
    if (hasValidCoordinates(lat, lng)) {
      return LatLng(lat!, lng!);
    }
    return findKnownCityPoint(cityName, extraCache: extraCache) ?? defaultFallback;
  }

  /// Matches a memory's saved location label against a city label using normalized city tokens.
  static bool locationMatchesCity(String memoryLocation, String cityName) {
    final memClean = memoryLocation.toLowerCase().trim();
    final cityClean = cityName.toLowerCase().trim();
    if (memClean.isEmpty || cityClean.isEmpty) return false;
    final cityPrimary = cityClean.split(',').first.trim();
    final memPrimary = memClean.split(',').first.trim();
    if (memClean == cityClean || memPrimary == cityPrimary) return true;
    if (cityPrimary.length >= 3 && memClean.contains(cityPrimary)) return true;
    if (memPrimary.length >= 3 && cityClean.contains(memPrimary)) return true;
    return false;
  }

  /// Chooses map zoom proportional to partner distance so both pins fit comfortably.
  static double calculateOptimalZoom(double distKm) {
    if (distKm <= 10) return 12.5;
    if (distKm <= 50) return 10.5;
    if (distKm <= 200) return 8.5;
    if (distKm <= 600) return 6.8;
    if (distKm <= 1500) return 5.4;
    if (distKm <= 3500) return 4.2;
    if (distKm <= 8000) return 3.0;
    return 2.2;
  }

  /// Builds a distance-scaled arc polyline between [start] and [end], strictly clamped within valid latitudes.
  static List<LatLng> calculateArcPoints(LatLng start, LatLng end) {
    final latDiff = (end.latitude - start.latitude).abs();
    final lngDiff = (end.longitude - start.longitude).abs();
    if (latDiff < 1e-6 && lngDiff < 1e-6) {
      return [start, end];
    }

    final angularSpan = math.sqrt(latDiff * latDiff + lngDiff * lngDiff);
    final arcHeight = (angularSpan * 0.22).clamp(0.002, 12.0);
    final midLat = (start.latitude + end.latitude) / 2.0;
    final bendSign = midLat > 72.0 ? -1.0 : 1.0;

    final points = <LatLng>[];
    const steps = 30;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final baseLat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = (start.longitude + (end.longitude - start.longitude) * t).clamp(-180.0, 180.0);
      final rawLat = baseLat + math.sin(t * math.pi) * arcHeight * bendSign;
      points.add(LatLng(rawLat.clamp(-85.0, 85.0), lng));
    }
    return points;
  }

  /// Parses `#RRGGBB` / `RRGGBB` / `#AARRGGBB` safely, falling back to [fallback].
  static Color parseMapLineColor(String? hex, {Color fallback = AppColors.primary}) {
    if (hex == null || hex.trim().isEmpty) return fallback;
    var normalized = hex.trim().replaceFirst('#', '');
    if (normalized.length == 6) {
      normalized = 'FF$normalized';
    }
    if (normalized.length != 8) return fallback;
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return fallback;
    return Color(value);
  }

  /// Builds arc polylines reflecting saved [style] (`'Neon'`, `'Solid'`, `'Dotted'`) and [hexColor].
  static List<Polyline> buildArcPolylines({
    required List<LatLng> points,
    String? hexColor,
    String? style,
  }) {
    final color = parseMapLineColor(hexColor);
    final normalizedStyle = (style ?? 'Neon').trim().toLowerCase();
    if (normalizedStyle == 'dotted') {
      return [
        Polyline(
          points: points,
          strokeWidth: 3.5,
          color: color,
          isDotted: true,
        ),
      ];
    }
    if (normalizedStyle == 'solid') {
      return [
        Polyline(
          points: points,
          strokeWidth: 3.5,
          color: color,
          isDotted: false,
        ),
      ];
    }
    // Neon: soft outer glow + crisp core
    return [
      Polyline(
        points: points,
        strokeWidth: 9.0,
        color: color.withValues(alpha: 0.25),
      ),
      Polyline(
        points: points,
        strokeWidth: 3.5,
        color: color,
      ),
    ];
  }

  @override
  State<SharedMapScreen> createState() => _SharedMapScreenState();
}

class _SharedMapScreenState extends State<SharedMapScreen> {
  final MapController _mapController = MapController();
  final LocationSearchService _locationSearch = LocationSearchService();
  CloudRelationshipService? _lazyCloudService;
  late final Stream<RelationshipModel?> _relationshipStream;
  Stream<List<MemoryModel>>? _memoriesStream;
  String? _memoriesRelId;

  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All places', 'Together', 'Apart', 'Trips'];

  bool _isMapReady = false;
  bool _hasAutoCenteredForRealRel = false;
  LatLng? _pendingCenter;
  double? _pendingZoom;

  final Map<String, LatLng> _geocodedCities = {};
  final Set<String> _pendingGeocodes = {};
  final Set<String> _failedGeocodes = {};

  CloudRelationshipService get _cloudService =>
      _lazyCloudService ??= CloudRelationshipService();

  String? get _currentUid =>
      widget.currentUidOverride ??
      (widget.relationshipStream != null ? null : AuthService().currentUid);

  @override
  void initState() {
    super.initState();
    _relationshipStream =
        widget.relationshipStream ?? _cloudService.streamRelationship();
  }

  Stream<List<MemoryModel>> _getMemoriesStream(String? relId) {
    if (relId == null || relId.isEmpty || relId == 'default_rel') {
      return Stream.value(const <MemoryModel>[]);
    }
    if (_memoriesStream == null || _memoriesRelId != relId) {
      _memoriesRelId = relId;
      _memoriesStream = widget.memoriesStreamBuilder != null
          ? widget.memoriesStreamBuilder!(relId)
          : _cloudService.streamMemories(relId);
    }
    return _memoriesStream!;
  }

  void _safeMoveMap(LatLng center, double zoom) {
    if (!mounted) return;
    if (_isMapReady) {
      _mapController.move(center, zoom);
    } else {
      _pendingCenter = center;
      _pendingZoom = zoom;
    }
  }

  void _maybeGeocodeCity(String cityName) {
    if (widget.relationshipStream != null) return;
    final clean = cityName.toLowerCase().trim();
    if (clean.isEmpty || clean == 'your city' || clean == 'partner city') return;
    if (SharedMapScreen.findKnownCityPoint(cityName, extraCache: _geocodedCities) != null) {
      return;
    }
    if (_pendingGeocodes.contains(clean) || _failedGeocodes.contains(clean)) {
      return;
    }
    _pendingGeocodes.add(clean);
    unawaited(_resolveCityRemotely(cityName, clean));
  }

  Future<void> _resolveCityRemotely(String rawCity, String cacheKey) async {
    try {
      final results = await _locationSearch.search(rawCity);
      final valid = results.where((r) => r.hasValidCoordinates).toList();
      if (valid.isNotEmpty) {
        _geocodedCities[cacheKey] = LatLng(valid.first.lat, valid.first.lng);
        if (mounted) {
          setState(() {});
        }
      } else {
        _failedGeocodes.add(cacheKey);
      }
    } catch (_) {
      _failedGeocodes.add(cacheKey);
    } finally {
      _pendingGeocodes.remove(cacheKey);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _currentUid;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    return StreamBuilder<RelationshipModel?>(
      stream: _relationshipStream,
      builder: (context, snapshot) {
        final rel = snapshot.data;
        final String? effectiveRelId = (rel?.id != null && rel!.id!.isNotEmpty)
            ? rel.id
            : (widget.relId != null && widget.relId!.isNotEmpty && widget.relId != 'default_rel'
                ? widget.relId
                : null);

        final myName = rel?.getMyName(currentUid) ?? 'You';
        final partnerName = rel?.getPartnerName(currentUid) ?? 'Partner';
        final myCity = rel?.getMyLocation(currentUid) ?? 'Your City';
        final partnerCity = rel?.getPartnerLocation(currentUid) ?? 'Partner City';

        final myLat = rel?.getMyLat(currentUid);
        final myLng = rel?.getMyLng(currentUid);
        final partnerLat = rel?.getPartnerLat(currentUid);
        final partnerLng = rel?.getPartnerLng(currentUid);

        if (rel != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (!SharedMapScreen.hasValidCoordinates(myLat, myLng)) {
              _maybeGeocodeCity(myCity);
            }
            if (!SharedMapScreen.hasValidCoordinates(partnerLat, partnerLng)) {
              _maybeGeocodeCity(partnerCity);
            }
          });
        }

        final myPoint = SharedMapScreen.resolveCityPoint(
          myCity,
          myLat,
          myLng,
          const LatLng(19.0760, 72.8777),
          extraCache: _geocodedCities,
        );
        final partnerPoint = SharedMapScreen.resolveCityPoint(
          partnerCity,
          partnerLat,
          partnerLng,
          const LatLng(48.8566, 2.3522),
          extraCache: _geocodedCities,
        );

        final double distanceKm = (rel != null && rel.computedDistance > 0)
            ? rel.computedDistance
            : ((rel != null && rel.distanceKm > 0)
                ? rel.distanceKm
                : CityData.calculateDistance(
                    myPoint.latitude,
                    myPoint.longitude,
                    partnerPoint.latitude,
                    partnerPoint.longitude,
                  ));

        final midLat = (myPoint.latitude + partnerPoint.latitude) / 2;
        final midLng = (myPoint.longitude + partnerPoint.longitude) / 2;
        final midpoint = LatLng(midLat, midLng);
        final optimalZoom = SharedMapScreen.calculateOptimalZoom(distanceKm);

        if (rel != null && !_hasAutoCenteredForRealRel) {
          _hasAutoCenteredForRealRel = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _safeMoveMap(midpoint, optimalZoom);
          });
        }

        final isCoLocated =
            (myPoint.latitude - partnerPoint.latitude).abs() < 0.002 &&
            (myPoint.longitude - partnerPoint.longitude).abs() < 0.002;

        return StreamBuilder<List<MemoryModel>>(
          stream: _getMemoriesStream(effectiveRelId),
          builder: (context, memSnap) {
            final memories = memSnap.data ?? const <MemoryModel>[];
            final List<Map<String, dynamic>> visitedPlaces = [];

            // 1. My Home Base
            if (myCity.isNotEmpty && myCity != 'Your City') {
              visitedPlaces.add({
                'name': "$myName's City",
                'city': myCity,
                'lat': myPoint.latitude,
                'lng': myPoint.longitude,
                'date': 'Home base',
                'photosCount': memories
                    .where((m) => SharedMapScreen.locationMatchesCity(m.location, myCity))
                    .length,
                'type': 'Apart',
                'isHomeBase': true,
                'icon': Icons.home_rounded,
                'color': AppColors.primary,
              });
            }

            // 2. Partner Home Base
            if (partnerCity.isNotEmpty && partnerCity != 'Partner City') {
              visitedPlaces.add({
                'name': "$partnerName's City",
                'city': partnerCity,
                'lat': partnerPoint.latitude,
                'lng': partnerPoint.longitude,
                'date': 'Partner base',
                'photosCount': memories
                    .where((m) => SharedMapScreen.locationMatchesCity(m.location, partnerCity))
                    .length,
                'type': distanceKm < 50 ? 'Together' : 'Apart',
                'isHomeBase': true,
                'icon': Icons.favorite_rounded,
                'color': AppColors.partner,
              });
            }

            // 3. Upcoming Planned Trip (Page 34/39)
            if (rel?.tripDestination != null && rel!.tripDestination!.trim().isNotEmpty) {
              final tripCity = rel.tripDestination!.trim();
              final resolvedTripPoint = SharedMapScreen.findKnownCityPoint(
                tripCity,
                extraCache: _geocodedCities,
              );
              if (resolvedTripPoint == null) {
                _maybeGeocodeCity(tripCity);
              }
              final tripPoint = resolvedTripPoint ?? midpoint;
              final tripPhotos = memories
                  .where((m) => SharedMapScreen.locationMatchesCity(m.location, tripCity))
                  .length;

              visitedPlaces.add({
                'name': 'Trip to $tripCity ✈️',
                'city': tripCity,
                'lat': tripPoint.latitude,
                'lng': tripPoint.longitude,
                'hasResolvedCoords': resolvedTripPoint != null,
                'date': rel.tripDate != null ? DateFormat('MMM d, yyyy').format(rel.tripDate!) : 'Planned Trip',
                'photosCount': tripPhotos,
                'type': 'Trips',
                'isTrip': true,
                'icon': Icons.flight_takeoff_rounded,
                'color': AppColors.butterText,
              });
            }

            // 4. Memory Locations
            for (final m in memories) {
              if (SharedMapScreen.hasValidCoordinates(m.lat, m.lng)) {
                final isTripMemory = m.moodEmoji == '✈️' ||
                    m.moodEmoji == 'Adventure' ||
                    m.caption.toLowerCase().contains('trip') ||
                    m.caption.toLowerCase().contains('flight');

                visitedPlaces.add({
                  'name': m.caption.isNotEmpty ? m.caption : m.location,
                  'city': m.location,
                  'lat': m.lat!,
                  'lng': m.lng!,
                  'date': DateFormat('MMM yyyy').format(m.date),
                  'photosCount': 1,
                  'type': isTripMemory ? 'Trips' : 'Together',
                  'memory': m,
                  'icon': Icons.camera_alt_rounded,
                  'color': isTripMemory ? AppColors.partner : AppColors.primary,
                });
              }
            }

            // Fallback points if none exist
            if (visitedPlaces.isEmpty) {
              visitedPlaces.add({
                'name': myCity.isNotEmpty ? myCity : 'My Location',
                'city': myCity.isNotEmpty ? myCity : 'Location 1',
                'lat': myPoint.latitude,
                'lng': myPoint.longitude,
                'date': 'Active',
                'photosCount': 0,
                'type': 'Apart',
                'isHomeBase': true,
                'icon': Icons.home_rounded,
                'color': AppColors.primary,
              });
              visitedPlaces.add({
                'name': partnerCity.isNotEmpty ? partnerCity : "$partnerName's Location",
                'city': partnerCity.isNotEmpty ? partnerCity : 'Location 2',
                'lat': partnerPoint.latitude,
                'lng': partnerPoint.longitude,
                'date': 'Active',
                'photosCount': 0,
                'type': 'Together',
                'isHomeBase': true,
                'icon': Icons.favorite_rounded,
                'color': AppColors.partner,
              });
            }

            final currentFilter = _filters[_selectedFilterIndex];
            final filteredPlaces = visitedPlaces.where((p) {
              if (currentFilter == 'All places') return true;
              return p['type'] == currentFilter;
            }).toList();

            // Exclude home-base entries and unresolved trip placeholders from duplicate map markers
            final markerPlaces = filteredPlaces.where((place) {
              if (place['isHomeBase'] == true) return false;
              if (place['isTrip'] == true && place['hasResolvedCoords'] == false) {
                return false;
              }
              return true;
            }).toList();

            final arcPoints = SharedMapScreen.calculateArcPoints(myPoint, partnerPoint);
            final arcPolylines = SharedMapScreen.buildArcPolylines(
              points: arcPoints,
              hexColor: rel?.mapLineColor,
              style: rel?.mapLineStyle,
            );

            return Scaffold(
              backgroundColor: AppColors.background,
              body: SafeArea(
                child: Stack(
                  children: [
                    // 1. Flutter Map Canvas
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: midpoint,
                        initialZoom: optimalZoom,
                        onMapReady: () {
                          _isMapReady = true;
                          if (_pendingCenter != null && _pendingZoom != null) {
                            _mapController.move(_pendingCenter!, _pendingZoom!);
                            _pendingCenter = null;
                            _pendingZoom = null;
                          } else if (rel != null) {
                            _mapController.move(midpoint, optimalZoom);
                          }
                        },
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          fallbackUrl: 'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                          maxZoom: 19,
                          userAgentPackageName: 'com.yousful.nextmeet',
                          tileProvider: widget.tileProvider,
                          evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
                        ),
                        // Polyline Arc between You and Partner (honoring style & color)
                        PolylineLayer(polylines: arcPolylines),
                        // Markers Layer
                        MarkerLayer(
                          markers: [
                            // Visited Places & Trips Markers (rendered below heart avatars)
                            ...markerPlaces.map((place) {
                              final isTrip = place['isTrip'] == true;
                              return Marker(
                                point: LatLng(place['lat'] as double, place['lng'] as double),
                                width: isTrip ? 42 : 36,
                                height: isTrip ? 42 : 36,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    VibrationService.light();
                                    _showPlaceDetails(place, rel, effectiveRelId: effectiveRelId);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isTrip ? AppColors.butterSoft : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isTrip ? AppColors.butterText : AppColors.primary,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.12),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      place['icon'] as IconData? ?? Icons.place_rounded,
                                      color: place['color'] as Color? ?? AppColors.primary,
                                      size: isTrip ? 22 : 18,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            // You Marker (Pink Heart)
                            Marker(
                              point: myPoint,
                              width: 96,
                              height: (84 * textScale.clamp(1.0, 1.3)).toDouble(),
                              child: Transform.translate(
                                offset: isCoLocated ? const Offset(-18, 0) : Offset.zero,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    VibrationService.light();
                                    _safeMoveMap(myPoint, 9.0);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('📍 $myName is in $myCity'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: _buildMapPin(myName, MascotColor.pink),
                                ),
                              ),
                            ),
                            // Partner Marker (Violet Heart)
                            Marker(
                              point: partnerPoint,
                              width: 96,
                              height: (84 * textScale.clamp(1.0, 1.3)).toDouble(),
                              child: Transform.translate(
                                offset: isCoLocated ? const Offset(18, 0) : Offset.zero,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    VibrationService.light();
                                    _safeMoveMap(partnerPoint, 9.0);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('📍 $partnerName is in $partnerCity'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: _buildMapPin(partnerName, MascotColor.violet),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // 2. Top Header & Action Controls (Page 25)
                    Positioned(
                      top: 12,
                      left: AppSpacing.page,
                      right: AppSpacing.page,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Back button
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.border, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Center Distance & Cities Pill
                              Expanded(
                                child: Center(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      VibrationService.light();
                                      _openEditLocation(rel, effectiveRelId);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(AppRadius.pill),
                                        border: Border.all(color: AppColors.border, width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 14),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              distanceKm > 1
                                                  ? '${NumberFormat("#,###").format(distanceKm.round())} km apart'
                                                  : 'Together nearby ❤️',
                                              style: AppTextStyles.heading.copyWith(fontSize: 13, color: AppColors.primary),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Recenter Camera Button (Calculates optimal zoom)
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  VibrationService.light();
                                  _safeMoveMap(midpoint, optimalZoom);
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.border, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.center_focus_strong_rounded, size: 20, color: AppColors.ink),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Add Memory / Drop Pin Button
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  VibrationService.light();
                                  _openAddMemory(effectiveRelId);
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.pinkSoft,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.primary, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.add_location_alt_rounded, size: 20, color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Edit Location Shortcut
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  VibrationService.light();
                                  _openEditLocation(rel, effectiveRelId);
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.edit_location_alt_rounded, size: 20, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Filter Pills: [All places] [Together] [Apart] [Trips]
                          SizedBox(
                            height: (36 * textScale).clamp(36.0, 52.0),
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _filters.length,
                              separatorBuilder: (context, index) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final isSelected = _selectedFilterIndex == index;
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    VibrationService.light();
                                    setState(() => _selectedFilterIndex = index);
                                  },
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primary : Colors.white,
                                        borderRadius: BorderRadius.circular(AppRadius.pill),
                                        border: Border.all(
                                          color: isSelected ? AppColors.primary : AppColors.border,
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.04),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        _filters[index],
                                        style: AppTextStyles.heading.copyWith(
                                          fontSize: 12,
                                          color: isSelected ? Colors.white : AppColors.ink,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Sub-bar: Attribution + Arc Path Customizer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                    border: Border.all(color: AppColors.border, width: 1),
                                  ),
                                  child: Text(
                                    '© OpenStreetMap',
                                    style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.ink),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    VibrationService.light();
                                    _showMapStyleSheet(rel, effectiveRelId);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                      border: Border.all(color: AppColors.border, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.palette_rounded,
                                          size: 14,
                                          color: SharedMapScreen.parseMapLineColor(rel?.mapLineColor),
                                        ),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            rel?.mapLineStyle ?? 'Neon',
                                            style: AppTextStyles.heading.copyWith(fontSize: 11, color: AppColors.ink),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 3. Bottom Sheet of Visited Places (Page 25)
                    Positioned(
                      bottom: 16,
                      left: AppSpacing.page,
                      right: AppSpacing.page,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.hero),
                          border: Border.all(color: AppColors.border, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Visited Places (${filteredPlaces.length})',
                                    style: AppTextStyles.heading.copyWith(fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Clickable "See all" pill
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    VibrationService.light();
                                    _showAllPlacesSheet(visitedPlaces, rel, effectiveRelId);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.pinkSoft,
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'See all',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (filteredPlaces.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  'No places under ${_filters[_selectedFilterIndex]} yet',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                                ),
                              )
                            else
                              SizedBox(
                                height: (92 * textScale).clamp(92.0, 134.0),
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: filteredPlaces.length,
                                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                                  itemBuilder: (context, index) {
                                    final place = filteredPlaces[index];
                                    final isTrip = place['isTrip'] == true;

                                    return GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        VibrationService.light();
                                        _safeMoveMap(
                                          LatLng(place['lat'] as double, place['lng'] as double),
                                          9.5,
                                        );
                                        _showPlaceDetails(place, rel, effectiveRelId: effectiveRelId);
                                      },
                                      child: Container(
                                        width: 168,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isTrip ? AppColors.butterSoft.withValues(alpha: 0.5) : AppColors.background,
                                          borderRadius: BorderRadius.circular(AppRadius.card),
                                          border: Border.all(
                                            color: isTrip ? AppColors.butter : AppColors.border,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  place['icon'] as IconData? ?? Icons.place_rounded,
                                                  size: 14,
                                                  color: place['color'] as Color? ?? AppColors.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    place['name'] as String,
                                                    style: AppTextStyles.heading.copyWith(fontSize: 12),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              place['city'] as String,
                                              style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.muted),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '📸 ${place['photosCount']} photo${place['photosCount'] == 1 ? '' : 's'}',
                                                    style: AppTextStyles.caption.copyWith(
                                                      fontSize: 10,
                                                      color: AppColors.primary,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                                    border: Border.all(color: AppColors.border, width: 1),
                                                  ),
                                                  child: Text(
                                                    place['type'] as String,
                                                    style: AppTextStyles.caption.copyWith(fontSize: 9, fontWeight: FontWeight.w700),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openEditLocation(RelationshipModel? rel, String? effectiveRelId) {
    if (effectiveRelId == null || effectiveRelId.isEmpty || rel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pair with your partner first to set your shared cities ✨')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditLocationScreen(
          relationship: rel,
          relationshipId: effectiveRelId,
        ),
      ),
    );
  }

  void _openAddMemory(
    String? effectiveRelId, {
    String? initialLocation,
    double? initialLat,
    double? initialLng,
  }) {
    if (effectiveRelId == null || effectiveRelId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pair with your partner first to save shared memories ✨')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewMemoryScreen(
          relId: effectiveRelId,
          initialLocation: initialLocation,
          initialLat: initialLat,
          initialLng: initialLng,
        ),
      ),
    );
  }

  Widget _buildMapPin(String name, MascotColor color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MascotHeart(color: color, size: 36),
        const SizedBox(height: 2),
        Container(
          constraints: const BoxConstraints(maxWidth: 90),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            name,
            style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  void _showMapStyleSheet(RelationshipModel? rel, String? effectiveRelId) {
    final currentStyle = rel?.mapLineStyle ?? 'Neon';
    final currentHex = rel?.mapLineColor ?? '#FF4B7D';
    final coupleLevel = ((rel?.coupleXp ?? 0) ~/ 200) + 1;
    final canUseGold = (rel?.isPlus ?? false) || coupleLevel >= 3;

    const styles = ['Neon', 'Solid', 'Dotted'];
    const colorOptions = [
      {'label': 'Rose', 'hex': '#FF4B7D', 'color': AppColors.primary, 'gold': false},
      {'label': 'Violet', 'hex': '#8B5CF6', 'color': AppColors.partner, 'gold': false},
      {'label': 'Mint', 'hex': '#10B981', 'color': AppColors.mintText, 'gold': false},
      {'label': 'Sky', 'hex': '#3B82F6', 'color': Color(0xFF3B82F6), 'gold': false},
      {'label': 'Gold', 'hex': '#F59E0B', 'color': Color(0xFFF59E0B), 'gold': true},
    ];

    String selectedStyle = currentStyle;
    String selectedHex = currentHex;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Map Path Style ✨', style: AppTextStyles.title2),
                    const SizedBox(height: 4),
                    Text(
                      'Customize the line linking your two cities',
                      style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 16),
                    Text('LINE STYLE', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: styles.map((style) {
                        final selected = selectedStyle.toLowerCase() == style.toLowerCase();
                        return ChoiceChip(
                          label: Text(style),
                          selected: selected,
                          selectedColor: AppColors.pinkSoft,
                          onSelected: (_) {
                            VibrationService.light();
                            setSheetState(() => selectedStyle = style);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text('ARC COLOR', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: colorOptions.map((opt) {
                        final hex = opt['hex'] as String;
                        final col = opt['color'] as Color;
                        final isGold = opt['gold'] == true;
                        final locked = isGold && !canUseGold;
                        final selected = selectedHex.toUpperCase() == hex.toUpperCase();

                        return GestureDetector(
                          onTap: () {
                            if (locked) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Gold Map Line unlocks at Couple Level 3 or NextMeet+ 🌟'),
                                ),
                              );
                              return;
                            }
                            VibrationService.light();
                            setSheetState(() => selectedHex = hex);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? col.withValues(alpha: 0.14) : AppColors.background,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: selected ? col : AppColors.border,
                                width: selected ? 2 : 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  locked ? '${opt['label']} 🔒' : (opt['label'] as String),
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      text: effectiveRelId == null ? 'Pair to Save Style' : 'Apply Map Style',
                      isLoading: isSaving,
                      onPressed: () async {
                        if (effectiveRelId == null || effectiveRelId.isEmpty) {
                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pair with your partner first to save map styling.')),
                          );
                          return;
                        }
                        setSheetState(() => isSaving = true);
                        try {
                          await _cloudService
                              .updateMapSettings(
                                effectiveRelId,
                                color: selectedHex,
                                style: selectedStyle,
                              )
                              .timeout(const Duration(seconds: 6));
                          if (!mounted) return;
                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          VibrationService.success();
                        } catch (e) {
                          if (sheetCtx.mounted) {
                            setSheetState(() => isSaving = false);
                          }
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not save map style: $e')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPlaceDetails(
    Map<String, dynamic> place,
    RelationshipModel? rel, {
    String? effectiveRelId,
  }) {
    final photosCount = place['photosCount'] as int? ?? 0;
    final isTrip = place['isTrip'] == true;
    final resolvedRelId = effectiveRelId ?? rel?.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  place['icon'] as IconData? ?? Icons.place_rounded,
                                  size: 20,
                                  color: place['color'] as Color? ?? AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    place['name'] as String,
                                    style: AppTextStyles.title2,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              place['city'] as String,
                              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isTrip ? AppColors.butterSoft : AppColors.mintSoft,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          place['date'] as String,
                          style: AppTextStyles.caption.copyWith(
                            color: isTrip ? AppColors.butterText : AppColors.mintText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isTrip
                        ? 'A romantic getaway planned for both of you. Add memories and countdown the days!'
                        : 'A meaningful location in your relationship journey with memories shared between both of you.',
                    style: AppTextStyles.body.copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: 20),

                  // Action 1: View Photos in Memories
                  PrimaryButton(
                    text: photosCount > 0 ? 'View Photos in Memories ($photosCount) 📸' : 'Open Memories Gallery 📸',
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MemoriesScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Action 2: Add Memory at this Location
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      _openAddMemory(
                        resolvedRelId,
                        initialLocation: place['city'] as String?,
                        initialLat: place['lat'] as double?,
                        initialLng: place['lng'] as double?,
                      );
                    },
                    icon: const Icon(Icons.add_photo_alternate_rounded, size: 18, color: AppColors.primary),
                    label: const Text('Add Memory at this Location', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAllPlacesSheet(
    List<Map<String, dynamic>> allPlaces,
    RelationshipModel? rel,
    String? effectiveRelId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return _AllPlacesModal(
          allPlaces: allPlaces,
          onFlyToPlace: (place) {
            Navigator.pop(sheetCtx);
            _safeMoveMap(
              LatLng(place['lat'] as double, place['lng'] as double),
              9.5,
            );
            _showPlaceDetails(place, rel, effectiveRelId: effectiveRelId);
          },
        );
      },
    );
  }
}

class _AllPlacesModal extends StatefulWidget {
  final List<Map<String, dynamic>> allPlaces;
  final void Function(Map<String, dynamic> place) onFlyToPlace;

  const _AllPlacesModal({
    required this.allPlaces,
    required this.onFlyToPlace,
  });

  @override
  State<_AllPlacesModal> createState() => _AllPlacesModalState();
}

class _AllPlacesModalState extends State<_AllPlacesModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.allPlaces.where((p) {
      final q = _searchQuery.toLowerCase().trim();
      if (q.isEmpty) return true;
      final name = (p['name'] as String).toLowerCase();
      final city = (p['city'] as String).toLowerCase();
      return name.contains(q) || city.contains(q);
    }).toList();

    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardBottom),
      child: SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'All Visited Places (${widget.allPlaces.length})',
                      style: AppTextStyles.title1.copyWith(fontSize: 20),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded, color: AppColors.muted, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search Field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.muted, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search city or place...',
                          border: InputBorder.none,
                        ),
                        style: AppTextStyles.body,
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(Icons.close_rounded, color: AppColors.muted, size: 18),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Place List
              Flexible(
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Text(
                          'No places match your search',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption,
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          final isTrip = p['isTrip'] == true;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isTrip ? AppColors.butterSoft : AppColors.pinkSoft,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                p['icon'] as IconData? ?? Icons.place_rounded,
                                color: p['color'] as Color? ?? AppColors.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(p['name'] as String, style: AppTextStyles.heading.copyWith(fontSize: 14)),
                            subtitle: Text(
                              '${p['city']} • ${p['photosCount']} photos',
                              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => widget.onFlyToPlace(p),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                              ),
                              child: const Text('Fly 📍', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
