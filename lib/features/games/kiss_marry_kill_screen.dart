import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import 'game_win_modal.dart';

/// NextMeet Kiss, Marry, or Pass (Romantic Couple Edition)
/// Assign one choice to Kiss 💋, one to Marry 💍, and one to Pass 💨!
class KissMarryKillScreen extends StatefulWidget {
  final String? relId;
  final String? partnerName;
  const KissMarryKillScreen({super.key, this.relId, this.partnerName});

  @override
  State<KissMarryKillScreen> createState() => _KissMarryKillScreenState();
}

enum ChoiceBadge { kiss, marry, pass }

class _KissMarryKillScreenState extends State<KissMarryKillScreen> {
  int _currentRound = 0;
  final Map<int, ChoiceBadge> _assignments = {};
  bool _roundSubmitted = false;
  int _compatibilityScore = 0;

  final List<Map<String, dynamic>> _rounds = [
    {
      'title': 'Dreamy Escapes ✈️',
      'subtitle': 'Where does your heart long to run away to?',
      'options': [
        'Private overwater bungalow in the Maldives with sunset deck',
        'Cozy snowed-in Swiss Alps chalet with crackling stone fireplace',
        'Charming rustic cobblestone cottage surrounded by Tuscany vineyards',
      ],
      'idealMarry': 1,
      'idealKiss': 0,
    },
    {
      'title': 'Date Night Vibes 🕯️',
      'subtitle': 'Pick the mood that matches your soul right now',
      'options': [
        'Dressed-to-the-nines rooftop dinner overlooking glittering skyline',
        'Midnight kitchen pajama dance while baking warm cinnamon rolls',
        'Spontaneous open-roof road trip with zero itinerary and top playlist',
      ],
      'idealMarry': 1,
      'idealKiss': 0,
    },
    {
      'title': 'Intimate Gestures 💕',
      'subtitle': 'Which sweet moment melts your heart into butter?',
      'options': [
        'Surprise heartfelt love letter tucked secretly into your coat pocket',
        'Gentle forehead kiss while half-asleep just before morning light',
        'Cooking your favorite comfort food when you have had an exhausting day',
      ],
      'idealMarry': 1,
      'idealKiss': 0,
    },
    {
      'title': 'Unforgettable Memories 🌟',
      'subtitle': 'Which adventure would you replay for a lifetime?',
      'options': [
        'Sunrise hot-air balloon drifting over golden morning clouds',
        'Getting soaked in warm summer rain and laughing together without umbrellas',
        'All-night cozy blanket fort marathon watching nostalgic comfort movies',
      ],
      'idealMarry': 2,
      'idealKiss': 1,
    },
    {
      'title': 'Quiet Romances 🌙',
      'subtitle': 'The subtle things that make love feel like home',
      'options': [
        'Slow dancing in the dimly lit living room with no music playing',
        'Walking in crisp autumn air with both hands linked inside one warm coat pocket',
        'Whispering secrets and giggles under the duvet at 3:00 AM',
      ],
      'idealMarry': 2,
      'idealKiss': 0,
    },
  ];

  void _assignChoice(int optionIndex, ChoiceBadge badge) {
    if (_roundSubmitted) return;
    VibrationService.light();

    setState(() {
      // If another option already had this badge, remove it from that option
      _assignments.removeWhere((key, value) => value == badge);
      _assignments[optionIndex] = badge;
    });
  }

  void _submitRound() {
    if (_assignments.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please assign all 3 choices: Kiss 💋, Marry 💍, and Pass 💨!'),
          duration: Duration(milliseconds: 1400),
        ),
      );
      return;
    }

    VibrationService.medium();
    final round = _rounds[_currentRound];
    int roundPoints = 0;

    // Check romantic alignment
    if (_assignments[round['idealMarry']] == ChoiceBadge.marry) {
      roundPoints += 50;
    }
    if (_assignments[round['idealKiss']] == ChoiceBadge.kiss) {
      roundPoints += 50;
    }

    setState(() {
      _roundSubmitted = true;
      _compatibilityScore += roundPoints;
    });

    VibrationService.success();
  }

  void _nextRound() {
    VibrationService.light();
    if (_currentRound < _rounds.length - 1) {
      setState(() {
        _currentRound++;
        _assignments.clear();
        _roundSubmitted = false;
      });
    } else {
      // Finished all rounds!
      if (widget.relId != null) {
        CloudRelationshipService().addCoupleXp(widget.relId!, 120);
      }
      GameWinModal.show(
        context,
        gameTitle: 'Kiss, Marry, or Pass',
        winnerName: 'Compatibility: ${(_compatibilityScore / 5).clamp(65, 100).toInt()}% Match! 💖',
        partnerName: widget.partnerName ?? 'Partner',
        score1: _compatibilityScore ~/ 5,
        score2: 100,
        xpEarned: 120,
        relId: widget.relId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final round = _rounds[_currentRound];
    final options = (round['options'] as List<String>);
    final allAssigned = _assignments.length == 3;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kiss, Marry, or Pass',
          style: AppTextStyles.title2.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                ),
                child: Text(
                  'Round ${_currentRound + 1}/${_rounds.length}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // Title Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      round['title'] as String,
                      style: AppTextStyles.title1.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      round['subtitle'] as String,
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3 Options to assign
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final assignedBadge = _assignments[index];

                    Color borderColor = AppColors.border;
                    Color cardBg = AppColors.card;
                    if (assignedBadge == ChoiceBadge.kiss) {
                      borderColor = AppColors.primary;
                      cardBg = AppColors.primarySoft.withValues(alpha: 0.3);
                    } else if (assignedBadge == ChoiceBadge.marry) {
                      borderColor = AppColors.butter;
                      cardBg = AppColors.butterSoft.withValues(alpha: 0.3);
                    } else if (assignedBadge == ChoiceBadge.pass) {
                      borderColor = AppColors.partner;
                      cardBg = AppColors.partnerSoft.withValues(alpha: 0.3);
                    }

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: borderColor, width: assignedBadge != null ? 2.0 : 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            options[index],
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Badges Row: Kiss / Marry / Pass buttons
                          Row(
                            children: [
                              _badgeChip(
                                label: '💋 Kiss',
                                badge: ChoiceBadge.kiss,
                                isSelected: assignedBadge == ChoiceBadge.kiss,
                                activeColor: AppColors.primary,
                                onSelect: () => _assignChoice(index, ChoiceBadge.kiss),
                              ),
                              const SizedBox(width: 8),
                              _badgeChip(
                                label: '💍 Marry',
                                badge: ChoiceBadge.marry,
                                isSelected: assignedBadge == ChoiceBadge.marry,
                                activeColor: AppColors.butterText,
                                onSelect: () => _assignChoice(index, ChoiceBadge.marry),
                              ),
                              const SizedBox(width: 8),
                              _badgeChip(
                                label: '💨 Pass',
                                badge: ChoiceBadge.pass,
                                isSelected: assignedBadge == ChoiceBadge.pass,
                                activeColor: AppColors.partnerText,
                                onSelect: () => _assignChoice(index, ChoiceBadge.pass),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Bottom Action Button
              if (!_roundSubmitted)
                PrimaryButton(
                  text: allAssigned ? 'Lock In Choices ✨' : 'Assign All 3 (Kiss, Marry, Pass)',
                  isLoading: false,
                  onPressed: _submitRound,
                )
              else
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.mintSoft,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite_rounded, color: AppColors.mintText, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Choices Locked! Loved how romantic your priorities are! 💕',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.mintText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    PrimaryButton(
                      text: _currentRound < _rounds.length - 1 ? 'Next Round →' : 'See Couple Chemistry 🎉',
                      isLoading: false,
                      onPressed: _nextRound,
                    ),
                  ],
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badgeChip({
    required String label,
    required ChoiceBadge badge,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onSelect,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: _roundSubmitted ? null : onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? activeColor : AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
