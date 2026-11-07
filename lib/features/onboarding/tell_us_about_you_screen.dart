import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import 'your_story_screen.dart';

/// Step 1 / 3: Tell Us About You
/// Strictly following NextMeet Redesign.pdf (Page 6)
class TellUsAboutYouScreen extends StatefulWidget {
  final String? initialName;
  final String? initialInviteCode;

  const TellUsAboutYouScreen({
    super.key,
    this.initialName,
    this.initialInviteCode,
  });

  @override
  State<TellUsAboutYouScreen> createState() => _TellUsAboutYouScreenState();
}

class _TellUsAboutYouScreenState extends State<TellUsAboutYouScreen> {
  MascotColor _selectedColor = MascotColor.pink;
  late TextEditingController _nameController;
  final _nicknameController = TextEditingController();
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  bool _autoDetectTimezone = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_nameController.text.trim().isEmpty) {
      VibrationService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    VibrationService.light();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YourStoryScreen(
          userName: _nameController.text.trim(),
          nickname: _nicknameController.text.trim(),
          mascotColor: _selectedColor,
          initialInviteCode: widget.initialInviteCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // Pink background header
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Step Indicator (1 / 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  // Progress line & Step label
                  Row(
                    children: [
                      Container(width: 48, height: 4, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 6),
                      Container(width: 48, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 6),
                      Container(width: 48, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                    ],
                  ),
                  Text(
                    '1 / 3',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            // Header Titles
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tell us about you',
                      style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 30),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pick your heart and say hello.',
                      style: AppTextStyles.body.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
            ),

            // Form Sheet
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mascot Heart Selector Card (Page 6)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            // Big Selected Heart Preview
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: AppColors.pinkSoft.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.center,
                              child: MascotHeart(
                                color: _selectedColor,
                                size: 84,
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Color Option Swatches
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pick your heart',
                                    style: AppTextStyles.label.copyWith(color: AppColors.ink),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _colorSwatch(MascotColor.pink),
                                      const SizedBox(width: 12),
                                      _colorSwatch(MascotColor.violet),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _colorSwatch(MascotColor.butter),
                                      const SizedBox(width: 12),
                                      _colorSwatch(MascotColor.mint),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Name Field
                      Text('Your name', style: AppTextStyles.label.copyWith(color: AppColors.ink)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: AppTextStyles.body,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Alex',
                          prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 22),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Nickname (optional)
                      Text('Nickname (optional)', style: AppTextStyles.label.copyWith(color: AppColors.ink)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nicknameController,
                        style: AppTextStyles.body,
                        decoration: const InputDecoration(
                          hintText: 'What your partner calls you',
                          prefixIcon: Icon(Icons.favorite_outline_rounded, color: AppColors.primary, size: 20),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Birthday Section (DD / MM / YYYY)
                      Text('Birthday', style: AppTextStyles.label.copyWith(color: AppColors.ink)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _dayController,
                              keyboardType: TextInputType.number,
                              maxLength: 2,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.title2,
                              decoration: const InputDecoration(
                                hintText: 'DD',
                                counterText: '',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _monthController,
                              keyboardType: TextInputType.number,
                              maxLength: 2,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.title2,
                              decoration: const InputDecoration(
                                hintText: 'MM',
                                counterText: '',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _yearController,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.title2,
                              decoration: const InputDecoration(
                                hintText: 'YYYY',
                                counterText: '',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Timezone Auto-detect Toggle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: AppColors.pinkSoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Time zone', style: AppTextStyles.heading.copyWith(fontSize: 15)),
                                  Text('Auto-detected', style: AppTextStyles.caption),
                                ],
                              ),
                            ),
                            Switch(
                              value: _autoDetectTimezone,
                              activeColor: AppColors.primary,
                              onChanged: (val) => setState(() => _autoDetectTimezone = val),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Continue CTA
                      PrimaryButton(
                        text: 'Continue',
                        onPressed: _handleContinue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorSwatch(MascotColor color) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () {
        VibrationService.light();
        setState(() => _selectedColor = color);
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2.5,
          ),
        ),
        alignment: Alignment.center,
        child: MascotHeart(
          color: color,
          size: 32,
        ),
      ),
    );
  }
}
