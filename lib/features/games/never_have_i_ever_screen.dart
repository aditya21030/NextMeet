import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/couple_game_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';

/// NextMeet Couple Never Have I Ever
/// Real-time synchronized couple confession game with simultaneous reveal.
class NeverHaveIEverScreen extends StatefulWidget {
  final String? relId;
  final String? partnerName;
  const NeverHaveIEverScreen({super.key, this.relId, this.partnerName});

  @override
  State<NeverHaveIEverScreen> createState() => _NeverHaveIEverScreenState();
}

class _NeverHaveIEverScreenState extends State<NeverHaveIEverScreen> {
  final CoupleGameService _gameService = CoupleGameService();
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  late bool _isOnlineMode;

  final List<Map<String, String>> _prompts = [
    {
      'category': 'Romantic',
      'emoji': '💌',
      'prompt': 'Never have I ever re-read our old text messages just to smile like a fool.',
    },
    {
      'category': 'Spicy',
      'emoji': '🔥',
      'prompt': 'Never have I ever fallen asleep on a video call while looking at your face.',
    },
    {
      'category': 'Funny',
      'emoji': '😂',
      'prompt': 'Never have I ever taken 10+ selfies just to send you ONE good photo.',
    },
    {
      'category': 'Cute',
      'emoji': '🥰',
      'prompt': 'Never have I ever worn your oversized shirt because it smelled like you.',
    },
    {
      'category': 'Deep',
      'emoji': '✨',
      'prompt': 'Never have I ever secretly planned our dream wedding or reunion trip in my head.',
    },
    {
      'category': 'Confession',
      'emoji': '🤫',
      'prompt': 'Never have I ever stalked your playlist to see what songs you were listening to.',
    },
    {
      'category': 'Adventure',
      'emoji': '✈️',
      'prompt': 'Never have I ever looked at flight tickets to your city at 2:00 AM on a random night.',
    },
    {
      'category': 'Sweet',
      'emoji': '🧸',
      'prompt': 'Never have I ever hugged my pillow and pretended it was you.',
    },
  ];

  // Local state
  int _localIndex = 0;
  bool? _localMyAnswer;
  bool? _localPartnerAnswer;
  bool _localP1Turn = true;

  @override
  void initState() {
    super.initState();
    _isOnlineMode = widget.relId != null && widget.relId!.isNotEmpty;
  }

  void _onAnswerTap(bool haveDone, String myUid, String? relId, int currentPromptIndex) async {
    VibrationService.medium();
    if (_isOnlineMode && relId != null) {
      await _gameService.submitNeverHaveIEverAnswer(relId, currentPromptIndex, myUid, haveDone);
    } else {
      if (_localP1Turn) {
        setState(() {
          _localMyAnswer = haveDone;
          _localP1Turn = false;
        });
      } else {
        setState(() {
          _localPartnerAnswer = haveDone;
        });
      }
    }
  }

  void _nextPrompt(String? relId, int currentIndex) async {
    VibrationService.light();
    final nextIdx = (currentIndex + 1) % _prompts.length;
    if (_isOnlineMode && relId != null) {
      await _gameService.nextNeverHaveIEverPrompt(relId, nextIdx);
      _cloudService.addCoupleXp(relId, 30);
    } else {
      setState(() {
        _localIndex = nextIdx;
        _localMyAnswer = null;
        _localPartnerAnswer = null;
        _localP1Turn = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = AuthService().currentUid ?? 'u1';
    final relId = widget.relId;
    final pName = widget.partnerName ?? 'Partner';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: (_isOnlineMode && relId != null)
          ? _gameService.streamNeverHaveIEver(relId)
          : const Stream.empty(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        int promptIndex;
        bool? myAnswer;
        bool? partnerAnswer;

        if (_isOnlineMode && data != null) {
          promptIndex = (data['promptIndex'] as num?)?.toInt() ?? 0;
          final answers = data['answers'] as Map<String, dynamic>? ?? {};
          myAnswer = answers[myUid] as bool?;
          // Any other UID in answers is the partner's answer
          for (final entry in answers.entries) {
            if (entry.key != myUid) {
              partnerAnswer = entry.value as bool?;
              break;
            }
          }
        } else {
          promptIndex = _localIndex;
          myAnswer = _localMyAnswer;
          partnerAnswer = _localPartnerAnswer;
        }

        final item = _prompts[promptIndex % _prompts.length];
        final bothAnswered = myAnswer != null && partnerAnswer != null;
        final isMatch = bothAnswered && myAnswer == partnerAnswer;

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
                      Expanded(
                        child: Text(
                          'Never Have I Ever',
                          style: AppTextStyles.title2.copyWith(fontSize: 18),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.butterSoft,
                          borderRadius: BorderRadius.circular(AppRadius.badge),
                        ),
                        child: Text(
                          '${promptIndex + 1}/${_prompts.length}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.butterText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Prompt Hero Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.hero),
                      border: Border.all(color: AppColors.border, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.pinkSoft,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                item['category']!,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(item['emoji']!, style: const TextStyle(fontSize: 28)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          item['prompt']!,
                          style: AppTextStyles.title1.copyWith(
                            fontSize: 22,
                            height: 1.35,
                            color: AppColors.ink,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Simultaneous Answer Reveal Panel
                  if (myAnswer != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Your answer
                              Column(
                                children: [
                                  const Text('You', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: myAnswer ? AppColors.mintSoft : AppColors.pinkSoft,
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                    ),
                                    child: Text(
                                      myAnswer ? 'I Have 🙋' : 'Never 🙅',
                                      style: AppTextStyles.heading.copyWith(
                                        fontSize: 14,
                                        color: myAnswer ? AppColors.mintText : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Container(width: 1.5, height: 40, color: AppColors.border),
                              // Partner's answer
                              Column(
                                children: [
                                  Text(pName, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.partner)),
                                  const SizedBox(height: 6),
                                  if (bothAnswered)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: partnerAnswer ? AppColors.mintSoft : AppColors.partnerSoft,
                                        borderRadius: BorderRadius.circular(AppRadius.pill),
                                      ),
                                      child: Text(
                                        partnerAnswer ? 'I Have 🙋' : 'Never 🙅',
                                        style: AppTextStyles.heading.copyWith(
                                          fontSize: 14,
                                          color: partnerAnswer ? AppColors.mintText : AppColors.partnerText,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.butterSoft,
                                        borderRadius: BorderRadius.circular(AppRadius.pill),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.butterText),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Waiting...',
                                            style: AppTextStyles.caption.copyWith(color: AppColors.butterText, fontWeight: FontWeight.w800),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          if (bothAnswered) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isMatch ? AppColors.mintSoft : AppColors.butterSoft,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                isMatch ? 'Match! Both on the same page! 💕' : 'Storytime! Spill the details! ☕',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isMatch ? AppColors.mintText : AppColors.butterText,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Buttons: I Have vs Never
                  if (myAnswer == null || (!_isOnlineMode && partnerAnswer == null)) ...[
                    if (!_isOnlineMode && myAnswer != null && partnerAnswer == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          "Pass phone to $pName to answer! 👇",
                          style: AppTextStyles.caption.copyWith(color: AppColors.partnerText, fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _onAnswerTap(true, myUid, relId, promptIndex),
                            child: Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'I Have 🙋',
                                style: AppTextStyles.button.copyWith(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _onAnswerTap(false, myUid, relId, promptIndex),
                            child: Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(color: AppColors.border, width: 1.5),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'I Have Never 🙅',
                                style: AppTextStyles.button.copyWith(fontSize: 16, color: AppColors.ink),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    PrimaryButton(
                      text: 'Next Confession ➡️',
                      onPressed: () => _nextPrompt(relId, promptIndex),
                    ),
                  ],

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
