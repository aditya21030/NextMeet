import 'dart:async';
import 'dart:math' as math;
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/auth_service.dart';
import '../auth/login_screen.dart';
import '../../core/constants.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../widgets/primary_button.dart';
import 'calendar_screen.dart';
import 'shared_map_screen.dart';
import '../../core/services/widget_service.dart';
import 'package:intl/intl.dart';
import '../onboarding/setup_couple_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/services/notification_service.dart';
import '../profile/edit_profile_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../private_space/love_letters_screen.dart';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/daily_questions.dart';
import '../../widgets/scratch_love_note_card.dart';

class HomeScreen extends StatefulWidget {
  final bool initialSynced;
  const HomeScreen({super.key, this.initialSynced = true});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final NotificationService _notificationService = NotificationService();
  late Timer _nowTimer;
  late Timer _locationTimer;
  late ValueNotifier<DateTime> _nowNotifier;
  Stream<RelationshipModel?>? _relationshipStream;
  String? _lastInitializedRelId;
  DateTime? _lastHandledTouchTime;
  bool _isPressingSync = false;
  Timer? _heartbeatTimer;
  Timer? _syncPulseTimer;
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batterySubscription;
  Timer? _batteryTimer;
  final List<_ReactionParticle> _particles = [];
  bool _showHugGlow = false;
  Timer? _hugGlowTimer;

  @override
  void initState() {
    super.initState();
    _nowNotifier = ValueNotifier(DateTime.now());
    _relationshipStream = _cloudService.streamRelationship();
    _fetchAndUpdateLocation();
    
    _locationTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) _fetchAndUpdateLocation();
    });

    _nowTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) _nowNotifier.value = DateTime.now();
    });

    _initBatteryMonitoring();
  }

  void _initBatteryMonitoring() {
    _batterySubscription = _battery.onBatteryStateChanged.listen((BatteryState state) {
      _reportBatteryStatus();
    });
    _batteryTimer = Timer.periodic(const Duration(minutes: 15), (timer) => _reportBatteryStatus());
    _reportBatteryStatus();
  }

  Future<void> _reportBatteryStatus() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      final isCharging = state == BatteryState.charging || state == BatteryState.full;
      
      final relationship = await _cloudService.streamRelationship().first;
      if (relationship != null && relationship.id != null) {
        await _cloudService.updateBatteryStatus(relationship.id!, level, isCharging);
        if (_cloudService.currentUid != null) {
          WidgetService.updateWidgetData(relationship, _cloudService.currentUid!);
        }
      }
    } catch (_) {
    }
  }

  Future<void> _fetchAndUpdateLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      
      String? currentCity;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          currentCity = placemarks.first.locality ?? placemarks.first.subAdministrativeArea;
        }
      } catch (e) {
        print("Geocoding failed, but coordinates obtained 📍");
      }

      final relationship = await _cloudService.streamRelationship().first;
      if (relationship != null && relationship.id != null) {
        await _cloudService.updateMyStatus(
          relationship.id!, 
          relationship, 
          city: currentCity,
          lat: position.latitude,
          lng: position.longitude,
        );
      }
    } catch (e) {
      print("Location fetch failed: $e");
    }
  }

  @override
  void dispose() {
    _nowTimer.cancel();
    _locationTimer.cancel();
    _batterySubscription?.cancel();
    _batteryTimer?.cancel();
    _heartbeatTimer?.cancel();
    _syncPulseTimer?.cancel();
    _hugGlowTimer?.cancel();
    super.dispose();
  }

  void _triggerParticleEffect(String type, {String? customEmoji}) {
    if (!mounted) return;
    final math.Random random = math.Random();
    List<String> emojis;
    if (customEmoji != null && customEmoji.isNotEmpty) {
      emojis = [customEmoji];
    } else {
      switch (type) {
        case 'miss':
          emojis = ['❤️', '💖', '💕', '✨', '🥺'];
          break;
        case 'hug':
          emojis = ['🤗', '🫂', '💖', '✨'];
          if (mounted) setState(() => _showHugGlow = true);
          _hugGlowTimer?.cancel();
          _hugGlowTimer = Timer(const Duration(milliseconds: 1400), () {
            if (mounted) setState(() => _showHugGlow = false);
          });
          break;
        case 'touch':
          emojis = ['⚡', '💖', '✨', '🔥'];
          break;
        case 'emoji':
          emojis = ['😘', '💖', '✨', '🥰', '🔥'];
          break;
        default:
          emojis = ['✨', '💖', '❤️'];
      }
    }

    final newParticles = List.generate(6, (i) {
      return _ReactionParticle(
        key: UniqueKey(),
        emoji: emojis[random.nextInt(emojis.length)],
        startX: 0.15 + (random.nextDouble() * 0.7),
        randomSway: (random.nextDouble() - 0.5) * 60,
        scale: 0.8 + (random.nextDouble() * 0.5),
      );
    });

    setState(() {
      _particles.addAll(newParticles);
    });

    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _particles.removeWhere((p) => newParticles.contains(p));
        });
      }
    });
  }

  void _handleInteraction(RelationshipModel data, String type, {String? emoji}) {
    if (data.id == null) return;
    
    _cloudService.sendTouch(data.id!, type, emoji: emoji);
    _triggerParticleEffect(type, customEmoji: emoji);
    
    switch(type) {
      case 'miss':
        VibrationService.medium();
        break;
      case 'touch':
        VibrationService.touchVibration();
        break;
      case 'hug':
        VibrationService.hugVibration();
        break;
      case 'emoji':
        VibrationService.sparkle();
        break;
      default:
        VibrationService.light();
    }
  }

  void _checkIncomingTouch(RelationshipModel data) {
    if (data.lastTouchTime == null || data.lastTouchFrom == _cloudService.currentUid) return;
    
    // Only handle if it's new (after we last handled) AND within the last 15 seconds
    // to prevent old notifications from re-triggering on screen navigation/mount
    final bool isRecent = DateTime.now().difference(data.lastTouchTime!).inSeconds < 15;
    
    if (isRecent && (_lastHandledTouchTime == null || data.lastTouchTime!.isAfter(_lastHandledTouchTime!))) {
      _lastHandledTouchTime = data.lastTouchTime;
      
      final type = data.lastTouchType ?? 'miss';
      VibrationService.playPattern(data.hapticPatternType);
      _triggerParticleEffect(type, customEmoji: data.lastTouchEmoji);
    }
  }

  void _startHeartbeat() {
    if (_heartbeatTimer != null) return;
    // Fire immediately so partner experiences zero vibration latency
    VibrationService.heartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (mounted) {
        VibrationService.heartbeat();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _startSyncPulse(String relId, bool isUser1) {
    _syncPulseTimer?.cancel();
    // Pulse immediately then every 2 seconds
    _cloudService.setHeartSync(relId, isUser1, true);
    _syncPulseTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _isPressingSync) {
        _cloudService.setHeartSync(relId, isUser1, true);
      } else {
        timer.cancel();
      }
    });
  }

  void _stopSyncPulse(String relId, bool isUser1) {
    _syncPulseTimer?.cancel();
    _syncPulseTimer = null;
    _cloudService.setHeartSync(relId, isUser1, false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _relationshipStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
                    const SizedBox(height: 24),
                    Text('Sync Error', style: AppTextStyles.h2),
                    const SizedBox(height: 12),
                    Text(
                      'We couldn\'t sync your heart! This might be a temporary connection or permission issue.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: 'Try Again ✨',
                      onPressed: () {
                        setState(() {
                          _relationshipStream = _cloudService.streamRelationship();
                        });
                      },
                    ),
                    TextButton(
                      onPressed: () async {
                        await AuthService().signOut();
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
      // ignore: use_build_context_synchronously
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      child: Text('Sign Out & Reset', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final data = snapshot.data;
        
        // Update Home Screen Widget
        if (data != null && _cloudService.currentUid != null) {
          WidgetService.updateWidgetData(data, _cloudService.currentUid!);
        }

        if (data != null) {
          _checkIncomingTouch(data);
        }

        if (data == null) {
          return _buildNotConnectedState();
        }

        // If partner hasn't joined yet
        if (data.uid2 == null) {
          return _buildWaitingForPartnerState(data);
        }

        // Initialize notifications and nested streams only once per relationship ID
        if (_lastInitializedRelId != data.id) {
          _lastInitializedRelId = data.id;
          _cloudService.updateActivityAndStreak(data.id!, data); // Ensure streak updates on open
          _notificationService.syncRelationshipReminders(data); // Sync anniversary notifications
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _cloudService.initNotifications(data.id!);
          });
        }

        return ValueListenableBuilder<DateTime>(
          valueListenable: _nowNotifier,
          builder: (context, now, child) {
            return _buildMainHome(data, now);
          },
        );
      },
    );
  }

  Widget _buildWaitingForPartnerState(RelationshipModel data) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              FadeInDown(
                child: Text('Waiting for Partner ❤️', style: AppTextStyles.h1.copyWith(fontSize: 28)),
              ),
              const SizedBox(height: 8),
              FadeInDown(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  'Waiting for ${data.getDisplayPartnerName(_cloudService.currentUid)} to connect using your invite code.',
                  style: AppTextStyles.bodyL.copyWith(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 32),
              
              // Pulsing Heart Centerpiece
              Center(
                child: Pulse(
                  infinite: true,
                  duration: const Duration(seconds: 2),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 64),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Enhanced Code Card
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: AppColors.premiumShadow,
                  ),
                  child: Column(
                    children: [
                      Text('YOUR LOVE CODE', style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: data.inviteCode ?? ''));
                          VibrationService.success();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied! ❤️'), behavior: SnackBarBehavior.floating));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                data.inviteCode ?? '...',
                                style: AppTextStyles.h1.copyWith(color: AppColors.primary, letterSpacing: 4),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.copy_rounded, color: AppColors.primary, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('SEND INVITE VIA', style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w900, color: Colors.grey)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMiniSocialBtn(FontAwesomeIcons.whatsapp, AppColors.whatsapp, () => _shareInvite(data, 'whatsapp')),
                          _buildMiniSocialBtn(FontAwesomeIcons.telegram, AppColors.telegram, () => _shareInvite(data, 'telegram')),
                          _buildMiniSocialBtn(FontAwesomeIcons.instagram, AppColors.instagram, () => _shareInvite(data, 'instagram')),
                          _buildMiniSocialBtn(Icons.share_rounded, Colors.grey.shade700, () => _shareInvite(data, 'generic')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text('WHILE YOU WAIT...', style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              const SizedBox(height: 16),

              _buildWaitingStep(
                'Create Journey', 
                'Magic link generated successfully', 
                Icons.check_circle_rounded, 
                AppColors.success, 
                true
              ),
              _buildWaitingStep(
                'Partner Joins', 
                'Waiting for ${data.getDisplayPartnerName(_cloudService.currentUid)}', 
                Icons.radio_button_unchecked_rounded, 
                Colors.grey, 
                false
              ),
              _buildWaitingStep(
                'Add First Memory', 
                'Upload a photo of you two', 
                Icons.add_photo_alternate_outlined, 
                AppColors.primary, 
                false,
                onTap: () => _showAddMemorySheet(data),
              ),
              _buildWaitingStep(
                'Write a Secret Letter', 
                'Start your Private Space', 
                Icons.edit_note_rounded, 
                AppColors.primary, 
                false,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoveLettersScreen())),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniSocialBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildWaitingStep(String title, String subtitle, IconData icon, Color color, bool isDone, {VoidCallback? onTap}) {
    return FadeInUp(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDone ? color.withValues(alpha: 0.2) : Colors.transparent),
              boxShadow: AppColors.softShadow,
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.w800, color: isDone ? color : AppColors.textPrimary)),
                      Text(subtitle, style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (isDone) const Icon(Icons.check_rounded, color: AppColors.success, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _shareInvite(RelationshipModel data, String platform) async {
    final message = AppLinks.getInviteMessage(data.inviteCode ?? '');
    VibrationService.medium();

    switch (platform) {
      case 'whatsapp':
        final url = "whatsapp://send?text=${Uri.encodeComponent(message)}";
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
        } else {
          Share.share(message);
        }
        break;
      case 'telegram':
        final url = "tg://msg?text=${Uri.encodeComponent(message)}";
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
        } else {
          Share.share(message);
        }
      default:
        Share.share(message, subject: 'NextMeet Love Invite');
    }
  }

  void _showAddMemorySheet(RelationshipModel data) {
    VibrationService.medium();
    final ImagePicker picker = ImagePicker();
    String newLocation = data.getMyLocation(_cloudService.currentUid);
    File? selectedImage;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.xl,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Capture Your First Moment 📸', style: AppTextStyles.h2),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                  if (image != null) setModalState(() => selectedImage = File(image.path));
                },
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(24),
                    image: selectedImage != null ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover) : null,
                  ),
                  child: selectedImage == null ? const Icon(Icons.add_a_photo_rounded, size: 48, color: AppColors.primary) : null,
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'SAVE TO JOURNEY',
                isLoading: isUploading,
                onPressed: () async {
                  if (selectedImage != null) {
                    setModalState(() => isUploading = true);
      // ignore: use_build_context_synchronously
                    await _cloudService.addMemory(data.id!, selectedImage!, "Our journey starts here!", newLocation);
                    VibrationService.success();
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      // ignore: unused_element
    );
  }


  Widget _buildNotConnectedState() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border_rounded, size: 80, color: AppColors.primary.withValues(alpha: 0.2)),
              const SizedBox(height: 24),
              Text('Not Connected Yet', style: AppTextStyles.h2),
              const SizedBox(height: 12),
              Text(
                'Create a journey or join one to start syncing hearts.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Join or Create Journey ✨',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SetupCoupleScreen()),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await AuthService().signOut();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                child: Text('Sign Out', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainHome(RelationshipModel data, DateTime now) {
    final bool isPast = now.isAfter(data.nextMeetingDate);
    final timeLeft = isPast ? Duration.zero : data.nextMeetingDate.difference(now);
    final daysLeft = timeLeft.inDays;

    final int? partnerOffset = _cloudService.currentUid == data.uid1 ? data.user2TimezoneOffset : data.user1TimezoneOffset;
    final DateTime partnerTime = partnerOffset != null 
        ? now.toUtc().add(Duration(minutes: partnerOffset))
        : now;
    final String partnerTimeStr = DateFormat.jm().format(partnerTime);
    final String myTimeStr = DateFormat.jm().format(now);
    final int? partnerBattery = data.getPartnerBattery(_cloudService.currentUid);
    final bool isPartnerCharging = data.isPartnerCharging(_cloudService.currentUid);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB), // Very light grey/white
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),

              // PIN Reset Approval Prompt (Priority)
              if (data.pinResetRequestBy != null && data.pinResetRequestBy != _cloudService.currentUid && !data.pinResetApproved)
                FadeInDown(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, AppSpacing.l),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5),
                        ],
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.security_rounded, color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('PIN Reset Request', style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                                    Text('${data.getDisplayPartnerName(_cloudService.currentUid)} wants to reset their Private PIN.', style: AppTextStyles.bodyS),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => _cloudService.cancelPinReset(data.id!),
                                  child: const Text('Decline', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    VibrationService.success();
                                    _cloudService.approvePinReset(data.id!);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            // High-Fidelity Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Row(
                children: [
                  // Left: Profile Avatar (New access point)
                  GestureDetector(
                    onTap: () {
                      VibrationService.light();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            relationshipId: data.id ?? '',
                            relationship: data,
                            isPartner: false,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, 10)),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.background,
                        backgroundImage: data.getMyPhoto(_cloudService.currentUid).isNotEmpty 
                            ? CachedNetworkImageProvider(data.getMyPhoto(_cloudService.currentUid)) 
                            : null,
                        child: data.getMyPhoto(_cloudService.currentUid).isEmpty 
                            ? const Icon(Icons.person_rounded, color: AppColors.primary, size: 22) 
                            : null,
                      ),
                    ),
                  ),
                  
                  // Center: Couple Names (Symmetrically Centered & Overflow-Proof)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              data.getDisplayMyName(_cloudService.currentUid), 
                              style: AppTextStyles.h3.copyWith(fontSize: 16, fontWeight: FontWeight.w900),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 16),
                          ),
                          Flexible(
                            child: Text(
                              data.getDisplayPartnerName(_cloudService.currentUid), 
                              style: AppTextStyles.h3.copyWith(fontSize: 16, fontWeight: FontWeight.w900),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right: Symmetric placeholder to keep couple names centered with the left avatar
                  const SizedBox(width: 44, height: 44),
                ],
              ),
            ),
            // Intimate Live Mood Status Row
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // My Mood (tap to change)
                  InkWell(
                    onTap: () {
                      VibrationService.light();
                      _showMoodPickerSheet(data);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            data.getMyMood(_cloudService.currentUid),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_rounded, size: 10, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Partner Mood (real-time display)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      '${data.getDisplayPartnerName(_cloudService.currentUid)}: ${data.getPartnerMood(_cloudService.currentUid)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            // Love Streak Tracker (Only display when active)
            if (data.streakCount > 0) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${data.streakCount} Day Love Streak', 
                            style: AppTextStyles.bodyS.copyWith(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ] else
              const SizedBox(height: 20),
            
            // Hero Reunion Boarding Pass Countdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: FadeInUp(
                child: GestureDetector(
                  onTap: () {
                    VibrationService.medium();
                    if (data.id != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CalendarScreen(relationshipId: data.id!),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF18181B), Color(0xFF27272A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE11D48).withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFE11D48).withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Flight Header: Route + Distance Pill
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE11D48).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.flight_takeoff_rounded, color: Color(0xFFFB7185), size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'NEXT REUNION',
                                    style: AppTextStyles.bodyS.copyWith(
                                      color: const Color(0xFFFB7185),
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                VibrationService.medium();
                                if (data.id != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SharedMapScreen(relId: data.id!),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.map_rounded, color: Color(0xFF38BDF8), size: 13),
                                    const SizedBox(width: 5),
                                    Text(
                                      data.formattedDistance,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 8),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        
                        // Cities Route Line
                        Row(
                          children: [
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  data.getMyLocation(_cloudService.currentUid).isNotEmpty
                                      ? data.getMyLocation(_cloudService.currentUid).split(',').first.trim().toUpperCase()
                                      : 'YOUR CITY',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                children: [
                                  Container(width: 16, height: 1.5, color: const Color(0xFFFB7185)),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(Icons.flight_rounded, color: Color(0xFFFB7185), size: 18),
                                  ),
                                  Container(width: 16, height: 1.5, color: const Color(0xFFFB7185)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  data.getPartnerLocation(_cloudService.currentUid).isNotEmpty
                                      ? data.getPartnerLocation(_cloudService.currentUid).split(',').first.trim().toUpperCase()
                                      : 'PARTNER CITY',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        
                        // Sub-row: Local Times & Partner Battery
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'You • $myTimeStr',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.access_time_rounded, color: Colors.white54, size: 11),
                                const SizedBox(width: 4),
                                Text(
                                  partnerTimeStr,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (partnerBattery != null) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    isPartnerCharging ? Icons.battery_charging_full_rounded : Icons.battery_std_rounded,
                                    color: isPartnerCharging ? const Color(0xFF10B981) : Colors.white70,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$partnerBattery%',
                                    style: TextStyle(
                                      color: isPartnerCharging ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        
                        // Countdown Blocks: Days • Hours • Mins
                        if (isPast)
                          Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFB7185).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFB7185).withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_month_rounded, color: Color(0xFFFB7185), size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Plan Next Reunion',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 10),
                                ],
                              ),
                            ),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildCountdownBlock('$daysLeft', 'Days'),
                              _buildCountdownColon(),
                              _buildCountdownBlock('${timeLeft.inHours % 24}'.padLeft(2, '0'), 'Hours'),
                              _buildCountdownColon(),
                              _buildCountdownBlock('${timeLeft.inMinutes % 60}'.padLeft(2, '0'), 'Mins'),
                            ],
                          ),
                        const SizedBox(height: 14),
                        
                        // Footer Date & Schedule Action
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat.yMMMMd().format(data.nextMeetingDate),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Row(
                              children: [
                                Text(
                                  'View Schedule',
                                  style: TextStyle(
                                    color: Color(0xFFFB7185),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFB7185), size: 10),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            
            // Sleek Tactile Quick Intimacy Bar (Replaces 4 bloated cards with 1 clean chic row)
            _buildQuickIntimacyBar(data),

            const SizedBox(height: 10),

            // Live Love Emoji Quick React Bar
            _buildQuickEmojiReactBar(data),

            const SizedBox(height: 24),

            // Discovery Section
            // NEW FEATURE: Heart Sync (Digital Hand Holding)
            Builder(builder: (context) {
              final isSynced = data.isHeartSynced(_cloudService.currentUid);
              final partnerPressing = data.isPartnerPressing(_cloudService.currentUid);
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                child: GestureDetector(
                  onTapDown: (_) {
                    setState(() => _isPressingSync = true);
                    _startSyncPulse(data.id!, data.uid1 == _cloudService.currentUid);
                    VibrationService.medium();
                  },
                  onTapUp: (_) {
                    setState(() => _isPressingSync = false);
                    _stopSyncPulse(data.id!, data.uid1 == _cloudService.currentUid);
                    _stopHeartbeat();
                  },
                  onTapCancel: () {
                    if (_isPressingSync) {
                      setState(() => _isPressingSync = false);
                      _stopSyncPulse(data.id!, data.uid1 == _cloudService.currentUid);
                      _stopHeartbeat();
                    }
                  },
                  onLongPressStart: (_) {
                    if (!_isPressingSync) {
                      setState(() => _isPressingSync = true);
                      _startSyncPulse(data.id!, data.uid1 == _cloudService.currentUid);
                      VibrationService.medium();
                    }
                  },
                  onLongPressEnd: (_) {
                    setState(() => _isPressingSync = false);
                    _stopSyncPulse(data.id!, data.uid1 == _cloudService.currentUid);
                    _stopHeartbeat();
                  },
                  onLongPressCancel: () {
                    if (_isPressingSync) {
                      setState(() => _isPressingSync = false);
                      _stopSyncPulse(data.id!, data.uid1 == _cloudService.currentUid);
                      _stopHeartbeat();
                    }
                  },
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.0, end: _isPressingSync ? 1.05 : 1.0),
                    duration: const Duration(milliseconds: 200),
                    builder: (context, scale, child) => Transform.scale(
                      scale: scale,
                      child: child,
                    ),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isPressingSync 
                            ? [const Color(0xFFFF5E7E), const Color(0xFFFF3D68)]
                            : [Colors.white, const Color(0xFFF8FAFC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: (_isPressingSync ? const Color(0xFFFF5E7E) : Colors.black).withValues(alpha: 0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                        border: Border.all(
                          color: _isPressingSync ? Colors.transparent : Colors.pinkAccent.withValues(alpha: 0.1),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isPressingSync)
                            FadeIn(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                width: 140,
                                height: 140,
                              ),
                            ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 56,
                                height: 56,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (_isPressingSync)
                                      const SizedBox(
                                        width: 56,
                                        height: 56,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                    Icon(
                                      _isPressingSync ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      color: _isPressingSync ? Colors.white : Colors.pinkAccent,
                                      size: 40,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _isPressingSync ? 'Holding hands...' : 'Heart Sync',
                                style: AppTextStyles.bodyS.copyWith(
                                  color: _isPressingSync ? Colors.white : Colors.pinkAccent,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isPressingSync 
                                  ? (partnerPressing ? 'Holding hands together ❤️' : 'Waiting for ${data.getDisplayPartnerName(_cloudService.currentUid)}...')
                                  : 'Touch and hold together',
                                style: AppTextStyles.bodyM.copyWith(
                                  color: _isPressingSync ? Colors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          // Real-time Sync Detection
                          if (isSynced && _isPressingSync)
                            Builder(builder: (context) {
                              WidgetsBinding.instance.addPostFrameCallback((_) => _startHeartbeat());
                              return Positioned(
                                top: 20,
                                child: FadeInDown(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Connected ❤️',
                                      style: TextStyle(
                                        color: Colors.pinkAccent,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            })
                          else if (_heartbeatTimer != null && !isSynced)
                            Builder(builder: (context) {
                              WidgetsBinding.instance.addPostFrameCallback((_) => _stopHeartbeat());
                              return const SizedBox.shrink();
                            }),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
            
            // Daily Scratch-off Love Note (Midnight Reset Hook)
            ScratchLoveNoteCard(
              relationship: data,
              currentUid: _cloudService.currentUid!,
            ),

            const SizedBox(height: 32),
            
            // Daily Question for Two (Core Retention Hook)
            _buildDailyQuestionCard(data, now),

            const SizedBox(height: 120), // Spacer for bottom Nav
          ],
        ),
      ),
    ),
    if (_showHugGlow) _buildAmbientHugGlow(),
    _buildParticleLayer(),
  ],
),
);
}

  void _showAnswerQuestionSheet(RelationshipModel data, String dateKey, String question) {
    final TextEditingController answerController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: AppSpacing.l,
            right: AppSpacing.l,
            top: AppSpacing.l,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.l,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Question of the Day', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                question,
                style: AppTextStyles.h3.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Your answer will be locked until ${data.getDisplayPartnerName(_cloudService.currentUid)} answers too! 💌',
                style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: answerController,
                autofocus: true,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write your honest, sweet answer...',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Save Answer 💌',
                isLoading: isSaving,
                onPressed: () async {
                  final text = answerController.text.trim();
                  if (text.isEmpty) return;
                  setModalState(() => isSaving = true);
                  VibrationService.success();
                  await _cloudService.submitDailyAnswer(data.id!, dateKey, question, text);
                  if (mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() => answerController.dispose());
  }

  Widget _buildDailyQuestionCard(RelationshipModel data, DateTime now) {
    final todayKey = DailyQuestions.getTodayKey();
    final question = DailyQuestions.getQuestionForDate(now);
    final myAnswer = data.getMyDailyAnswer(_cloudService.currentUid, todayKey);
    final partnerAnswer = data.getPartnerDailyAnswer(_cloudService.currentUid, todayKey);
    final bool hasPartnerAnswered = partnerAnswer != null;
    final bool haveBothAnswered = myAnswer != null && hasPartnerAnswered;
    final partnerName = data.getDisplayPartnerName(_cloudService.currentUid);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: FadeInUp(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: (haveBothAnswered ? const Color(0xFF10B981) : AppColors.primary).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: haveBothAnswered 
                  ? const Color(0xFF10B981).withValues(alpha: 0.3) 
                  : AppColors.primary.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'DAILY QUESTION',
                        style: AppTextStyles.bodyS.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 1.0,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: haveBothAnswered
                          ? const Color(0xFF10B981).withValues(alpha: 0.12)
                          : (hasPartnerAnswered
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      haveBothAnswered
                          ? 'Both Answered ✨'
                          : (hasPartnerAnswered
                              ? '$partnerName answered! 🔒'
                              : (myAnswer != null ? 'Waiting for $partnerName' : 'New today 💌')),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: haveBothAnswered
                            ? const Color(0xFF10B981)
                            : (hasPartnerAnswered ? AppColors.primary : AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Question Text
              Text(
                question,
                style: AppTextStyles.h3.copyWith(
                  fontSize: 17,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),

              // Interactive States
              if (!haveBothAnswered) ...[
                if (myAnswer == null) ...[
                  // Not answered yet
                  InkWell(
                    onTap: () {
                      VibrationService.light();
                      _showAnswerQuestionSheet(data, todayKey, question);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.buttonShadow,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit_note_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            hasPartnerAnswered
                                ? 'Unlock $partnerName\'s answer ✨'
                                : 'Write your answer 💌',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // I answered, partner hasn't answered
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Answer:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '"$myAnswer"',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          '$partnerName\'s answer unlocks once they reply',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                // Both answered! Reveal side-by-side or stacked
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'You:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '"$myAnswer"',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$partnerName:',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6366F1)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '"$partnerAnswer"',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickIntimacyBar(RelationshipModel data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildQuickTouchPill(
              emoji: '❤️',
              label: 'Miss You',
              onTap: () => _handleInteraction(data, 'miss'),
            ),
            _buildQuickTouchDivider(),
            _buildQuickTouchPill(
              emoji: '🤗',
              label: 'Send Hug',
              onTap: () => _handleInteraction(data, 'hug'),
            ),
            _buildQuickTouchDivider(),
            _buildQuickTouchPill(
              emoji: '⚡',
              label: 'Touch',
              onTap: () => _handleInteraction(data, 'touch'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTouchPill({
    required String emoji,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTouchDivider() {
    return Container(
      width: 1,
      height: 20,
      color: const Color(0xFFF1F5F9),
    );
  }

  void _showMoodPickerSheet(RelationshipModel data) {
    if (data.id == null) return;
    final moods = [
      'Happy 💖',
      'Missing You 🥺',
      'In Love 🥰',
      'Need a Hug 🫂',
      'Sleepy 😴',
      'Working 💻',
      'Spicy 🔥',
      'Grateful ✨',
      'Thinking of You 💭',
      'Traveling ✈️',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'How are you feeling right now? ✨',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            Text(
              '${data.getDisplayPartnerName(_cloudService.currentUid)} will see your updated mood live.',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: moods.map((m) {
                final isCurrent = data.getMyMood(_cloudService.currentUid) == m;
                return InkWell(
                  onTap: () async {
                    VibrationService.success();
                    Navigator.pop(context);
                    await _cloudService.updateMyStatus(data.id!, data, mood: m);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.primary.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrent ? AppColors.primary : const Color(0xFFE2E8F0),
                        width: isCurrent ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      m,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                        color: isCurrent ? AppColors.primary : const Color(0xFF1E293B),
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickEmojiReactBar(RelationshipModel data) {
    final emojis = [
      {'emoji': '😘', 'label': 'Kiss'},
      {'emoji': '🥺', 'label': 'Miss'},
      {'emoji': '🔥', 'label': 'Spicy'},
      {'emoji': '💖', 'label': 'Love'},
      {'emoji': '✨', 'label': 'Magic'},
      {'emoji': '💋', 'label': 'Smooch'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: emojis.map((e) {
            final emojiStr = e['emoji']!;
            return InkWell(
              onTap: () {
                _handleInteraction(data, 'emoji', emoji: emojiStr);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.5)),
                ),
                child: Text(
                  emojiStr,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }


  Widget _buildParticleLayer() {
    if (_particles.isEmpty) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: _particles,
        ),
      ),
    );
  }

  Widget _buildAmbientHugGlow() {
    return Positioned.fill(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, child) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFFF5E7E).withValues(alpha: 0.35 * value),
                  width: 6,
                ),
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    const Color(0xFFFF5E7E).withValues(alpha: 0.12 * value),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCountdownBlock(String val, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFF59E0B),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.white60,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownColon() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        ':',
        style: TextStyle(
          color: Color(0xFFF59E0B),
          fontSize: 24,
          fontWeight: FontWeight.bold,
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
  late Animation<double> _fadeAnimation;
  late Animation<double> _riseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _riseAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final startLeft = size.width * widget.startX;
    final startTop = size.height * 0.72;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double currentTop = startTop - (_riseAnimation.value * 280);
        final double currentLeft = startLeft + (math.sin(_riseAnimation.value * math.pi) * widget.randomSway);

        return Positioned(
          top: currentTop,
          left: currentLeft,
          child: Opacity(
            opacity: _fadeAnimation.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: widget.scale * (1.0 + (_riseAnimation.value * 0.3)),
              child: child,
            ),
          ),
        );
      },
      child: Text(
        widget.emoji,
        style: const TextStyle(fontSize: 32),
      ),
    );
  }
}
