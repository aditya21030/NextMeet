import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';
import '../../widgets/glass_card.dart';
import 'private_space_settings_screen.dart';
import 'secret_photos_screen.dart';
import 'love_letters_screen.dart';
import '../onboarding/setup_couple_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/vibration_service.dart';

class PrivateHomeScreen extends StatefulWidget {
  final VoidCallback? onLock;
  const PrivateHomeScreen({super.key, this.onLock});

  @override
  State<PrivateHomeScreen> createState() => _PrivateHomeScreenState();
}

class _PrivateHomeScreenState extends State<PrivateHomeScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _scrollOffset.value = _scrollController.offset;
    });
    // Record sanctuary entry
    _cloudService.updateSanctuaryStatus(true);
  }

  @override
  void dispose() {
    _cloudService.updateSanctuaryStatus(false);
    _scrollController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFFDEEF1),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data?.id == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFFDEEF1),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'SANCTUARY',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2, color: AppColors.textPrimary),
              ),
              centerTitle: true,
              leading: Navigator.canPop(context)
                  ? IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                    )
                  : null,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_moon_rounded, size: 56, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    Text('Private Couple Sanctuary', style: AppTextStyles.h2, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text(
                      'A private, protected space for your Love Notes and Secret Photos. Connect with your partner to unlock.',
                      style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SetupCoupleScreen()));
                      },
                      icon: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
                      label: const Text('Connect with Partner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final rel = snapshot.data!;

        if (rel.uid2 == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFFDEEF1),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'SANCTUARY',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2, color: AppColors.textPrimary),
              ),
              centerTitle: true,
              leading: Navigator.canPop(context)
                  ? IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                    )
                  : null,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_rounded, size: 56, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    Text('Unlock Couple Sanctuary 🔒', style: AppTextStyles.h2, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text(
                      'A private, protected space for your Love Notes and Secret Photos. Unlock as soon as your partner joins your journey!',
                      style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: () {
                        VibrationService.medium();
                        Share.share(AppLinks.getInviteMessage(rel.inviteCode ?? ''));
                      },
                      icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                      label: Text('Share Love Code (${rel.inviteCode ?? ''})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final relId = rel.id!;
        final name1 = rel.userName1 ?? 'Partner 1';
        final name2 = rel.userName2 ?? 'Partner 2';
        final isPlus = rel.isPlus;

        return Scaffold(
          backgroundColor: const Color(0xFFFDEEF1),
          body: Stack(
            children: [
              // 3D Parallax Layers
              _buildParallaxBackground(isPlus),
              
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Sticky Header
                  ValueListenableBuilder<double>(
                    valueListenable: _scrollOffset,
                    builder: (context, offset, _) => SliverAppBar(
                      pinned: true,
                      expandedHeight: 0,
                      backgroundColor: const Color(0xFFFDEEF1).withValues(alpha: offset > 50 ? 0.95 : 0.0),
                      elevation: offset > 50 ? 2 : 0,
                      leading: Navigator.canPop(context)
                          ? IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                            )
                          : null,
                      title: AnimatedOpacity(
                        opacity: offset > 50 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Text(
                          'PRIVATE SANCTUARY',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2, color: AppColors.textPrimary),
                        ),
                      ),
                      actions: [
                        if (widget.onLock != null)
                          IconButton(
                            onPressed: widget.onLock,
                            icon: const Icon(Icons.lock_outline_rounded, color: AppColors.textPrimary, size: 20),
                            tooltip: 'Lock Sanctuary',
                          ),
                        IconButton(
                          onPressed: () => _navigateTo(const PrivateSpaceSettingsScreen()),
                          icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary, size: 20),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),

                  // Profile Header Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.l, 20, AppSpacing.l, 0),
                      child: FadeInDown(
                        duration: const Duration(milliseconds: 800),
                        child: _buildProfileHeader(
                          '$name1 ❤️ $name2', 
                          rel.userPhoto1, 
                          rel.userPhoto2, 
                          rel.uid1 ?? '1', 
                          rel.uid2 ?? '2',
                          isBothOnline: (rel.u1InSanctuary) && (rel.u2InSanctuary),
                          isPlus: isPlus,
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.l)),

                  // FEATURED 1: Love Notes (Hero Card)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                      child: FadeInUp(
                        delay: const Duration(milliseconds: 100),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _cloudService.streamLoveLetters(relId),
                          builder: (context, snapshot) => _buildHeroFeaturedCard(
                            'Love Notes',
                            '${snapshot.data?.docs.length ?? 0} heartfelt notes sent',
                            Icons.favorite_rounded,
                            const Color(0xFFFF5E7E),
                            () => _navigateTo(const LoveLettersScreen()),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.m)),

                  // FEATURED 2: Secret Photos (Hero Card)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                      child: FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _cloudService.streamPrivatePhotos(relId),
                          builder: (context, snapshot) {
                            return _buildHeroFeaturedCard(
                              'Secret Photo Vault',
                              '${snapshot.data?.docs.length ?? 0} Shared Moments',
                              Icons.photo_library_rounded,
                              AppColors.primary,
                              () => _navigateTo(const SecretPhotosScreen()),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

                  // Footer Info
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.m),
                        FadeInUp(
                          delay: const Duration(milliseconds: 300),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(AppRadius.circle),
                              border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock_rounded, size: 12, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  'End-to-end encrypted & Private',
                                  style: AppTextStyles.bodyS.copyWith(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroFeaturedCard(String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(sub, style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildParallaxBackground(bool isPlus) {
    return ValueListenableBuilder<double>(
      valueListenable: _scrollOffset,
      builder: (context, offset, _) => Stack(
        children: [
          // Base Layer (Static)
          Container(color: const Color(0xFFFDEEF1)),
          // Top Floating Hearts
          Positioned(
            top: -20 - (offset * 0.2),
            right: 20,
            child: Opacity(
              opacity: 0.15,
              child: Icon(Icons.favorite, size: 100, color: AppColors.primary.withValues(alpha: 0.3)),
            ),
          ),
          // Middle Floating Blob
          Positioned(
            top: 300 - (offset * 0.4),
            left: -50,
            child: Opacity(
              opacity: 0.1,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.05), 
                  shape: BoxShape.circle, 
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryLight.withValues(alpha: 0.2), blurRadius: 100, spreadRadius: 20)
                  ]
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String names, String? p1, String? p2, String uid1, String uid2, {required bool isBothOnline, bool isPlus = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 125,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 0,
                  child: _buildAvatar(p1, isBothOnline),
                ),
                Positioned(
                  right: 0,
                  child: _buildAvatar(p2, isBothOnline),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            names, 
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.textPrimary),
          ),
          if (isBothOnline)
            FadeIn(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('Both in Sanctuary', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? photo, bool isOnline) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: CircleAvatar(
        radius: 35,
        backgroundColor: Colors.grey.shade100,
        backgroundImage: photo != null ? NetworkImage(photo) : null,
        child: photo == null ? const Icon(Icons.person, color: Colors.grey) : null,
      ),
    );
  }
}
