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

class _HapticPreferencesScreenState extends State<HapticPreferencesScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  String? _selectedPattern;

  @override
  void initState() {
    super.initState();
    _selectedPattern = widget.rel.hapticPatternType ?? 'Heartbeat';
  }

  final List<Map<String, dynamic>> _standardPatterns = [
    {
      'name': 'Heartbeat',
      'icon': Icons.favorite_rounded,
      'desc': 'Biological dual-pulse rhythm (Lub-dub).',
      'func': VibrationService.heartbeat,
      'isPlus': false,
    },
    {
      'name': 'Warm Hug',
      'icon': Icons.handshake_rounded,
      'desc': 'A soft, comforting long squeeze.',
      'func': VibrationService.hugVibration,
      'isPlus': false,
    },
    {
      'name': 'Digital Touch',
      'icon': Icons.touch_app_rounded,
      'desc': 'A rapid, triple-tap energy pulse.',
      'func': VibrationService.touchVibration,
      'isPlus': false,
    },
    {
      'name': 'Sparkle',
      'icon': Icons.auto_awesome_rounded,
      'desc': 'A light, shimmering sequence.',
      'func': VibrationService.sparkle,
      'isPlus': false,
    },
    {
      'name': 'Pulse',
      'icon': Icons.sensors_rounded,
      'desc': 'A rhythmic growing vibration.',
      'func': VibrationService.pulse,
      'isPlus': false,
    },
    {
      'name': 'Echo',
      'icon': Icons.hearing_rounded,
      'desc': 'A strong hit with fading ripples.',
      'func': VibrationService.echo,
      'isPlus': false,
    },
    {
      'name': 'Wave',
      'icon': Icons.waves_rounded,
      'desc': 'A smooth, rolling wave sensation.',
      'func': VibrationService.wave,
      'isPlus': false,
    },
  ];

  final List<Map<String, dynamic>> _plusPatterns = [
    {
      'name': 'Soulmate Flutter',
      'icon': Icons.favorite_border_rounded,
      'desc': 'Butterflies in your stomach micro-pulses.',
      'func': VibrationService.soulmateFlutter,
      'isPlus': true,
    },
    {
      'name': 'Cosmic Surge',
      'icon': Icons.electric_bolt_rounded,
      'desc': 'Escalating electrical burst of passion.',
      'func': VibrationService.cosmicSurge,
      'isPlus': true,
    },
    {
      'name': 'Endless Love',
      'icon': Icons.all_inclusive_rounded,
      'desc': 'Hypnotic triple-heartbeat loop.',
      'func': VibrationService.endlessLove,
      'isPlus': true,
    },
    {
      'name': 'Deep Embrace',
      'icon': Icons.favorite_rounded,
      'desc': 'Sustained, deep chest-to-chest squeeze.',
      'func': VibrationService.deepEmbrace,
      'isPlus': true,
    },
    {
      'name': 'Secret Whisper',
      'icon': Icons.spatial_audio_off_rounded,
      'desc': 'Subtle microscopic touch in your hand.',
      'func': VibrationService.secretWhisper,
      'isPlus': true,
    },
  ];

  void _onPatternTap(Map<String, dynamic> pattern) {
    // Always trigger the vibration so users can feel it
    pattern['func']();

    if (pattern['isPlus'] == true && !widget.rel.isPlus) {
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

  Widget _buildPatternTile(Map<String, dynamic> pattern, int index) {
    final isSelected = _selectedPattern == pattern['name'];
    final bool isPlusPattern = pattern['isPlus'] == true;
    final bool isLocked = isPlusPattern && !widget.rel.isPlus;

    return FadeInUp(
      delay: Duration(milliseconds: index * 40),
      child: GestureDetector(
        onTap: () => _onPatternTap(pattern),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? (isPlusPattern
                    ? const Color(0xFFFFB3C6).withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.08))
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? (isPlusPattern ? const Color(0xFFFFC75F) : AppColors.primary)
                  : Colors.white.withValues(alpha: 0.05),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (isPlusPattern ? const Color(0xFFFFC75F) : AppColors.primary)
                          .withValues(alpha: 0.15),
                      blurRadius: 15,
                      spreadRadius: -3,
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
                          ? const Color(0xFFFFC75F).withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  pattern['icon'],
                  color: isSelected ? Colors.black87 : (isPlusPattern ? const Color(0xFFFFC75F) : Colors.white),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            pattern['name'].toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        if (isPlusPattern) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFC75F), Color(0xFFFF5E7E)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'PLUS',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w900,
                                fontSize: 9,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pattern['desc'],
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => pattern['func'](),
                icon: Icon(
                  isSelected
                      ? Icons.play_circle_fill_rounded
                      : (isLocked ? Icons.lock_outline_rounded : Icons.play_arrow_rounded),
                  color: isSelected
                      ? (isPlusPattern ? const Color(0xFFFFC75F) : AppColors.primary)
                      : (isLocked ? const Color(0xFFFFC75F).withValues(alpha: 0.6) : Colors.white30),
                  size: 24,
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F0812),
      body: Stack(
        children: [
          // Ambient Glow
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
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
                    fontSize: 18,
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
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInDown(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.vibration_rounded, color: AppColors.primary, size: 40),
                              const SizedBox(height: 12),
                              Text(
                                'Select your rhythmic identity ✨',
                                style: AppTextStyles.bodyM.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Whenever your partner touches the heart or sends intimacy, this rhythm will vibrate on their phone.',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // NextMeet+ Exclusives
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: Color(0xFFFFC75F), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'NEXTMEET+ EXCLUSIVE RHYTHMS',
                            style: TextStyle(
                              color: const Color(0xFFFFC75F).withValues(alpha: 0.9),
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._plusPatterns.asMap().entries.map((entry) {
                        return _buildPatternTile(entry.value, entry.key);
                      }),

                      const SizedBox(height: 24),

                      // Standard Rhythms
                      Text(
                        'STANDARD RHYTHMS',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._standardPatterns.asMap().entries.map((entry) {
                        return _buildPatternTile(entry.value, entry.key + _plusPatterns.length);
                      }),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // Action Bar
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: PrimaryButton(
                text: 'SET AS SIGNATURE ❤️',
                onPressed: () async {
                  if (_selectedPattern != null) {
                    VibrationService.success();
                    await _cloudService.updateRelationshipDetails(
                      widget.rel.id!,
                      {'hapticPatternType': _selectedPattern},
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.black87,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          content: Text(
                            'Signature Touch set to "$_selectedPattern"! ✨',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
