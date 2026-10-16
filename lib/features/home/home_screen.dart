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
import '../../core/models/memory_model.dart';
import '../onboarding/setup_couple_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/services/notification_service.dart';
import '../profile/edit_profile_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../private_space/love_letters_screen.dart';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/daily_questions.dart';

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
  Stream<List<MemoryModel>>? _memoryStream;
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
      }
    } catch (e) {
      print("Battery report failed: $e");
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
    _batteryTimer?.cancel();
    _batterySubscription?.cancel();
    _batteryTimer?.cancel();
    _heartbeatTimer?.cancel();
    _syncPulseTimer?.cancel();
    _hugGlowTimer?.cancel();
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
        if (mounted) setState(() => _showHugGlow = true);
        _hugGlowTimer?.cancel();
        _hugGlowTimer = Timer(const Duration(milliseconds: 1400), () {
          if (mounted) setState(() => _showHugGlow = false);
        });
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

  void _handleInteraction(RelationshipModel data, String type) {
    if (data.id == null) return;
    
    _cloudService.sendTouch(data.id!, type);
    _triggerParticleEffect(type);
    
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
        VibrationService.light();
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
      VibrationService.touchVibration();
      _triggerParticleEffect(type);
    }
  }

  void _startHeartbeat() {
    if (_heartbeatTimer != null) return;
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
          _memoryStream = _cloudService.streamMemories(data.id!);
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
                child: Text('Our World is Loading... ✨', style: AppTextStyles.h1.copyWith(fontSize: 32)),
              ),
              const SizedBox(height: 8),
              FadeInDown(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  'Waiting for ${data.getDisplayPartnerName(_cloudService.currentUid)} to join the journey.',
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
                'Daily Heart Check-in', 
                'Keep your side of the heart warm', 
                Icons.favorite_outline_rounded, 
                AppColors.primary, 
                false,
                onTap: () => _showMoodPicker(data),
              ),
              
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
                'Set Your Mood', 
                'Current: ${data.getMyMood(_cloudService.currentUid)}', 
                Icons.emoji_emotions_outlined, 
                AppColors.primary, 
                false,
                onTap: () => _showMoodPicker(data),
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

  void _showMoodPicker(RelationshipModel data) {
    VibrationService.medium();
    final List<String> moods = ['Happy 💖', 'Missing You 🥺', 'In Love 🥰', 'Excited ✨', 'Chill ☕', 'Thinking of You 💭'];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Set Your Mood', style: AppTextStyles.h2),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12, runSpacing: 12,
              children: moods.map((mood) => InkWell(
                onTap: () async {
                  await _cloudService.updateMyStatus(data.id!, data, mood: mood);
      // ignore: use_build_context_synchronously
                  VibrationService.success();
                  if (mounted) Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: data.getMyMood(_cloudService.currentUid) == mood ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: data.getMyMood(_cloudService.currentUid) == mood ? AppColors.primary : Colors.transparent),
                  ),
                  child: Text(mood, style: TextStyle(fontWeight: FontWeight.bold, color: data.getMyMood(_cloudService.currentUid) == mood ? AppColors.primary : AppColors.textPrimary)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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

  Widget _buildSoloActionCard(String title, String subtitle, IconData icon, Color color) {
    return FadeInUp(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.w800)),
                  Text(subtitle, style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.divider),
          ],
        ),
      ),
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
    
    final totalGap = data.nextMeetingDate.difference(data.lastMeetingDate).inDays;
    final elapsed = now.difference(data.lastMeetingDate).inDays;
    final double progress = totalGap > 0 ? (elapsed / totalGap).clamp(0.0, 1.0) : 0.0;
      // ignore: unused_local_variable
    
    final daysTogether = now.difference(data.anniversaryDate).inDays;
    final daysSince = now.difference(data.lastMeetingDate).inDays;

    final String name1 = data.userName1 ?? 'You';
    final String name2 = data.userName2 ?? 'Partner';
    
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
                                  child: const Text('DENY', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
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
                                  child: const Text('APPROVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  
                  // Center: Names & Status (Symmetrically Centered & Overflow-Proof)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              data.getDisplayMyName(_cloudService.currentUid), 
                              style: AppTextStyles.h3.copyWith(fontSize: 17, fontWeight: FontWeight.w900),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 18),
                          ),
                          Flexible(
                            child: Text(
                              data.getDisplayPartnerName(_cloudService.currentUid), 
                              style: AppTextStyles.h3.copyWith(fontSize: 17, fontWeight: FontWeight.w900),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right: Calendar
                  GestureDetector(
                    onTap: () {
                      VibrationService.medium();
                      if (data.id != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CalendarScreen(
                              relationshipId: data.id!,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, 10)),
                        ],
                      ),
                      child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Love Streak Tracker
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${data.streakCount} DAY LOVE STREAK', 
                          style: AppTextStyles.bodyS.copyWith(color: Colors.orange.shade800, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
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
                                    'NEXT MEETUP',
                                    style: AppTextStyles.bodyS.copyWith(
                                      color: const Color(0xFFFB7185),
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                data.formattedDistance,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
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
                              child: Text(
                                data.getMyLocation(_cloudService.currentUid).isNotEmpty
                                    ? data.getMyLocation(_cloudService.currentUid)
                                    : 'Your City',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                children: [
                                  Container(width: 20, height: 1.5, color: const Color(0xFFF59E0B)),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(Icons.flight_rounded, color: Color(0xFFF59E0B), size: 18),
                                  ),
                                  Container(width: 20, height: 1.5, color: const Color(0xFFF59E0B)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                data.getPartnerLocation(_cloudService.currentUid).isNotEmpty
                                    ? data.getPartnerLocation(_cloudService.currentUid)
                                    : 'Partner City',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        
                        // Countdown Blocks: DAYS • HOURS • MINS
                        if (isPast)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Together Again 🎉 Tap to schedule Next Meet!',
                                style: AppTextStyles.bodyL.copyWith(
                                  color: const Color(0xFFF59E0B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildCountdownBlock('$daysLeft', 'DAYS'),
                              _buildCountdownColon(),
                              _buildCountdownBlock('${timeLeft.inHours % 24}'.padLeft(2, '0'), 'HOURS'),
                              _buildCountdownColon(),
                              _buildCountdownBlock('${timeLeft.inMinutes % 60}'.padLeft(2, '0'), 'MINS'),
                            ],
                          ),
                        const SizedBox(height: 14),
                        
                        // Footer Date & Tap Call to Action
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
                            Row(
                              children: [
                                Text(
                                  'Tap to view schedule',
                                  style: TextStyle(
                                    color: const Color(0xFFFB7185).withValues(alpha: 0.9),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFB7185), size: 10),
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

            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Column(
                children: [
                  Row(
                    children: [
                       Expanded(
                        child: _buildHighFidelityButton(
                          'Miss You ❤️', 
                          const Color(0xFFFF5E7E), 
                          Icons.favorite_rounded, 
                          () => _handleInteraction(data, 'miss'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                       Expanded(
                        child: _buildHighFidelityButton(
                          'Hug ✨', 
                          const Color(0xFFF59E0B), 
                          Icons.handshake_rounded, 
                          () => _handleInteraction(data, 'hug'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  _buildHighFidelityButton(
                    'Touch ⚡', 
                    const Color(0xFF8B5CF6), 
                    Icons.touch_app_rounded, 
                    () => _handleInteraction(data, 'touch'),
                    isFullWidth: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Micro Reactions Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Row(
                children: [
                  _buildReactionItem(data, 'Love', '❤️'),
                  const SizedBox(width: 8),
                  _buildReactionItem(data, 'Hug', '🤗'),
                  const SizedBox(width: 8),
                  _buildReactionItem(data, 'Kiss', '😘'),
                  const SizedBox(width: 8),
                  _buildReactionItem(data, 'Miss', '🔥'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Row(
                  children: [
                    _buildStatColumn('$daysTogether', 'DAYS\nTOGETHER'),
                    _buildStatDivider(),
                    _buildStatColumn(
                      data.computedDistance < 0.1 
                        ? 'SAME PLACE ❤️'
                        : (data.computedDistance < 1 
                            ? (data.computedDistance == 0 ? '0' : data.computedDistance.toStringAsFixed(1)) 
                            : (data.computedDistance == data.computedDistance.toInt() 
                                ? data.computedDistance.toInt().toString() 
                                : data.computedDistance.toStringAsFixed(1))), 
                      'KM\nAPART'
                    ),
                    _buildStatDivider(),
                    _buildStatColumn('$daysSince', 'DAYS\nSINCE'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Discovery Section
            // NEW FEATURE: Heart Sync (Digital Hand Holding)
            Builder(builder: (context) {
              final isSynced = data.isHeartSynced(_cloudService.currentUid);
              final partnerPressing = data.isPartnerPressing(_cloudService.currentUid);
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                child: GestureDetector(
                  onLongPressStart: (_) {
                    setState(() => _isPressingSync = true);
                    _startSyncPulse(data.id!, data.uid1 == _cloudService.currentUid);
                    VibrationService.medium();
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
                      height: 180,
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
                                _isPressingSync ? 'HOLDING HANDS...' : 'HEART SYNC',
                                style: AppTextStyles.bodyS.copyWith(
                                  color: _isPressingSync ? Colors.white : Colors.pinkAccent,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isPressingSync 
                                  ? (partnerPressing ? 'CONNECTED WITH HEART! ✨' : 'Wait for ${data.getDisplayPartnerName(_cloudService.currentUid)} to join')
                                  : 'Press and hold to sync hearts',
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
                                      'STAYING CONNECTED! ✨',
                                      style: TextStyle(
                                        color: Colors.pinkAccent,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 10,
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
            
            // Daily Question for Two (Core Retention Hook)
            _buildDailyQuestionCard(data, now),

            const SizedBox(height: 32),
            
            // Shared Map Feature (Premium)
            _buildSharedMapCard(data),

            const SizedBox(height: 32),
            
            // Shared Memories 📸 (Limited to 5 items)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('SHARED MEMORIES 📸', style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: AppColors.textSecondary.withValues(alpha: 0.8))),
                      const Icon(Icons.auto_awesome_mosaic_rounded, color: Colors.pinkAccent, size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<MemoryModel>>(
                    stream: _memoryStream,
                    builder: (context, snapshot) {
                      final memories = (snapshot.data ?? []).take(5).toList();
                      if (memories.isEmpty) {
                        return _buildEmptyMemoryPrompt();
                      }
                      return MasonryGridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: memories.length,
                        itemBuilder: (context, index) {
                          final memory = memories[index];
                          final double height = (index % 3 == 0) ? 260 : 180;
                          
                          return FadeInUp(
                            delay: Duration(milliseconds: index * 100),
                            child: Container(
                              height: height,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                image: DecorationImage(
                                  image: CachedNetworkImageProvider(memory.imageUrl),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 8)),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      memory.caption,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time_rounded, color: Colors.white70, size: 10),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat.MMMd().format(memory.date),
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Love Message Card (The Pink Box)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F3),
                  borderRadius: BorderRadius.circular(32),
                  border: const Border(left: BorderSide(color: Colors.pinkAccent, width: 4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.format_quote_rounded, color: Colors.redAccent, size: 24),
                        const SizedBox(width: 8),
                        Text('DAILY LOVE QUOTE ❤️', style: AppTextStyles.bodyS.copyWith(color: Colors.redAccent, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '"${data.loveQuote}"',
                      style: AppTextStyles.h2.copyWith(fontSize: 20, fontStyle: FontStyle.italic, color: const Color(0xFF1E293B)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
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
                  const Text('DAILY QUESTION FOR TWO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2, color: AppColors.primary)),
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
                text: 'LOCK IN MY ANSWER 💖',
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
                        'DAILY QUESTION FOR TWO',
                        style: AppTextStyles.bodyS.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 1.2,
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
                          ? 'BOTH ANSWERED ✨'
                          : (hasPartnerAnswered
                              ? '$partnerName answered! 🔒'
                              : (myAnswer != null ? 'Waiting for $partnerName ⏳' : 'New today 💌')),
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
                                ? 'ANSWER TO UNLOCK $partnerName\'S ANSWER ✨'
                                : 'ANSWER TODAY\'S QUESTION 💌',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 0.5,
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
                          'YOUR ANSWER:',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary),
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
                          '$partnerName\'s answer unlocks once they reply 🔒',
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
                        'YOU:',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary),
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
                        '$partnerName:'.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF6366F1)),
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

  Widget _buildEmptyMemoryPrompt() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_rounded, color: Colors.pinkAccent.withValues(alpha: 0.3), size: 40),
          const SizedBox(height: 12),
          Text('No memories yet', style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary)),
          Text('Capture your journey together', style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 10)),
      // ignore: unused_element
        ],
      ),
    );
  }

  Widget _buildAvatarPair() {
    return SizedBox(
      width: 76,
      height: 44,
      child: Stack(
        children: [
          // Partner Avatar (Back)
          Positioned(
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 1),
                boxShadow: [
                  BoxShadow(color: AppColors.accent.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2),
                ],
              ),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(Icons.person_rounded, color: AppColors.accent, size: 20),
              ),
            ),
          ),
          // User Avatar (Front)
          Positioned(
            left: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 12, spreadRadius: 4),
                ],
              ),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
              ),
            ),
          ),
          // Connection Heart
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppColors.softShadow,
              ),
              child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 10),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildHighFidelityButton(String text, Color color, IconData icon, VoidCallback onTap, {bool isFullWidth = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 56,
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: AppTextStyles.button.copyWith(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionItem(RelationshipModel data, String label, String emoji) {
    return Expanded(
      child: InkWell(
        onTap: () => _handleInteraction(data, 'emoji'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                label, 
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyS.copyWith(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: AppTextStyles.h2.copyWith(fontSize: 20, color: Colors.pinkAccent)),
            ),
            const SizedBox(height: 4),
            Text(
              label, 
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyS.copyWith(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.textSecondary.withValues(alpha: 0.5), letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 40, color: const Color(0xFFF1F5F9));
  }

  Widget _buildPartnerLocalTime(RelationshipModel data) {
    final int? partnerOffset = _cloudService.currentUid == data.uid1 ? data.user2TimezoneOffset : data.user1TimezoneOffset;
    if (partnerOffset == null) return const SizedBox.shrink();

    final nowUtc = DateTime.now().toUtc();
    final partnerTime = nowUtc.add(Duration(minutes: partnerOffset));
    final timeStr = DateFormat.jm().format(partnerTime); // Localized time (e.g. 10:55 PM)

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_filled_rounded, size: 10, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            'Partner Time: $timeStr',
            style: AppTextStyles.bodyS.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSharedMapCard(RelationshipModel data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: GestureDetector(
        onTap: () {
          VibrationService.medium();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SharedMapScreen(relId: data.id!),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80&w=1000'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.map_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'SHARED LOVE TRAIL',
                          style: AppTextStyles.h3.copyWith(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Visualize your journey on a beautiful map ✨',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (data.isPlus)
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                    child: const Text('PLUS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
                ),
            ],
          ),
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
