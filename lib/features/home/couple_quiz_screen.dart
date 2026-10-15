import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/primary_button.dart';

class CoupleQuizScreen extends StatefulWidget {
  const CoupleQuizScreen({super.key});

  @override
  State<CoupleQuizScreen> createState() => _CoupleQuizScreenState();
}

class _CoupleQuizScreenState extends State<CoupleQuizScreen> {
  final TextEditingController _answerController = TextEditingController();
  bool _hasAnswered = false;

  final String _question = "If we could teleport anywhere in the world right now for just 1 hour, where would you want to go?";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF), // Very soft blue
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
        ),
        title: Text('Daily Discovery 🧩', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: 20),
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'QUESTION OF THE DAY', 
                  style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeInDown(
              delay: const Duration(milliseconds: 200),
              child: Text(
                _question,
                style: AppTextStyles.h2.copyWith(fontSize: 26, height: 1.3),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 48),
            
            if (!_hasAnswered)
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Column(
                  children: [
                    TextField(
                      controller: _answerController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Type your answer here...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          borderSide: BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          borderSide: BorderSide(color: AppColors.accent, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: 'REVEAL PARTNER\'S ANSWER',
                      onPressed: () {
                        if (_answerController.text.isNotEmpty) {
                          VibrationService.success();
                          setState(() => _hasAnswered = true);
                        }
                      },
                    ),
                  ],
                ),
              )
            else
              FadeInUp(
                child: Column(
                  children: [
                    _buildAnswerBubble('Your Answer', _answerController.text, true),
                    const SizedBox(height: 24),
                    _buildAnswerBubble('Partner\'s Answer', 'I\'d definitely pick a secret beach in Bali where we can watch the sunset together! 🌊☀️', false),
                    const SizedBox(height: 48),
                    Text('GREAT CONNECTING! ✨', style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.textSecondary)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerBubble(String label, String text, bool isMine) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodyS.copyWith(color: isMine ? AppColors.accent : AppColors.primary, fontWeight: FontWeight.w900, fontSize: 10)),
          const SizedBox(height: 12),
          Text(text, style: AppTextStyles.bodyM.copyWith(fontSize: 16, height: 1.5, color: Colors.black87)),
        ],
      ),
    );
  }
}
