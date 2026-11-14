import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/models/relationship_model.dart';
import '../../core/models/memory_model.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/widget_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/theme_service.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import 'heartbeat_sync_modal.dart';
import 'notifications_screen.dart';
import 'memories_screen.dart';
import 'new_memory_screen.dart';
import 'memory_detail_screen.dart';
import 'shared_map_screen.dart';
import 'calendar_screen.dart';
import '../moments/moments_screen.dart';
import '../onboarding/join_couple_screen.dart';
import '../onboarding/tell_us_about_you_screen.dart';
import '../profile/widgets_showcase_screen.dart';

/// NextMeet Home Screen (Paired Dashboard & Unpaired State)
/// Strictly following NextMeet Redesign.pdf (Pages 16, 17, 18)
class HomeScreen extends StatefulWidget {
  final bool initialSynced;
  const HomeScreen({super.key, this.initialSynced = true});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  late Timer _nowTimer;
  late Timer _locationTimer;
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batterySubscription;
  Timer? _batteryTimer;
  final List<_ReactionParticle> _particles = [];
  final List<Timer> _particleTimers = [];
  bool _isOffline = false;
  DateTime? _lastObservedTouchTime;
  DateTime? _lastWidgetSyncTime;
  String? _incomingTouchBanner;
  Timer? _bannerTimer;
  bool _wasUnpairedView = false;

  @override
  void initState() {
    super.initState();
    _lastObservedTouchTime = DateTime.now();
    _fetchAndUpdateLocation(requestIfDenied: true);

    _locationTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) _fetchAndUpdateLocation(requestIfDenied: false);
    });

    _nowTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });

    _initBatteryMonitoring();
  }

  void _initBatteryMonitoring() {
    _batterySubscription = _battery.onBatteryStateChanged.listen((_) {
      _reportBatteryStatus();
    });
    _batteryTimer = Timer.periodic(const Duration(minutes: 15), (_) => _reportBatteryStatus());
    _reportBatteryStatus();
  }

  Future<void> _reportBatteryStatus() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      final isCharging = state == BatteryState.charging || state == BatteryState.full;

      final rel = await _cloudService.streamRelationship().first.timeout(
        const Duration(seconds: 4),
        onTimeout: () => _cloudService.cachedRelationship,
      );
      if (rel != null && rel.id != null) {
        await _cloudService.updateBatteryStatus(rel.id!, level, isCharging);
        if (_cloudService.currentUid != null) {
          WidgetService.updateWidgetData(rel, _cloudService.currentUid!);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchAndUpdateLocation({bool requestIfDenied = false}) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!requestIfDenied) return;
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(const Duration(seconds: 5));

      String? currentCity;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude)
            .timeout(const Duration(seconds: 5));
        if (placemarks.isNotEmpty) {
          currentCity = placemarks.first.locality ?? placemarks.first.subAdministrativeArea;
        }
      } catch (_) {}

      final rel = await _cloudService.streamRelationship().first.timeout(
        const Duration(seconds: 4),
        onTimeout: () => _cloudService.cachedRelationship,
      );
      if (rel != null && rel.id != null) {
        await _cloudService.updateMyStatus(
          rel.id!,
          rel,
          city: currentCity,
          lat: pos.latitude,
          lng: pos.longitude,
        );
        if (_cloudService.currentUid != null) {
          WidgetService.updateWidgetData(rel, _cloudService.currentUid!);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nowTimer.cancel();
    _locationTimer.cancel();
    _batterySubscription?.cancel();
    _batteryTimer?.cancel();
    _bannerTimer?.cancel();
    for (final t in _particleTimers) {
      t.cancel();
    }
    _particleTimers.clear();
    super.dispose();
  }

  void _triggerParticleEffect(String type) {
    if (!mounted) return;
    final math.Random random = math.Random();
    List<String> emojis;
    switch (type) {
      case 'miss':
        emojis = ['❤️', '💖', '💕', '✨', '🥺'];
        break;
      case 'hug':
        emojis = ['🤗', '🫂', '💖', '✨'];
        break;
      case 'touch':
        emojis = ['⚡', '💖', '✨', '🔥'];
        break;
      default:
        emojis = ['✨', '💖', '❤️'];
    }

    final newParticles = List.generate(6, (i) {
      return _ReactionParticle(
        key: UniqueKey(),
        emoji: emojis[random.nextInt(emojis.length)],
        startX: 0.2 + (random.nextDouble() * 0.6),
        randomSway: (random.nextDouble() - 0.5) * 50,
        scale: 0.8 + (random.nextDouble() * 0.4),
      );
    });

    setState(() => _particles.addAll(newParticles));
    late final Timer timer;
    timer = Timer(const Duration(milliseconds: 1400), () {
      _particleTimers.remove(timer);
      if (mounted) {
        setState(() => _particles.removeWhere((p) => newParticles.contains(p)));
      }
    });
    _particleTimers.add(timer);
  }

  void _handleInteraction(RelationshipModel rel, String type) {
    if (rel.id == null) return;
    _cloudService.sendTouch(rel.id!, type);
    _triggerParticleEffect(type);
    VibrationService.light();
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return _buildOfflineScreen();
    }

    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return StreamBuilder<RelationshipModel?>(
          stream: _cloudService.streamRelationship(),
          builder: (context, snapshot) {
            final rel = snapshot.data;
            final isPaired = rel != null && rel.status == 'active' && rel.uid2 != null;

            if (!isPaired) {
              _wasUnpairedView = true;
            } else if (_wasUnpairedView) {
              _wasUnpairedView = false;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                VibrationService.success();
                _triggerParticleEffect('miss');
                final pName = rel.getPartnerName(_cloudService.currentUid);
                _bannerTimer?.cancel();
                setState(() {
                  _incomingTouchBanner = '$pName joined your couple space! ❤️';
                });
                _bannerTimer = Timer(const Duration(seconds: 4), () {
                  if (mounted) {
                    setState(() => _incomingTouchBanner = null);
                  }
                });
              });
            }

            if (rel != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                ThemeService.instance.syncFromRelationshipData(
                  rel.toFirestore(),
                  currentUid: _cloudService.currentUid,
                );
              });
            }

            if (isPaired && rel != null && (_lastWidgetSyncTime == null || DateTime.now().difference(_lastWidgetSyncTime!).inMinutes >= 2)) {
              _lastWidgetSyncTime = DateTime.now();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final uid = _cloudService.currentUid;
                if (uid != null) {
                  WidgetService.updateWidgetData(rel, uid);
                }
              });
            }

            // Check for incoming touch from partner in real-time
            if (rel != null && rel.lastTouchTime != null && rel.lastTouchFrom != null) {
              final currentUid = AuthService().currentUid;
              if (rel.lastTouchFrom != currentUid &&
                  (_lastObservedTouchTime == null || rel.lastTouchTime!.isAfter(_lastObservedTouchTime!))) {
                _lastObservedTouchTime = rel.lastTouchTime;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _triggerParticleEffect(rel.lastTouchType ?? 'miss');
                  VibrationService.success();
                  final pName = rel.getPartnerName(currentUid);
                  final touchType = rel.lastTouchType ?? 'touch';
                  final label = touchType == 'miss'
                      ? 'Miss You ❤️'
                      : (touchType == 'hug' ? 'Warm Hug 🤗' : 'Touch of Love ⚡');
                  _bannerTimer?.cancel();
                  setState(() {
                    _incomingTouchBanner = '$pName sent you a $label!';
                  });
                  _bannerTimer = Timer(const Duration(seconds: 4), () {
                    if (mounted) {
                      setState(() => _incomingTouchBanner = null);
                    }
                  });
                });
              }
            }

            return Stack(
              children: [
                Scaffold(
                  backgroundColor: ThemeService.instance.backgroundColor,
                  body: SafeArea(
                    child: isPaired ? _buildPairedHomeScreen(rel) : _buildUnpairedHomeScreen(rel),
                  ),
                ),
                // Floating Reaction Particles (Non-blocking)
                ..._particles,
                // Romantic Floating In-App Touch Banner
                if (_incomingTouchBanner != null)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 20,
                    right: 20,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: ThemeService.instance.primaryColor.withValues(alpha: 0.3), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: ThemeService.instance.primaryColor.withValues(alpha: 0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MascotHeart(
                              color: ThemeService.instance.partnerMascotColor,
                              size: 28,
                              accessory: ThemeService.instance.partnerMascotAccessory,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                _incomingTouchBanner!,
                                style: AppTextStyles.heading.copyWith(
                                  color: AppColors.ink,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // Page 16: Unpaired Home State
  Widget _buildUnpairedHomeScreen(RelationshipModel? rel) {
    final currentUid = AuthService().currentUid;
    final myName = rel?.getMyName(currentUid) ??
        (AuthService().currentUser?.displayName?.isNotEmpty == true
            ? AuthService().currentUser!.displayName!
            : 'You');
    final partnerName = rel?.getPartnerName(currentUid) ?? 'Partner';
    final inviteCode = (rel?.inviteCode ?? '').trim();
    final hasValidCode = inviteCode.length == 6;

    return RefreshIndicator(
      color: ThemeService.instance.primaryColor,
      backgroundColor: Colors.white,
      onRefresh: () async {
        VibrationService.light();
        if (mounted) setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          // Top Header (Page 16)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: ThemeService.instance.softColor,
                      child: Text(
                        myName.isNotEmpty ? myName[0].toUpperCase() : 'A',
                        style: AppTextStyles.heading.copyWith(color: ThemeService.instance.primaryColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getTimeGreeting(), style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(
                            'Hi, $myName',
                            style: AppTextStyles.title2.copyWith(fontSize: 18),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(
                        partnerName: partnerName,
                        rel: rel,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_none_rounded, color: AppColors.ink, size: 24),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Card 1: Waiting for your person banner (Page 16)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.pinkSoft.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.hero),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'Waiting for your person...',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Pink Heart pointing to Dashed Outline Heart with "?"
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MascotHeart(
                      color: ThemeService.instance.myMascotColor,
                      size: 76,
                      leanRight: true,
                      accessory: ThemeService.instance.myMascotAccessory,
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.partner, width: 2, style: BorderStyle.solid),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '?',
                        style: AppTextStyles.display.copyWith(
                          color: AppColors.partner,
                          fontSize: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Card 2: Invite Your Partner Box (Page 16)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasValidCode) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Invite your partner', style: AppTextStyles.label.copyWith(color: AppColors.ink)),
                      GestureDetector(
                        onTap: () => _copyInviteCode(inviteCode),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.pinkSoft,
                            borderRadius: BorderRadius.circular(AppRadius.badge),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.copy_rounded, color: AppColors.primary, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                'Copy',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _copyInviteCode(inviteCode),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: inviteCode.split('').map((digit) {
                        return Container(
                          width: 44,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            digit,
                            style: AppTextStyles.display.copyWith(
                              fontSize: 22,
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _unpairedActionPill(
                        label: 'Share my code',
                        filled: true,
                        onTap: () {
                          VibrationService.light();
                          Share.share(AppLinks.getInviteMessage(inviteCode));
                        },
                      ),
                      const SizedBox(width: 10),
                      _unpairedActionPill(
                        label: 'Enter theirs',
                        filled: false,
                        onTap: () {
                          VibrationService.light();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JoinCoupleScreen(userName: myName),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ] else ...[
                  Text('Connect with your partner', style: AppTextStyles.label.copyWith(color: AppColors.ink)),
                  const SizedBox(height: 6),
                  Text(
                    'Create a 6-digit invite code to invite them, or enter the code they shared.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _unpairedActionPill(
                        label: 'Get invite code',
                        filled: true,
                        onTap: () {
                          VibrationService.light();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TellUsAboutYouScreen(initialName: myName),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _unpairedActionPill(
                        label: 'Enter theirs',
                        filled: false,
                        onTap: () {
                          VibrationService.light();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JoinCoupleScreen(userName: myName),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section: Unlocks when you connect (Page 16)
          Text('Unlocks when you connect', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _lockedFeatureTile('Heartbeat', Icons.favorite_outline_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _lockedFeatureTile('Countdown', Icons.calendar_today_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _lockedFeatureTile('Memories', Icons.photo_library_outlined)),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

  /// Copies the active waiting invite code and gives haptic + snackbar feedback.
  void _copyInviteCode(String inviteCode) {
    Clipboard.setData(ClipboardData(text: inviteCode));
    VibrationService.success();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite code copied! Send it to your partner ❤️'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  /// Renders a pill CTA for the unpaired / waiting HomeScreen action row.
  Widget _unpairedActionPill({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: filled ? AppColors.primary : AppColors.pinkSoft,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.button.copyWith(
              color: filled ? Colors.white : AppColors.primary,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _lockedFeatureTile(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline_rounded, color: AppColors.muted, size: 20),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  static String _cleanCityName(String raw) {
    if (raw.trim().isEmpty) return '';
    final firstPart = raw.split(RegExp(r'[,;\n]')).first.trim();
    return firstPart.isNotEmpty ? firstPart : raw.trim();
  }

  // Page 18: Paired Home Dashboard
  Widget _buildPairedHomeScreen(RelationshipModel rel) {
    final currentUid = AuthService().currentUser?.uid;
    final myName = rel.getMyName(currentUid);
    final partnerName = rel.getPartnerName(currentUid);
    final rawMyCity = rel.getMyLocation(currentUid);
    final rawPartnerCity = rel.getPartnerLocation(currentUid);
    final myCity = _cleanCityName(rawMyCity);
    final partnerCity = _cleanCityName(rawPartnerCity);
    final partnerBattery = rel.getPartnerBattery(currentUid) ?? 85;
    final partnerTimezone = rel.getPartnerTimezoneOffset(currentUid);
    final streak = rel.streakCount;

    final now = DateTime.now();
    final myTimeStr = DateFormat('h:mm a').format(now);
    final partnerTime = now.toUtc().add(Duration(minutes: partnerTimezone));
    final partnerTimeStr = DateFormat('h:mm a').format(partnerTime);

    final isPartnerCharging = rel.isPartnerCharging(currentUid);
    final isPartnerAsleep = partnerTime.hour >= 23 || partnerTime.hour < 7;
    String partnerStatusText;
    if (isPartnerCharging) {
      partnerStatusText = '⚡ Charging • $partnerBattery%';
    } else if (isPartnerAsleep) {
      partnerStatusText = '🌙 Asleep • $partnerBattery%';
    } else {
      partnerStatusText = 'Online now • $partnerBattery%';
    }

    return RefreshIndicator(
      color: ThemeService.instance.primaryColor,
      backgroundColor: Colors.white,
      onRefresh: () async {
        VibrationService.light();
        await Future.wait([
          _fetchAndUpdateLocation(requestIfDenied: false),
          _reportBatteryStatus(),
        ]);
        if (mounted) setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          // Top Header (Page 18)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: ThemeService.instance.softColor,
                      child: Text(
                        myName.isNotEmpty ? myName[0].toUpperCase() : 'A',
                        style: AppTextStyles.heading.copyWith(color: ThemeService.instance.primaryColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getTimeGreeting(), style: AppTextStyles.caption),
                          Text(
                            'Hi, $myName',
                            style: AppTextStyles.title2.copyWith(fontSize: 18),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  VibrationService.light();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WidgetsShowcaseScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: const Icon(Icons.widgets_rounded, color: AppColors.ink, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(partnerName: partnerName, rel: rel),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.notifications_none_rounded, color: AppColors.ink, size: 22),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Hero Partner Status Card (Page 18)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ThemeService.instance.primaryColor,
              borderRadius: BorderRadius.circular(AppRadius.hero),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          MascotHeart(
                            color: ThemeService.instance.partnerMascotColor,
                            size: 48,
                            accessory: ThemeService.instance.partnerMascotAccessory,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  partnerName,
                                  style: AppTextStyles.title1.copyWith(color: Colors.white, fontSize: 22),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    partnerStatusText,
                                    style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '$streak-day streak',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Dual Time Comparison Pill (Page 18)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text('You', style: AppTextStyles.caption.copyWith(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(myTimeStr, style: AppTextStyles.heading.copyWith(fontSize: 18, color: AppColors.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Container(width: 1.5, height: 28, color: AppColors.border),
                      Expanded(
                        child: Column(
                          children: [
                            Text(partnerName, style: AppTextStyles.caption.copyWith(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(partnerTimeStr, style: AppTextStyles.heading.copyWith(fontSize: 18, color: AppColors.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Quick 3-Metric Chips (Page 18) - Real dynamic metrics
          Builder(
            builder: (context) {
              final daysTogether = DateTime.now().difference(rel.anniversaryDate).inDays;
              String togetherStr;
              if (daysTogether <= 0) {
                togetherStr = '1 day';
              } else if (daysTogether >= 365) {
                final y = daysTogether ~/ 365;
                final m = (daysTogether % 365) ~/ 30;
                togetherStr = m > 0 ? '${y}y ${m}m' : '${y}y';
              } else if (daysTogether >= 30) {
                togetherStr = '${daysTogether ~/ 30} mo';
              } else {
                togetherStr = '$daysTogether days';
              }

              final daysSinceLastMet = DateTime.now().difference(rel.lastMeetingDate).inDays;
              String lastMetStr;
              if (daysSinceLastMet <= 0) {
                lastMetStr = 'Today';
              } else if (daysSinceLastMet < 30) {
                lastMetStr = '${daysSinceLastMet}d ago';
              } else if (daysSinceLastMet < 365) {
                lastMetStr = '${daysSinceLastMet ~/ 30} mo ago';
              } else {
                lastMetStr = '${daysSinceLastMet ~/ 365}y ago';
              }

              final daysToNextMeet = rel.nextMeetingDate.difference(DateTime.now()).inDays;
              String nextMeetStr;
              if (daysToNextMeet <= 0) {
                nextMeetStr = 'Today!';
              } else {
                nextMeetStr = '$daysToNextMeet days';
              }

              return Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        VibrationService.light();
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const CalendarScreen()));
                      },
                      child: _metricPill('Together', togetherStr, Icons.favorite_rounded, AppColors.partnerLight),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        VibrationService.light();
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const CalendarScreen()));
                      },
                      child: _metricPill('Last met', lastMetStr, Icons.check_rounded, AppColors.pinkLight),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        VibrationService.light();
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const CalendarScreen()));
                      },
                      child: _metricPill('Next meet', nextMeetStr, Icons.send_rounded, AppColors.butterSoft),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 14),

          // Flight Arc Distance Map Card (Page 18)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SharedMapScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Flight Path',
                        style: AppTextStyles.heading.copyWith(fontSize: 14),
                      ),
                      TagChip(
                        label: (rel.tripDestination != null && rel.tripDestination!.isNotEmpty)
                            ? rel.tripDestination!
                            : 'Live Track',
                        backgroundColor: AppColors.partnerSoft,
                        textColor: AppColors.partnerText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Dotted Arc Flight Path between pins with City Labels
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            Icon(Icons.location_on_rounded, color: ThemeService.instance.primaryColor, size: 24),
                            const SizedBox(height: 2),
                            Text(
                              myCity.isNotEmpty ? myCity : 'You',
                              style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Row(
                                children: List.generate(
                                  12,
                                  (index) => Expanded(
                                    child: Container(
                                      height: 2,
                                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                      color: index % 2 == 0 ? ThemeService.instance.primaryColor : Colors.transparent,
                                    ),
                                  ),
                                ),
                              ),
                              Transform.rotate(
                                angle: 0.15,
                                child: const Icon(Icons.send_rounded, color: AppColors.ink, size: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            const Icon(Icons.location_on_rounded, color: AppColors.partner, size: 24),
                            const SizedBox(height: 2),
                            Text(
                              partnerCity.isNotEmpty ? partnerCity : partnerName,
                              style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: Text(
                      (rel.computedDistance > 0 ? rel.computedDistance : rel.distanceKm) > 0
                          ? '${NumberFormat("#,###").format((rel.computedDistance > 0 ? rel.computedDistance : rel.distanceKm).round())} km apart'
                          : 'Together nearby',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Heartbeat Sync Hold Card (Page 18)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      VibrationService.light();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HeartbeatSyncModal(partnerName: partnerName),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: ThemeService.instance.softColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.favorite_rounded, color: ThemeService.instance.primaryColor, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Heartbeat sync', style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text('Hold together', style: AppTextStyles.heading.copyWith(fontSize: 15), maxLines: 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    _quickActionButton(
                      type: 'miss',
                      label: 'Miss you',
                      icon: Icons.favorite_rounded,
                      color: AppColors.primary,
                      bg: AppColors.pinkSoft,
                      onTap: () => _handleInteraction(rel, 'miss'),
                    ),
                    const SizedBox(width: 8),
                    _quickActionButton(
                      type: 'hug',
                      label: 'Warm Hug',
                      icon: Icons.volunteer_activism_rounded,
                      color: AppColors.partner,
                      bg: AppColors.partnerSoft,
                      onTap: () => _handleInteraction(rel, 'hug'),
                    ),
                    const SizedBox(width: 8),
                    _quickActionButton(
                      type: 'touch',
                      label: 'Touch of Love',
                      icon: Icons.touch_app_rounded,
                      color: AppColors.butterText,
                      bg: AppColors.butterSoft,
                      onTap: () => _handleInteraction(rel, 'touch'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // "Our memories" Section with See All & Moments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Our memories', style: AppTextStyles.heading),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      VibrationService.light();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MomentsScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.butterSoft,
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                        border: Border.all(color: AppColors.butter, width: 1.0),
                      ),
                      child: Text(
                        'Moments 📸',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.butterText,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MemoriesScreen()),
                  );
                },
                child: Text(
                  'See all',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Real Memories Photo Carousel (Always includes Add Memory tile)
          SizedBox(
            height: 110,
            child: rel.id == null
                ? _buildAddMemoryPlaceholder(rel.id)
                : StreamBuilder<List<MemoryModel>>(
                    stream: _cloudService.streamMemories(rel.id!),
                    builder: (context, memSnapshot) {
                      final memories = memSnapshot.data ?? [];
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: memories.length + 1,
                        separatorBuilder: (context, index) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildAddMemoryPlaceholder(rel.id);
                          }
                          return _realMemoryThumbnail(memories[index - 1]);
                        },
                      );
                    },
                  ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

  Widget _metricPill(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.heading.copyWith(fontSize: 15, color: AppColors.ink),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton({
    required String type,
    required String label,
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.0),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _buildAddMemoryPlaceholder(String? relId) {
    return GestureDetector(
      onTap: () {
        VibrationService.light();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewMemoryScreen(relId: relId)),
        );
      },
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 28),
            const SizedBox(height: 6),
            Text(
              'Add Memory',
              style: AppTextStyles.heading.copyWith(fontSize: 12, color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _realMemoryThumbnail(MemoryModel m) {
    final hasImg = m.imageUrl.isNotEmpty;
    return GestureDetector(
      onTap: () {
        VibrationService.light();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MemoryDetailScreen(
              memory: m,
              title: m.caption.isNotEmpty ? m.caption : 'Memory',
              date: DateFormat('d MMM yyyy').format(m.date),
              location: m.location,
              imageUrl: hasImg ? m.imageUrl : null,
              emotion: m.moodEmoji,
            ),
          ),
        );
      },
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImg)
              CachedNetworkImage(
                imageUrl: m.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: AppColors.pinkSoft),
                errorWidget: (context, url, error) => Container(color: AppColors.pinkSoft),
              )
            else
              Container(
                color: AppColors.pinkSoft,
                child: const Center(
                  child: Icon(Icons.favorite_rounded, color: AppColors.primary, size: 24),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                m.caption.isNotEmpty ? m.caption : 'Memory',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Page 17: Offline Screen
  Widget _buildOfflineScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Sleeping Cloud Mascot with Heart
              Center(
                child: Container(
                  width: 140,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.pinkSoft.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.cloud_queue_rounded, color: Colors.white, size: 64),
                      Positioned(
                        bottom: 24,
                        child: MascotHeart(
                          color: ThemeService.instance.myMascotColor,
                          size: 52,
                          accessory: ThemeService.instance.myMascotAccessory,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('You are offline', style: AppTextStyles.display.copyWith(fontSize: 26)),
              const SizedBox(height: 8),
              Text(
                'No worries. Hugs, moments and whispers will send as soon as you are back online.',
                style: AppTextStyles.body.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Queued Items List
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.photo_camera_outlined, color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Text('2 moments', style: AppTextStyles.heading.copyWith(fontSize: 14)),
                          ],
                        ),
                        TagChip(label: 'Waiting', backgroundColor: AppColors.butterSoft, textColor: AppColors.butterText),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.mic_none_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Text('1 voice whisper', style: AppTextStyles.heading.copyWith(fontSize: 14)),
                          ],
                        ),
                        TagChip(label: 'Waiting', backgroundColor: AppColors.butterSoft, textColor: AppColors.butterText),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Try again',
                onPressed: () => setState(() => _isOffline = false),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactionParticle extends StatefulWidget {
  final String emoji;
  final double startX;
  final double randomSway;
  final double scale;

  const _ReactionParticle({
    super.key,
    required this.emoji,
    required this.startX,
    required this.randomSway,
    required this.scale,
  });

  @override
  State<_ReactionParticle> createState() => _ReactionParticleState();
}

class _ReactionParticleState extends State<_ReactionParticle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _yAnim = Tween<double>(begin: 0, end: -350).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: (size.width * widget.startX) + (widget.randomSway * _controller.value),
          bottom: 120 - _yAnim.value,
          child: IgnorePointer(
            child: Opacity(
              opacity: _opacityAnim.value,
              child: Transform.scale(
                scale: widget.scale,
                child: Text(
                  widget.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
