import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';
import '../../core/models/memory_model.dart';
import '../../core/cities.dart';
import '../../widgets/sync_error_widget.dart';
import '../onboarding/setup_couple_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../profile/nextmeet_plus_screen.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isBookView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddMomentDialog(String relId, RelationshipModel rel) {
    VibrationService.medium();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMomentBottomSheet(
        relId: relId,
        rel: rel,
        cloudService: _cloudService,
        picker: _picker,
      ),
    );
  }

  void _showPlusUpgradeSheet(String relId, String title, String description, IconData icon) {
    VibrationService.medium();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Icon(icon, color: Colors.amber, size: 52),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.1),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NextMeetPlusScreen(relId: relId)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('UNLOCK WITH NEXTMEET+ ✨', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('MAYBE LATER', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _viewStory(MemoryModel moment, String relId, RelationshipModel rel) {
    VibrationService.medium();
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => _StoryPage(moment: moment, relId: relId, rel: rel, cloudService: _cloudService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, relSnapshot) {
        if (relSnapshot.hasError) {
          return Scaffold(
            body: SyncErrorWidget(
              errorMessage: 'Failed to sync relationship data.',
              onRetry: () => setState(() {}),
            ),
          );
        }

        if (relSnapshot.connectionState == ConnectionState.waiting && !relSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!relSnapshot.hasData || relSnapshot.data?.id == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              title: Text('Memories', style: AppTextStyles.h3),
              centerTitle: true,
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
                      child: const Icon(Icons.favorite_outline_rounded, size: 56, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    Text('No Memories Yet', style: AppTextStyles.h2, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text(
                      'Pair with your partner to start creating a shared digital timeline of your moments and milestones.',
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
        
        final rel = relSnapshot.data!;

        if (rel.uid2 == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              title: Text('Memories', style: AppTextStyles.h3),
              centerTitle: true,
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
                      child: const Icon(Icons.lock_outline_rounded, size: 56, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    Text('Unlock Shared Memories ✨', style: AppTextStyles.h2, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text(
                      'Unlock shared memories and build your couple timeline as soon as your partner joins your journey!',
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

        return StreamBuilder<List<MemoryModel>>(
          stream: _cloudService.streamMemories(relId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: SyncErrorWidget(
                    errorMessage: 'Unable to load moments.',
                    onRetry: () => setState(() {}),
                  ),
                ),
              );
            }
            
            final moments = snapshot.data ?? [];
            final stories = moments.where((m) => m.isStory).toList();
            final filteredMoments = _searchQuery.isEmpty
                ? moments
                : moments.where((m) {
                    final q = _searchQuery;
                    final loc = m.location.toLowerCase();
                    final cap = m.caption.toLowerCase();
                    final p1 = (m.partner1Caption ?? '').toLowerCase();
                    final p2 = (m.partner2Caption ?? '').toLowerCase();
                    final month = DateFormat('MMMM yyyy').format(m.date).toLowerCase();
                    return loc.contains(q) || cap.contains(q) || p1.contains(q) || p2.contains(q) || month.contains(q);
                  }).toList();
            
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: AppColors.background,
                elevation: 0,
                scrolledUnderElevation: 0,
                title: Row(
                  children: [
                    Text('Memories ✨', style: AppTextStyles.h2.copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    _buildCountBadge(moments.length),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddMomentDialog(relId, rel),
                      icon: const Icon(Icons.add_photo_alternate_rounded, size: 16, color: Colors.white),
                      label: const Text('Add Moment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                ],
              ),
              body: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.s),
                          // NextMeet+ Romantic Feature Bar
                          _buildMemoriesFeatureBar(relId, rel, moments),
                          if (stories.isNotEmpty && _searchQuery.isEmpty) ...[
                            _buildFeaturedMemory(stories[0], relId, rel),
                            const SizedBox(height: AppSpacing.xxl),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_searchQuery.isEmpty ? 'All Moments' : 'Search Results', style: AppTextStyles.h3),
                              Row(
                                children: [
                                  if (rel.isPlus) ...[
                                    IconButton(
                                      onPressed: () => setState(() => _isBookView = !_isBookView),
                                      icon: Icon(
                                        _isBookView ? Icons.grid_view_rounded : Icons.auto_stories_rounded, 
                                        color: AppColors.primary
                                      ),
                                      tooltip: _isBookView ? 'Switch to Gallery' : 'Switch to Storybook',
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  _buildCountBadge(filteredMoments.length),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.l),
                          TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.trim().toLowerCase();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search city or caption...',
                              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.m),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.m),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.m),
                                borderSide: const BorderSide(color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.l),
                          if (_searchQuery.isNotEmpty && filteredMoments.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                                    const SizedBox(height: 12),
                                    Text('No memories found', style: AppTextStyles.h3),
                                    const SizedBox(height: 4),
                                    Text('No moments matching "$_searchQuery"', style: AppTextStyles.bodyS),
                                  ],
                                ),
                              ),
                            )
                          else if (rel.isPlus)
                            (_isBookView ? _buildStorybookAlbum(filteredMoments, relId, rel) : _buildPremiumAlbum(filteredMoments, relId, rel))
                          else
                            _buildFreeGrid(filteredMoments, relId, rel),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildMemoriesFeatureBar(String relId, RelationshipModel rel, List<MemoryModel> moments) {
    final lockedCapsulesCount = moments.where((m) => m.isTimeLocked).length;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.l),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // 1. Cinematic Love Story Reel
            _buildFeatureChip(
              icon: Icons.movie_filter_rounded,
              iconColor: const Color(0xFFEC4899),
              title: 'Love Story Reel',
              badge: 'NextMeet+',
              onTap: () {
                if (rel.isPlus) {
                  _showCinematicReels(moments, relId, rel);
                } else {
                  _showPlusUpgradeSheet(
                    relId,
                    'Cinematic Love Story 🎬',
                    'Experience your love journey in a full-screen, auto-playing cinematic montage with smooth Ken Burns motion, ambient soundtrack, dates, and romantic transitions.',
                    Icons.movie_filter_rounded,
                  );
                }
              },
            ),
            const SizedBox(width: 10),

            // 2. 3D Flipping Storybook Album
            _buildFeatureChip(
              icon: _isBookView ? Icons.grid_view_rounded : Icons.auto_stories_rounded,
              iconColor: const Color(0xFF8B5CF6),
              title: _isBookView ? 'Gallery View' : '3D Storybook',
              badge: 'NextMeet+',
              onTap: () {
                if (rel.isPlus) {
                  setState(() => _isBookView = !_isBookView);
                } else {
                  _showPlusUpgradeSheet(
                    relId,
                    '3D Flipping Storybook 📖',
                    'Turn your shared moments into a realistic, touchable 3D coffee-table photobook with turning pages, vintage Polaroid frames, and handwritten notes.',
                    Icons.auto_stories_rounded,
                  );
                }
              },
            ),
            const SizedBox(width: 10),

            // 3. Couple Time Capsules
            _buildFeatureChip(
              icon: Icons.hourglass_top_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: lockedCapsulesCount > 0 ? '$lockedCapsulesCount Sealed Capsule${lockedCapsulesCount > 1 ? 's' : ''}' : 'Time Capsule',
              badge: 'NextMeet+',
              onTap: () {
                if (rel.isPlus) {
                  _showTimeCapsuleInfoDialog(relId, rel);
                } else {
                  _showPlusUpgradeSheet(
                    relId,
                    'Couple Time Capsules ⏳',
                    'Lock secret photos and romantic memories inside a glowing time capsule that only unlocks on a future date (Anniversaries, Valentine\'s Day, Reunions) to surprise each other.',
                    Icons.hourglass_top_rounded,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          VibrationService.light();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.pink.shade50, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6584), Color(0xFFFF8E53)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimeCapsuleInfoDialog(String relId, RelationshipModel rel) {
    VibrationService.light();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top_rounded, color: Colors.amber, size: 24),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Couple Time Capsule ⏳',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Capsules allow you to seal precious photos and love notes until a future milestone date—like your next Anniversary, Valentine\'s Day, or Reunion.\n\nUntil that date arrives, the capsule remains sealed with a glowing countdown!',
              style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_clock_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ready to seal a moment? Tap "+ Add Moment" and turn on "Seal as Time Capsule".',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('GOT IT', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showAddMomentDialog(relId, rel);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('SEAL A MEMORY', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSealedCapsuleDialog(MemoryModel moment) {
    VibrationService.medium();
    final remaining = moment.unlockDate!.difference(DateTime.now());
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1035),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_bottom_rounded, color: Colors.amber, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Time Capsule Sealed ⏳',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Unlocks on ${DateFormat('MMMM dd, yyyy').format(moment.unlockDate!)}',
              style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                days > 0
                    ? 'Opens in $days day${days > 1 ? 's' : ''} and $hours hr${hours > 1 ? 's' : ''} ✨'
                    : 'Opens in $hours hour${hours > 1 ? 's' : ''} ✨',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              moment.location.isNotEmpty ? '📍 ${moment.location}' : '📍 Our Secret Milestone',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 10),
            const Text(
              'This romantic memory is locked with love until that special day arrives! 🔒💖',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CAN\'T WAIT! 💖', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }

  Widget _buildEmptyState(String relId, RelationshipModel rel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: 70),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_library_outlined, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text('No Memories Yet', style: AppTextStyles.h2),
            const SizedBox(height: 10),
            Text(
              'Your love story is just beginning. Save photos, notes, and milestones of your journey together.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _showAddMomentDialog(relId, rel),
              icon: const Icon(Icons.add_a_photo_rounded, size: 18, color: Colors.white),
              label: const Text('Capture Your First Moment', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedMemory(MemoryModel featured, String relId, RelationshipModel rel) {
    return GestureDetector(
      onTap: () => _viewStory(featured, relId, rel),
      child: Container(
        width: double.infinity,
        height: 380,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          boxShadow: AppColors.premiumShadow,
          image: DecorationImage(image: CachedNetworkImageProvider(featured.imageUrl), fit: BoxFit.cover),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.1), Colors.black.withValues(alpha: 0.85)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                child: const Text('LATEST STORY ✨', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 12),
              Text(featured.location, style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 32)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white70),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM dd, yyyy').format(featured.date).toUpperCase(), 
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 10),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.circle)),
                    child: const Text('VIEW STORY', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 10)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreeGrid(List<MemoryModel> moments, String relId, RelationshipModel rel) {
    if (moments.isEmpty) return _buildEmptyState(relId, rel);
    return _buildMomentsGrid(moments, relId, rel);
  }

  Widget _buildPremiumAlbum(List<MemoryModel> moments, String relId, RelationshipModel rel) {
    if (moments.isEmpty) return _buildEmptyState(relId, rel);
    
    final Map<String, List<MemoryModel>> grouped = {};
    for (var m in moments) {
      final key = DateFormat('MMMM yyyy').format(m.date);
      grouped.putIfAbsent(key, () => []).add(m);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) {
      final dateA = DateFormat('MMMM yyyy').parse(a);
      final dateB = DateFormat('MMMM yyyy').parse(b);
      return dateB.compareTo(dateA);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.8), AppColors.primary]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10)],
          ),
          child: Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NEXTMEET+ ALBUM ✨', style: AppTextStyles.bodyS.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    Text('${moments.length} Eternal Memories • Unlimited Vault ✨', style: AppTextStyles.bodyS.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              if (moments.isNotEmpty)
                IconButton(
                  onPressed: () => _showCinematicReels(moments, relId, rel),
                  icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 32),
                  tooltip: 'Play Cinematic Recap',
                ),
            ],
          ),
        ),

        ...sortedKeys.map((month) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 16, top: 8),
                child: Text(month.toUpperCase(), style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 2)),
              ),
              GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.75,
                ),
                itemCount: grouped[month]!.length,
                itemBuilder: (context, index) {
                  final moment = grouped[month]![index];
                  return _buildPolaroidCard(moment, relId, rel);
                },
              ),
              const SizedBox(height: 32),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildStorybookAlbum(List<MemoryModel> moments, String relId, RelationshipModel rel) {
    if (moments.isEmpty) return _buildEmptyState(relId, rel);
    
    return SizedBox(
      height: 600,
      child: _ArchiveBookEngine(
        moments: moments, 
        relId: relId, 
        rel: rel, 
        cloudService: _cloudService
      ),
    );
  }

  void _showCinematicReels(List<MemoryModel> moments, String relId, RelationshipModel rel) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Reels',
      barrierColor: Colors.black,
      pageBuilder: (context, _, _) => _CinematicReelsPage(moments: moments),
    );
  }

  Widget _buildPolaroidCard(MemoryModel moment, String relId, RelationshipModel rel) {
    final isPlus = rel.isPlus;
    final isLocked = moment.isTimeLocked;
    
    return FadeInUp(
      child: GestureDetector(
        onTap: () {
          if (isLocked) {
            _showSealedCapsuleDialog(moment);
          } else {
            _viewStory(moment, relId, rel);
          }
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          decoration: BoxDecoration(
            color: isLocked
                ? const Color(0xFF1E1035)
                : (isPlus ? Colors.white.withValues(alpha: 0.8) : Colors.white),
            borderRadius: BorderRadius.circular(isPlus ? 12 : 4),
            border: isPlus
                ? Border.all(
                    color: isLocked ? Colors.amber.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.1),
                    width: 1.5,
                  )
                : null,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isPlus ? 8 : 2),
                  child: isLocked
                      ? Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF2E1065), Color(0xFF4C1D95)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.hourglass_top_rounded, color: Colors.amber, size: 30),
                              const SizedBox(height: 6),
                              const Text(
                                'TIME CAPSULE',
                                style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Opens ${DateFormat('MMM dd').format(moment.unlockDate!)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )
                      : Stack(
                          children: [
                            Positioned.fill(
                              child: CachedNetworkImage(imageUrl: moment.imageUrl, fit: BoxFit.cover),
                            ),
                            if (isPlus)
                              Positioned(
                                top: 8, right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), shape: BoxShape.circle),
                                  child: const Icon(Icons.star_rounded, color: Colors.white, size: 12),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (isLocked ? 'SEALED CAPSULE' : moment.location).toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Inter', 
                        fontSize: 9, 
                        fontWeight: FontWeight.w900, 
                        letterSpacing: 0.5,
                        color: isLocked ? Colors.amber : (isPlus ? AppColors.primary : AppColors.textPrimary),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLocked ? 'Locked until milestone 🔒' : DateFormat('MMM dd, yyyy').format(moment.date),
                      style: TextStyle(fontSize: 8, color: isLocked ? Colors.white60 : AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMomentsGrid(List<MemoryModel> moments, String relId, RelationshipModel rel) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: moments.length,
      itemBuilder: (context, index) {
        final moment = moments[index];
        final isLocked = moment.isTimeLocked;

        return GestureDetector(
          onTap: () {
            if (isLocked) {
              _showSealedCapsuleDialog(moment);
            } else {
              _viewStory(moment, relId, rel);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppColors.softShadow,
              color: isLocked ? const Color(0xFF1E1035) : null,
              image: isLocked
                  ? null
                  : DecorationImage(image: CachedNetworkImageProvider(moment.imageUrl), fit: BoxFit.cover),
            ),
            child: isLocked
                ? Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E1065), Color(0xFF4C1D95)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.hourglass_top_rounded, color: Colors.amber, size: 36),
                        const SizedBox(height: 8),
                        const Text(
                          'TIME CAPSULE ⏳',
                          style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Unlocks ${DateFormat('MMM dd').format(moment.unlockDate!)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            moment.location, 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _StoryPage extends StatefulWidget {
  final MemoryModel moment;
  final String relId;
  final RelationshipModel rel;
  final CloudRelationshipService cloudService;

  const _StoryPage({required this.moment, required this.relId, required this.rel, required this.cloudService});

  @override
  State<_StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<_StoryPage> {
  final TextEditingController _editController = TextEditingController();
  bool get _isUser1 => widget.cloudService.currentUid == widget.rel.uid1;

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  Future<void> _deleteMoment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Memory?'),
        content: const Text('Are you sure you want to remove this beautiful moment from your journey?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.cloudService.deleteMemory(widget.relId, widget.moment.id!, widget.moment.imageUrl);
      VibrationService.medium();
      if (mounted) Navigator.pop(context);
    }
  }

  void _showEditCaption() {
    _editController.text = _isUser1 ? (widget.moment.partner1Caption ?? '') : (widget.moment.partner2Caption ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your Perspective ✍️', style: AppTextStyles.h3),
              const SizedBox(height: 16),
              TextField(
                controller: _editController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'What were you thinking in this moment?'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_isUser1) {
                      await widget.cloudService.updateMemoryCaptions(widget.relId, widget.moment.id!, p1Caption: _editController.text);
                    } else {
                      await widget.cloudService.updateMemoryCaptions(widget.relId, widget.moment.id!, p2Caption: _editController.text);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('SAVE CAPTION'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: widget.moment.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent, Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStoryBadge(DateFormat('MMMM dd, yyyy').format(widget.moment.date).toUpperCase()),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _deleteMoment,
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  FadeInUp(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.moment.location, style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 36)),
                        const SizedBox(height: 24),
                        const Text('OUR PERSPECTIVES', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        const SizedBox(height: 12),
                        _buildPerspectiveTile(
                          _isUser1 ? 'YOU SAID' : 'PARTNER SAID', 
                          widget.moment.partner1Caption ?? 'No thoughts yet...', 
                          () { if (_isUser1) _showEditCaption(); }
                        ),
                        const SizedBox(height: 12),
                        _buildPerspectiveTile(
                          !_isUser1 ? 'YOU SAID' : 'PARTNER SAID', 
                          widget.moment.partner2Caption ?? 'No thoughts yet...', 
                          () { if (!_isUser1) _showEditCaption(); }
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white30)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
    );
  }

  Widget _buildPerspectiveTile(String label, String content, VoidCallback onTap) {
    bool isMine = label.contains('YOU');
    return GestureDetector(
      onTap: isMine ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMine ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05), 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: isMine ? AppColors.primary.withValues(alpha: 0.3) : Colors.white10)
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: isMine ? AppColors.primary : Colors.white30, fontSize: 8, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: Text(content, style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4)),
                ),
              ],
            ),
            const Spacer(),
            if (isMine) const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _CinematicReelsPage extends StatefulWidget {
  final List<MemoryModel> moments;
  const _CinematicReelsPage({required this.moments});

  @override
  State<_CinematicReelsPage> createState() => _CinematicReelsPageState();
}

class _CinematicReelsPageState extends State<_CinematicReelsPage> {
  int _currentIndex = 0;
  Timer? _reelsTimer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _reelsTimer?.cancel();
    if (widget.moments.length > 1) {
      _reelsTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.moments.length;
        });
      });
    }
  }

  void _nextReel() {
    if (widget.moments.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.moments.length;
    });
    _startTimer();
  }

  void _prevReel() {
    if (widget.moments.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 + widget.moments.length) % widget.moments.length;
    });
    _startTimer();
  }

  @override
  void dispose() {
    _reelsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moment = widget.moments[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(seconds: 1),
              child: CachedNetworkImage(
                key: ValueKey(moment.id),
                imageUrl: moment.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: List.generate(widget.moments.length, (index) {
                      return Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: index <= _currentIndex ? Colors.white : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildReelBadge(moment.location.toUpperCase()),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
                      ),
                    ],
                  ),
                  const Spacer(),
                  FadeInUp(
                    key: ValueKey('content_$_currentIndex'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(moment.date).toUpperCase(),
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          moment.location,
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        if (moment.caption.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              moment.caption,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5, fontStyle: FontStyle.italic),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              children: [
                Expanded(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _prevReel)),
                Expanded(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _nextReel)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReelBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
    );
  }
}

class _ArchiveBookEngine extends StatefulWidget {
  final List<MemoryModel> moments;
  final String relId;
  final RelationshipModel rel;
  final CloudRelationshipService cloudService;

  const _ArchiveBookEngine({required this.moments, required this.relId, required this.rel, required this.cloudService});

  @override
  State<_ArchiveBookEngine> createState() => _ArchiveBookEngineState();
}

class _ArchiveBookEngineState extends State<_ArchiveBookEngine> {
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _pageController.addListener(() { setState(() { _currentPage = _pageController.page ?? 0; }); });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.moments.length,
      clipBehavior: Clip.none,
      itemBuilder: (context, index) {
      // ignore: deprecated_member_use
        final moment = widget.moments[index];
        double delta = index - _currentPage;
        double rotation = (delta * 0.45).clamp(-0.8, 0.8);
        return Transform(
          transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(rotation)..translate(delta * 15.0, delta.abs() * 40.0, 0),
          alignment: delta > 0 ? Alignment.centerLeft : Alignment.centerRight,
          child: _ArchivePageContent(moment: moment, relId: widget.relId, rel: widget.rel, cloudService: widget.cloudService, isCurrent: delta.abs() < 0.1),
        );
      },
    );
  }
}

class _ArchivePageContent extends StatelessWidget {
  final MemoryModel moment;
  final String relId;
  final RelationshipModel rel;
  final CloudRelationshipService cloudService;
  final bool isCurrent;

  const _ArchivePageContent({required this.moment, required this.relId, required this.rel, required this.cloudService, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 25),
      decoration: BoxDecoration(
        color: const Color(0xFFF4ECD8),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 25, offset: const Offset(8, 12)), BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 1, spreadRadius: -3, offset: const Offset(-2, 0))],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Colors.black.withValues(alpha: 0.08), Colors.transparent, Colors.transparent, Colors.black.withValues(alpha: 0.05)])))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                        ),
                        child: ClipRRect(
                          child: CachedNetworkImage(
                            imageUrl: moment.imageUrl,
                            height: 280,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 280,
                              color: Colors.brown.shade100,
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, error) => const SizedBox(
                              height: 280,
                              child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                            ),
                          ),
                        ),
                      ),
                      _buildAntiqueCorner(Alignment.topLeft),
                      _buildAntiqueCorner(Alignment.topRight),
                      _buildAntiqueCorner(Alignment.bottomLeft),
                      _buildAntiqueCorner(Alignment.bottomRight),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moment.location.toUpperCase(),
                      style: TextStyle(fontFamily: 'serif', fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.2, color: Colors.brown.shade800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('MMM dd, yyyy').format(moment.date),
                      style: TextStyle(fontFamily: 'serif', fontSize: 12, fontStyle: FontStyle.italic, color: Colors.brown.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showInkJournal(context),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        moment.caption.isEmpty ? 'Tap to scribe the memory...' : moment.caption,
                        style: const TextStyle(fontFamily: 'GreatVibes', fontSize: 22, height: 1.4, color: Color(0xFF2C3E50)),
                      ),
                    ),
                  ),
                ),
                const Divider(color: Colors.black12, thickness: 0.8),
                Center(child: Text('Eternal Archive 📜 Signature Series', style: TextStyle(fontSize: 8, color: Colors.brown.withValues(alpha: 0.35), letterSpacing: 1.8, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAntiqueCorner(Alignment alignment) {
    return Positioned(
      top: alignment.y == -1 ? 0 : null,
      bottom: alignment.y == 1 ? 0 : null,
      left: alignment.x == -1 ? 0 : null,
      right: alignment.x == 1 ? 0 : null,
      child: Transform.rotate(
        angle: (alignment.x * alignment.y) * 0.78,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey.shade400.withValues(alpha: 0.4),
            border: Border.all(color: Colors.white24, width: 0.5),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }

  void _showInkJournal(BuildContext context) {
    final controller = TextEditingController(text: moment.caption);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF4ECD8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 28,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ink & Quill 🖋️', style: TextStyle(fontFamily: 'serif', fontSize: 26, fontWeight: FontWeight.bold, color: Colors.brown)),
            const SizedBox(height: 18),
            TextField(
              controller: controller,
              maxLines: 7,
              autofocus: true,
              style: const TextStyle(fontFamily: 'serif', fontSize: 17, color: Color(0xFF2C3E50), height: 1.5),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Describe this moment poetically...',
                hintStyle: TextStyle(fontStyle: FontStyle.italic, color: Colors.black26),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await cloudService.updateMemoryCaptions(relId, moment.id!, caption: controller.text);
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('SEAL TO ARCHIVE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMomentBottomSheet extends StatefulWidget {
  final String relId;
  final RelationshipModel rel;
  final CloudRelationshipService cloudService;
  final ImagePicker picker;

  const _AddMomentBottomSheet({
    required this.relId,
    required this.rel,
    required this.cloudService,
    required this.picker,
  });

  @override
  State<_AddMomentBottomSheet> createState() => _AddMomentBottomSheetState();
}

class _AddMomentBottomSheetState extends State<_AddMomentBottomSheet> {
  File? _selectedImage;
  bool _isStory = false;
  bool _isTimeCapsule = false;
  DateTime? _unlockDate;
  bool _isUploading = false;
  String _selectedLocation = '';
  late final TextEditingController _captionController;
  late final TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
    _locationController = TextEditingController();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    VibrationService.light();
    try {
      final XFile? image = await widget.picker.pickImage(
        source: source,
        maxWidth: 1440,
        maxHeight: 1440,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
        VibrationService.light();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access image: $e')),
        );
      }
    }
  }

  Future<void> _saveMoment() async {
    if (_selectedImage == null) {
      VibrationService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or capture a photo first! 📸'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);
    VibrationService.medium();

    try {
      final finalLocation = _selectedLocation.trim().isNotEmpty
          ? _selectedLocation.trim()
          : (_locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : 'Our Journey ❤️');

      await widget.cloudService.addMemory(
        widget.relId,
        _selectedImage!,
        _captionController.text.trim(),
        finalLocation,
        isStory: _isStory,
        unlockDate: _isTimeCapsule ? _unlockDate : null,
      );

      VibrationService.success();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Memory saved to your eternal journey! ✨📸'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        VibrationService.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save memory: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.l,
        right: AppSpacing.l,
        top: AppSpacing.m,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.l,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Capture a Moment 📸',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Preserve this memory in your eternal timeline.',
                        style: AppTextStyles.bodyS.copyWith(
                          color: AppColors.textSecondary,
                        ),
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
            const SizedBox(height: 18),

            // Photo Selection Area
            if (_selectedImage == null) ...[
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickImage(ImageSource.camera),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Take Photo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Open Camera',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickImage(ImageSource.gallery),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF845EC2).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF845EC2).withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF845EC2).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.photo_library_rounded,
                                color: Color(0xFF845EC2),
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'From Gallery',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Select Photo',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 210,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        image: DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () {
                              VibrationService.light();
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                                        title: const Text('Retake with Camera'),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          _pickImage(ImageSource.camera);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF845EC2)),
                                        title: const Text('Choose Another from Gallery'),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          _pickImage(ImageSource.gallery);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh_rounded, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Change',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () {
                              VibrationService.light();
                              setState(() => _selectedImage = null);
                            },
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.close_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),

            // Caption Field
            Text(
              'A SWEET CAPTION (OPTIONAL) 💭',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _captionController,
              maxLines: 2,
              minLines: 1,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'What made this moment unforgettable?',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                filled: true,
                fillColor: AppColors.background,
                prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.pink.shade50),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location Autocomplete Field
            Text(
              'LOCATION 📍',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 6),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return CityData.majorCities
                    .map((c) => c.name)
                    .where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selection) {
                _selectedLocation = selection;
                _locationController.text = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: (v) => _selectedLocation = v,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Where did this happen? (e.g. Paris, Eiffel Tower)',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                    filled: true,
                    fillColor: AppColors.background,
                    prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.pink.shade50),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Daily Story Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: _isStory
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isStory
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : Colors.pink.shade50,
                ),
              ),
              child: SwitchListTile(
                value: _isStory,
                onChanged: (v) {
                  VibrationService.light();
                  setState(() => _isStory = v);
                },
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                title: const Row(
                  children: [
                    Text(
                      'Pin to Daily Stories ✨',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Highlight at the top of your shared timeline for 24 hours',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Time Capsule Toggle (NextMeet+ Exclusive Feature)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: _isTimeCapsule
                    ? Colors.amber.withValues(alpha: 0.08)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isTimeCapsule
                      ? Colors.amber.shade300
                      : Colors.pink.shade50,
                ),
              ),
              child: SwitchListTile(
                value: _isTimeCapsule,
                onChanged: (v) async {
                  VibrationService.light();
                  if (!widget.rel.isPlus) {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NextMeetPlusScreen(relId: widget.relId)),
                    );
                    return;
                  }
                  if (v) {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now().add(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                      helpText: 'SELECT TIME CAPSULE UNLOCK DATE ⏳',
                    );
                    if (picked != null) {
                      setState(() {
                        _isTimeCapsule = true;
                        _unlockDate = picked;
                      });
                    }
                  } else {
                    setState(() {
                      _isTimeCapsule = false;
                      _unlockDate = null;
                    });
                  }
                },
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.amber.shade700,
                title: Row(
                  children: [
                    const Text(
                      'Seal as Time Capsule ⏳',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6584), Color(0xFFFF8E53)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Plus ✨',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  _isTimeCapsule && _unlockDate != null
                      ? 'Sealed until ${DateFormat('MMMM dd, yyyy').format(_unlockDate!)} 🔒'
                      : 'Lock this memory until a future anniversary or milestone',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isTimeCapsule ? Colors.amber.shade900 : AppColors.textSecondary.withValues(alpha: 0.8),
                    fontWeight: _isTimeCapsule ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Action Button
            if (_isUploading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Preserving your memory... ✨',
                        style: AppTextStyles.bodyM.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveMoment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 3,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  child: const Text(
                    'SAVE TO OUR JOURNEY ❤️',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
