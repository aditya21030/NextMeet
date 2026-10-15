import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../core/models/relationship_model.dart';

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

  void _sendDigitalTouch(String relId) {
    VibrationService.medium();
    _cloudService.logActivity(relId, 'touch', 'Sent a Digital Touch from the map! 💓');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Digital Touch Sent! 💓'), duration: Duration(seconds: 1)),
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
    return AppColors.primary.withValues(alpha: isPlus ? 0.8 : 0.3);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data?.id == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              title: Text('Partner Map', style: AppTextStyles.h3),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map_rounded, size: 56, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text('No Partner Connected', style: AppTextStyles.h2),
                    const SizedBox(height: 8),
                    Text('Connect with your partner to share live locations and distance.', style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          );
        }

        final rel = snapshot.data!;
        final p1Pos = LatLng(rel.user1Lat ?? 0, rel.user1Lng ?? 0);
        final p2Pos = LatLng(rel.user2Lat ?? 0, rel.user2Lng ?? 0);
        final isPlus = rel.isPlus;

        final center = LatLng(
          (p1Pos.latitude + p2Pos.latitude) / 2,
          (p1Pos.longitude + p2Pos.longitude) / 2,
        );

        // Adjust pulse speed if close
        if (rel.distanceKm < 5 && _pulseController.duration!.inSeconds != 1) {
          _pulseController.duration = const Duration(seconds: 1);
          if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
        } else if (rel.distanceKm >= 5 && _pulseController.duration!.inSeconds != 2) {
          _pulseController.duration = const Duration(seconds: 2);
          if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
        }

        return Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 4,
                  minZoom: 2,
                  maxZoom: 18,
                ),
                children: [
                   TileLayer(
                    urlTemplate: isPlus && rel.mapLineStyle == 'Sanctum'
                      ? 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager_nolabels/{z}/{x}/{y}{r}.png'
                      : 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                  ),
                  
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [p1Pos, p2Pos],
                        color: _parseMapLineColor(rel.mapLineColor, isPlus),
                        strokeWidth: isPlus ? (rel.mapLineStyle == 'Neon' ? 6 : 4) : 2,
                        isDotted: isPlus && rel.mapLineStyle == 'Dotted',
                        gradientColors: isPlus && (rel.mapLineStyle == 'Neon' || rel.mapLineStyle == 'Sanctum')
                          ? [AppColors.primary, AppColors.accent] 
                          : null,
                      ),
                    ],
                  ),

                  MarkerLayer(
                    markers: [
                      Marker(
                        point: p1Pos,
                        width: 140, height: 140,
                        child: _buildUserMarker(
                          rel.userName1 ?? 'You', 
                          rel.userPhoto1, 
                          AppColors.primary,
                          rel.user1Battery,
                          rel.user1IsCharging ?? false,
                          rel.userMood1 ?? 'Happy 💖',
                          isPlus,
                          false, // isPartner
                          rel.id ?? '',
                        ),
                      ),
                      Marker(
                        point: p2Pos,
                        width: 140, height: 140,
                        child: _buildUserMarker(
                          rel.userName2 ?? 'Partner', 
                          rel.userPhoto2, 
                          AppColors.accent,
                          rel.user2Battery,
                          rel.user2IsCharging ?? false,
                          rel.userMood2 ?? 'Missing You 🥺',
                          isPlus,
                          true, // isPartner
                          rel.id ?? '',
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              Positioned(
                top: 60, left: 24,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
              _buildStatsOverlay(rel),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPlus)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FloatingActionButton(
                    heroTag: 'mapStyle',
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.palette_rounded, color: AppColors.primary),
                    onPressed: () => _showStyleCustomizer(context, rel),
                  ),
                ),
              FloatingActionButton(
                heroTag: 'mapCenter',
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.center_focus_strong_rounded, color: Colors.white),
                onPressed: () {
                  VibrationService.light();
                  _mapController.move(center, 4);
                },
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildUserMarker(String name, String? photo, Color accent, int? battery, bool isCharging, String mood, bool isPlus, bool isPartner, String relId) {
    return GestureDetector(
      onDoubleTap: isPlus ? () => _sendDigitalTouch(relId) : null,
      child: Column(
        children: [
          if (isPlus && isPartner) 
            FadeInDown(
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wb_sunny_rounded, color: Colors.orange, size: 10),
                    const SizedBox(width: 4),
                    Text('24°C • 10:45 PM', style: AppTextStyles.bodyS.copyWith(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
              ),
            ),
          Stack(
            alignment: Alignment.center,
            children: [
              if (isPlus)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 70 + (_pulseController.value * 20),
                      height: 70 + (_pulseController.value * 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.15 * (1 - _pulseController.value)),
                        border: Border.all(color: accent.withValues(alpha: 0.3 * (1 - _pulseController.value)), width: 2),
                      ),
                    );
                  },
                ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.5), blurRadius: 15)],
                  border: Border.all(color: accent, width: 3),
                ),
                child: CircleAvatar(
                  radius: 25,
                  backgroundColor: accent.withValues(alpha: 0.1),
                  backgroundImage: photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: (photo == null || photo.isEmpty) ? Text(name[0], style: const TextStyle(color: Colors.white)) : null,
                ),
              ),
              if (isPlus)
                Positioned(
                  top: 0, right: 0,
                  child: FadeIn(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.amber, 
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: const Icon(Icons.star_rounded, color: Colors.white, size: 10),
                    ),
                  ),
                ),
              if (battery != null)
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: battery < 20 ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCharging) 
                          const Icon(Icons.flash_on, color: Colors.white, size: 8),
                        Text('$battery%', style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 1),
                Text(mood, style: const TextStyle(color: Colors.white60, fontSize: 7, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverlay(RelationshipModel rel) {
    return Positioned(
      bottom: 100, left: 24, right: 24,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white10),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30)],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('DISTANCE', rel.formattedDistance, Icons.sync_alt_rounded),
                Container(width: 1, height: 40, color: Colors.white12),
                _buildStatItem('SAFE ZONE', 'Secured', Icons.verified_user_rounded),
              ],
            ),
            if (rel.isPlus) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.shield_rounded, color: AppColors.primary, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('SOUL-SYNC: PRECISION SYNC ACTIVE', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showStyleCustomizer(BuildContext context, RelationshipModel rel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SOUL-SYNC CUSTOMIZER', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 32),
              
              const Text('PATH COLOR', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  '#FF5E7D', '#6366F1', '#10B981', '#F59E0B', '#EC4899'
                ].map((hex) => GestureDetector(
                  onTap: () {
                    _cloudService.updateMapSettings(rel.id!, color: hex);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 45, height: 45,
                    decoration: BoxDecoration(
                      color: Color(int.parse(hex.replaceAll('#', '0xFF'))),
                      shape: BoxShape.circle,
                      border: Border.all(color: rel.mapLineColor == hex ? Colors.white : Colors.transparent, width: 3),
                    ),
                  ),
                )).toList(),
              ),
              
              const SizedBox(height: 32),
              
              const Text('MAP SKIN', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['Sanctum', 'Night Indigo', 'Neon', 'Dotted'].map((style) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(style, style: const TextStyle(fontSize: 10)),
                      selected: rel.mapLineStyle == style,
                      onSelected: (val) {
                        _cloudService.updateMapSettings(rel.id!, style: style);
                        Navigator.pop(context);
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.black45,
                      labelStyle: TextStyle(
                        color: rel.mapLineStyle == style ? Colors.white : Colors.white70, 
                        fontWeight: rel.mapLineStyle == style ? FontWeight.bold : FontWeight.normal,
                        fontSize: 10,
                      ),
                      side: BorderSide(
                        color: rel.mapLineStyle == style ? Colors.white : Colors.white24,
                        width: rel.mapLineStyle == style ? 2 : 1,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white38, size: 16),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }
}
