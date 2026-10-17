import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';

class LetterDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  final String date;
  final String sender;

  const LetterDetailScreen({
    super.key,
    required this.title,
    required this.content,
    required this.date,
    required this.sender,
  });

  void _shareLetter() {
    VibrationService.light();
    final message = '$title\n\n$content\n\n— Always yours, $sender ($date)\n\nSent via NextMeet ❤️';
    Share.share(message, subject: title);
  }

  void _copyLetter(BuildContext context) {
    VibrationService.success();
    final message = '$title\n\n$content\n\n— Always yours, $sender';
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Love letter copied to clipboard! 📜✨'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F8), // Soft parchment color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: () => _copyLetter(context),
            icon: const Icon(Icons.copy_rounded, color: AppColors.textPrimary, size: 20),
            tooltip: 'Copy Letter',
          ),
          IconButton(
            onPressed: _shareLetter,
            icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary, size: 20),
            tooltip: 'Share Letter',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: AppTextStyles.h1.copyWith(
                      fontSize: 32,
                      fontFamily: 'serif', // Use a more classic font if available
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.l),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.l),
                ),
                child: Text(
                  content,
                  style: AppTextStyles.bodyM.copyWith(
                    fontSize: 18,
                    height: 1.8,
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Always yours,', style: AppTextStyles.bodyM),
                  const SizedBox(height: 8),
                  Text(
                    sender,
                    style: AppTextStyles.h2.copyWith(
                       fontFamily: 'serif',
                       color: AppColors.primary,
                       fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Center(
              child: FadeIn(
                delay: const Duration(milliseconds: 500),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'SEALED IN SANCTUARY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: AppColors.primary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
