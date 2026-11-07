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

            if (myCity.isNotEmpty && myCity != 'Your City') {
              visitedPlaces.add({
                'name': "$myName's City",
                'city': myCity,
                'lat': myPoint.latitude,
                'lng': myPoint.longitude,
                'date': 'Home base',
                'photosCount': memories.where((m) => m.location.toLowerCase().contains(myCity.toLowerCase())).length,
                'type': 'Apart',
              });
            }

            if (partnerCity.isNotEmpty && partnerCity != 'Partner City') {
              visitedPlaces.add({
                'name': "$partnerName's City",
                'city': partnerCity,
                'lat': partnerPoint.latitude,
                'lng': partnerPoint.longitude,
                'date': 'Partner base',
                'photosCount': memories.where((m) => m.location.toLowerCase().contains(partnerCity.toLowerCase())).length,
                'type': 'Together',
              });
            }

            for (final m in memories) {
              if (m.lat != null && m.lng != null && m.lat != 0.0 && m.lng != 0.0) {
                visitedPlaces.add({
                  'name': m.caption.isNotEmpty ? m.caption : m.location,
                  'city': m.location,
                  'lat': m.lat!,
                  'lng': m.lng!,
                  'date': DateFormat('MMM yyyy').format(m.date),
                  'photosCount': 1,
                  'type': 'Together',
                });
              }
            }

            if (visitedPlaces.isEmpty) {
              visitedPlaces.add({
                'name': myCity.isNotEmpty ? myCity : 'My Location',
                'city': myCity.isNotEmpty ? myCity : 'Location 1',
                'lat': myPoint.latitude,
                'lng': myPoint.longitude,
                'date': 'Active',
                'photosCount': 0,
                'type': 'Apart',
              });
              visitedPlaces.add({
                'name': partnerCity.isNotEmpty ? partnerCity : "$partnerName's Location",
                'city': partnerCity.isNotEmpty ? partnerCity : 'Location 2',
                'lat': partnerPoint.latitude,
                'lng': partnerPoint.longitude,
                'date': 'Active',
                'photosCount': 0,
                'type': 'Together',
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
                    initialZoom: 3.2,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.nextmeet.app',
                    ),
                    // Polyline between You and Partner
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
                            onTap: () {
                              VibrationService.light();
                              _mapController.move(myPoint, 8.0);
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
                            onTap: () {
                              VibrationService.light();
                              _mapController.move(partnerPoint, 8.0);
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
                        // Visited Places Markers
                        ...filteredPlaces.map((place) {
                          return Marker(
                            point: LatLng(place['lat'] as double, place['lng'] as double),
                            width: 36,
                            height: 36,
                            child: GestureDetector(
                              onTap: () {
                                VibrationService.light();
                                _showPlaceDetails(place);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.place_rounded, color: AppColors.primary, size: 20),
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
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border, width: 1.5),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Center(
                              child: GestureDetector(
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
                                      Text(
                                        distanceKm > 1
                                            ? '${NumberFormat("#,###").format(distanceKm.round())} km apart'
                                            : 'Together nearby ❤️',
                                        style: AppTextStyles.heading.copyWith(fontSize: 13, color: AppColors.primary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Recenter Camera Button
                          GestureDetector(
                            onTap: () {
                              VibrationService.light();
                              _mapController.move(midpoint, 3.2);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border, width: 1.5),
                              ),
                              child: const Icon(Icons.center_focus_strong_rounded, size: 20, color: AppColors.ink),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Edit Location Shortcut
                          GestureDetector(
                            onTap: () {
                              VibrationService.light();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditLocationScreen(
                                    relationship: rel,
                                    relationshipId: rel?.id ?? 'default_rel',
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
                              ),
                              child: const Icon(Icons.edit_location_alt_rounded, size: 20, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Filter Pills
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filters.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final isSelected = _selectedFilterIndex == index;
                            return GestureDetector(
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
                            Text(
                              'See all',
                              style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: filteredPlaces.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final place = filteredPlaces[index];
                              return GestureDetector(
                                onTap: () {
                                  VibrationService.light();
                                  _mapController.move(
                                    LatLng(place['lat'] as double, place['lng'] as double),
                                    8.0,
                                  );
                                },
                                child: Container(
                                  width: 160,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(AppRadius.card),
                                    border: Border.all(color: AppColors.border, width: 1.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        place['name'] as String,
                                        style: AppTextStyles.heading.copyWith(fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        place['city'] as String,
                                        style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.muted),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '📸 ${place['photosCount']} photos',
                                        style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.primary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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

  void _showPlaceDetails(Map<String, dynamic> place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
                        Text(
                          place['name'] as String,
                          style: AppTextStyles.title2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                      color: AppColors.mintSoft,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      place['date'] as String,
                      style: AppTextStyles.caption.copyWith(color: AppColors.mintText, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'A romantic spot where you made memories together. Click below to view the full photo gallery.',
                style: AppTextStyles.body.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'View Photos (${place['photosCount']})',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
