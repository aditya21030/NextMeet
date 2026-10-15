import 'package:flutter/material.dart';
import '../../core/services/vibration_service.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/primary_button.dart';
import '../../core/models/milestone_model.dart';
import '../../core/models/relationship_model.dart';
import '../../core/achievements_data.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AchievementsScreen extends StatefulWidget {
  final RelationshipModel relationship;

  const AchievementsScreen({super.key, required this.relationship});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  final List<Milestone> _allMilestones = AchievementsData.getMilestones();
  late Map<String, List<Milestone>> _categorizedMilestones;
  late List<String> _categories;
  int _selectedCategoryIndex = 0; // 0 for "All", 1+ for specific categories

  @override
  void initState() {
    super.initState();
    _groupMilestones();
  }

  void _groupMilestones() {
    _categorizedMilestones = {};
    _categories = [
      'STREAKS',
      'CONNECTION',
      'MEMORIES',
      'TRIPS',
      'PRIVATE SPACE',
      'SPECIAL'
    ];

    for (var category in _categories) {
      _categorizedMilestones[category] = _allMilestones
          .where((m) => m.category == category)
          .toList();
    }
  }

  Milestone? _getNextMilestone(Map<String, int> stats) {
    List<Milestone> incomplete = _allMilestones.where((m) => !m.isUnlocked(stats)).toList();
    if (incomplete.isEmpty) return null;

    // Sort by progress descending
    incomplete.sort((a, b) => b.getProgress(stats).compareTo(a.getProgress(stats)));
    return incomplete.first;
  }



  @override
  Widget build(BuildContext context) {
    // Sync streakCount into stats for accurate milestone tracking
    final stats = Map<String, int>.from(widget.relationship.stats);
    stats['streak'] = widget.relationship.streakCount;
    
    final nextMilestone = _getNextMilestone(stats);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
                  child: _buildOverallProgress(stats),
                ),
                if (nextMilestone != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                    child: _buildNextMilestoneSpotlight(nextMilestone, stats),
                  ),
                _buildCategoryChips(),
              ],
            ),
          ),
          if (_selectedCategoryIndex == 0)
            ..._categories.map((category) => _buildCategorySection(category, stats))
          else
            _buildCategorySection(_categories[_selectedCategoryIndex - 1], stats),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final chips = ['ALL', ..._categories];
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.m),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        itemCount: chips.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(chips[index]),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategoryIndex = index);
                }
              },
              labelStyle: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              elevation: isSelected ? 4 : 0,
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildNextMilestoneSpotlight(Milestone m, Map<String, int> stats) {
    final progress = m.getProgress(stats);
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'NEXT UP',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}% COMPLETE',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(m.icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      m.subTitle,
                      style: GoogleFonts.outfit(fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showAchievementDetails(m, stats),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Finish this task',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Milestone Hub',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withValues(alpha: 0.05), AppColors.background],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverallProgress(Map<String, int> stats) {
    int unlockedTotal = _allMilestones.where((m) => m.isUnlocked(stats)).length;
    double progress = unlockedTotal / _allMilestones.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Progress', style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
                  Text(
                    unlockedTotal >= _allMilestones.length ? 'Ultimate Couple ♾️' : 'Rising Legends ✨',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
              Text(
                '$unlockedTotal / ${_allMilestones.length}',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.primary.withValues(alpha: 0.05),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String category, Map<String, int> stats) {
    final milestones = _categorizedMilestones[category] ?? [];
    if (milestones.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    int unlockedCount = milestones.where((m) => m.isUnlocked(stats)).length;

    IconData categoryIcon = Icons.star_rounded;
    switch(category) {
      case 'STREAKS': categoryIcon = Icons.local_fire_department_rounded; break;
      case 'CONNECTION': categoryIcon = Icons.favorite_rounded; break;
      case 'MEMORIES': categoryIcon = Icons.camera_alt_rounded; break;
      case 'TRIPS': categoryIcon = Icons.public_rounded; break;
      case 'PRIVATE SPACE': categoryIcon = Icons.lock_rounded; break;
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.xl, AppSpacing.l, AppSpacing.m),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(categoryIcon, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      category,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$unlockedCount/${milestones.length} UNLOCKED',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildBadgeCard(milestones[index], stats);
              },
              childCount: milestones.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeCard(Milestone m, Map<String, int> stats) {
    final isUnlocked = m.isUnlocked(stats);
    final progress = m.getProgress(stats);

    return FadeInUp(
      child: GestureDetector(
        onTap: () {
          VibrationService.light();
          _showAchievementDetails(m, stats);
        },
        child: _AwardShimmer(
          enabled: isUnlocked,
          child: Container(
            decoration: BoxDecoration(
              color: isUnlocked ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isUnlocked 
                  ? m.color.withValues(alpha: 0.4) 
                  : Colors.grey.withValues(alpha: 0.1),
                width: 1.5,
              ),
              boxShadow: [
                if (isUnlocked)
                  BoxShadow(
                    color: m.color.withValues(alpha: 0.2),
                    blurRadius: 25,
                    spreadRadius: -2,
                    offset: const Offset(0, 10),
                  ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  // Metallic/Glassy Background for Unlocked
                  if (isUnlocked)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              m.color.withValues(alpha: 0.15),
                              Colors.transparent,
                              m.color.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        // THE AWARD ORB / HEXAGON
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Background Glow
                              if (isUnlocked)
                                FadeIn(
                                  child: Container(
                                    width: 75,
                                    height: 75,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: m.color.withValues(alpha: 0.3),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              
                              // The Frame
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: isUnlocked ? const Color(0xFF2A2A3E) : Colors.grey.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(22), // Squircle/Hex-like
                                  border: Border.all(
                                    color: isUnlocked ? m.color : Colors.grey.withValues(alpha: 0.2),
                                    width: 2,
                                  ),
                                  gradient: isUnlocked ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      m.color,
                                      m.color.withValues(alpha: 0.7),
                                      m.color.withAlpha(200),
                                    ],
                                  ) : null,
                                ),
                                child: Center(
                                  child: Icon(
                                    isUnlocked ? m.icon : Icons.lock_rounded,
                                    color: isUnlocked ? Colors.white : Colors.grey.withValues(alpha: 0.3),
                                    size: 32,
                                  ),
                                ),
                              ),

                              // Progress Ring for Locked (SQUIRCLE PATH)
                              if (!isUnlocked && progress > 0)
                                SizedBox(
                                  width: 82,
                                  height: 82,
                                  child: CustomPaint(
                                    painter: _SquircleProgressPainter(
                                      progress: progress,
                                      color: m.color.withValues(alpha: 0.6),
                                      strokeWidth: 3.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 18),
                        
                        // Text Labels
                        Text(
                          m.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isUnlocked ? Colors.white : AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.subTitle.toUpperCase(),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: isUnlocked ? m.color.withValues(alpha: 0.8) : Colors.grey.shade400,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        
                        // Status Badge
                        if (isUnlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: m.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: m.color.withValues(alpha: 0.3), width: 0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                                  child: const Icon(Icons.stars_rounded, color: Colors.white, size: 10),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'COLLECTED',
                                  style: TextStyle(
                                    color: m.color,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            '${(progress * 100).toInt()}% READY',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // TOP-RIGHT GLASS GLINT
                  if (isUnlocked)
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAchievementDetails(Milestone milestone, Map<String, int> stats) {
    final bool isUnlocked = milestone.isUnlocked(stats);
    final double overallProgress = milestone.getProgress(stats);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: const BoxDecoration(
          color: Color(0xFF16161E), // Premium Dark
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 30),
            
            // THE PREMIUM ORB (CONSISTENT)
            _AwardShimmer(
              enabled: isUnlocked,
              child: _PremiumAwardOrb(
                milestone: milestone,
                isUnlocked: isUnlocked,
                progress: overallProgress,
                size: 140,
              ),
            ),
            
            const SizedBox(height: 24),
            Text(
              milestone.title, 
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              milestone.description,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'REQUIREMENTS', 
                style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),
            ...milestone.tasks.map((task) {
              final current = (stats[task.id] ?? 0).clamp(0, task.targetValue); // BUG FIX: Clamp to target
              final progress = (current / task.targetValue).clamp(0.0, 1.0);
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(task.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(
                        '$current / ${task.targetValue}', 
                        style: TextStyle(color: milestone.color, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(milestone.color),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 40),
            if (isUnlocked)
              PrimaryButton(
                text: 'Share My Badge ✨',
                onPressed: () {
                  Navigator.pop(context);
                  _showSharePreview(milestone);
                },
                color: milestone.color,
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_rounded, size: 18, color: Colors.white24),
                      const SizedBox(width: 10),
                      Text(
                        'LOCKED', 
                        style: GoogleFonts.outfit(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- SHARE PREVIEW ---
  void _showSharePreview(Milestone milestone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: Color(0xFF16161E), // Match Premium Dark
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text('Preview Image', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: _buildShareCard(milestone),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: PrimaryButton(
                text: 'SHARE TO STORY 🚀',
                onPressed: () {
                  Navigator.pop(context);
                  _shareBadge(milestone);
                },
                color: milestone.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareCard(Milestone milestone) {
    // Safety Container to prevent edge clipping during RepaintBoundary capture
    return Container(
      width: 340, // Slightly wider for shadow safety
      height: 600, // Slightly taller for shadow safety
      padding: const EdgeInsets.all(10), // Shadow safety margin
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0812), Color(0xFF1E1E2E)],
          ),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: milestone.color.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: milestone.color.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const Text(
              'MILESTONE UNLOCKED',
              style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 3),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // PREMIUM ORB IN SHARE
            _PremiumAwardOrb(
              milestone: milestone,
              isUnlocked: true,
              progress: 1.0,
              size: 160,
            ),
            
            const SizedBox(height: 50),
            Text(
              milestone.title,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1.1),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
             Text(
              milestone.subTitle.toUpperCase(),
              style: TextStyle(color: milestone.color, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              '"${milestone.description}"',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'NextMeet',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareBadge(Milestone milestone) async {
    try {
      RenderRepaintBoundary boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/badge_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await imagePath.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: 'I just unlocked the "${milestone.title}" badge on NextMeet! ✨🚀',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
    }
  }
}
}

class _AwardShimmer extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const _AwardShimmer({required this.child, required this.enabled});

  @override
  State<_AwardShimmer> createState() => _AwardShimmerState();
}

class _AwardShimmerState extends State<_AwardShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.5),
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
              transform: _SlidingGradientTransform(_controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double offset;
  const _SlidingGradientTransform(this.offset);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (offset * 3 - 1.5), 0, 0);
  }
}

class _PremiumAwardOrb extends StatelessWidget {
  final Milestone milestone;
  final bool isUnlocked;
  final double progress;
  final double size;

  const _PremiumAwardOrb({
    required this.milestone,
    required this.isUnlocked,
    required this.progress,
    this.size = 82,
  });

  @override
  Widget build(BuildContext context) {
    final double iconSize = size * 0.4;
    final double innerSize = size * 0.85;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow
          if (isUnlocked)
            Container(
              width: size * 0.9,
              height: size * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: milestone.color.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),

          // Inner Orb/Medal
          Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isUnlocked
                    ? [milestone.color.withValues(alpha: 0.3), milestone.color.withValues(alpha: 0.1)]
                    : [Colors.grey.withValues(alpha: 0.1), Colors.grey.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(innerSize * 0.35),
              border: Border.all(
                color: isUnlocked ? milestone.color.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                milestone.icon,
                color: isUnlocked ? milestone.color : Colors.grey.withValues(alpha: 0.3),
                size: iconSize,
              ),
            ),
          ),

          // Progress Ring for Locked (SQUIRCLE PATH)
          if (!isUnlocked && progress > 0)
            SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _SquircleProgressPainter(
                  progress: progress,
                  color: milestone.color.withValues(alpha: 0.6),
                  strokeWidth: 3.5,
                ),
              ),
            ),
            
          // Inner Glint
          Positioned(
             top: size * 0.15,
             left: size * 0.15,
             child: Container(
               width: size * 0.3,
               height: size * 0.1,
               decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(10),
                 gradient: LinearGradient(
                   colors: [Colors.white.withValues(alpha: 0.2), Colors.transparent],
                 ),
               ),
             ),
          ),
        ],
      ),
    );
  }
}

class _SquircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _SquircleProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.3));
    final path = Path()..addRRect(rrect);

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      final extractPath = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(_SquircleProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
