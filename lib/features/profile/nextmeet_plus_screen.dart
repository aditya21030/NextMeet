import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/flat_components.dart';
import 'plus_welcome_screen.dart';
import 'manage_subscription_screen.dart';

/// NextMeet+ Paywall Screen ("One subscription, two hearts covered")
/// Strictly following NextMeet Redesign.pdf (Page 76)
class NextMeetPlusScreen extends StatefulWidget {
  final String? relId;
  const NextMeetPlusScreen({super.key, this.relId});

  @override
  State<NextMeetPlusScreen> createState() => _NextMeetPlusScreenState();
}

class _NextMeetPlusScreenState extends State<NextMeetPlusScreen> {
  bool _isYearly = true; // Yearly: ₹499/yr, Monthly: ₹49/mo
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _perks = [
    {
      'title': 'Unlimited Sanctum Vault',
      'desc': 'Zero photo storage caps with end-to-end PIN encryption',
      'icon': Icons.lock_rounded,
      'color': AppColors.primary,
      'bg': AppColors.pinkSoft,
    },
    {
      'title': 'Voice Whispers Archive',
      'desc': 'Listen back to every sweet whisper anytime without expiration',
      'icon': Icons.mic_rounded,
      'color': AppColors.partner,
      'bg': AppColors.partnerSoft,
    },
    {
      'title': 'Golden Crowns & Hats',
      'desc': 'Equip royal accessories to both your mascot hearts',
      'icon': Icons.celebration_rounded,
      'color': AppColors.butterText,
      'bg': AppColors.butterSoft,
    },
    {
      'title': 'NextMeet Wrapped 2026',
      'desc': 'Personalized 6-slide story recap of your year together',
      'icon': Icons.auto_stories_rounded,
      'color': AppColors.mintText,
      'bg': AppColors.mintSoft,
    },
  ];

  Future<void> _subscribe() async {
    VibrationService.heavy();
    setState(() => _isProcessing = true);

    try {
      final targetRelId = widget.relId ?? CloudRelationshipService().cachedRelationship?.id;
      if (targetRelId != null && targetRelId.isNotEmpty) {
        final plan = _isYearly ? 'yearly' : 'monthly';
        final expiry = DateTime.now().add(_isYearly ? const Duration(days: 365) : const Duration(days: 30));
        await CloudRelationshipService().activateRealPremium(
          relId: targetRelId,
          planType: plan,
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
            // Top Bar
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
                      'NextMeet+',
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
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Scrollable Paywall Body (Page 76)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero Mascot Crown Banner
                    Center(
                      child: Column(
                        children: [
                          const TwoMascotsRow(
                            spacing: 16,
                            leftAccessory: MascotAccessory.crown,
                            rightAccessory: MascotAccessory.crown,
                          ),
                          const SizedBox(height: 16),
                          Text('NextMeet+ For Two', style: AppTextStyles.title1.copyWith(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(
                            'One subscription, both hearts covered.',
                            style: AppTextStyles.body.copyWith(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Pricing Selector Cards (Yearly vs Monthly)
                    Row(
                      children: [
                        // Yearly Option
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              VibrationService.light();
                              setState(() => _isYearly = true);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _isYearly ? AppColors.pinkSoft.withValues(alpha: 0.8) : Colors.white,
                                borderRadius: BorderRadius.circular(AppRadius.card),
                                border: Border.all(
                                  color: _isYearly ? AppColors.primary : AppColors.border,
                                  width: _isYearly ? 2.0 : 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                    ),
                                    child: Text(
                                      'BEST VALUE',
                                      style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 9),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Yearly', style: AppTextStyles.heading.copyWith(fontSize: 15)),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text('₹499 / yr', style: AppTextStyles.title1.copyWith(fontSize: 18, color: AppColors.primary)),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text('Just ₹41/month', style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Monthly Option
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              VibrationService.light();
                              setState(() => _isYearly = false);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: !_isYearly ? AppColors.pinkSoft.withValues(alpha: 0.8) : Colors.white,
                                borderRadius: BorderRadius.circular(AppRadius.card),
                                border: Border.all(
                                  color: !_isYearly ? AppColors.primary : AppColors.border,
                                  width: !_isYearly ? 2.0 : 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                    ),
                                    child: Text(
                                      'FLEXIBLE',
                                      style: AppTextStyles.label.copyWith(color: AppColors.muted, fontSize: 9),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Monthly', style: AppTextStyles.heading.copyWith(fontSize: 15)),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text('₹49 / mo', style: AppTextStyles.title1.copyWith(fontSize: 18, color: AppColors.primary)),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text('Cancel anytime', style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 4 VIP Perks Cards
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

                    const SizedBox(height: 24),

                    // Primary Subscription Button
                    PrimaryButton(
                      text: _isYearly ? 'Get NextMeet+ (₹499/yr) 👑' : 'Get NextMeet+ (₹49/mo) 👑',
                      isLoading: _isProcessing,
                      onPressed: _subscribe,
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'Payment charged via App Store / Google Play. Auto-renews unless cancelled 24 hours prior.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
