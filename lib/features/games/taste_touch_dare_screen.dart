import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';

/// NextMeet Sensory Taste & Touch Dares
/// Playful sensory challenges for date night & video calls.
class TasteTouchDareScreen extends StatefulWidget {
  final String? relId;
  final String? partnerName;
  const TasteTouchDareScreen({super.key, this.relId, this.partnerName});

  @override
  State<TasteTouchDareScreen> createState() => _TasteTouchDareScreenState();
}

class _TasteTouchDareScreenState extends State<TasteTouchDareScreen> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _dares = [
    {
      'title': 'The Blindfolded Flavor Mystery',
      'category': 'Taste 🍫',
      'emoji': '🙈',
      'desc': 'Blindfold yourself or close your eyes. Your partner chooses a piece of fruit, chocolate, or sweet from your kitchen. Guess the exact flavor!',
      'tip': 'No peeking! Pay attention to texture and scent first.',
    },
    {
      'title': 'Ice & Fire Pulse',
      'category': 'Temperature ❄️',
      'emoji': '🧊',
      'desc': 'Take an ice cube or a warm mug and trace along your partner\'s wrist or collarbone over video call while they describe the sensation.',
      'tip': 'Breathe slowly and sync your heartbeats.',
    },
    {
      'title': 'Fingerprint Whisper Maze',
      'category': 'Touch 🖐️',
      'emoji': '✨',
      'desc': 'Draw a mystery letter or romantic symbol on your partner\'s back or forearm with your fingertip. Can they guess what you wrote?',
      'tip': 'Start with a simple heart or the first letter of their name.',
    },
    {
      'title': 'The 10-Second Distance Stare',
      'category': 'Gaze 👁️',
      'emoji': '👀',
      'desc': 'Look directly into each other\'s eyes on camera for 30 seconds without saying a single word or breaking eye contact. First to giggle loses!',
      'tip': 'Notice the color of their eyes under the light.',
    },
  ];

  void _nextDare() {
    VibrationService.success();
    if (widget.relId != null) {
      CloudRelationshipService().addCoupleXp(widget.relId!, 40);
    }
    setState(() {
      _currentIndex = (_currentIndex + 1) % _dares.length;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Completed sensory challenge! +40 XP ✨'), duration: Duration(milliseconds: 1000)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dare = _dares[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: const Icon(Icons.close_rounded, size: 20, color: AppColors.ink),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Sensory Dares',
                      style: AppTextStyles.title2.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.pinkSoft,
                      borderRadius: BorderRadius.circular(AppRadius.badge),
                    ),
                    child: Text(
                      '${_currentIndex + 1}/${_dares.length}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Dare Card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.hero),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(dare['emoji'] as String, style: const TextStyle(fontSize: 54)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.partnerSoft,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        dare['category'] as String,
                        style: AppTextStyles.caption.copyWith(color: AppColors.partnerText, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      dare['title'] as String,
                      style: AppTextStyles.title1.copyWith(fontSize: 22),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      dare['desc'] as String,
                      style: AppTextStyles.body.copyWith(color: AppColors.ink, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.butterSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.butterText),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dare['tip'] as String,
                              style: AppTextStyles.caption.copyWith(color: AppColors.butterText, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              PrimaryButton(
                text: 'Challenge Completed! 🎉',
                onPressed: _nextDare,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
