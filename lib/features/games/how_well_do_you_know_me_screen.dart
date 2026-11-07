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

/// NextMeet "How Well Do You Know Me?" Couple Quiz Game
/// Real-time synchronized question and answer reveal with compatibility scoring!
class HowWellDoYouKnowMeScreen extends StatefulWidget {
  final String? relId;
  final String? myName;
  final String? partnerName;
  final String? partnerUid;

  const HowWellDoYouKnowMeScreen({
    super.key,
    this.relId,
    this.myName,
    this.partnerName,
    this.partnerUid,
  });

  @override
  State<HowWellDoYouKnowMeScreen> createState() => _HowWellDoYouKnowMeScreenState();
}

class _HowWellDoYouKnowMeScreenState extends State<HowWellDoYouKnowMeScreen> {
  final CoupleGameService _gameService = CoupleGameService();
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  late bool _isOnlineMode;

  late final List<Map<String, dynamic>> _questions;

  // Local Pass & Play state
  int _localQuestionIndex = 0;
  int? _localP1Answer;
  int? _localP2Answer;
  bool _localP1Turn = true;
  bool _localRevealed = false;
  int _localScore1 = 0;
  int _localScore2 = 0;

  @override
  void initState() {
    super.initState();
    _isOnlineMode = widget.relId != null && widget.relId!.isNotEmpty;

    final pName = widget.partnerName ?? 'Partner';
    final mName = widget.myName ?? 'You';

    _questions = [
      {
        'question': "What is $mName's ultimate comfort food after a tough day?",
        'target': 'About $mName',
        'options': [
          'Butter chicken & garlic naan',
          'Margherita pizza with chili flakes',
          'Hot chocolate & warm cookies',
          'Spicy ramen bowl with extra egg',
        ],
        'correct': 1,
      },
      {
        'question': 'Where does $pName dream of travelling next with you?',
        'target': 'About $pName',
        'options': [
          'Northern Lights in Norway',
          'Cherry blossoms in Kyoto',
          'Road trip across Amalfi Coast',
          'Backpacking in New Zealand',
        ],
        'correct': 0,
      },
      {
        'question': 'What was $mName wearing when you two had your first video call?',
        'target': 'About $mName',
        'options': [
          'An oversized yellow hoodie',
          'A light blue denim shirt',
          'A pink comfy pajama top',
          'A black knit sweater',
        ],
        'correct': 0,
      },
      {
        'question': "What is $pName's biggest pet peeve?",
        'target': 'About $pName',
        'options': [
          'Slow Wi-Fi during video calls',
          'Cold coffee when it should be hot',
          'Leaving unread message notifications',
          'Airport terminal delays',
        ],
        'correct': 2,
      },
      {
        'question': "Which song immediately makes $mName think of you?",
        'target': 'About $mName',
        'options': [
          'Lover by Taylor Swift',
          'Perfect by Ed Sheeran',
          'Until I Found You by Stephen Sanchez',
          'Golden Hour by JVKE',
        ],
        'correct': 2,
      },
    ];
  }

  void _onAnswerTap(int index, String myUid, String? relId, int qIndex) async {
    VibrationService.medium();
    if (_isOnlineMode && relId != null) {
      await _gameService.submitQuizAnswer(relId, qIndex, myUid, index);
    } else {
      if (_localP1Turn) {
        setState(() {
          _localP1Answer = index;
          _localP1Turn = false;
        });
      } else {
        final q = _questions[qIndex % _questions.length];
        final correctIdx = q['correct'] as int;

        setState(() {
          _localP2Answer = index;
          _localRevealed = true;
          if (_localP1Answer == correctIdx) _localScore1++;
          if (_localP2Answer == correctIdx) _localScore2++;
        });
      }
    }
  }

  void _nextQuestion(String? relId, int currentIndex, int s1, int s2) async {
    VibrationService.light();
    final nextIdx = currentIndex + 1;

    if (nextIdx < _questions.length) {
      if (_isOnlineMode && relId != null) {
        await _gameService.nextQuizQuestion(relId, nextIdx);
      } else {
        setState(() {
          _localQuestionIndex = nextIdx;
          _localP1Answer = null;
          _localP2Answer = null;
          _localP1Turn = true;
          _localRevealed = false;
        });
      }
    } else {
      // Completed Quiz
      if (relId != null) {
        _cloudService.addCoupleXp(relId, 150);
      }
      GameWinModal.show(
        context,
        gameTitle: 'How Well Do You Know Me?',
        winnerName: 'Score: $s1 vs $s2 💕',
        partnerName: widget.partnerName ?? 'Partner',
        score1: s1,
        score2: s2,
        xpEarned: 150,
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
    final mName = widget.myName ?? 'You';
    final isUser1 = myUid == rel?.uid1;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: (_isOnlineMode && relId != null)
          ? _gameService.streamQuiz(relId)
          : const Stream.empty(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        int currentIndex = 0;
        int? myAnswer;
        int? partnerAnswer;
        bool bothAnswered = false;
        int score1 = 0;
        int score2 = 0;

        if (_isOnlineMode && data != null) {
          currentIndex = (data['questionIndex'] as num?)?.toInt() ?? 0;
          score1 = (data['scoreU1'] as num?)?.toInt() ?? 0;
          score2 = (data['scoreU2'] as num?)?.toInt() ?? 0;

          final answers = (data['answers'] as Map<String, dynamic>?) ?? {};
          myAnswer = (answers[myUid] as num?)?.toInt();
          for (final entry in answers.entries) {
            if (entry.key != myUid) {
              partnerAnswer = (entry.value as num?)?.toInt();
              break;
            }
          }
          bothAnswered = myAnswer != null && partnerAnswer != null;
        } else {
          currentIndex = _localQuestionIndex;
          myAnswer = _localP1Answer;
          partnerAnswer = _localP2Answer;
          bothAnswered = _localRevealed;
          score1 = _localScore1;
          score2 = _localScore2;
        }

        final q = _questions[currentIndex % _questions.length];
        final options = (q['options'] as List<String>);
        final correctIdx = q['correct'] as int;

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
                      Text('Couple Quiz', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.butterSoft,
                          borderRadius: BorderRadius.circular(AppRadius.badge),
                        ),
                        child: Text(
                          '${currentIndex + 1}/${_questions.length}',
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

                  // Question Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.hero),
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.partnerSoft,
                            borderRadius: BorderRadius.circular(AppRadius.badge),
                          ),
                          child: Text(
                            q['target'] as String,
                            style: AppTextStyles.caption.copyWith(color: AppColors.partnerText, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          q['question'] as String,
                          style: AppTextStyles.title1.copyWith(fontSize: 19, height: 1.3),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Status Hint
                  Text(
                    bothAnswered
                        ? 'Answers revealed! Check who got it right! 🎉'
                        : (myAnswer != null
                            ? 'Answer locked in! Waiting for $pName... ⏳'
                            : (!_isOnlineMode && !_localP1Turn ? "Pass to $pName to answer!" : 'Tap your guess!')),
                    style: AppTextStyles.caption.copyWith(
                      color: bothAnswered ? AppColors.mintText : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 14),

                  // 4 Answer Options
                  Column(
                    children: List.generate(options.length, (optIdx) {
                      final optText = options[optIdx];
                      final isMyPick = myAnswer == optIdx;
                      final isPartnerPick = partnerAnswer == optIdx;
                      final isCorrect = optIdx == correctIdx;

                      Color borderColor = AppColors.border;
                      Color bgColor = Colors.white;

                      if (bothAnswered) {
                        if (isCorrect) {
                          borderColor = AppColors.mint;
                          bgColor = AppColors.mintSoft;
                        } else if (isMyPick || isPartnerPick) {
                          borderColor = AppColors.primary;
                          bgColor = AppColors.primarySoft.withValues(alpha: 0.3);
                        }
                      } else if (isMyPick) {
                        borderColor = AppColors.primary;
                        bgColor = AppColors.primarySoft.withValues(alpha: 0.4);
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: (myAnswer == null || (!_isOnlineMode && !_localP1Turn && _localP2Answer == null))
                              ? () => _onAnswerTap(optIdx, myUid, relId, currentIndex)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              border: Border.all(color: borderColor, width: (isMyPick || (bothAnswered && isCorrect)) ? 2.5 : 1.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: (bothAnswered && isCorrect)
                                        ? AppColors.mint
                                        : (isMyPick ? AppColors.primary : AppColors.background),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    String.fromCharCode(65 + optIdx),
                                    style: TextStyle(
                                      color: (isMyPick || (bothAnswered && isCorrect)) ? Colors.white : AppColors.ink,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    optText,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: isMyPick ? FontWeight.w800 : FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (bothAnswered && isCorrect)
                                  const Icon(Icons.check_circle_rounded, color: AppColors.mintText, size: 22)
                                else if (isMyPick && !bothAnswered)
                                  const Icon(Icons.lock_rounded, color: AppColors.primary, size: 18),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 12),

                  if (bothAnswered)
                    PrimaryButton(
                      text: currentIndex < _questions.length - 1 ? 'Next Question →' : 'See Final Results 🏆',
                      onPressed: () => _nextQuestion(relId, currentIndex, isUser1 ? score1 : score2, isUser1 ? score2 : score1),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
