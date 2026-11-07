import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/couple_game_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import 'game_win_modal.dart';

/// NextMeet Couple "Would You Rather?" Dilemma Game
/// Real-time synchronized couple choices with simultaneous match reveal!
class WouldYouRatherScreen extends StatefulWidget {
  final String? relId;
  final String? partnerName;
  final String? partnerUid;
  const WouldYouRatherScreen({super.key, this.relId, this.partnerName, this.partnerUid});

  @override
  State<WouldYouRatherScreen> createState() => _WouldYouRatherScreenState();
}

class _WouldYouRatherScreenState extends State<WouldYouRatherScreen> {
  final CoupleGameService _gameService = CoupleGameService();
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  late bool _isOnlineMode;

  final List<Map<String, String>> _dilemmas = [
    {
      'optionA': 'Live in a cozy wooden cabin in the snowy mountains 🏔️',
      'optionB': 'Live in a breezy glass villa by the tropical ocean 🌊',
    },
    {
      'optionA': 'Cook an elaborate 5-course meal together at home 🍳',
      'optionB': 'Dress up for a surprise Michelin star candlelight dinner 🍷',
    },
    {
      'optionA': 'A 2-week digital detox road trip with no phones 📵',
      'optionB': 'A luxury resort holiday with 24/7 spa & room service 💆',
    },
    {
      'optionA': 'Rewatch our favorite show together for the 5th time 📺',
      'optionB': 'Find a brand new spooky thriller movie to watch 🍿',
    },
    {
      'optionA': 'Have breakfast in bed every morning 🥐',
      'optionB': 'Midnight stargazing with hot cocoa every evening 🌌',
    },
  ];

  // Local Pass & Play state
  int _localIndex = 0;
  int? _localP1Choice;
  int? _localP2Choice;
  bool _localP1Turn = true;
  bool _localRevealed = false;
  int _localMatches = 0;

  @override
  void initState() {
    super.initState();
    _isOnlineMode = widget.relId != null && widget.relId!.isNotEmpty;
  }

  void _chooseOption(int index, String myUid, String? relId, int currentIndex) async {
    VibrationService.medium();
    if (_isOnlineMode && relId != null) {
      await _gameService.submitWouldYouRatherChoice(relId, currentIndex, myUid, index);
    } else {
      if (_localP1Turn) {
        setState(() {
          _localP1Choice = index;
          _localP1Turn = false;
        });
      } else {
        setState(() {
          _localP2Choice = index;
          _localRevealed = true;
          if (_localP1Choice == index) {
            _localMatches++;
            VibrationService.success();
          }
        });
      }
    }
  }

  void _nextDilemma(String? relId, int currentIndex, int totalMatches) async {
    VibrationService.light();
    final nextIdx = currentIndex + 1;

    if (nextIdx < _dilemmas.length) {
      if (_isOnlineMode && relId != null) {
        await _gameService.nextWouldYouRather(relId, nextIdx);
      } else {
        setState(() {
          _localIndex = nextIdx;
          _localP1Choice = null;
          _localP2Choice = null;
          _localP1Turn = true;
          _localRevealed = false;
        });
      }
    } else {
      // Completed game
      if (relId != null) {
        _cloudService.addCoupleXp(relId, 130);
      }
      GameWinModal.show(
        context,
        gameTitle: 'Would You Rather?',
        winnerName: '$totalMatches of ${_dilemmas.length} Soulmate Matches 💕',
        partnerName: widget.partnerName ?? 'Partner',
        score1: totalMatches,
        score2: _dilemmas.length,
        xpEarned: 130,
        relId: relId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rel = _cloudService.cachedRelationship;
    final myUid = _cloudService.currentUid ?? AuthService().currentUid ?? 'u1';
    final relId = widget.relId;
    final pName = widget.partnerName ?? 'Partner';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: (_isOnlineMode && relId != null)
          ? _gameService.streamWouldYouRather(relId)
          : const Stream.empty(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        int currentIndex = 0;
        int? myChoice;
        int? partnerChoice;
        bool bothChosen = false;

        if (_isOnlineMode && data != null) {
          currentIndex = (data['dilemmaIndex'] as num?)?.toInt() ?? 0;
          final choices = (data['choices'] as Map<String, dynamic>?) ?? {};
          myChoice = (choices[myUid] as num?)?.toInt();
          for (final entry in choices.entries) {
            if (entry.key != myUid) {
              partnerChoice = (entry.value as num?)?.toInt();
              break;
            }
          }
          bothChosen = myChoice != null && partnerChoice != null;
        } else {
          currentIndex = _localIndex;
          myChoice = _localP1Choice;
          partnerChoice = _localP2Choice;
          bothChosen = _localRevealed;
        }

        final d = _dilemmas[currentIndex % _dilemmas.length];
        final isMatch = bothChosen && (myChoice == partnerChoice);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
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
                      Text('Would You Rather?', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.butterSoft,
                          borderRadius: BorderRadius.circular(AppRadius.badge),
                        ),
                        child: Text(
                          '${currentIndex + 1}/${_dilemmas.length}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.butterText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Mode Toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (relId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Pair with partner to enable Live Online mode! ❤️')),
                                );
                                return;
                              }
                              VibrationService.light();
                              setState(() => _isOnlineMode = true);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _isOnlineMode ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.wifi_tethering_rounded, size: 16, color: _isOnlineMode ? Colors.white : AppColors.ink),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Online Live ⚡',
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: _isOnlineMode ? Colors.white : AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              VibrationService.light();
                              setState(() => _isOnlineMode = false);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_isOnlineMode ? AppColors.partner : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.phone_android_rounded, size: 16, color: !_isOnlineMode ? Colors.white : AppColors.ink),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Pass & Play 🤝',
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: !_isOnlineMode ? Colors.white : AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Header Prompt
                  Text(
                    'Would you rather...',
                    style: AppTextStyles.display.copyWith(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bothChosen
                        ? (isMatch ? 'It\'s a Match! You both think alike! 💕' : 'Different choices! Celebrate your unique minds ✨')
                        : (myChoice != null
                            ? 'Your choice is locked! Waiting for $pName... ⏳'
                            : (!_isOnlineMode && !_localP1Turn ? "Pass to $pName to pick!" : 'Tap your pick!')),
                    style: AppTextStyles.caption.copyWith(
                      color: isMatch ? AppColors.mintText : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // Option A Card
                  _optionCard(
                    title: d['optionA']!,
                    isSelected: myChoice == 0,
                    isPartnerSelected: partnerChoice == 0,
                    bothChosen: bothChosen,
                    partnerName: pName,
                    color: AppColors.primary,
                    onTap: (myChoice == null || (!_isOnlineMode && !_localP1Turn && _localP2Choice == null))
                        ? () => _chooseOption(0, myUid, relId, currentIndex)
                        : null,
                  ),

                  const SizedBox(height: 14),

                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Text('OR', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w900, color: AppColors.muted)),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Option B Card
                  _optionCard(
                    title: d['optionB']!,
                    isSelected: myChoice == 1,
                    isPartnerSelected: partnerChoice == 1,
                    bothChosen: bothChosen,
                    partnerName: pName,
                    color: AppColors.partner,
                    onTap: (myChoice == null || (!_isOnlineMode && !_localP1Turn && _localP2Choice == null))
                        ? () => _chooseOption(1, myUid, relId, currentIndex)
                        : null,
                  ),

                  const SizedBox(height: 24),

                  if (bothChosen)
                    PrimaryButton(
                      text: currentIndex < _dilemmas.length - 1 ? 'Next Dilemma →' : 'See Chemistry Score 🎉',
                      onPressed: () => _nextDilemma(relId, currentIndex, _localMatches),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _optionCard({
    required String title,
    required bool isSelected,
    required bool isPartnerSelected,
    required bool bothChosen,
    required String partnerName,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: AppTextStyles.title2.copyWith(
                fontSize: 17,
                height: 1.3,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? color : AppColors.textPrimary,
              ),
            ),
            if (bothChosen) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                      ),
                      child: Text('You picked', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                  if (isSelected && isPartnerSelected) const SizedBox(width: 8),
                  if (isPartnerSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.partnerSoft,
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                      ),
                      child: Text('$partnerName picked', style: AppTextStyles.caption.copyWith(color: AppColors.partnerText, fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
