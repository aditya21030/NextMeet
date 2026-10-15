import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';
import '../../widgets/primary_button.dart';

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

  final List<Map<String, dynamic>> _patterns = [
    {'name': 'Heartbeat', 'icon': Icons.favorite_rounded, 'desc': 'A dual-pulse rhythmic beat.', 'func': VibrationService.heartbeat},
    {'name': 'Warm Hug', 'icon': Icons.handshake_rounded, 'desc': 'A soft, comforting long squeeze.', 'func': VibrationService.hugVibration},
    {'name': 'Digital Touch', 'icon': Icons.touch_app_rounded, 'desc': 'A rapid, triple-tap energy pulse.', 'func': VibrationService.touchVibration},
    {'name': 'Sparkle', 'icon': Icons.auto_awesome_rounded, 'desc': 'A light, shimmering sequence.', 'func': VibrationService.sparkle},
    {'name': 'Pulse', 'icon': Icons.sensors_rounded, 'desc': 'A rhythmic growing vibration.', 'func': VibrationService.pulse},
    {'name': 'Echo', 'icon': Icons.hearing_rounded, 'desc': 'A strong hit with fading ripples.', 'func': VibrationService.echo},
    {'name': 'Wave', 'icon': Icons.waves_rounded, 'desc': 'A smooth, rolling wave sensation.', 'func': VibrationService.wave},
  ];

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
                  style: AppTextStyles.h1.copyWith(fontSize: 18, color: Colors.white, letterSpacing: 1.5, fontWeight: FontWeight.w900),
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
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _patterns.length,
                        itemBuilder: (context, index) {
                          final pattern = _patterns[index];
                          final isSelected = _selectedPattern == pattern['name'];

                          return FadeInUp(
                            delay: Duration(milliseconds: index * 50),
                            child: GestureDetector(
                              onTap: () {
                                pattern['func']();
                                setState(() => _selectedPattern = pattern['name']);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected ? [
                                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 15, spreadRadius: -5)
                                  ] : [],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(pattern['icon'], color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pattern['name'].toUpperCase(),
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : Colors.white60, 
                                              fontWeight: FontWeight.w900, 
                                              fontSize: 13, 
                                              letterSpacing: 1
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            pattern['desc'],
                                            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected) 
                                      IconButton(
                                        onPressed: () => pattern['func'](),
                                        icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 28),
                                      )
                                    else if (widget.rel.isPlus)
                                      IconButton(
                                        onPressed: () => pattern['func'](),
                                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white24),
                                      )
                                    else
                                      const Icon(Icons.verified_rounded, color: AppColors.primary, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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
                    await _cloudService.updateRelationshipDetails(widget.rel.id!, {'hapticPatternType': _selectedPattern});
                    if (mounted) {
      // ignore: use_build_context_synchronously
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.black87,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          content: Text('Signature Touch Activated! ✨', style: const TextStyle(fontWeight: FontWeight.bold)),
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
