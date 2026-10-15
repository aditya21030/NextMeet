import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';

class TermsPolicyScreen extends StatelessWidget {
  final String title;
  final String content;

  const TermsPolicyScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: FadeInUp(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Updated: March 2026',
                style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                _getLegalContent(title),
                style: AppTextStyles.bodyM.copyWith(height: 1.6),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'CONTACT US',
                style: AppTextStyles.h3.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'If you have any questions about these ${title}s, please contact us at helpnextmeet@gmail.com',
                style: AppTextStyles.bodyM,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: Text(
                  'Thank you for trusting NextMeet ❤️',
                  style: AppTextStyles.bodyS.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  String _getLegalContent(String title) {
    if (title.toLowerCase().contains('privacy')) {
      return '''
1. DATA COLLECTION
We collect information you provide directly to us, such as when you create an account, sync with a partner, or upload content to your Private Space.

2. SECURE STORAGE
Your private photos, notes, and messages are stored using industry-standard encryption. We prioritize your privacy as a couple above all else.

3. DATA SHARING
NextMeet is designed for two. We do not sell your personal data to third parties. Information is only shared between you and your linked partner.

4. COOKIES & TRACKING
We use minimal tracking to ensure app stability and to improve your user experience.
      ''';
    } else {
      return '''
1. ACCEPTANCE OF TERMS
By using NextMeet, you agree to follow these rules. This is a space for healthy, shared connection between partners.

2. USER CONDUCT
You are responsible for the content you share. NextMeet is intended for private use between consenting partners.

3. PRIVATE SPACE
The Private Space is a digital sanctuary. You are responsible for maintaining the secrecy of your PIN and security credentials.

4. SERVICE UPDATES
We continuously improve NextMeet. We may update features or terms to better serve our community of couples.

5. TERMINATION
You can delete your account and shared relationship at any time. This will permanently remove your shared data from our active servers.
      ''';
    }
  }
}
