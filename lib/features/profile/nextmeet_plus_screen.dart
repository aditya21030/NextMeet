import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/models/relationship_model.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/subscription_service.dart';

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
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          // PREMIUM GRADIENT BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F0812),
                  Color(0xFF1A0A1D),
                  Color(0xFF0F0812),
                ],
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
                  SliverAppBar(
                    backgroundColor: const Color(0xFF0F0812).withValues(alpha: 0.7),
                    elevation: 0,
                    pinned: true,
                    centerTitle: true,
                    flexibleSpace: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: Text(
                      'NextMeet+',
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // SUBSCRIPTION DASHBOARD OR PRICING
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: isPlus 
                        ? _buildSubscriptionDashboard(rel!)
                        : FadeInDown(
                            duration: const Duration(milliseconds: 800),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.celebration_rounded, color: Colors.white, size: 14),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'SANCTUARY ELITE OFFER 🎁', 
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildPricingCards(),
                                if (_subService.error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(
                                      'Store Issue: ${_subService.error}',
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 10),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),

                  // FEATURE LIST
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        FadeInUp(
                          delay: const Duration(milliseconds: 400),
                          child: Column(
                            children: [
                               _buildPremiumListItem(_FeatureInfo('Smart AI Suggestions ✈️', Icons.auto_awesome_rounded, 'AI-powered suggestions for your shared trips.')),
                               _buildPremiumListItem(_FeatureInfo('Nearby places for Trip 🗺️', Icons.near_me_rounded, 'Discover perfect stays and spots around your trip.')),
                               _buildPremiumListItem(_FeatureInfo('Unlimited Memories ✨', Icons.photo_library_rounded, 'Store your beautiful journey with zero limits.')),
                               _buildPremiumListItem(_FeatureInfo('150 MB Private Space ☁️', Icons.cloud_done_rounded, 'Massive storage for your secret photos and notes.')),
                               _buildPremiumListItem(_FeatureInfo('Pro-Haptics & Patterns 💓', Icons.vibration_rounded, 'Exclusive heartbeat & touch vibration patterns.')),
                               _buildPremiumListItem(_FeatureInfo('Neon Glow & Indigo Badge ✨', Icons.stars_rounded, 'Stand out with premium profile aesthetics.')),
                               _buildPremiumListItem(_FeatureInfo('100% Ad-Free Sanctuary 🛡️', Icons.block_rounded, 'Zero distractions. Just you two.')),
                               _buildPremiumListItem(_FeatureInfo('Shared Map Love Trail 🗺️', Icons.map_rounded, 'Visualize your journey on a beautiful shared map.')),
                               _buildPremiumListItem(_FeatureInfo('Environment Status 🌦️', Icons.cloud_circle_rounded, 'Partner real-time weather & time status.')),
                               
                               const SizedBox(height: 40),
                               const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 180)),
                ],
              );
            },
          ),

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
    return Row(
      children: [
        Expanded(
          child: _buildPriceCard(
            'Monthly',
            _subService.getPriceById(SubscriptionService.monthlyId),
            '₹99',
            'Early Couple Offer 🎁',
            !isYearly,
            () => setState(() => isYearly = false),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildPriceCard(
            'Yearly',
            _subService.getPriceById(SubscriptionService.yearlyId),
            '₹999',
            'Best Value ✨',
            isYearly,
            () => setState(() => isYearly = true),
            isBestValue: true,
          ),
        ),
      ],
    );
  }
 
  Widget _buildPriceCard(String title, String price, String originalPrice, String sub, bool isSelected, VoidCallback onTap, {bool isBestValue = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontWeight: FontWeight.w900, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  originalPrice, 
                  style: TextStyle(
                    color: Colors.white24, 
                    fontSize: 12, 
                    decoration: TextDecoration.lineThrough,
                    fontWeight: FontWeight.w500
                  )
                ),
                const SizedBox(width: 4),
                Text(price, style: TextStyle(color: isSelected ? AppColors.primary : Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
              ],
            ),
            const SizedBox(height: 4),
            Text(sub, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white70 : Colors.white38, fontSize: 8, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumListItem(_FeatureInfo f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(f.icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(f.description, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
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
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F0812).withValues(alpha: 0),
              const Color(0xFF0F0812).withValues(alpha: 0.95),
              const Color(0xFF0F0812),
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 40, spreadRadius: 0),
            ],
          ),
          child: ElevatedButton(
            onPressed: _subService.isLoading ? null : _handleUpgrade,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              child: _subService.isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text(
                  'UPGRADE NOW',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleUpgrade() async {
    // Find the correct product based on selection
    ProductDetails? selectedProduct;
    final String targetId = isYearly ? SubscriptionService.yearlyId : SubscriptionService.monthlyId;
    
    for (var p in _subService.products) {
      if (p.id == targetId) selectedProduct = p;
    }

    if (selectedProduct == null) {
      // If store hasn't loaded real products, show why
      final String errorMsg = _subService.error != null 
          ? 'Store Error: ${_subService.error}' 
          : 'Connecting to Store... Please wait 10 seconds and try again.';
          
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
        )
      );
      _subService.loadProducts();
      return;
    }

    await _subService.buyProduct(selectedProduct, isYearly);
  }

  Widget _buildSubscriptionDashboard(RelationshipModel rel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Text('ACTIVE SUBSCRIPTION', style: AppTextStyles.h3.copyWith(color: Colors.white, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 24),
          _buildStatRow('Plan', rel.premiumPlanType ?? 'Monthly Sanctuary', Colors.white),
          const Divider(color: Colors.white10, height: 32),
          _buildStatRow('Transaction', rel.premiumTransactionId ?? 'NX-XXX', Colors.white70),
          const Divider(color: Colors.white10, height: 32),
          _buildStatRow(
            'Renews On', 
            rel.premiumRenewalDate != null ? DateFormat('MMM dd, yyyy').format(rel.premiumRenewalDate!) : '...',
            AppColors.primary
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _FeatureInfo {
  final String title;
  final IconData icon;
  final String description;
  _FeatureInfo(this.title, this.icon, this.description);
}
