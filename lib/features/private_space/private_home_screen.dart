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
import 'voice_whispers_screen.dart';
import '../onboarding/setup_couple_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/vibration_service.dart';

class PrivateHomeScreen extends StatefulWidget {
  final RelationshipModel? rel;
  final VoidCallback? onLock;
  final VoidCallback? onClose;

  const PrivateHomeScreen({super.key, this.rel, this.onLock, this.onClose});

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
    _updatePresence(true);
  }

  void _updatePresence(bool isIn) {
    final relId = widget.rel?.id;
    if (relId != null) {
      _cloudService.updateSanctuaryPresence(relId, isIn);
    } else {
      _cloudService.updateSanctuaryStatus(isIn);
    }
  }

  @override
  void dispose() {
    _updatePresence(false);
    _scrollController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  void _handleExit() {
    VibrationService.light();
    _updatePresence(false);
    widget.onLock?.call();
    if (widget.onClose != null) {
      widget.onClose!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rel != null) {
      if (widget.rel!.id == null || widget.rel!.uid2 == null) {
        return _buildUnpairedScreen(widget.rel);
      }
      return _buildContent(widget.rel!);
    }

    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (!snapshot.hasData || snapshot.data?.id == null || snapshot.data?.uid2 == null) {
          return _buildUnpairedScreen(snapshot.data);
        }

        return _buildContent(snapshot.data!);
      },
    );
  }

  Widget _buildUnpairedScreen(RelationshipModel? rel) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'SANCTUARY',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2, color: AppColors.textPrimary),
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: _handleExit,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
            tooltip: 'Exit Sanctuary',
          ),
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
                Text('Unlock Couple Sanctuary 🔒', style: AppTextStyles.h2, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  'A private, protected space for your Love Notes and Secret Photos. Unlock as soon as your partner joins your journey!',
                  style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                if (rel != null)
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
                  )
                else
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
      ),
    );
  }

  Widget _buildContent(RelationshipModel rel) {
    final relId = rel.id!;
    final currentUid = _cloudService.currentUid;
    final myName = rel.getDisplayMyName(currentUid);
    final partnerName = rel.getDisplayPartnerName(currentUid);
    final myPhoto = rel.getMyPhoto(currentUid);
    final partnerPhoto = rel.getPartnerPhoto(currentUid);
    final isPlus = rel.isPlus;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleExit();
      },
      child: Scaffold(
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
                    leading: IconButton(
                      onPressed: _handleExit,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                      tooltip: 'Exit Sanctuary',
                    ),
                    title: const Text(
                      'SANCTUARY',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2, color: AppColors.textPrimary),
                    ),
                    actions: [
                      IconButton(
                        onPressed: _handleExit,
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
                          myName: myName,
                          partnerName: partnerName,
                          myPhoto: myPhoto,
                          partnerPhoto: partnerPhoto,
                          isBothOnline: rel.isPartnerInSanctuary(currentUid),
                          isPlus: isPlus,
                          relId: relId,
                          rel: rel,
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPlus ? AppColors.primary.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPlus ? Icons.stars_rounded : Icons.storage_rounded,
                                  size: 12,
                                  color: isPlus ? AppColors.primary : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${(rel.privateSpaceStorageBytes / (1024 * 1024)).toStringAsFixed(1)} / ${isPlus ? 150 : 20} MB',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isPlus ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // FEATURED 3: Secret Voice Whispers (NextMeet+ Voice Vault)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                      child: FadeInUp(
                        delay: const Duration(milliseconds: 220),
                        child: _buildHeroFeaturedCard(
                          'Secret Voice Whispers',
                          isPlus ? 'Encrypted intimate audio notes' : 'NextMeet+ exclusive voice vault',
                          Icons.mic_rounded,
                          const Color(0xFFFB8500),
                          () => _navigateTo(VoiceWhispersScreen(rel: rel)),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // FEATURED 4: Quick Love Note
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                      child: FadeInUp(
                        delay: const Duration(milliseconds: 260),
                        child: InkWell(
                          onTap: () => _showQuickWhisperSheet(relId, partnerName),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
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
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5E7D).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Leave a Note',
                                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Leave an intimate note for $partnerName',
                                        style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('WRITE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                                ),
                              ],
                            ),
                          ),
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
        ),
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

  Widget _buildProfileHeader({
    required String myName,
    required String partnerName,
    required String? myPhoto,
    required String? partnerPhoto,
    required bool isBothOnline,
    required bool isPlus,
    required String relId,
    required RelationshipModel rel,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
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
          // Overlapping Avatars
          SizedBox(
            width: 146,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 4,
                  child: _buildSafeAvatar(myPhoto, myName),
                ),
                Positioned(
                  right: 4,
                  child: _buildSafeAvatar(partnerPhoto, partnerName),
                ),
                // Center connection badge
                Positioned(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$myName ❤️ $partnerName',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Protected Couple Vault',
            style: AppTextStyles.bodyS.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // Badges row
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              if (isBothOnline)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_rounded, size: 10, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Encrypted & Private',
                        style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              if (isPlus)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB703), Color(0xFFFB8500)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, size: 10, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'NextMeet+ Vault',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafeAvatar(String? photoUrl, String fallbackName) {
    final initials = fallbackName.trim().isNotEmpty
        ? fallbackName.trim()[0].toUpperCase()
        : '❤️';
    final hasPhoto = photoUrl != null && photoUrl.trim().isNotEmpty;

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: ClipOval(
        child: hasPhoto
            ? CachedNetworkImage(
                imageUrl: photoUrl.trim(),
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.pink.shade50,
                  child: const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => _buildInitialsPlaceholder(initials),
              )
            : _buildInitialsPlaceholder(initials),
      ),
    );
  }

  Widget _buildInitialsPlaceholder(String initials) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF758C), Color(0xFFFF7EB3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  void _showQuickWhisperSheet(String relId, String partnerName) {
    VibrationService.medium();
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final suggestions = ['Thinking of you', 'For your eyes only', 'Always & forever', 'A promise'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.l,
            left: AppSpacing.l,
            right: AppSpacing.l,
            top: AppSpacing.m,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Leave a Private Note',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.textPrimary),
                          ),
                          Text(
                            'Encrypted note for $partnerName',
                            style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: suggestions.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                        onPressed: () {
                          titleController.text = s;
                          setModalState(() {});
                        },
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Note Subject / Title...',
                    hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 13),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.pink.shade50)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 4,
                  minLines: 3,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                  decoration: InputDecoration(
                    hintText: 'Write your private note here...',
                    hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 13),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.pink.shade50)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (contentController.text.trim().isEmpty) {
                        VibrationService.error();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write a message first.')));
                        return;
                      }
                      final title = titleController.text.trim().isNotEmpty ? titleController.text.trim() : 'Private Note';
                      await _cloudService.addLoveLetter(relId, title, contentController.text.trim());
                      VibrationService.success();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Note sealed and saved for $partnerName! ✨'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                    label: const Text('SEAL & SAVE NOTE', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
