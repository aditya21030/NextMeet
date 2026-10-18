import 'package:flutter/material.dart';
import '../../core/constants.dart';

class TermsPolicyScreen extends StatelessWidget {
  final String? title;
  final String? content;
  final int initialTab; // 0 for Terms, 1 for Privacy

  const TermsPolicyScreen({
    super.key,
    this.title,
    this.content,
    this.initialTab = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPrivacy = (title?.toLowerCase().contains('privacy') ?? false) || initialTab == 1;
    final String displayTitle = title?.isNotEmpty == true
        ? title!
        : (isPrivacy ? 'Privacy Policy' : 'Terms of Service');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          displayTitle.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: isPrivacy ? _buildPrivacyView() : _buildTermsView(),
    );
  }

  Widget _buildTermsView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetaBadge('Last Updated: October 2026 • Version 1.0.39'),
          const SizedBox(height: 16),
          _buildSection(
            number: '1',
            title: 'Agreement & Core Purpose',
            content:
                'NextMeet is an intimate, private digital application created specifically for couples. By creating an account or pairing with a partner, you enter into a binding agreement with NextMeet. The application is intended solely for personal, non-commercial use between two consenting individuals.',
          ),
          _buildSection(
            number: '2',
            title: 'Couple Pairing & Shared Space',
            content:
                'Each relationship space in NextMeet links exactly two user accounts. Both partners have equal read and write access to shared memories, calendar events, countdowns, and love notes. Either partner may choose to unpair or delete the shared relationship at any time, which permanently purges the shared archive.',
          ),
          _buildSection(
            number: '3',
            title: 'Private Sanctuary & Security',
            content:
                'The Sanctuary is a protected couple vault locked by a 4-digit PIN or local device biometrics (Fingerprint / Face ID). You are exclusively responsible for safeguarding your passcode. NextMeet staff cannot decrypt or recover your Sanctuary contents without your device authentication.',
          ),
          _buildSection(
            number: '4',
            title: 'NextMeet+ Subscriptions & Billing',
            content:
                'NextMeet+ is offered as an auto-renewing subscription (Monthly or Annual). A single subscription upgrades both linked partners. Payments are processed securely via Google Play In-App Billing or Apple App Store. You may manage or cancel your subscription at any time directly through your app store account settings.',
          ),
          _buildSection(
            number: '5',
            title: 'Content Guidelines & Ownership',
            content:
                'You retain full intellectual property ownership of all photos, letters, voice notes, and messages uploaded to NextMeet. You agree not to upload unlawful, non-consensual, infringing, or abusive media. NextMeet reserves the right to terminate accounts that violate safety guidelines.',
          ),
          _buildSection(
            number: '6',
            title: 'Service Continuity & Disclaimers',
            content:
                'While we engineer NextMeet for 99.9% uptime and zero data loss, the service is provided on an "as-is" and "as-available" basis. We recommend keeping independent backups of critical life memories. NextMeet shall not be held liable for indirect or consequential damages.',
          ),
          _buildContactCard(),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildPrivacyView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetaBadge('Last Updated: October 2026 • Strict Couple Privacy Guarantee'),
          const SizedBox(height: 16),
          _buildPledgeCard(),
          const SizedBox(height: 16),
          _buildSection(
            number: '1',
            title: 'Information We Collect',
            content:
                'We collect only the essential data required to provide real-time connection:\n'
                '• Profile Information: Email address, display names, and optional avatars.\n'
                '• Shared Content: Photos, voice whispers, calendar entries, and love letters.\n'
                '• Geolocation (Optional): Live coordinates collected only when both partners grant permission, used strictly to compute distance apart. Location is never logged or sold.',
          ),
          _buildSection(
            number: '2',
            title: 'Zero Data-Selling Commitment',
            content:
                'NextMeet does NOT sell, rent, monetize, or trade your personal data, relationship history, photos, or private communications to any third-party advertisers, brokers, or analytics corporations. Your relationship is private, sacred, and strictly between you and your partner.',
          ),
          _buildSection(
            number: '3',
            title: 'Cloud Storage & Encryption',
            content:
                'All data transmitted between your device and NextMeet is encrypted using Transport Layer Security (TLS 1.3). Photos and vault archives are stored in encrypted cloud storage buckets (Google Cloud Firebase & Supabase) with strict access control rules.',
          ),
          _buildSection(
            number: '4',
            title: 'Device Permissions & Local Privacy',
            content:
                '• Biometrics: Fingerprint and Face Unlock credentials never leave your physical device hardware (Android Keystore / iOS Secure Enclave).\n'
                '• Microphone: Used solely when you record a Secret Voice Whisper.\n'
                '• Photo Library: Used solely when you select a memory or secret photo.',
          ),
          _buildSection(
            number: '5',
            title: 'Data Retention & Complete Erasure (Right to be Forgotten)',
            content:
                'In full accordance with GDPR and CCPA standards, you have the right to permanent deletion. Tapping "Delete Account" or "Unpair Couple" permanently removes all shared media, letters, and database records from our active servers.',
          ),
          _buildContactCard(),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildMetaBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPledgeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The NextMeet Privacy Oath 🛡️',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF15803D)),
                ),
                SizedBox(height: 4),
                Text(
                  'No ads. No data brokers. No public profiles. NextMeet is built from the ground up as a private haven exclusively for two.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF166534), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String number, required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.pink.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: AppTextStyles.bodyM.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.pink.shade50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Official Inquiries & Privacy Contact',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'If you have questions regarding these terms, security practices, or wish to request data export:\nEmail: helpnextmeet@gmail.com',
            style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}
