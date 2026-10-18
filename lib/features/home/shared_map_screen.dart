import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../core/models/relationship_model.dart';
import '../profile/nextmeet_plus_screen.dart';

class SharedMapScreen extends StatefulWidget {
  final String? relId;
  const SharedMapScreen({super.key, this.relId});

  @override
  State<SharedMapScreen> createState() => _SharedMapScreenState();
}

class _SharedMapScreenState extends State<SharedMapScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  late AnimationController _pulseController;
  bool _hasInitialCentered = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _sendDigitalTouch(String relId, String partnerName) {
    VibrationService.touchVibration();
    _cloudService.sendTouch(relId, 'touch');
    _cloudService.logActivity(relId, 'touch', 'Sent a Digital Touch from the map! 💓');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Digital Touch sent to $partnerName! 💓',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1B4B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _parseMapLineColor(String? hexString, bool isPlus) {
    if (isPlus && hexString != null && hexString.isNotEmpty) {
      try {
        final clean = hexString.replaceAll('#', '').replaceAll('0x', '');
        if (clean.length == 6) {
          return Color(int.parse('0xFF$clean'));
        } else if (clean.length == 8) {
          return Color(int.parse('0x$clean'));
        }
      } catch (_) {}
    }
    return AppColors.primary;
  }

  double _calculateOptimalZoom(double distanceKm) {
    if (distanceKm <= 0) return 4.0;
    if (distanceKm < 15) return 12.0;
    if (distanceKm < 60) return 9.5;
    if (distanceKm < 250) return 7.5;
    if (distanceKm < 800) return 6.0;
    if (distanceKm < 2500) return 4.5;
    if (distanceKm < 7000) return 3.5;
    return 2.5;
  }

  /// Calculates a smooth romantic flight arc between two coordinates
  List<LatLng> _calculateArc(LatLng p1, LatLng p2, {int pointsCount = 40}) {
    if ((p1.latitude == 0 && p1.longitude == 0) || (p2.latitude == 0 && p2.longitude == 0)) {
      return [p1, p2];
    }
    if (p1.latitude == p2.latitude && p1.longitude == p2.longitude) {
      return [p1, p2];
    }

    final List<LatLng> arcPoints = [];
    final double dLat = p2.latitude - p1.latitude;
    final double dLng = p2.longitude - p1.longitude;
    final double distance = math.sqrt(dLat * dLat + dLng * dLng);

    // Arch height proportional to distance, capped gracefully
    final double archHeight = (distance * 0.16).clamp(0.4, 7.5);

    // Normal vector perpendicular to chord
    double normLat = -dLng;
    double normLng = dLat;
    final double normLength = math.sqrt(normLat * normLat + normLng * normLng);
    if (normLength > 0) {
      normLat = (normLat / normLength) * archHeight;
      normLng = (normLng / normLength) * archHeight;
    }

    // Direct arc northward/outward for aesthetic curve
    if (normLat < 0 && dLng.abs() > dLat.abs()) {
      normLat = -normLat;
      normLng = -normLng;
    }

    for (int i = 0; i <= pointsCount; i++) {
      final double t = i / pointsCount;
      final double baseLat = p1.latitude + (dLat * t);
      final double baseLng = p1.longitude + (dLng * t);
      final double arcFactor = math.sin(t * math.pi);

      arcPoints.add(LatLng(
        baseLat + (normLat * arcFactor),
        baseLng + (normLng * arcFactor),
      ));
    }
    return arcPoints;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF090D16),
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (!snapshot.hasData || snapshot.data?.id == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF090D16),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map_rounded, size: 64, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text('No Partner Connected', style: AppTextStyles.h2.copyWith(color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(
                      'Pair with your partner to unlock the live interactive Couple Radar.',
                      style: AppTextStyles.bodyM.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final rel = snapshot.data!;
        final currentUid = _cloudService.currentUid;
        final bool isUser1 = currentUid == rel.uid1;

        // Position coordinates
        final LatLng myPos = LatLng(
          isUser1 ? (rel.user1Lat ?? 20.5937) : (rel.user2Lat ?? 20.5937),
          isUser1 ? (rel.user1Lng ?? 78.9629) : (rel.user2Lng ?? 78.9629),
        );
        final LatLng partnerPos = LatLng(
          isUser1 ? (rel.user2Lat ?? 28.6139) : (rel.user1Lat ?? 28.6139),
          isUser1 ? (rel.user2Lng ?? 77.2090) : (rel.user1Lng ?? 77.2090),
        );

        final LatLng center = LatLng(
          (myPos.latitude + partnerPos.latitude) / 2,
          (myPos.longitude + partnerPos.longitude) / 2,
        );

        final optimalZoom = _calculateOptimalZoom(rel.distanceKm);

        if (!_hasInitialCentered) {
          _hasInitialCentered = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _mapController.move(center, optimalZoom);
            }
          });
        }

        final isPlus = rel.isPlus;
        final flightArc = _calculateArc(myPos, partnerPos);
        final LatLng arcMidpoint = flightArc[flightArc.length ~/ 2];
        final Color lineColor = _parseMapLineColor(rel.mapLineColor, isPlus);

        // Partner Time & Battery
        final int? partnerOffset = isUser1 ? rel.user2TimezoneOffset : rel.user1TimezoneOffset;
        final DateTime partnerTime = partnerOffset != null
            ? DateTime.now().toUtc().add(Duration(minutes: partnerOffset))
            : DateTime.now();
        final String partnerTimeStr = DateFormat.jm().format(partnerTime);
        final String myTimeStr = DateFormat.jm().format(DateTime.now());

        final int? partnerBattery = rel.getPartnerBattery(currentUid);
        final bool partnerCharging = rel.isPartnerCharging(currentUid);
        final int? myBattery = rel.getMyBattery(currentUid);
        final bool myCharging = rel.isMyCharging(currentUid);

        return Scaffold(
          backgroundColor: const Color(0xFF090D16),
          body: Stack(
            children: [
              // Interactive FlutterMap
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: optimalZoom,
                  minZoom: 2,
                  maxZoom: 18,
                ),
                children: [
                  // OpenStreetMap free tile layer (zero API key requirement)
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.yousful.nextmeet',
                  ),

                  // Flight Connection Arc (Dual Polyline: Neon Ambient Glow + Sharp Laser Core)
                  PolylineLayer(
                    polylines: [
                      // Under-glow Polyline
                      Polyline(
                        points: flightArc,
                        color: lineColor.withValues(alpha: 0.28),
                        strokeWidth: isPlus ? 10 : 7,
                      ),
                      // Core Polyline
                      Polyline(
                        points: flightArc,
                        color: lineColor,
                        strokeWidth: isPlus ? (rel.mapLineStyle == 'Neon' ? 4.5 : 3.5) : 2.5,
                        isDotted: isPlus && rel.mapLineStyle == 'Dotted',
                        gradientColors: isPlus && (rel.mapLineStyle == 'Neon' || rel.mapLineStyle == 'Sanctum')
                            ? [const Color(0xFFE11D48), const Color(0xFF6366F1)]
                            : null,
                      ),
                    ],
                  ),

                  // Markers Layer
                  MarkerLayer(
                    markers: [
                      // 1. My User Marker
                      Marker(
                        point: myPos,
                        width: 140,
                        height: 140,
                        child: _buildUserMarker(
                          name: rel.getDisplayMyName(currentUid),
                          photo: rel.getMyPhoto(currentUid),
                          accent: AppColors.primary,
                          battery: myBattery,
                          isCharging: myCharging,
                          timeStr: myTimeStr,
                          isPlus: isPlus,
                          isPartner: false,
                          relId: rel.id ?? '',
                          partnerName: rel.getDisplayPartnerName(currentUid),
                        ),
                      ),

                      // 2. Partner Marker
                      Marker(
                        point: partnerPos,
                        width: 140,
                        height: 140,
                        child: _buildUserMarker(
                          name: rel.getDisplayPartnerName(currentUid),
                          photo: rel.getPartnerPhoto(currentUid),
                          accent: const Color(0xFF6366F1),
                          battery: partnerBattery,
                          isCharging: partnerCharging,
                          timeStr: partnerTimeStr,
                          isPlus: isPlus,
                          isPartner: true,
                          relId: rel.id ?? '',
                          partnerName: rel.getDisplayPartnerName(currentUid),
                        ),
                      ),

                      // 3. Flight Arc Midpoint Badge
                      Marker(
                        point: arcMidpoint,
                        width: 110,
                        height: 42,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: lineColor.withValues(alpha: 0.5),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: lineColor.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.flight_takeoff_rounded, color: Color(0xFFFB7185), size: 12),
                                const SizedBox(width: 5),
                                Text(
                                  rel.formattedDistance,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
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

              // Floating Frosted Glass Top Bar
              _buildTopFloatingBar(context, rel),

              // Floating Frosted Glass Intimacy HUD
              _buildStatsOverlay(rel),

              // Right-Side Map Controls (Floated comfortably above the Bottom HUD)
              Positioned(
                right: 16,
                bottom: 235,
                child: FloatingActionButton.small(
                  heroTag: 'mapCenter',
                  backgroundColor: const Color(0xFF0F172A),
                  child: const Icon(Icons.crop_free_rounded, color: Colors.white, size: 20),
                  onPressed: () {
                    VibrationService.light();
                    _mapController.move(center, optimalZoom);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopFloatingBar(BuildContext context, RelationshipModel rel) {
    return Positioned(
      top: 52,
      left: 20,
      right: 20,
      child: FadeInDown(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back Button
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: GestureDetector(
                  onTap: () {
                    VibrationService.light();
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),

            // Center Glass Title Pill
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.7),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'COUPLE RADAR',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Customizer / Settings Button
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: GestureDetector(
                  onTap: () {
                    VibrationService.light();
                    _showStyleCustomizer(context, rel);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMarker({
    required String name,
    required String? photo,
    required Color accent,
    required int? battery,
    required bool isCharging,
    required String? timeStr,
    required bool isPlus,
    required bool isPartner,
    required String relId,
    required String partnerName,
  }) {
    return GestureDetector(
      onTap: () {
        VibrationService.heartbeat();
        if (isPartner) {
          _sendDigitalTouch(relId, partnerName);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Local Time Pill
          if (timeStr != null)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time_rounded, color: accent, size: 9),
                  const SizedBox(width: 4),
                  Text(
                    timeStr,
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),

          // Glowing Pulsing Avatar
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer radar pulse ripple
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 74 + (_pulseController.value * 22),
                    height: 74 + (_pulseController.value * 22),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.18 * (1 - _pulseController.value)),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.38 * (1 - _pulseController.value)),
                        width: 1.5,
                      ),
                    ),
                  );
                },
              ),

              // Avatar Circle
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: accent.withValues(alpha: 0.5), blurRadius: 16, spreadRadius: 2),
                  ],
                  border: Border.all(color: accent, width: 2.5),
                ),
                child: ClipOval(
                  child: photo != null && photo.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: photo,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFF1E293B),
                            child: const Center(
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFF1E293B),
                            child: Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          color: const Color(0xFF1E293B),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                            ),
                          ),
                        ),
                ),
              ),

              // Battery Pill Badge
              if (battery != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCharging
                          ? const Color(0xFF10B981)
                          : (battery < 20 ? const Color(0xFFEF4444) : const Color(0xFF1E293B)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCharging) ...[
                          const Icon(Icons.flash_on_rounded, color: Colors.white, size: 8),
                          const SizedBox(width: 1),
                        ],
                        Text(
                          '$battery%',
                          style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 4),

          // Name Pill (Clean, uncluttered, no mood text)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
            ),
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverlay(RelationshipModel rel) {
    final currentUid = _cloudService.currentUid;
    final String myCity = rel.getMyLocation(currentUid).isNotEmpty
        ? rel.getMyLocation(currentUid).split(',').first.trim().toUpperCase()
        : 'YOUR CITY';
    final String partnerCity = rel.getPartnerLocation(currentUid).isNotEmpty
        ? rel.getPartnerLocation(currentUid).split(',').first.trim().toUpperCase()
        : 'PARTNER CITY';
    final String partnerName = rel.getDisplayPartnerName(currentUid);
    final int? partnerOffset = currentUid == rel.uid1 ? rel.user2TimezoneOffset : rel.user1TimezoneOffset;
    final DateTime partnerTime = partnerOffset != null
        ? DateTime.now().toUtc().add(Duration(minutes: partnerOffset))
        : DateTime.now();
    final String partnerTimeStr = DateFormat.jm().format(partnerTime);

    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: FadeInUp(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0F172A).withValues(alpha: 0.88),
                    const Color(0xFF1E1B4B).withValues(alpha: 0.88),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cities Route Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          myCity,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Container(width: 14, height: 1.5, color: const Color(0xFFFB7185)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.flight_rounded, color: Color(0xFFFB7185), size: 16),
                            ),
                            Container(width: 14, height: 1.5, color: const Color(0xFFFB7185)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          partnerCity,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Stat Tiles
                  Row(
                    children: [
                      Expanded(
                        child: _buildGlassStatTile(
                          icon: Icons.near_me_rounded,
                          iconColor: const Color(0xFF38BDF8),
                          title: 'DISTANCE',
                          value: rel.formattedDistance,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildGlassStatTile(
                          icon: Icons.access_time_filled_rounded,
                          iconColor: const Color(0xFFFB7185),
                          title: "${partnerName.toUpperCase()}'S TIME",
                          value: partnerTimeStr,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Tactile Touch Button
                  GestureDetector(
                    onTap: () => _sendDigitalTouch(rel.id!, partnerName),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE11D48), Color(0xFFFF5E7E)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE11D48).withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Send Love to $partnerName 💌',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassStatTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 12),
              const SizedBox(width: 5),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showStyleCustomizer(BuildContext context, RelationshipModel rel) {
    if (!rel.isPlus) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NextMeetPlusScreen(relId: rel.id ?? '')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'COUPLE RADAR THEMES',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'FLIGHT PATH COLOR',
              style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                '#FF5E7D', '#6366F1', '#10B981', '#F59E0B', '#EC4899', '#38BDF8'
              ].map((hex) => GestureDetector(
                onTap: () {
                  VibrationService.light();
                  _cloudService.updateMapSettings(rel.id!, color: hex);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(int.parse(hex.replaceAll('#', '0xFF'))),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: rel.mapLineColor == hex ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(int.parse(hex.replaceAll('#', '0xFF'))).withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'MAP SKIN',
              style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                {'id': 'Dark', 'name': 'Night', 'icon': Icons.dark_mode_rounded},
                {'id': 'Night Indigo', 'name': 'Indigo', 'icon': Icons.nightlight_round},
                {'id': 'Neon', 'name': 'Neon', 'icon': Icons.auto_awesome_rounded},
                {'id': 'Sanctum', 'name': 'Light', 'icon': Icons.light_mode_rounded},
              ].map((skin) {
                final String skinId = skin['id'] as String;
                final bool isSelected = (rel.mapLineStyle == skinId) ||
                    (skinId == 'Dark' && (rel.mapLineStyle == null || rel.mapLineStyle == 'Dotted' || rel.mapLineStyle == 'Dark'));
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        VibrationService.light();
                        _cloudService.updateMapSettings(rel.id!, style: skinId);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white12,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              skin['icon'] as IconData,
                              color: isSelected ? Colors.white : Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              skin['name'] as String,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
