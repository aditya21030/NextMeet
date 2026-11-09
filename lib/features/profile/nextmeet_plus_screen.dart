import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/flat_components.dart';
import 'plus_welcome_screen.dart';
import 'manage_subscription_screen.dart';

enum PlusPlanChoice { annual, monthly, lifetime }

/// NextMeet+ Paywall Screen ("One subscription, two hearts covered")
/// Strictly following NextMeet Monetize.md & Design System
class NextMeetPlusScreen extends StatefulWidget {
  final String? relId;
  const NextMeetPlusScreen({super.key, this.relId});

  @override
  State<NextMeetPlusScreen> createState() => _NextMeetPlusScreenState();
}

class _NextMeetPlusScreenState extends State<NextMeetPlusScreen> {
  PlusPlanChoice _selectedPlan = PlusPlanChoice.annual;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _perks = [
    {
      'title': '100% Ad-Free All 20 Games',
      'desc': 'Zero ads between rounds, instant revives & VIP winner badges',
      'icon': Icons.block_rounded,
      'color': AppColors.primary,
      'bg': AppColors.pinkSoft,
    },
    {
      'title': 'Unlimited 4K Vault & Audio',
      'desc': 'No photo caps, original 4K resolution & permanent voice archive',
      'icon': Icons.cloud_done_rounded,
      'color': AppColors.partner,
      'bg': AppColors.partnerSoft,
    },
    {
      'title': 'All 14 Interactive Widgets',
      'desc': 'Airport flight board, live heartbeat, countdowns & AMOLED styles',
      'icon': Icons.widgets_rounded,
      'color': AppColors.mintText,
      'bg': AppColors.mintSoft,
    },
    {
      'title': 'Golden Crowns & Mascot Hats',
      'desc': 'Equip royal crowns, caps, halos & custom colors for both mascots',
      'icon': Icons.celebration_rounded,
      'color': AppColors.butterText,
      'bg': AppColors.butterSoft,
    },
    {
      'title': 'Time Capsule Letters & Wrapped',
      'desc': 'Seal letters until reunion dates + full 6-slide animated year story',
      'icon': Icons.mark_email_unread_rounded,
      'color': AppColors.primary,
      'bg': AppColors.pinkSoft,
    },
    {
      'title': 'Unlimited Trips & Boarding Passes',
      'desc': 'Multiple concurrent trips, shared budget calculator & airport tracker',
      'icon': Icons.flight_takeoff_rounded,
      'color': AppColors.partner,
      'bg': AppColors.partnerSoft,
    },
  ];

  Future<void> _subscribe() async {
    VibrationService.heavy();
    setState(() => _isProcessing = true);

    try {
      final targetRelId = widget.relId ?? CloudRelationshipService().cachedRelationship?.id;
      if (targetRelId != null && targetRelId.isNotEmpty) {
        String planStr;
        DateTime expiry;

        switch (_selectedPlan) {
          case PlusPlanChoice.annual:
            planStr = 'Annual Sanctuary';
            expiry = DateTime.now().add(const Duration(days: 365));
            break;
          case PlusPlanChoice.monthly:
            planStr = 'Monthly Sanctuary';
            expiry = DateTime.now().add(const Duration(days: 30));
            break;
          case PlusPlanChoice.lifetime:
            planStr = 'Lifetime Pass';
            expiry = DateTime.now().add(const Duration(days: 36500)); // 100 years
            break;
        }

        await CloudRelationshipService().activateRealPremium(
          relId: targetRelId,
          planType: planStr,
          renewalDate: expiry,
          transactionId: 'nm_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isProcessing = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PlusWelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Modern Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Row(
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
                      'NextMeet+ Pro',
                      style: AppTextStyles.title2.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      VibrationService.light();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ManageSubscriptionScreen()),
                      );
                    },
                    child: Text(
                      'Manage',
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Scrollable Paywall Body
            Expanded(
              child: SingleChildScrollView(
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 18),
                    // Hero Mascot Crown Header
                    Center(
                      child: Column(
                        children: [
                          const TwoMascotsRow(
                            spacing: 16,
                            leftAccessory: MascotAccessory.crown,
                            rightAccessory: MascotAccessory.crown,
                          ),
                          const SizedBox(height: 14),
                          Text('NextMeet+ For Two', style: AppTextStyles.title1.copyWith(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(
                            'One subscription, both hearts covered.',
                            style: AppTextStyles.body.copyWith(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Golden Couple Rule Banner (Monetize.md Section 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.pinkSoft,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'The Golden Couple Rule 🌟',
                                  style: AppTextStyles.heading.copyWith(fontSize: 13, color: AppColors.primary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Pay once, both hearts unlocked. When you subscribe, your partner gets full NextMeet+ Pro at zero extra charge.',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontSize: 11, height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 3 Pricing Options (Monetize.md Section 4)
                    Row(
                      children: [
                        // Option 1: Monthly Sanctuary
                        _buildPlanCard(
                          choice: PlusPlanChoice.monthly,
                          badge: 'FLEXIBLE',
                          badgeBg: AppColors.card,
                          badgeColor: AppColors.muted,
                          title: 'Monthly',
                          price: '₹49',
                          period: '/ month',
                          subtitle: 'Cancel anytime',
                        ),
                        const SizedBox(width: 8),

                        // Option 2: Annual Sanctuary (BEST VALUE)
                        _buildPlanCard(
                          choice: PlusPlanChoice.annual,
                          badge: 'SAVE 17% 👑',
                          badgeBg: AppColors.primary,
                          badgeColor: Colors.white,
                          title: 'Annual',
                          price: '₹499',
                          period: '/ year',
                          subtitle: 'Just ₹41/mo',
                          isHero: true,
                        ),
                        const SizedBox(width: 8),

                        // Option 3: Lifetime Pass
                        _buildPlanCard(
                          choice: PlusPlanChoice.lifetime,
                          badge: 'LIFETIME ✨',
                          badgeBg: AppColors.butter,
                          badgeColor: AppColors.butterText,
                          title: 'Forever',
                          price: '₹1,499',
                          period: 'one-time',
                          subtitle: 'Never pay again',
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Master VIP Perks List (Monetize.md Section 2)
                    ..._perks.map((perk) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: perk['bg'] as Color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(perk['icon'] as IconData, color: perk['color'] as Color, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(perk['title'] as String, style: AppTextStyles.heading.copyWith(fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(
                                    perk['desc'] as String,
                                    style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    // Primary Subscription Button
                    PrimaryButton(
                      text: _getCtaText(),
                      isLoading: _isProcessing,
                      onPressed: _subscribe,
                    ),

                    const SizedBox(height: 10),
                    Text(
                      'Payment charged via Google Play Store / App Store. Auto-renews unless cancelled 24 hours prior. Covers both partners.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCtaText() {
    switch (_selectedPlan) {
      case PlusPlanChoice.annual:
        return 'Unlock for Both Hearts (₹499/yr) 👑';
      case PlusPlanChoice.monthly:
        return 'Unlock for Both Hearts (₹49/mo) 👑';
      case PlusPlanChoice.lifetime:
        return 'Unlock Lifetime for Both (₹1,499) 💎';
    }
  }

  Widget _buildPlanCard({
    required PlusPlanChoice choice,
    required String badge,
    required Color badgeBg,
    required Color badgeColor,
    required String title,
    required String price,
    required String period,
    required String subtitle,
    bool isHero = false,
  }) {
    final isSelected = _selectedPlan == choice;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          VibrationService.light();
          setState(() => _selectedPlan = choice);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.pinkSoft.withValues(alpha: 0.85) : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2.0 : 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  badge,
                  style: AppTextStyles.label.copyWith(color: badgeColor, fontSize: 8, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 8),
              Text(title, style: AppTextStyles.heading.copyWith(fontSize: 13)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  price,
                  style: AppTextStyles.title1.copyWith(
                    fontSize: 17,
                    color: isSelected ? AppColors.primary : AppColors.ink,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(period, style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.muted)),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
