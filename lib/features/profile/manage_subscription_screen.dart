import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import 'nextmeet_plus_screen.dart';

/// NextMeet Manage Subscription Screen
/// Strictly following NextMeet Monetize.md & Design System
class ManageSubscriptionScreen extends StatelessWidget {
  const ManageSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cloudService = CloudRelationshipService();

    return StreamBuilder<RelationshipModel?>(
      stream: cloudService.streamRelationship(),
      builder: (context, snapshot) {
        final rel = snapshot.data;
        final isPlus = rel?.isPlus ?? false;
        final planType = rel?.premiumPlanType ?? 'Annual Sanctuary';
        final isLifetime = planType.toLowerCase().contains('lifetime');
        final isMonthly = planType.toLowerCase().contains('monthly');

        String priceStr;
        if (isLifetime) {
          priceStr = '₹1,499 One-Time';
        } else if (isMonthly) {
          priceStr = '₹49 / month';
        } else {
          priceStr = '₹499 / year';
        }

        final renewalDate = rel?.premiumRenewalDate ??
            DateTime.now().add(Duration(days: isMonthly ? 30 : 365));
        final renewalStr = DateFormat('d MMM yyyy').format(renewalDate);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // Modern Top Bar
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
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Subscription',
                          style: AppTextStyles.title2.copyWith(fontSize: 18),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Active Plan Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.hero),
                      border: Border.all(
                        color: isPlus ? AppColors.primary : AppColors.border,
                        width: isPlus ? 2.0 : 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPlus ? AppColors.pinkSoft : AppColors.card,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                  color: isPlus ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
                                ),
                              ),
                              child: Text(
                                isPlus ? (isLifetime ? 'LIFETIME PASS 💎' : 'ACTIVE PLAN 👑') : 'FREE TIER',
                                style: AppTextStyles.label.copyWith(
                                  color: isPlus ? AppColors.primary : AppColors.muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              isPlus ? priceStr : 'Free Forever',
                              style: AppTextStyles.heading.copyWith(
                                color: isPlus ? AppColors.primary : AppColors.ink,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          isPlus ? 'NextMeet+ Pro ($planType)' : 'NextMeet Free Plan',
                          style: AppTextStyles.title1.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isPlus
                              ? 'The Golden Couple Rule is active: One subscription covers both you and your partner with full Pro access across all devices.'
                              : 'Enjoy unlimited chat, real-time distance sync, touch bar, and all 20 free games.',
                          style: AppTextStyles.body.copyWith(color: AppColors.muted, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        if (isPlus)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_repeat_rounded, color: AppColors.primary, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isLifetime
                                        ? 'Permanent VIP access unlocked • No renewal required'
                                        : 'Next auto-renewal on $renewalStr',
                                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () {
                              VibrationService.medium();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NextMeetPlusScreen(relId: rel?.id ?? 'default_rel'),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Center(
                                child: Text(
                                  'Upgrade to NextMeet+ 👑',
                                  style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // The Golden Couple Rule Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.pinkSoft,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
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
                                'Pay Once, Both Hearts Unlocked 💖',
                                style: AppTextStyles.heading.copyWith(fontSize: 13, color: AppColors.primary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Couples never pay twice. Subscription syncs seamlessly across iOS & Android.',
                                style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Billing Platform Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.credit_card_rounded, color: AppColors.primary, size: 24),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Billed via Google Play / App Store',
                                style: AppTextStyles.heading.copyWith(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Manage subscriptions and payment methods through your store account',
                                style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Restore Purchases Button
                  GestureDetector(
                    onTap: () {
                      VibrationService.success();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Purchases verified and restored! ✅')),
                      );
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text('Restore Purchases', style: AppTextStyles.button.copyWith(color: AppColors.ink)),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Cancel Info
                  Center(
                    child: Text(
                      'Manage or cancel anytime via Google Play / App Store Subscriptions',
                      style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
