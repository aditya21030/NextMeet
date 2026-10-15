import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';
import '../../core/models/milestone_model.dart';
import '../../widgets/love_constellation.dart';
import '../../widgets/glass_card.dart';
import '../home/achievements_screen.dart';
import '../../core/achievements_data.dart';
import '../../widgets/sync_error_widget.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  Stream<RelationshipModel?>? _relationshipStream;
  Stream<QuerySnapshot>? _activitiesStream;
  String? _lastRelId;
      // ignore: unused_field
  int _memoryCount = 0;
  int _touchCount = 0;
  
  // Memoization
  QuerySnapshot? _lastActivitySnapshot;
  Map<DateTime, int> _cachedActivityMap = {};

  @override
  void initState() {
    super.initState();
    _relationshipStream = _cloudService.streamRelationship();
  }

  // Activity processing for heatmap and badge counting
  Map<DateTime, int> _processActivityData(QuerySnapshot? snapshot) {
    final Map<DateTime, int> data = {};
    _memoryCount = 0;
    _touchCount = 0;
    
    if (snapshot == null) return data;
    
    for (var doc in snapshot.docs) {
      final type = doc['type'] as String?;
      if (type == 'memory') _memoryCount++;
      if (type == 'nudge') _touchCount++;

      final timestamp = doc['timestamp'] as Timestamp?;
      if (timestamp != null) {
        final date = DateTime(timestamp.toDate().year, timestamp.toDate().month, timestamp.toDate().day);
        data[date] = (data[date] ?? 0) + 1;
      }
    }
    return data;
  }

  // Removed Connection Missions as requested

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _relationshipStream,
      builder: (context, relSnapshot) {
        if (relSnapshot.hasError) {
          return Scaffold(
            body: SyncErrorWidget(
              errorMessage: 'Failed to sync your streak data.',
              onRetry: () => setState(() {}),
            ),
          );
        }

        if (!relSnapshot.hasData || relSnapshot.data?.id == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final rel = relSnapshot.data!;
        final relId = rel.id!;
        if (_lastRelId != relId) {
          _lastRelId = relId;
          _activitiesStream = _cloudService.streamActivities(relId);
          // Trigger streak update once on load
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _cloudService.updateActivityAndStreak(relId, rel);
          });
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: StreamBuilder<QuerySnapshot>(
            stream: _activitiesStream,
            builder: (context, activitySnapshot) {
              if (activitySnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: SyncErrorWidget(
                      errorMessage: 'Failed to sync activity heatmap.',
                      onRetry: () => setState(() {}),
                    ),
                  ),
                );
              }
              
              // Optimization: Only reprocess if snapshot changed
              if (activitySnapshot.data != _lastActivitySnapshot) {
                _lastActivitySnapshot = activitySnapshot.data;
                _cachedActivityMap = _processActivityData(activitySnapshot.data);
              }
              final activityMap = _cachedActivityMap;

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 0,
                    floating: true,
                    backgroundColor: AppColors.background,
                    elevation: 0,
                    title: const SizedBox.shrink(),
                    centerTitle: false,
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeInDown(child: _buildStreakCard(rel)),
                          const SizedBox(height: AppSpacing.xl),
                          
                          // Replacement for Daily Reminder: Constellation Love Map
                          FadeInDown(
                            delay: const Duration(milliseconds: 100), 
                            child: RepaintBoundary(
                              child: LoveConstellation(activityData: activityMap, year: 2026)
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          
                          // Restored Relationship Roadmap
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Relationship Roadmap 🏆', style: AppTextStyles.h3),
                              TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AchievementsScreen(relationship: rel))),
                                child: Text('View Hub →', style: AppTextStyles.bodyS.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.l),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                    sliver: _buildRelationshipRoadmap(rel.streakCount, rel),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              );
            }
          ),
        );
      }
    );
  }

  Widget _buildStreakCard(RelationshipModel rel) {
    final streakDays = rel.streakCount;
    
    // Define Achievements (Premium Naming)
    final streakMilestones = AchievementsData.getMilestones()
        .where((m) => m.category == 'STREAKS')
        .toList();
    
    Milestone? currentM;
    Milestone? nextM;

    for (var m in streakMilestones) {
      if (streakDays >= m.daysRequired) {
        currentM = m;
      } else {
        nextM = m;
        break;
      }
    }

    String badge = currentM?.title ?? "Soul Connection ✨";
    IconData badgeIcon = currentM?.icon ?? Icons.auto_awesome_rounded;
    Color badgeColor = currentM?.color ?? Colors.pinkAccent;
      // ignore: unused_local_variable
    int targetStreak = nextM?.daysRequired ?? 7;
    int currentMilestoneBase = currentM?.daysRequired ?? 0;

    final double progress = (streakDays / targetStreak);
    final finalProgress = progress.clamp(0.005, 1.0);
    final level = (streakDays / 31).floor() + 1;


    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Row(
            children: [
              Pulse(
                infinite: true,
                duration: const Duration(seconds: 2),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: badgeColor.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 2),
                    ],
                  ),
                  child: Icon(badgeIcon, color: badgeColor, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(badge, style: AppTextStyles.h3.copyWith(color: badgeColor, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    Text('$streakDays Day Journey 🔥', style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              _buildFloatingBadge('LEVEL $level'),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(color: AppColors.background.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4)),
                    ),
                    FractionallySizedBox(
                      widthFactor: finalProgress,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [badgeColor, badgeColor.withValues(alpha: 0.6)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(color: badgeColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 22),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                streakDays >= 2000 ? 'Ultimate Achievement!' : 'Next: $targetStreak Days Milestone', 
                style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.textPrimary.withValues(alpha: 0.6)),
              ),
              Text('${(finalProgress * 100).toInt()}%', style: AppTextStyles.bodyS.copyWith(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipRoadmap(int currentStreak, RelationshipModel rel) {
    final List<Milestone> milestones = AchievementsData.getMilestones()
        .where((m) => m.category == 'STREAKS')
        .toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final m = milestones[index];
          final bool isUnlocked = currentStreak >= m.daysRequired;
          final bool isCurrent = index == 0 ? (currentStreak < milestones[1].daysRequired) : 
                               (index == milestones.length - 1 ? isUnlocked : 
                               (isUnlocked && (index + 1 < milestones.length && currentStreak < milestones[index + 1].daysRequired)));

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.m),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline Connector
                Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isUnlocked ? m.color.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.03),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrent ? m.color.withValues(alpha: 0.5) : (isUnlocked ? m.color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1)),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          isUnlocked ? m.icon : Icons.lock_outline_rounded,
                          color: isUnlocked ? m.color.withValues(alpha: 0.8) : Colors.grey.withValues(alpha: 0.3),
                          size: 18,
                        ),
                      ),
                    ),
                    if (index != milestones.length - 1)
                      Container(
                        width: 2,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              isUnlocked ? m.color.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.1),
                              (index + 1 < milestones.length && currentStreak >= milestones[index+1].daysRequired) 
                                  ? milestones[index+1].color.withValues(alpha: 0.5) 
                                  : Colors.grey.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.m),
                
                // Content Card
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    color: isCurrent ? m.color.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05),
                    borderRadius: 16,
                    useBlur: false, // PERFORMANCE: Disable blur for smooth scrolling
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(m.title, style: AppTextStyles.bodyM.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked ? AppColors.textPrimary : Colors.grey,
                                  fontSize: 15,
                                )),
                              ),
                              if (isUnlocked) 
                                Icon(Icons.stars_rounded, color: m.color.withValues(alpha: 0.6), size: 16),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(m.subTitle, style: AppTextStyles.bodyS.copyWith(
                            color: isUnlocked ? m.color : Colors.grey,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            fontSize: 10,
                          )),
                          const SizedBox(height: 8),
                          Text(m.description, style: AppTextStyles.bodyS.copyWith(
                            color: AppColors.textSecondary.withValues(alpha: isUnlocked ? 0.9 : 0.5),
                            fontSize: 11,
                            height: 1.4,
                          )),
                          if (!isUnlocked) ...[
                            const SizedBox(height: 12),
                            // Small progress bar for locked milestones
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: (currentStreak / m.daysRequired).clamp(0.01, 1.0),
                                backgroundColor: Colors.grey.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(m.color.withValues(alpha: 0.3)),
                                minHeight: 4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${m.daysRequired - currentStreak} days to go',
                              style: AppTextStyles.bodyS.copyWith(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                  ),
                ),
              ],
            ),
          );
        },
        childCount: milestones.length,
      ),
    );
  }



  Widget _buildFloatingBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Text(
        text, 
        style: TextStyle(
          color: AppColors.primary, 
          fontSize: 9, 
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
      // ignore: unused_element
  }

  Widget _buildSparkTile(BuildContext context, String title, String subtitle, IconData icon, Color color, Widget destination) {
    return FadeInUp(
      child: GestureDetector(
        onTap: () {
          VibrationService.light();
          Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
        },
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.divider),
            ],
          ),
        ),
      ),
    );
  }
}
