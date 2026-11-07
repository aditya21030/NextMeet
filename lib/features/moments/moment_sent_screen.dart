import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/flat_components.dart';

/// NextMeet Moment Sent Screen (Widget Mockup & Expiration Selector)
/// Strictly following NextMeet Redesign.pdf (Page 28)
class MomentSentScreen extends StatefulWidget {
  final String caption;
  final String frame;
  final String partnerName;

  const MomentSentScreen({
    super.key,
    required this.caption,
    required this.frame,
    this.partnerName = 'Partner',
  });

  @override
  State<MomentSentScreen> createState() => _MomentSentScreenState();
}

class _MomentSentScreenState extends State<MomentSentScreen> {
  int _selectedDurationIndex = 1; // 0: 1 hour, 1: 24 hours, 2: Until next moment
  final List<String> _durations = ['1 hour', '24 hours', 'Until next moment'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // Celebration Mascot & Header
              Center(
                child: Column(
                  children: [
                    const MascotHeart(color: MascotColor.pink, size: 72),
                    const SizedBox(height: 14),
                    Text(
                      'Sent to ${widget.partnerName}! 🎉',
                      style: AppTextStyles.title1.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "It's now glowing on their home screen widget",
                      style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Phone Widget Mockup (Page 28)
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      // Widget Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 14),
                              const SizedBox(width: 4),
                              Text('NextMeet', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w800, fontSize: 11)),
                            ],
                          ),
                          Text('Just now', style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Widget Photo Area
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.pinkSoft,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border, width: 1),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const MascotHeart(color: MascotColor.pink, size: 48),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    widget.caption,
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Expiration Selector Title (Page 28)
              Text(
                'Show on his widget for:',
                style: AppTextStyles.heading.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 12),

              // Radio Duration Selector List
              ..._durations.asMap().entries.map((entry) {
                final idx = entry.key;
                final duration = entry.value;
                final isSelected = _selectedDurationIndex == idx;

                return GestureDetector(
                  onTap: () {
                    VibrationService.light();
                    setState(() => _selectedDurationIndex = idx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.pinkSoft.withValues(alpha: 0.5) : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          duration,
                          style: AppTextStyles.heading.copyWith(
                            fontSize: 14,
                            color: isSelected ? AppColors.primary : AppColors.ink,
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? AppColors.primary : Colors.white,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(Icons.check_rounded, color: Colors.white, size: 14),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Done Button
              PrimaryButton(
                text: 'Done',
                onPressed: () {
                  VibrationService.light();
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
