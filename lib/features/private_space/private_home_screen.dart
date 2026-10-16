import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';
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
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (!snapshot.hasData || snapshot.data?.id == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
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
            backgroundColor: AppColors.background,
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
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Parallax Soft Gradient & Decorative Layer
              _buildParallaxBackground(isPlus),
              
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Elegant Pinned Header
                  ValueListenableBuilder<double>(
                    valueListenable: _scrollOffset,
                    builder: (context, offset, _) => SliverAppBar(
                      pinned: true,
                      expandedHeight: 0,
                      backgroundColor: offset > 20
                          ? AppColors.background.withValues(alpha: 0.95)
                          : Colors.transparent,
                      elevation: offset > 20 ? 1 : 0,
                      centerTitle: true,
                      leading: Navigator.canPop(context)
                          ? IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                            )
                          : null,
                      title: const Text(
                        'SANCTUARY',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2, color: AppColors.textPrimary),
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
                          tooltip: 'Sanctuary Settings',
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),

                  // Profile Header Section (Clean, aligned, centered)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.l, 12, AppSpacing.l, 0),
                      child: FadeInDown(
                        duration: const Duration(milliseconds: 600),
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

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // Section Header: Vault Features
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                      child: Row(
                        children: [
                          Text(
                            'PROTECTED ARCHIVES',
                            style: AppTextStyles.bodyS.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: AppColors.textSecondary.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

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
                            '${snapshot.data?.docs.length ?? 0} heartfelt letters kept safe',
                            Icons.favorite_rounded,
                            const Color(0xFFFF4D6D),
                            () => _navigateTo(const LoveLettersScreen()),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // FEATURED 2: Secret Photos (Hero Card)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                      child: FadeInUp(
                        delay: const Duration(milliseconds: 180),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _cloudService.streamPrivatePhotos(relId),
                          builder: (context, snapshot) {
                            return _buildHeroFeaturedCard(
                              'Secret Photo Vault',
                              '${snapshot.data?.docs.length ?? 0} private moments stored',
                              Icons.photo_library_rounded,
                              const Color(0xFF845EC2),
                              () => _navigateTo(const SecretPhotosScreen()),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 28)),

                  // Footer Security Pill
                  SliverToBoxAdapter(
                    child: Center(
                      child: FadeInUp(
                        delay: const Duration(milliseconds: 260),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.circle),
                            border: Border.all(color: Colors.pink.shade50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_rounded, size: 12, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'End-to-End Encrypted & Private',
                                style: AppTextStyles.bodyS.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroFeaturedCard(String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          VibrationService.light();
          onTap();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.pink.shade50),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sub,
                      style: AppTextStyles.bodyS.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParallaxBackground(bool isPlus) {
    return ValueListenableBuilder<double>(
      valueListenable: _scrollOffset,
      builder: (context, offset, _) => Stack(
        children: [
          // Base Soft Romantic Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFF5F7), // Soft cashmere blush
                  AppColors.background,
                ],
              ),
            ),
          ),
          // Top Floating Heart Accent
          Positioned(
            top: -20 - (offset * 0.2),
            right: 16,
            child: Opacity(
              opacity: 0.12,
              child: Icon(Icons.favorite, size: 100, color: AppColors.primary.withValues(alpha: 0.3)),
            ),
          ),
          // Middle Floating Accent
          Positioned(
            top: 260 - (offset * 0.3),
            left: -40,
            child: Opacity(
              opacity: 0.08,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryLight.withValues(alpha: 0.2),
                      blurRadius: 90,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    String names,
    String? p1,
    String? p2,
    String uid1,
    String uid2, {
    required bool isBothOnline,
    bool isPlus = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.pink.shade50),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 140,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 6,
                  child: _buildAvatar(p1, isBothOnline),
                ),
                Positioned(
                  right: 6,
                  child: _buildAvatar(p2, isBothOnline),
                ),
                // Center connection badge
                Positioned(
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 14),
                  ),
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
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Your Intimate Digital Sanctuary',
            style: AppTextStyles.bodyS.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isBothOnline) ...[
            const SizedBox(height: 10),
            FadeIn(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Both in Sanctuary',
                      style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(String? photo, bool isOnline) {
    final hasPhoto = photo != null && photo.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 34,
        backgroundColor: Colors.pink.shade50,
        backgroundImage: hasPhoto ? CachedNetworkImageProvider(photo) : null,
        child: !hasPhoto ? const Icon(Icons.person_rounded, color: AppColors.primary, size: 30) : null,
      ),
    );
  }
}
