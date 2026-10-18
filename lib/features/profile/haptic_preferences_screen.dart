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
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
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
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars_rounded, color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                'Unlock "$patternName"',
                style: AppTextStyles.h2.copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'NextMeet+ includes 16 exclusive heartbeat rhythms and custom tactile sensations shared across both phones.',
                style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                text: 'Upgrade with NextMeet+ ❤️',
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
              const SizedBox(height: AppSpacing.m),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Maybe Later',
                  style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
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
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Touch & Vibration Rhythms',
              style: AppTextStyles.h3.copyWith(fontSize: 16),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tactile Preview Stage Card
                      FadeInDown(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.xxl),
                            border: Border.all(color: AppColors.divider),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Heart Pulse Button
                              GestureDetector(
                                onTap: () => _playAndAnimate(currentPatternObj),
                                child: AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _isPlaying ? _pulseAnimation.value : 1.0,
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primary,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary.withValues(alpha: _isPlaying ? 0.45 : 0.2),
                                              blurRadius: _isPlaying ? 24 : 12,
                                              spreadRadius: _isPlaying ? 3 : 0,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          _isPlaying ? Icons.vibration_rounded : (currentPatternObj['icon'] as IconData),
                                          color: Colors.white,
                                          size: 36,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpacing.m),
                              Text(
                                _selectedPattern,
                                style: AppTextStyles.h2.copyWith(fontSize: 18),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  currentPatternObj['cadence'] ?? 'Dual Pulse • 400ms',
                                  style: AppTextStyles.bodyS.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap heart to feel vibration',
                                style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 11),
                              ),

                              const Divider(height: 28, color: AppColors.divider),

                              // Intensity Selector
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'VIBRATION INTENSITY',
                                    style: AppTextStyles.bodyS.copyWith(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    _selectedIntensity,
                                    style: AppTextStyles.bodyS.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
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
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isSel
                                              ? AppColors.primary.withValues(alpha: 0.1)
                                              : AppColors.background,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSel ? AppColors.primary : AppColors.divider,
                                            width: isSel ? 1.5 : 1,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          intensity,
                                          style: TextStyle(
                                            color: isSel ? AppColors.primary : AppColors.textSecondary,
                                            fontSize: 12,
                                            fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // PRO RHYTHMS
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            isPlusUser ? 'NEXTMEET+ RHYTHMIC SUITE (UNLOCKED)' : 'NEXTMEET+ RHYTHMIC SUITE',
                            style: AppTextStyles.bodyM.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      ..._plusPatterns.asMap().entries.map((entry) {
                        return _buildPatternTile(
                          pattern: entry.value,
                          index: entry.key,
                          isPlusUser: isPlusUser,
                        );
                      }),

                      const SizedBox(height: AppSpacing.l),

                      // CLASSIC RHYTHMS
                      Text(
                        'CLASSIC RHYTHMS',
                        style: AppTextStyles.bodyM.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      ..._standardPatterns.asMap().entries.map((entry) {
                        return _buildPatternTile(
                          pattern: entry.value,
                          index: entry.key + _plusPatterns.length,
                          isPlusUser: isPlusUser,
                        );
                      }),

                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),

              // Bottom Save Bar
              Container(
                padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.l),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.divider.withValues(alpha: 0.8))),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: PrimaryButton(
                    text: 'Save Vibration Rhythm ❤️',
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
                            backgroundColor: AppColors.textPrimary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            content: Row(
                              children: [
                                const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Vibration rhythm updated to "$_selectedPattern"!',
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.divider,
          width: isSelected ? 1.8 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.l),
          onTap: () => _onPatternTap(pattern, isPlusUser),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    pattern['icon'] as IconData,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            pattern['name'],
                            style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (isPlusPattern) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '+',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pattern['cadence'],
                        style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (isLocked)
                  const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textSecondary)
                else if (isSelected)
                  const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.primary)
                else
                  IconButton(
                    icon: const Icon(Icons.play_circle_outline_rounded, size: 22, color: AppColors.textSecondary),
                    onPressed: () => _playAndAnimate(pattern),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
