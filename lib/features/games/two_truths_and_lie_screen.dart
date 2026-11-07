import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import 'game_win_modal.dart';

/// NextMeet Two Truths and a Lie
/// Guess which statement about your partner is the cheeky lie!
class TwoTruthsAndLieScreen extends StatefulWidget {
  final String? relId;
  final String? partnerName;
  const TwoTruthsAndLieScreen({super.key, this.relId, this.partnerName});

  @override
  State<TwoTruthsAndLieScreen> createState() => _TwoTruthsAndLieScreenState();
}

class _TwoTruthsAndLieScreenState extends State<TwoTruthsAndLieScreen> {
  int _currentIndex = 0;
  int? _selectedLie;
  bool _revealed = false;
  int _score = 0;

  final List<Map<String, dynamic>> _rounds = [
    {
      'title': 'Childhood Confessions',
      'statements': [
        'I once broke my arm trying to jump like Spider-Man off the sofa.',
        'I had an imaginary pet penguin named Waddle for 2 years.',
        'I won 1st prize in a regional spelling bee in 5th grade.',
      ],
      'lieIndex': 2,
      'story': 'The lie is the spelling bee! I misspelled "banana" on round 1! 😂',
    },
    {
      'title': 'Travel & Adventure',
      'statements': [
        'I lost my passport at an international airport terminal.',
        'I have swam with dolphins in the open sea.',
        'I ate fried tarantula on a street food dare.',
      ],
      'lieIndex': 1,
      'story': 'The lie is the dolphins! I was too scared to get into the water! 🐬',
    },
    {
      'title': 'Romance & Dating',
      'statements': [
        'I memorized your phone number before our third date.',
        'I practiced what to say to you in the mirror for 20 minutes.',
        'I accidentally texted my mom instead of you about our first date.',
      ],
      'lieIndex': 2,
      'story': 'The lie is the text to mom! I was too focused to make that mistake! 💕',
    },
  ];

  void _onStatementTap(int index) {
    if (_revealed) return;
    VibrationService.medium();

    final isLie = index == _rounds[_currentIndex]['lieIndex'];
    if (isLie) {
      _score += 1;
      VibrationService.success();
    } else {
      VibrationService.error();
    }

    setState(() {
      _selectedLie = index;
      _revealed = true;
    });
  }

  void _nextRound() {
    VibrationService.light();
    if (_currentIndex < _rounds.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedLie = null;
        _revealed = false;
      });
    } else {
      if (widget.relId != null) {
        CloudRelationshipService().addCoupleXp(widget.relId!, 110);
      }
      GameWinModal.show(
        context,
        gameTitle: 'Two Truths & a Lie',
        winnerName: 'Score: $_score / ${_rounds.length} Caught!',
        partnerName: widget.partnerName ?? 'Partner',
        score1: _score,
        score2: _rounds.length,
        xpEarned: 110,
        relId: widget.relId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final round = _rounds[_currentIndex];
    final pName = widget.partnerName ?? 'Partner';

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
                  Text('Two Truths & a Lie', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.partnerSoft,
                      borderRadius: BorderRadius.circular(AppRadius.badge),
                    ),
                    child: Text(
                      'Round ${_currentIndex + 1}/${_rounds.length}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.partnerText, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                'Spot the lie about $pName! Two are true, one is fake 🕵️',
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // 3 Statements
              ...List.generate(3, (i) {
                final statement = (round['statements'] as List<String>)[i];
                final isLie = i == round['lieIndex'];
                final isSelected = i == _selectedLie;

                Color bg = Colors.white;
                Color border = AppColors.border;

                if (_revealed) {
                  if (isLie) {
                    bg = AppColors.pinkSoft;
                    border = AppColors.danger;
                  } else if (isSelected && !isLie) {
                    bg = AppColors.mintSoft;
                    border = AppColors.mint;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: GestureDetector(
                    onTap: () => _onStatementTap(i),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: border, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border, width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              statement,
                              style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.3),
                            ),
                          ),
                          if (_revealed && isLie)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: const Text('LIE! 🤥', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              if (_revealed) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.butterSoft,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.butter, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, color: AppColors.butterText),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          round['story'] as String,
                          style: AppTextStyles.caption.copyWith(color: AppColors.butterText, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  text: 'Next Round ➡️',
                  onPressed: _nextRound,
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
