import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';
import '../../widgets/primary_button.dart';
import 'nextmeet_plus_screen.dart';

class HapticPreferencesScreen extends StatefulWidget {
  final RelationshipModel rel;
  const HapticPreferencesScreen({super.key, required this.rel});

  @override
  State<HapticPreferencesScreen> createState() => _HapticPreferencesScreenState();
}

class _HapticPreferencesScreenState extends State<HapticPreferencesScreen> with SingleTickerProviderStateMixin {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  late String _selectedPattern;
  late String _selectedIntensity;
  bool _isPlaying = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _selectedPattern = widget.rel.hapticPatternType ?? 'Heartbeat';
    _selectedIntensity = widget.rel.hapticIntensity ?? 'Balanced';

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _plusPatterns = [
    {
      'name': 'Soulmate Flutter',
      'icon': Icons.favorite_border_rounded,
      'cadence': 'Flutter • 450ms',
      'desc': 'Rapid delicate flutter resembling butterflies in your stomach.',
      'func': VibrationService.soulmateFlutter,
      'isPlus': true,
    },
    {
      'name': 'Cosmic Surge',
      'icon': Icons.electric_bolt_rounded,
      'cadence': 'Surge • 680ms',
      'desc': 'Escalating electrical burst of deep romantic passion.',
      'func': VibrationService.cosmicSurge,
      'isPlus': true,
    },
    {
      'name': 'Endless Love',
      'icon': Icons.all_inclusive_rounded,
      'cadence': 'Triple Beat • 920ms',
      'desc': 'Hypnotic continuous triple-heartbeat loop.',
      'func': VibrationService.endlessLove,
      'isPlus': true,
    },
    {
      'name': 'Deep Embrace',
      'icon': Icons.favorite_rounded,
      'cadence': 'Sustained • 750ms',
      'desc': 'Intense, warm sustained chest-to-chest hold.',
      'func': VibrationService.deepEmbrace,
      'isPlus': true,
    },
    {
      'name': 'Secret Whisper',
      'icon': Icons.spatial_audio_off_rounded,
      'cadence': 'Micro-taps • 500ms',
      'desc': 'Subtle microscopic touch designed to be felt discreetly in your palm.',
      'func': VibrationService.secretWhisper,
      'isPlus': true,
    },
    {
      'name': 'Passionate Gallop',
      'icon': Icons.speed_rounded,
      'cadence': 'Accelerando • 600ms',
      'desc': 'Surging accelerando rhythm that beats like a racing heart.',
      'func': VibrationService.passionateGallop,
      'isPlus': true,
    },
    {
      'name': 'Velvet Rain',
      'icon': Icons.water_drop_rounded,
      'cadence': 'Droplets • 520ms',
      'desc': 'Gentle cascading droplets of silky micro-clicks and soft taps.',
      'func': VibrationService.velvetRain,
      'isPlus': true,
    },
    {
      'name': 'Tender Caress',
      'icon': Icons.spa_rounded,
      'cadence': 'Silky Pulse • 640ms',
      'desc': 'Silky, soothing alternating warm double-vibrations.',
      'func': VibrationService.tenderCaress,
      'isPlus': true,
    },
    {
      'name': 'Infinity Pulse',
      'icon': Icons.stream_rounded,
      'cadence': 'Harmonic • 800ms',
      'desc': 'Continuous harmonic wave that rises and smoothly fades.',
      'func': VibrationService.infinityPulse,
      'isPlus': true,
    },
  ];

  final List<Map<String, dynamic>> _standardPatterns = [
    {
      'name': 'Heartbeat',
      'icon': Icons.favorite_rounded,
      'cadence': 'Dual Pulse • 400ms',
      'desc': 'Biological dual-pulse rhythm (Lub-dub).',
      'func': VibrationService.heartbeat,
      'isPlus': false,
    },
    {
      'name': 'Warm Hug',
      'icon': Icons.handshake_rounded,
      'cadence': 'Squeeze • 550ms',
      'desc': 'A soft, comforting long squeeze.',
      'func': VibrationService.hugVibration,
      'isPlus': false,
    },
    {
      'name': 'Digital Touch',
      'icon': Icons.touch_app_rounded,
      'cadence': 'Triple Tap • 350ms',
      'desc': 'A rapid, triple-tap energy pulse.',
      'func': VibrationService.touchVibration,
      'isPlus': false,
    },
    {
      'name': 'Sparkle',
      'icon': Icons.auto_awesome_rounded,
      'cadence': 'Glimmer • 300ms',
      'desc': 'A light, shimmering sequence.',
      'func': VibrationService.sparkle,
      'isPlus': false,
    },
    {
      'name': 'Pulse',
      'icon': Icons.sensors_rounded,
      'cadence': 'Growing Wave • 420ms',
      'desc': 'A rhythmic growing vibration.',
      'func': VibrationService.pulse,
      'isPlus': false,
    },
    {
      'name': 'Echo',
      'icon': Icons.hearing_rounded,
      'cadence': 'Fading • 480ms',
      'desc': 'A strong hit with fading ripples.',
      'func': VibrationService.echo,
      'isPlus': false,
    },
    {
      'name': 'Wave',
      'icon': Icons.waves_rounded,
      'cadence': 'Rolling • 500ms',
      'desc': 'A smooth, rolling wave sensation.',
      'func': VibrationService.wave,
      'isPlus': false,
    },
  ];

  Future<void> _playAndAnimate(Map<String, dynamic> pattern) async {
    setState(() => _isPlaying = true);
    _pulseController.repeat(reverse: true);

    try {
      await pattern['func']();
    } finally {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            _pulseController.stop();
            _pulseController.reset();
            setState(() => _isPlaying = false);
          }
        });
      }
    }
  }

  void _onPatternTap(Map<String, dynamic> pattern, bool isPlusUser) {
    _playAndAnimate(pattern);

    if (pattern['isPlus'] == true && !isPlusUser) {
      _showPlusUpgradeSheet(pattern['name']);
      return;
    }

    setState(() => _selectedPattern = pattern['name']);
  }

  void _showPlusUpgradeSheet(String patternName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Color(0xFF18101E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: Color(0xFFFFB3C6), width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5E7E), Color(0xFF845EC2)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5E7E).withValues(alpha: 0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.stars_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Unlock "$patternName"',
              style: AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'NextMeet+ members get exclusive luxury tactile rhythms that turn phone vibrations into emotional connections.',
              style: AppTextStyles.bodyM.copyWith(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'UNLOCK WITH NEXTMEET+ 👑',
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NextMeetPlusScreen(relId: widget.rel.id ?? ''),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later', style: TextStyle(color: Colors.white38)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      initialData: widget.rel,
      builder: (context, snapshot) {
        final rel = snapshot.data ?? widget.rel;
        final bool isPlusUser = rel.isPlus;

        final currentPatternObj = [..._plusPatterns, ..._standardPatterns].firstWhere(
          (p) => p['name'] == _selectedPattern,
          orElse: () => _standardPatterns[0],
        );

        return Scaffold(
          backgroundColor: const Color(0xFF0F0812),
          body: Stack(
            children: [
              // Ambient Glow
              Positioned(
                top: -100,
                right: -50,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    color: isPlusUser
                        ? const Color(0xFFFFC75F).withValues(alpha: 0.08)
                        : AppColors.primary.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    pinned: true,
                    centerTitle: true,
                    title: Text(
                      'SIGNATURE TOUCH',
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 17,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // TACTILE STUDIO HERO STAGE
                          FadeInDown(
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isPlusUser
                                      ? [
                                          const Color(0xFF26182C),
                                          const Color(0xFF190F1E),
                                        ]
                                      : [
                                          const Color(0xFF1E1424),
                                          const Color(0xFF120B16),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: isPlusUser
                                      ? const Color(0xFFFFC75F).withValues(alpha: 0.3)
                                      : Colors.white12,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Animated Pulsing Heart Ring
                                  GestureDetector(
                                    onTap: () => _playAndAnimate(currentPatternObj),
                                    child: AnimatedBuilder(
                                      animation: _pulseAnimation,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: _isPlaying ? _pulseAnimation.value : 1.0,
                                          child: Container(
                                            width: 76,
                                            height: 76,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: isPlusUser
                                                    ? [const Color(0xFFFF5E7E), const Color(0xFFFFC75F)]
                                                    : [AppColors.primary, const Color(0xFF845EC2)],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: (isPlusUser ? const Color(0xFFFF5E7E) : AppColors.primary)
                                                      .withValues(alpha: _isPlaying ? 0.6 : 0.3),
                                                  blurRadius: _isPlaying ? 28 : 16,
                                                  spreadRadius: _isPlaying ? 4 : 0,
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              _isPlaying ? Icons.vibration_rounded : currentPatternObj['icon'],
                                              color: Colors.white,
                                              size: 34,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Active Name & Cadence Badge
                                  Text(
                                    _selectedPattern.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      currentPatternObj['cadence'] ?? 'Tactile Touch',
                                      style: TextStyle(
                                        color: isPlusUser ? const Color(0xFFFFC75F) : Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    currentPatternObj['desc'] ?? '',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Test Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _playAndAnimate(currentPatternObj),
                                          icon: Icon(
                                            _isPlaying ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
                                            size: 18,
                                            color: isPlusUser ? const Color(0xFFFFC75F) : Colors.white,
                                          ),
                                          label: Text(
                                            _isPlaying ? 'VIBRATING...' : 'FEEL NOW',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1,
                                              color: isPlusUser ? const Color(0xFFFFC75F) : Colors.white,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            side: BorderSide(
                                              color: isPlusUser
                                                  ? const Color(0xFFFFC75F).withValues(alpha: 0.5)
                                                  : Colors.white24,
                                            ),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Intensity Selector for Plus Members
                                  if (isPlusUser) ...[
                                    const SizedBox(height: 18),
                                    Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                                    const SizedBox(height: 14),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'HAPTIC INTENSITY',
                                          style: TextStyle(
                                            color: Color(0xFFFFC75F),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        Text(
                                          _selectedIntensity,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: ['Gentle', 'Balanced', 'Intense'].map((intensity) {
                                        final isSel = _selectedIntensity == intensity;
                                        return Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              VibrationService.light();
                                              setState(() => _selectedIntensity = intensity);
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 4),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              decoration: BoxDecoration(
                                                color: isSel
                                                    ? const Color(0xFFFFC75F).withValues(alpha: 0.2)
                                                    : Colors.white.withValues(alpha: 0.04),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isSel
                                                      ? const Color(0xFFFFC75F)
                                                      : Colors.white12,
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                intensity,
                                                style: TextStyle(
                                                  color: isSel ? const Color(0xFFFFC75F) : Colors.white60,
                                                  fontSize: 11,
                                                  fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // VIP / NEXTMEET+ RHYTHMS HEADER
                          Row(
                            children: [
                              Icon(
                                Icons.stars_rounded,
                                color: isPlusUser ? const Color(0xFFFFC75F) : const Color(0xFFFF5E7E),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isPlusUser ? 'VIP RHYTHMIC SUITE (UNLOCKED 👑)' : 'NEXTMEET+ EXCLUSIVE RHYTHMS',
                                style: TextStyle(
                                  color: isPlusUser
                                      ? const Color(0xFFFFC75F)
                                      : const Color(0xFFFFC75F).withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11.5,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          ..._plusPatterns.asMap().entries.map((entry) {
                            return _buildPatternTile(
                              pattern: entry.value,
                              index: entry.key,
                              isPlusUser: isPlusUser,
                            );
                          }),

                          const SizedBox(height: 24),

                          // STANDARD RHYTHMS HEADER
                          const Text(
                            'CLASSIC RHYTHMS',
                            style: TextStyle(
                              color: Colors.white54,
                              fontWeight: FontWeight.w900,
                              fontSize: 11.5,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),

                          ..._standardPatterns.asMap().entries.map((entry) {
                            return _buildPatternTile(
                              pattern: entry.value,
                              index: entry.key + _plusPatterns.length,
                              isPlusUser: isPlusUser,
                            );
                          }),

                          const SizedBox(height: 140),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // STICKY BOTTOM ACTION BAR
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: PrimaryButton(
                      text: 'SAVE AS SIGNATURE TOUCH ❤️',
                      onPressed: () async {
                        VibrationService.success();
                        await _cloudService.updateRelationshipDetails(
                          widget.rel.id!,
                          {
                            'hapticPatternType': _selectedPattern,
                            'hapticIntensity': _selectedIntensity,
                          },
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF1F1426),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              content: Row(
                                children: [
                                  const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Signature Touch updated to "$_selectedPattern"! ✨',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatternTile({
    required Map<String, dynamic> pattern,
    required int index,
    required bool isPlusUser,
  }) {
    final isSelected = _selectedPattern == pattern['name'];
    final bool isPlusPattern = pattern['isPlus'] == true;
    final bool isLocked = isPlusPattern && !isPlusUser;

    return FadeInUp(
      delay: Duration(milliseconds: (index * 25).clamp(0, 400)),
      child: GestureDetector(
        onTap: () => _onPatternTap(pattern, isPlusUser),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? (isPlusPattern
                    ? const Color(0xFFFFC75F).withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.12))
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? (isPlusPattern ? const Color(0xFFFFC75F) : AppColors.primary)
                  : Colors.white.withValues(alpha: 0.06),
              width: isSelected ? 1.8 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (isPlusPattern ? const Color(0xFFFFC75F) : AppColors.primary)
                          .withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isPlusPattern ? const Color(0xFFFFC75F) : AppColors.primary)
                      : (isPlusPattern
                          ? const Color(0xFFFFC75F).withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  pattern['icon'],
                  color: isSelected ? Colors.black87 : (isPlusPattern ? const Color(0xFFFFC75F) : Colors.white70),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            pattern['name'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          pattern['cadence'] ?? '',
                          style: TextStyle(
                            color: isPlusPattern && isPlusUser
                                ? const Color(0xFFFFC75F).withValues(alpha: 0.8)
                                : Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      pattern['desc'],
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Play/Lock Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? (isPlusPattern ? const Color(0xFFFFC75F).withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.2))
                      : Colors.white.withValues(alpha: 0.04),
                ),
                child: Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : (isLocked ? Icons.lock_outline_rounded : Icons.play_arrow_rounded),
                  color: isSelected
                      ? (isPlusPattern ? const Color(0xFFFFC75F) : AppColors.primary)
                      : (isLocked ? const Color(0xFFFFC75F).withValues(alpha: 0.6) : Colors.white30),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
