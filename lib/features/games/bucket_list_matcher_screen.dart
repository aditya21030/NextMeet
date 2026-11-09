import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import 'game_win_modal.dart';

/// NextMeet Date Night Speed Match (Bucket List Swipe)
/// Swipe right on date ideas to find mutual romantic dreams!
class BucketListMatcherScreen extends StatefulWidget {
  final String? relId;
  final String? partnerName;
  const BucketListMatcherScreen({super.key, this.relId, this.partnerName});

  @override
  State<BucketListMatcherScreen> createState() => _BucketListMatcherScreenState();
}

class _BucketListMatcherScreenState extends State<BucketListMatcherScreen> {
  int _currentIndex = 0;
  final List<String> _matchedDates = [];

  final List<Map<String, dynamic>> _dateIdeas = [
    {
      'title': 'Sunset Picnic by the Water',
      'emoji': '🌅',
      'category': 'Outdoor',
      'desc': 'Pack strawberries, cheese, sparkling cider, and watch golden hour melt into night.',
      'partnerLikes': true,
    },
    {
      'title': 'Late Night Drive with Lo-Fi Beats',
      'emoji': '🚗',
      'category': 'Spontaneous',
      'desc': 'Empty highway, windows cracked open, holding hands while singing along.',
      'partnerLikes': true,
    },
    {
      'title': 'Pottery & Clay Sculpting Class',
      'emoji': '🏺',
      'category': 'Creative',
      'desc': 'Get messy hands making custom couple mugs for each other.',
      'partnerLikes': true,
    },
    {
      'title': 'Snowy Mountain Cabin with Jacuzzi',
      'emoji': '🏔️',
      'category': 'Getaway',
      'desc': 'Wood-burning fireplace, hot cocoa, and steamy outdoor hot tub under falling snow.',
      'partnerLikes': true,
    },
    {
      'title': 'Cook a 4-Course French Meal',
      'emoji': '🍳',
      'category': 'Foodie',
      'desc': 'Tie our aprons together, open a bottle of wine, and master a gourmet recipe.',
      'partnerLikes': false,
    },
  ];

  void _onSwipe(bool isYes) {
    if (_currentIndex >= _dateIdeas.length) return;

    final idea = _dateIdeas[_currentIndex];
    if (isYes) {
      VibrationService.medium();
      if (idea['partnerLikes'] == true) {
        _matchedDates.add(idea['title'] as String);
        VibrationService.success();
        // Add to cloud bucket list automatically!
        if (widget.relId != null) {
          CloudRelationshipService().addBucketItem(widget.relId!, idea['title'] as String, 'Date Night');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('It\'s a Match! Added "${idea['title']}" to your Bucket List! 💕'),
            backgroundColor: AppColors.primary,
            duration: const Duration(milliseconds: 1400),
          ),
        );
      }
    } else {
      VibrationService.light();
    }

    setState(() {
      _currentIndex++;
    });

    if (_currentIndex >= _dateIdeas.length) {
      if (widget.relId != null) {
        CloudRelationshipService().addCoupleXp(widget.relId!, 130);
      }
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        GameWinModal.show(
          context,
          gameTitle: 'Date Night Speed Match',
          winnerName: '${_matchedDates.length} Date Matches Found!',
          partnerName: widget.partnerName ?? 'Partner',
          score1: _matchedDates.length,
          score2: _dateIdeas.length,
          xpEarned: 130,
          onRematch: () => setState(() {
            _currentIndex = 0;
            _matchedDates.clear();
          }),
          relId: widget.relId,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _currentIndex >= _dateIdeas.length;
    final currentIdea = isDone ? null : _dateIdeas[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Top Bar
              Row(
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
                      'Date Night Match',
                      style: AppTextStyles.title2.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.mintSoft,
                      borderRadius: BorderRadius.circular(AppRadius.badge),
                    ),
                    child: Text(
                      '${_matchedDates.length} Matches',
                      style: AppTextStyles.caption.copyWith(color: AppColors.mintText, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                'Swipe right on dates you want to do. If you both say YES, it\'s a match!',
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Swipable Card
              if (!isDone && currentIdea != null)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: AppColors.border, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(currentIdea['emoji'] as String, style: const TextStyle(fontSize: 64)),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.partnerSoft,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            currentIdea['category'] as String,
                            style: AppTextStyles.caption.copyWith(color: AppColors.partnerText, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          currentIdea['title'] as String,
                          style: AppTextStyles.title1.copyWith(fontSize: 24),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          currentIdea['desc'] as String,
                          style: AppTextStyles.body.copyWith(color: AppColors.muted, height: 1.35),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Expanded(
                  child: Center(
                    child: Text('All date ideas reviewed! 🎉'),
                  ),
                ),

              const SizedBox(height: 24),

              // Swipe Action Buttons (Pass vs Love)
              if (!isDone)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => _onSwipe(false),
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.close_rounded, color: AppColors.muted, size: 32),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _onSwipe(true),
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 36),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
