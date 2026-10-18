import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/relationship_model.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/primary_button.dart';
import 'terms_policy_screen.dart';
import 'haptic_preferences_screen.dart';

class NextMeetPlusScreen extends StatefulWidget {
  final String relId;
  const NextMeetPlusScreen({super.key, required this.relId});

  @override
  State<NextMeetPlusScreen> createState() => _NextMeetPlusScreenState();
}

class _NextMeetPlusScreenState extends State<NextMeetPlusScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final SubscriptionService _subService = SubscriptionService();
  bool isYearly = true;

  @override
  void initState() {
    super.initState();
    _subService.initialize(widget.relId);
    _subService.addListener(_onSubServiceUpdate);
  }

  @override
  void dispose() {
    _subService.removeListener(_onSubServiceUpdate);
    _subService.dispose();
    super.dispose();
  }

  void _onSubServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _openPlayStoreSubscriptions() async {
    final Uri uri = Uri.parse('https://play.google.com/store/account/subscriptions');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _handleUpgrade() async {
    final success = await _subService.buyProduct(isYearly);
    if (!mounted) return;
    if (success) {
      VibrationService.success();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to NextMeet Pro! Both of your spaces are upgraded ❤️'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (_subService.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_subService.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary, size: 22),
          onPressed: () {
            VibrationService.light();
            Navigator.pop(context);
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              'NEXTMEET PRO',
              style: AppTextStyles.h3.copyWith(
                fontSize: 14,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<RelationshipModel?>(
            stream: _cloudService.streamRelationship(),
            builder: (context, snapshot) {
              final isPlus = snapshot.data?.isPlus ?? false;
              if (isPlus) return const SizedBox.shrink();

              return TextButton(
                onPressed: _subService.isLoading
                    ? null
                    : () async {
                        VibrationService.light();
                        final success = await _subService.restorePurchases();
                        if (!context.mounted) return;
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Purchases restored successfully! NextMeet Pro is active.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_subService.error ?? 'No active subscription found for this account.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                child: const Text(
                  'Restore',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<RelationshipModel?>(
        stream: _cloudService.streamRelationship(),
        builder: (context, snapshot) {
          final rel = snapshot.data;
          final bool isPlus = rel?.isPlus ?? false;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Active Pro Dashboard (if already subscribed)
                      if (isPlus && rel != null) ...[
                        _buildSubscriptionDashboard(rel, context),
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      // Hero Section (Clean & Native)
                      if (!isPlus) ...[
                        FadeInDown(
                          duration: const Duration(milliseconds: 350),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'One Upgrade. Both Partners.',
                                style: AppTextStyles.h1.copyWith(fontSize: 24),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '1 single subscription covers both phones permanently.\nEverything shared is private and encrypted.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyM.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Clean Plan Selector (Annual vs Monthly)
                        FadeInUp(
                          duration: const Duration(milliseconds: 350),
                          child: _buildPricingSelector(),
                        ),

                        if (_subService.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _subService.error!,
                              style: const TextStyle(color: AppColors.error, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        const SizedBox(height: AppSpacing.xl),
                      ],

                      // Perks List Card
                      FadeInUp(
                        delay: const Duration(milliseconds: 150),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.l),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.xxl),
                            border: Border.all(color: AppColors.divider),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.stars_rounded, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    isPlus ? 'YOUR PRO FEATURES' : 'INCLUDED IN PRO',
                                    style: AppTextStyles.bodyM.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, color: AppColors.divider),
                              _buildPerkItem(
                                icon: Icons.favorite_border_rounded,
                                title: 'Both Partners Included',
                                subtitle: 'Only one partner subscribes. Both phones automatically get full Pro access.',
                              ),
                              _buildPerkItem(
                                icon: Icons.vibration_rounded,
                                title: '16 Pro-Haptic Rhythms',
                                subtitle: 'Feel each other\'s heartbeat with exclusive intimate tactile vibration rhythms.',
                              ),
                              _buildPerkItem(
                                icon: Icons.photo_library_rounded,
                                title: 'Unlimited HD Memories',
                                subtitle: 'Store and preserve your full couple timeline in original full resolution.',
                              ),
                              _buildPerkItem(
                                icon: Icons.mic_rounded,
                                title: 'Encrypted Voice Whispers',
                                subtitle: 'Record and replay intimate voice notes safely locked in your Private Space.',
                              ),
                              _buildPerkItem(
                                icon: Icons.hourglass_top_rounded,
                                title: 'Couple Time Capsules',
                                subtitle: 'Lock surprise love letters and photos that unlock on future anniversary dates.',
                              ),
                              _buildPerkItem(
                                icon: Icons.lock_outline_rounded,
                                title: '150 MB Private Space Cloud Vault',
                                subtitle: 'Extended encrypted storage for your intimate notes and shared media.',
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),

              // Bottom Sticky Action (Only shown when not subscribed)
              if (!isPlus) _buildBottomBar(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPricingSelector() {
    final yearlyPrice = _subService.getPriceById(SubscriptionService.yearlyId);
    final monthlyPrice = _subService.getPriceById(SubscriptionService.monthlyId);

    // Compute monthly equivalent
    String monthlyEquivalent = '₹41 / mo';
    try {
      final digits = RegExp(r'\d+').allMatches(yearlyPrice).map((m) => m.group(0)).join();
      if (digits.isNotEmpty) {
        final val = double.tryParse(digits);
        if (val != null) {
          final perMo = (val / 12).round();
          monthlyEquivalent = '₹$perMo / mo';
        }
      }
    } catch (_) {}

    return Column(
      children: [
        // Annual Plan Card (Featured)
        _buildPlanOption(
          title: 'Annual Plan',
          badge: 'BEST VALUE • SAVE 50%',
          price: yearlyPrice,
          subPrice: '$monthlyEquivalent • Billed annually',
          isSelected: isYearly,
          onTap: () {
            VibrationService.light();
            setState(() => isYearly = true);
          },
        ),
        const SizedBox(height: 12),
        // Monthly Plan Card
        _buildPlanOption(
          title: 'Monthly Plan',
          badge: 'FLEXIBLE',
          price: monthlyPrice,
          subPrice: 'Billed monthly • Cancel anytime',
          isSelected: !isYearly,
          onTap: () {
            VibrationService.light();
            setState(() => isYearly = false);
          },
        ),
      ],
    );
  }

  Widget _buildPlanOption({
    required String title,
    required String badge,
    required String price,
    required String subPrice,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Radio circle
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.m),
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.divider,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subPrice,
                    style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            // Price
            Text(
              price,
              style: AppTextStyles.bodyL.copyWith(
                fontWeight: FontWeight.w900,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerkItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final activePrice = isYearly
        ? _subService.getPriceById(SubscriptionService.yearlyId)
        : _subService.getPriceById(SubscriptionService.monthlyId);

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider.withValues(alpha: 0.8))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              text: isYearly ? 'Upgrade for Both ($activePrice/yr) ❤️' : 'Upgrade for Both ($activePrice/mo) ❤️',
              isLoading: _subService.isLoading,
              onPressed: _handleUpgrade,
            ),
            const SizedBox(height: 8),
            Text(
              '1 purchase covers both partners • Cancel anytime in Google Play',
              style: AppTextStyles.bodyS.copyWith(fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    VibrationService.light();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsPolicyScreen(title: 'Terms of Service', initialTab: 0),
                      ),
                    );
                  },
                  child: Text(
                    'Terms of Service',
                    style: AppTextStyles.bodyS.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text('  •  ', style: AppTextStyles.bodyS.copyWith(fontSize: 11, color: AppColors.textSecondary)),
                GestureDetector(
                  onTap: () {
                    VibrationService.light();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsPolicyScreen(title: 'Privacy Policy', initialTab: 1),
                      ),
                    );
                  },
                  child: Text(
                    'Privacy Policy',
                    style: AppTextStyles.bodyS.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionDashboard(RelationshipModel rel, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.06),
            blurRadius: 16,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEXTMEET PRO ACTIVE',
                      style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    Text(
                      'Both phones are upgraded and connected',
                      style: AppTextStyles.bodyS.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.divider, height: 24),
          _buildDashboardStat('Plan', rel.premiumPlanType ?? 'NextMeet Pro Annual'),
          const SizedBox(height: 8),
          _buildDashboardStat(
            'Renewal Date',
            rel.premiumRenewalDate != null
                ? DateFormat('MMMM dd, yyyy').format(rel.premiumRenewalDate!)
                : 'Active (Auto-Renewing)',
          ),
          const Divider(color: AppColors.divider, height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    VibrationService.light();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HapticPreferencesScreen(rel: rel),
                      ),
                    );
                  },
                  icon: const Icon(Icons.vibration_rounded, color: AppColors.primary, size: 16),
                  label: const Text(
                    'Touch Rhythms',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openPlayStoreSubscriptions,
                  icon: const Icon(Icons.open_in_new_rounded, color: AppColors.textSecondary, size: 16),
                  label: const Text(
                    'Manage Plan',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardStat(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}
