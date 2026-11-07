import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';

/// NextMeet 2026 Wrapped 6-Slide Story Recap Screen
/// Strictly following NextMeet Redesign.pdf (Pages 79-84)
class WrappedStoryScreen extends StatefulWidget {
  const WrappedStoryScreen({super.key});

  @override
  State<WrappedStoryScreen> createState() => _WrappedStoryScreenState();
}

class _WrappedStoryScreenState extends State<WrappedStoryScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  int _currentSlide = 0;
  final int _totalSlides = 6;
  Timer? _progressTimer;
  double _slideProgress = 0.0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _startStoryTimer();
  }

  void _startStoryTimer() {
    _slideProgress = 0.0;
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      if (_isPaused) return;
      setState(() {
        _slideProgress += 0.01;
        if (_slideProgress >= 1.0) {
          _nextSlide();
        }
      });
    });
  }

  void _pauseStoryTimer() {
    _isPaused = true;
  }

  void _resumeStoryTimer() {
    _isPaused = false;
  }

  void _nextSlide() {
    if (_currentSlide < _totalSlides - 1) {
      setState(() {
        _currentSlide += 1;
        _slideProgress = 0.0;
      });
    } else {
      _progressTimer?.cancel();
    }
  }

  void _prevSlide() {
    if (_currentSlide > 0) {
      setState(() {
        _currentSlide -= 1;
        _slideProgress = 0.0;
      });
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUid;

    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, snapshot) {
        final rel = snapshot.data;
        final myName = rel?.getMyName(currentUid) ?? 'You';
        final partnerName = rel?.getPartnerName(currentUid) ?? 'Partner';
        final myCity = rel?.getMyLocation(currentUid) ?? 'Here';
        final partnerCity = rel?.getPartnerLocation(currentUid) ?? 'There';
        final distanceKm = (rel?.computedDistance ?? 0) > 0 ? rel!.computedDistance : (rel?.distanceKm ?? 0);
        final streak = rel?.streakCount ?? 42;

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: GestureDetector(
              onTapDown: (details) {
                final screenWidth = MediaQuery.of(context).size.width;
                if (details.globalPosition.dx < screenWidth / 3) {
                  VibrationService.light();
                  _prevSlide();
                } else {
                  VibrationService.light();
                  _nextSlide();
                }
              },
              onLongPressStart: (_) => _pauseStoryTimer(),
              onLongPressEnd: (_) => _resumeStoryTimer(),
              child: Stack(
                children: [
                  // Current Slide Content
                  Positioned.fill(
                    child: _buildSlideContent(
                      index: _currentSlide,
                      myName: myName,
                      partnerName: partnerName,
                      myCity: myCity,
                      partnerCity: partnerCity,
                      distanceKm: distanceKm,
                      streak: streak,
                    ),
                  ),

                  // Top Multi-Segment Progress Bars (Page 79)
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: Column(
                      children: [
                        Row(
                          children: List.generate(_totalSlides, (index) {
                            double val = 0.0;
                            if (index < _currentSlide) {
                              val = 1.0;
                            } else if (index == _currentSlide) {
                              val = _slideProgress.clamp(0.0, 1.0);
                            }

                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                height: 3.5,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: val,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'NextMeet 2026 Wrapped',
                              style: AppTextStyles.caption.copyWith(color: Colors.white70, fontWeight: FontWeight.w700),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlideContent({
    required int index,
    required String myName,
    required String partnerName,
    required String myCity,
    required String partnerCity,
    required double distanceKm,
    required int streak,
  }) {
    switch (index) {
      case 0:
        return _slide1Welcome(myName, partnerName);
      case 1:
        return _slide2Touches(streak);
      case 2:
        return _slide3Distance(myCity, partnerCity, distanceKm);
      case 3:
        return _slide4Games(myName, partnerName);
      case 4:
        return _slide5Memories(myCity, partnerCity);
      case 5:
      default:
        return _slide6Share(myName, partnerName, distanceKm);
    }
  }

  // Slide 1: Welcome & Cover
  Widget _slide1Welcome(String myName, String partnerName) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const TwoMascotsRow(
            spacing: 24,
            leftAccessory: MascotAccessory.partyHat,
            rightAccessory: MascotAccessory.partyHat,
          ),
          const SizedBox(height: 28),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$myName & $partnerName',
              style: AppTextStyles.title1.copyWith(color: Colors.white, fontSize: 26),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your 2026 Year Together',
            style: AppTextStyles.display.copyWith(color: AppColors.butter, fontSize: 30),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'A year of distance made small by love. Tap to begin your story.',
            style: AppTextStyles.body.copyWith(color: Colors.white.withValues(alpha: 0.9), height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Slide 2: Touches & Hugs
  Widget _slide2Touches(int streak) {
    return Container(
      color: AppColors.partner,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_rounded, color: Colors.white, size: 64),
          const SizedBox(height: 20),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '12,480',
              style: AppTextStyles.display.copyWith(color: AppColors.butter, fontSize: 48),
            ),
          ),
          Text(
            'Digital Touches & Hugs Sent',
            style: AppTextStyles.title1.copyWith(color: Colors.white, fontSize: 22),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              children: [
                Text('🔥 $streak-Day Active Streak', style: AppTextStyles.heading.copyWith(color: Colors.white)),
                const SizedBox(height: 6),
                Text('Most active time: 11:42 PM', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Slide 3: Distance & Reunion
  Widget _slide3Distance(String myCity, String partnerCity, double distanceKm) {
    return Container(
      color: const Color(0xFF1E293B), // Midnight slate
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flight_takeoff_rounded, color: AppColors.mint, size: 64),
          const SizedBox(height: 20),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${distanceKm.toInt()} km',
              style: AppTextStyles.display.copyWith(color: AppColors.mint, fontSize: 44),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Between $myCity & $partnerCity',
              style: AppTextStyles.title1.copyWith(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              children: [
                Text('Reunion Flights ✈️', style: AppTextStyles.heading.copyWith(color: Colors.white)),
                const SizedBox(height: 6),
                Text('Countless memories bridged across distance', style: AppTextStyles.body.copyWith(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Slide 4: Couple Games
  Widget _slide4Games(String myName, String partnerName) {
    return Container(
      color: const Color(0xFF7A5200), // Rich amber
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎮', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            '89 Games Played',
            style: AppTextStyles.display.copyWith(color: AppColors.butter, fontSize: 32),
          ),
          Text(
            'Top game: "How Well Do You Know Me?"',
            style: AppTextStyles.body.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        myName,
                        style: AppTextStyles.heading.copyWith(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text('52 wins', style: AppTextStyles.title1.copyWith(color: AppColors.butter)),
                    ],
                  ),
                ),
                Text('VS', style: AppTextStyles.caption.copyWith(color: Colors.white60)),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        partnerName,
                        style: AppTextStyles.heading.copyWith(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text('37 wins', style: AppTextStyles.title1.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Slide 5: Memories
  Widget _slide5Memories(String myCity, String partnerCity) {
    return Container(
      color: const Color(0xFFB0145A), // Deep berry
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_rounded, color: Colors.white, size: 64),
          const SizedBox(height: 20),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '64 Memories Saved',
              style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 30),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Captured moments between hearts',
            style: AppTextStyles.body.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              children: [
                Text('Special Places Visited 🏖️', style: AppTextStyles.heading.copyWith(color: Colors.white)),
                const SizedBox(height: 6),
                Text('Love letters sealed and exchanged forever', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Slide 6: Summary & Share Card (Page 84)
  Widget _slide6Share(String myName, String partnerName, double distanceKm) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Polaroid Style Couple Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const TwoMascotsRow(
                    spacing: 16,
                    leftAccessory: MascotAccessory.crown,
                    rightAccessory: MascotAccessory.crown,
                  ),
                  const SizedBox(height: 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$myName & $partnerName',
                      style: AppTextStyles.title1.copyWith(fontSize: 22),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('NextMeet 2026 Wrapped', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Text(
                    'Distance: ${distanceKm.toInt()} km\nLove: Infinite 💕',
                    style: AppTextStyles.body.copyWith(color: AppColors.ink, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            GestureDetector(
              onTap: () async {
                VibrationService.success();
                final text = '✨ NextMeet 2026 Wrapped ✨\n'
                    '💕 $myName & $partnerName\n'
                    '📍 ${distanceKm.round()} km bridged with love\n'
                    'Infinite Love in NextMeet ❤️';
                await Share.share(text);
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('Share Story 📲', style: AppTextStyles.button.copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text('Done', style: AppTextStyles.button.copyWith(color: AppColors.ink)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
