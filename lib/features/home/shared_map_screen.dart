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
  const SharedMapScreen({super.key, this.relId});

  @override
  State<SharedMapScreen> createState() => _SharedMapScreenState();
}

class _SharedMapScreenState extends State<SharedMapScreen> {
  final MapController _mapController = MapController();
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All places', 'Together', 'Apart', 'Trips'];

  LatLng _resolveCityPoint(String cityName, double? lat, double? lng, LatLng defaultFallback) {
    if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
      return LatLng(lat, lng);
    }
    final clean = cityName.toLowerCase().trim();
    if (clean.isNotEmpty) {
      for (final c in CityData.majorCities) {
        if (clean.contains(c.name.toLowerCase()) || c.name.toLowerCase().contains(clean)) {
          return LatLng(c.lat, c.lng);
        }
      }
    }
    return defaultFallback;
  }

  double _calculateOptimalZoom(double distKm) {
    if (distKm <= 10) return 12.5;
    if (distKm <= 50) return 10.5;
    if (distKm <= 200) return 8.5;
    if (distKm <= 600) return 6.8;
    if (distKm <= 1500) return 5.4;
    if (distKm <= 3500) return 4.2;
    return 3.0;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUid;

    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, snapshot) {
        final rel = snapshot.data;
        final relId = rel?.id ?? 'default_rel';
        final myName = rel?.getMyName(currentUid) ?? 'You';
        final partnerName = rel?.getPartnerName(currentUid) ?? 'Partner';
        final myCity = rel?.getMyLocation(currentUid) ?? 'Your City';
        final partnerCity = rel?.getPartnerLocation(currentUid) ?? 'Partner City';

        final myLat = rel?.getMyLat(currentUid);
        final myLng = rel?.getMyLng(currentUid);
        final partnerLat = rel?.getPartnerLat(currentUid);
        final partnerLng = rel?.getPartnerLng(currentUid);

        final myPoint = _resolveCityPoint(myCity, myLat, myLng, const LatLng(19.0760, 72.8777));
        final partnerPoint = _resolveCityPoint(partnerCity, partnerLat, partnerLng, const LatLng(48.8566, 2.3522));

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

        return StreamBuilder<List<MemoryModel>>(
          stream: _cloudService.streamMemories(relId),
          builder: (context, memSnap) {
            final memories = memSnap.data ?? [];
            final List<Map<String, dynamic>> visitedPlaces = [];

            // 1. My Home Base
            if (myCity.isNotEmpty && myCity != 'Your City') {
              visitedPlaces.add({
                'name': "$myName's City",
                'city': myCity,
                'lat': myPoint.latitude,
                'lng': myPoint.longitude,
                'date': 'Home base',
                'photosCount': memories.where((m) => m.location.toLowerCase().contains(myCity.toLowerCase())).length,
                'type': 'Apart',
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
                'photosCount': memories.where((m) => m.location.toLowerCase().contains(partnerCity.toLowerCase())).length,
                'type': distanceKm < 50 ? 'Together' : 'Apart',
                'icon': Icons.favorite_rounded,
                'color': AppColors.partner,
              });
            }

            // 3. Upcoming Planned Trip (Page 34/39)
            if (rel?.tripDestination != null && rel!.tripDestination!.isNotEmpty) {
              final tripCity = rel.tripDestination!;
              final tripPoint = _resolveCityPoint(tripCity, null, null, midpoint);
              final tripPhotos = memories.where((m) => m.location.toLowerCase().contains(tripCity.toLowerCase())).length;

              visitedPlaces.add({
                'name': 'Trip to $tripCity ✈️',
                'city': tripCity,
                'lat': tripPoint.latitude,
                'lng': tripPoint.longitude,
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
              if (m.lat != null && m.lng != null && m.lat != 0.0 && m.lng != 0.0) {
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
                'icon': Icons.favorite_rounded,
                'color': AppColors.partner,
              });
            }

            final currentFilter = _filters[_selectedFilterIndex];
            final filteredPlaces = visitedPlaces.where((p) {
              if (currentFilter == 'All places') return true;
              return p['type'] == currentFilter;
            }).toList();

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
                        initialZoom: _calculateOptimalZoom(distanceKm),
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.nextmeet.app',
                        ),
                        // Polyline Arc between You and Partner
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _calculateArcPoints(myPoint, partnerPoint),
                              strokeWidth: 3.0,
                              color: AppColors.primary,
                              isDotted: true,
                            ),
                          ],
                        ),
                        // Markers Layer
                        MarkerLayer(
                          markers: [
                            // You Marker (Pink Heart)
                            Marker(
                              point: myPoint,
                              width: 84,
                              height: 74,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  VibrationService.light();
                                  _mapController.move(myPoint, 9.0);
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
                            // Partner Marker (Violet Heart)
                            Marker(
                              point: partnerPoint,
                              width: 84,
                              height: 74,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  VibrationService.light();
                                  _mapController.move(partnerPoint, 9.0);
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
                            // Visited Places & Trips Markers
                            ...filteredPlaces.map((place) {
                              final isTrip = place['isTrip'] == true;
                              return Marker(
                                point: LatLng(place['lat'] as double, place['lng'] as double),
                                width: isTrip ? 42 : 36,
                                height: isTrip ? 42 : 36,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    VibrationService.light();
                                    _showPlaceDetails(place, rel);
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
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditLocationScreen(
                                            relationship: rel,
                                            relationshipId: relId,
                                          ),
                                        ),
                                      );
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
                                  final optimalZoom = _calculateOptimalZoom(distanceKm);
                                  _mapController.move(midpoint, optimalZoom);
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => NewMemoryScreen(relId: relId)),
                                  );
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditLocationScreen(
                                        relationship: rel,
                                        relationshipId: relId,
                                      ),
                                    ),
                                  );
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
                            height: 36,
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
                                );
                              },
                            ),
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
                                    _showAllPlacesSheet(visitedPlaces, rel);
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
                            SizedBox(
                              height: 84,
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
                                      _mapController.move(
                                        LatLng(place['lat'] as double, place['lng'] as double),
                                        9.5,
                                      );
                                      _showPlaceDetails(place, rel);
                                    },
                                    child: Container(
                                      width: 164,
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
                                              Text(
                                                '📸 ${place['photosCount']} photo${place['photosCount'] == 1 ? '' : 's'}',
                                                style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w700),
                                              ),
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

  Widget _buildMapPin(String name, MascotColor color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MascotHeart(color: color, size: 36),
        const SizedBox(height: 2),
        Container(
          constraints: const BoxConstraints(maxWidth: 80),
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

  List<LatLng> _calculateArcPoints(LatLng start, LatLng end) {
    final points = <LatLng>[];
    const steps = 30;

    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      // Parabolic upward curve for flight arc
      final height = math.sin(t * math.pi) * 8.0;
      points.add(LatLng(lat + height, lng));
    }
    return points;
  }

  void _showPlaceDetails(Map<String, dynamic> place, RelationshipModel? rel) {
    final photosCount = place['photosCount'] as int? ?? 0;
    final isTrip = place['isTrip'] == true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
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
                  Navigator.pop(context);
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
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NewMemoryScreen(relId: rel?.id)),
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
        );
      },
    );
  }

  void _showAllPlacesSheet(List<Map<String, dynamic>> allPlaces, RelationshipModel? rel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = allPlaces.where((p) {
              final q = searchQuery.toLowerCase().trim();
              if (q.isEmpty) return true;
              final name = (p['name'] as String).toLowerCase();
              final city = (p['city'] as String).toLowerCase();
              return name.contains(q) || city.contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
              ),
              child: Column(
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
                      Text('All Visited Places (${allPlaces.length})', style: AppTextStyles.title1.copyWith(fontSize: 20)),
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
                            decoration: const InputDecoration(
                              hintText: 'Search city or place...',
                              border: InputBorder.none,
                            ),
                            style: AppTextStyles.body,
                            onChanged: (val) {
                              setSheetState(() => searchQuery = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Place List
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text('No places match your search', style: AppTextStyles.caption),
                          )
                        : ListView.separated(
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
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _mapController.move(
                                      LatLng(p['lat'] as double, p['lng'] as double),
                                      9.5,
                                    );
                                    _showPlaceDetails(p, rel);
                                  },
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
            );
          },
        );
      },
    );
  }
}
