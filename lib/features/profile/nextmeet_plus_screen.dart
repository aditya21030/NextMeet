import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../core/models/relationship_model.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/vibration_service.dart';
import 'terms_policy_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0814),
      body: Stack(
        children: [
          // LUXURY AMBIENT BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E0E24),
                  Color(0xFF130917),
                  Color(0xFF0A040D),
                ],
              ),
            ),
          ),

          // Ambient Glow Blob
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
          ),

          StreamBuilder<RelationshipModel?>(
            stream: _cloudService.streamRelationship(),
            builder: (context, snapshot) {
              final rel = snapshot.data;
              final bool isPlus = rel?.isPlus ?? false;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Sleek App Bar
                  SliverAppBar(
                    backgroundColor: const Color(0xFF1E0E24).withValues(alpha: 0.7),
                    elevation: 0,
                    pinned: true,
                    centerTitle: true,
                    flexibleSpace: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () {
                        VibrationService.light();
                        Navigator.pop(context);
                      },
                    ),
                    title: const Text(
                      'NextMeet+',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: _subService.isLoading
                            ? null
                            : () async {
                                VibrationService.light();
                                final success = await _subService.restorePurchases();
                                if (!context.mounted) return;
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Purchases restored! NextMeet+ active ❤️')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(_subService.error ?? 'No active subscription found.')),
                                  );
                                }
                              },
                        child: const Text(
                          'Restore',
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),

                  // Hero Title Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    const Color(0xFF845EC2),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 36),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Intimacy Without Distance',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                              ),
                              child: const Text(
                                '💑 One subscription covers both partners',
                                style: TextStyle(
                                  color: Color(0xFFFFB3C6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // PRICING CARDS OR ACTIVE DASHBOARD
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: isPlus
                          ? _buildSubscriptionDashboard(rel!)
                          : FadeInUp(
                              duration: const Duration(milliseconds: 600),
                              child: Column(
                                children: [
                                  _buildPricingCards(),
                                  if (_subService.error != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(
                                        _subService.error!,
                                        style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 28)),

                  // CURATED PERKS SECTION HEADER
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          const Text(
                            'UNLOCKED SUPERPOWERS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: Colors.white54,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.stars_rounded, size: 16, color: Colors.amber.shade300),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // CLEAN PERKS LIST
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildCleanPerk(
                          icon: Icons.fingerprint_rounded,
                          color: const Color(0xFF10B981),
                          title: 'Face & Fingerprint Passcode',
                          subtitle: 'Instant biometric unlock for Sanctuary without typing your 4-digit code.',
                        ),
                        _buildCleanPerk(
                          icon: Icons.mic_rounded,
                          color: const Color(0xFFFB8500),
                          title: 'Secret Voice Whispers',
                          subtitle: 'Record and preserve intimate audio moments encrypted in your Couple Sanctuary.',
                        ),
                        _buildCleanPerk(
                          icon: Icons.lock_open_rounded,
                          color: const Color(0xFFFF4D6D),
                          title: '150 MB Ultra-HD Vault',
                          subtitle: '7.5x storage space for crystal-clear secret photos and voice notes.',
                        ),
                        _buildCleanPerk(
                          icon: Icons.history_edu_rounded,
                          color: const Color(0xFFFF5E7E),
                          title: 'Romantic "On This Day" Flashbacks',
                          subtitle: 'Relive special anniversary moments and trips as they happened on this date in past months and years.',
                        ),
                        _buildCleanPerk(
                          icon: Icons.hourglass_top_rounded,
                          color: const Color(0xFFF59E0B),
                          title: 'Couple Time Capsules',
                          subtitle: 'Seal secret surprise memories locked until anniversaries or milestones.',
                        ),
                        _buildCleanPerk(
                          icon: Icons.photo_library_rounded,
                          color: const Color(0xFFFF8E71),
                          title: 'Eternal 500+ HD Memories',
                          subtitle: 'Preserve your full relationship journey without free-tier photo limits.',
                        ),
                        _buildCleanPerk(
                          icon: Icons.palette_rounded,
                          color: const Color(0xFF06B6D4),
                          title: 'Custom Chat Atmosphere',
                          subtitle: 'Personalize your private couple chat with custom themes and photos.',
                        ),
                        _buildCleanPerk(
                          icon: Icons.vibration_rounded,
                          color: const Color(0xFF845EC2),
                          title: 'Pro-Haptics Engine',
                          subtitle: 'Exclusive heartbeat patterns and custom tactile touch rhythms.',
                        ),
                        _buildCleanPerk(
                          icon: Icons.stars_rounded,
                          color: const Color(0xFFFFC75F),
                          title: 'VIP Couple Prestige Badge',
                          subtitle: 'Glowing golden avatar aura on both phones to celebrate your bond.',
                        ),
                      ]),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 140)),
                ],
              );
            },
          ),

          // STICKY BOTTOM ACTION BAR (Hidden when already subscribed)
          StreamBuilder<RelationshipModel?>(
            stream: _cloudService.streamRelationship(),
            builder: (context, snapshot) {
              final isPlus = snapshot.data?.isPlus ?? false;
              if (isPlus) return const SizedBox.shrink();
              return _buildBottomAction(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCards() {
    final yearlyPrice = _subService.getPriceById(SubscriptionService.yearlyId);
    final monthlyPrice = _subService.getPriceById(SubscriptionService.monthlyId);

    return Row(
      children: [
        // Yearly Card (Highlighted)
        Expanded(
          child: _buildPriceCard(
            title: 'Annual',
            price: yearlyPrice,
            strikethrough: '₹999',
            badge: 'SAVE 50%',
            subtitle: 'Best Value • Renews yearly',
            isSelected: isYearly,
            onTap: () {
              VibrationService.light();
              setState(() => isYearly = true);
            },
          ),
        ),
        const SizedBox(width: 12),
        // Monthly Card
        Expanded(
          child: _buildPriceCard(
            title: 'Monthly',
            price: monthlyPrice,
            strikethrough: '₹99',
            badge: 'Flexible',
            subtitle: 'Renews monthly',
            isSelected: !isYearly,
            onTap: () {
              VibrationService.light();
              setState(() => isYearly = false);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriceCard({
    required String title,
    required String price,
    required String strikethrough,
    required String badge,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  strikethrough,
                  style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  price,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFFFB3C6) : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white70 : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanPerk({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F0814).withValues(alpha: 0),
              const Color(0xFF0F0814).withValues(alpha: 0.95),
              const Color(0xFF0F0814),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _subService.isLoading ? null : _handleUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 8,
                shadowColor: AppColors.primary.withValues(alpha: 0.5),
              ),
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: _subService.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            isYearly ? 'Unlock for Both (Annual) ❤️' : 'Unlock for Both (Monthly) ❤️',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Auto-renews • Cancel anytime in Google Play Store',
              style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    VibrationService.light();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsPolicyScreen(initialTab: 0)));
                  },
                  child: const Text(
                    'Terms of Service',
                    style: TextStyle(color: Colors.white54, fontSize: 10, decoration: TextDecoration.underline),
                  ),
                ),
                const Text('  •  ', style: TextStyle(color: Colors.white24, fontSize: 10)),
                GestureDetector(
                  onTap: () {
                    VibrationService.light();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsPolicyScreen(initialTab: 1)));
                  },
                  child: const Text(
                    'Privacy Policy',
                    style: TextStyle(color: Colors.white54, fontSize: 10, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleUpgrade() async {
    final success = await _subService.buyProduct(isYearly);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Welcome to NextMeet+! Both of your spaces are upgraded ❤️'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (_subService.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_subService.error!),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildSubscriptionDashboard(RelationshipModel rel) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.primary, size: 26),
              const SizedBox(width: 10),
              const Text(
                'ACTIVE COUPLE SUBSCRIPTION',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatRow('Plan Type', rel.premiumPlanType ?? 'Sanctuary Elite', Colors.white),
          const Divider(color: Colors.white10, height: 24),
          _buildStatRow(
            'Renews On',
            rel.premiumRenewalDate != null
                ? DateFormat('MMM dd, yyyy').format(rel.premiumRenewalDate!)
                : 'Active',
            const Color(0xFFFFB3C6),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
