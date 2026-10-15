import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/glass_card.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
        title: Text('Help & Support', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          children: [
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 64),
              ),
            ),
            const SizedBox(height: 24),
            FadeInDown(
              delay: const Duration(milliseconds: 100),
              child: Text(
                'How can we help you?',
                style: AppTextStyles.h2.copyWith(fontSize: 24),
              ),
            ),
            _buildSupportOption(
              context,
              icon: Icons.mail_outline_rounded,
              title: 'Email Support',
              subtitle: 'helpnextmeet@gmail.com',
              onTap: () => VibrationService.light(),
            ),
            const SizedBox(height: AppSpacing.xxl),

            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'FREQUENTLY ASKED QUESTIONS',
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 1.5, 
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),

            _buildFAQItem('How do I update my partner nickname?', 'You can update your partner\'s nickname directly from the Profile screen under the "Save Couple Info" section.'),
            _buildFAQItem('Where do I find my sync code?', 'Your sync code was assigned when you created your account. You can find it on the Join Partner screen if they haven\'t connected yet.'),
            _buildFAQItem('How does the Private Space work?', 'The private space is a secured area where your photos are stored with a 20MB limit (150MB for NextMeet+ users).'),
            
            const SizedBox(height: AppSpacing.xxl),
            
            FadeInUp(
              delay: const Duration(milliseconds: 400),

              child: const Column(
                children: [
                  Text(
                    'Version 1.0.9 (Hardened)',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Built with ❤️ in India',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOption(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return FadeInUp(
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: AppSpacing.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.divider, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.m),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Theme(
          data: ThemeData().copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            iconColor: AppColors.primary,
            collapsedIconColor: AppColors.textSecondary,
            title: Text(
              question,
              style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Text(
                  answer,
                  style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

