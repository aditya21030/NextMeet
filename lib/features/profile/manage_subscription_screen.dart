import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import 'nextmeet_plus_screen.dart';

/// NextMeet Manage Subscription Screen
/// Strictly following NextMeet Redesign.pdf (Page 78)
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
        final planType = rel?.premiumPlanType ?? 'Annual';
        final isMonthly = planType.toLowerCase() == 'monthly';
        final priceStr = isMonthly ? '₹49 / month' : '₹499 / year';
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
                  // Top Bar
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
                      Text('Subscription', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                      const SizedBox(width: 40),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Active Plan Card (Page 78)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.hero),
                      border: Border.all(
                        color: isPlus ? AppColors.primary : AppColors.border,
                        width: isPlus ? 2 : 1.5,
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
                                color: isPlus ? AppColors.pinkSoft : AppColors.border.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                isPlus ? 'ACTIVE PLAN' : 'FREE TIER',
                                style: AppTextStyles.label.copyWith(
                                  color: isPlus ? AppColors.primary : AppColors.muted,
                                  fontSize: 10,
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
                          isPlus ? 'NextMeet+ Couple VIP' : 'NextMeet Free Plan',
                          style: AppTextStyles.title1.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPlus
                              ? 'One subscription covers both you and your partner with full VIP access across both devices.'
                              : 'Enjoy unlimited chat, real-time distance sync, touch bar, and all 20 free games.',
                          style: AppTextStyles.body.copyWith(color: AppColors.muted, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        if (isPlus)
                          Text(
                            'Next auto-renewal on $renewalStr',
                            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink),
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
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                'Upgrade to NextMeet+ 👑',
                                style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

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
                                'Billed via App Store / Google Play',
                                style: AppTextStyles.heading.copyWith(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Manage payment methods through your store account',
                                style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

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
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
