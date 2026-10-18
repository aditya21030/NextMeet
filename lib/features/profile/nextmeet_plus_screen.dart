import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/relationship_model.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/vibration_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0612),
      body: Stack(
        children: [
          // LUXURY OBSIDIAN AMBIENT GRADIENT
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E0E24),
                  Color(0xFF130917),
                  Color(0xFF09030C),
                ],
              ),
            ),
          ),

          // Ambient Glow Blobs
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF5E7E).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            top: 240,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFC75F).withValues(alpha: 0.08),
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
                  // App Bar
                  SliverAppBar(
                    backgroundColor: const Color(0xFF1E0E24).withValues(alpha: 0.75),
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
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, color: Color(0xFFFFC75F), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          isPlus ? 'VIP COUPLE MEMBERSHIP' : 'NEXTMEET PRO',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      if (!isPlus)
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

                  // Hero Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: FadeInDown(
                        duration: const Duration(milliseconds: 500),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF5E7E), Color(0xFFFFC75F)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF5E7E).withValues(alpha: 0.35),
                                    blurRadius: 28,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.all_inclusive_rounded, color: Colors.white, size: 36),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isPlus ? 'Your Shared Space is Elevated' : 'One Upgrade. Both Partners Connected.',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.favorite_rounded, color: Color(0xFFFFB3C6), size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    isPlus
                                        ? 'Both Partner A & Partner B are covered'
                                        : 'Upgrades both phones with 1 single purchase',
                                    style: const TextStyle(
                                      color: Color(0xFFFFB3C6),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
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
                          ? _buildSubscriptionDashboard(rel!, context)
                          : FadeInUp(
                              duration: const Duration(milliseconds: 500),
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

                  // UNLOCKED SUPERPOWERS HEADER
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
                          const Icon(Icons.stars_rounded, size: 16, color: Color(0xFFFFC75F)),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 14)),

                  // CLEAN PERKS LIST
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildCleanPerk(
                          icon: Icons.vibration_rounded,
                          color: const Color(0xFFFFC75F),
                          title: 'Pro-Haptic Rhythms Suite',
                          subtitle: '16 exclusive heartbeat rhythms and custom tactile sensations shared with your partner.',
                        ),
                        _buildCleanPerk(
                          icon: Icons.photo_library_rounded,
                          color: const Color(0xFFFF4D6D),
                          title: 'Eternal HD Memories (Unlimited)',
                          subtitle: 'Preserve your complete couple journey in full original resolution without storage caps.',
                        ),
                        _buildCleanPerk(
                          icon: Icons.mic_rounded,
                          color: const Color(0xFFFB8500),
                          title: 'Encrypted Voice Whispers',
                          subtitle: 'Record and replay intimate voice memos safely locked inside your shared Sanctuary.',
                        ),
                        _buildCleanPerk(
                          icon: Icons.hourglass_top_rounded,
                          color: const Color(0xFF845EC2),
                          title: 'Couple Time Capsules',
                          subtitle: 'Seal secret surprise love letters & photos that automatically unlock on milestones.',
                        ),
                        _buildCleanPerk(
                          icon: Icons.lock_open_rounded,
                          color: const Color(0xFF10B981),
                          title: '150 MB Ultra-HD Vault',
                          subtitle: 'Extended encrypted cloud storage for crystal-clear secret photos and whispers.',
                        ),
                        _buildCleanPerk(
                          icon: Icons.palette_rounded,
                          color: const Color(0xFF06B6D4),
                          title: 'Custom Chat Atmosphere & Wallpaper',
                          subtitle: 'Personalize your couple space with custom photo wallpapers and ambient glowing auras.',
                        ),
                      ]),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 28)),

                  // TRANSPARENT COMPARISON TABLE
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildComparisonTable(),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 150)),
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

    // Compute monthly equivalent for yearly (e.g., ₹499/yr => ~₹41/mo)
    String monthlyEquivalent = '₹41 / month';
    try {
      final digits = RegExp(r'\d+').allMatches(yearlyPrice).map((m) => m.group(0)).join();
      if (digits.isNotEmpty) {
        final val = double.tryParse(digits);
        if (val != null) {
          final perMo = (val / 12).round();
          monthlyEquivalent = '₹$perMo / month';
        }
      }
    } catch (_) {}

    return Row(
      children: [
        // Yearly Card (Highlighted)
        Expanded(
          child: _buildPriceCard(
            title: 'Annual Plan',
            price: yearlyPrice,
            subPrice: monthlyEquivalent,
            strikethrough: '₹999',
            badge: 'SAVE 50% • BEST VALUE',
            subtitle: 'Billed annually • Both phones covered',
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
            title: 'Monthly Plan',
            price: monthlyPrice,
            subPrice: 'Billed monthly',
            strikethrough: '₹99',
            badge: 'FLEXIBLE',
            subtitle: 'Cancel anytime in Play Store',
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
    required String subPrice,
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
              ? const Color(0xFFFF5E7E).withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFC75F) : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFC75F).withValues(alpha: 0.2),
                    blurRadius: 18,
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
                color: isSelected ? const Color(0xFFFFC75F) : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: isSelected ? Colors.black87 : Colors.white70,
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 13,
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
                    fontSize: 11,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  price,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFFFB3C6) : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subPrice,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFFC75F) : Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
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
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    final rows = [
      {'feature': 'Shared Couple Space', 'free': 'Included', 'plus': 'Included'},
      {'feature': 'Memory Photos', 'free': '50 Photos', 'plus': 'Unlimited Ultra-HD'},
      {'feature': 'Touch Rhythms', 'free': '7 Classic', 'plus': '16 Pro Rhythms'},
      {'feature': 'Sanctuary Vault', 'free': '20 MB', 'plus': '150 MB (7.5x)'},
      {'feature': 'Voice Whispers', 'free': '1 Recording', 'plus': 'Unlimited'},
      {'feature': 'Couple Time Capsules', 'free': '1 Milestone', 'plus': 'Unlimited'},
      {'feature': 'VIP Golden Glow Aura', 'free': '-', 'plus': 'Unlocked for Both'},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FEATURE COMPARISON',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC75F).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'FREE vs PLUS',
                  style: TextStyle(
                    color: Color(0xFFFFC75F),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...rows.map((row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      row['feature']!,
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      row['free']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      row['plus']!,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFFFFC75F),
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    final activePrice = isYearly
        ? _subService.getPriceById(SubscriptionService.yearlyId)
        : _subService.getPriceById(SubscriptionService.monthlyId);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0D0612).withValues(alpha: 0),
              const Color(0xFF0D0612).withValues(alpha: 0.95),
              const Color(0xFF0D0612),
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
                            isYearly ? 'Unlock for Both ($activePrice/yr) ❤️' : 'Unlock for Both ($activePrice/mo) ❤️',
                            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Auto-renews • Cancel anytime with 1 tap in Google Play Store',
              style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w500),
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
                        builder: (context) => const TermsPolicyScreen(
                          title: 'Terms of Service',
                          initialTab: 0,
                        ),
                      ),
                    );
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsPolicyScreen(
                          title: 'Privacy Policy',
                          initialTab: 1,
                        ),
                      ),
                    );
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

  Widget _buildSubscriptionDashboard(RelationshipModel rel, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFC75F).withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC75F).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
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
                  color: const Color(0xFFFFC75F).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars_rounded, color: Color(0xFFFFC75F), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE COUPLE MEMBERSHIP',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                    ),
                    Text(
                      'Both Partner A & Partner B are Unlocked',
                      style: TextStyle(color: Color(0xFFFFB3C6), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatRow('Plan Type', rel.premiumPlanType ?? 'NextMeet+ Annual Elite', Colors.white),
          const Divider(color: Colors.white10, height: 24),
          _buildStatRow(
            'Renews On',
            rel.premiumRenewalDate != null
                ? DateFormat('MMM dd, yyyy').format(rel.premiumRenewalDate!)
                : 'Active & Auto-Renewing',
            const Color(0xFFFFB3C6),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 16),
          // Direct Action Shortcuts
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
                  icon: const Icon(Icons.vibration_rounded, color: Color(0xFFFFC75F), size: 16),
                  label: const Text(
                    'PRO HAPTICS',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFFFC75F)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color(0xFFFFC75F).withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openPlayStoreSubscriptions,
                  icon: const Icon(Icons.open_in_new_rounded, color: Colors.white70, size: 16),
                  label: const Text(
                    'MANAGE PLAN',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
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
