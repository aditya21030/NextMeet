import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/couple_game_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';

/// NextMeet Couple Truth or Dare Game
/// Real-time live challenges across distance with interactive XP rewards!
class TruthOrDareScreen extends StatefulWidget {
  final String? relId;
  final String? partnerName;

  const TruthOrDareScreen({super.key, this.relId, this.partnerName});

  @override
  State<TruthOrDareScreen> createState() => _TruthOrDareScreenState();
}

class _TruthOrDareScreenState extends State<TruthOrDareScreen> {
  final CoupleGameService _gameService = CoupleGameService();
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  bool _isTruthMode = true;
  int _currentPromptIndex = 0;
  int _xpTotal = 120;

  final List<Map<String, String>> _truthPrompts = [
    {
      'prompt': 'What was the exact second you realized you had feelings for me?',
      'tag': 'Romantic',
      'emoji': '💌',
    },
    {
      'prompt': 'What is one quirk of mine that secretly makes you smile every time?',
      'tag': 'Cute',
      'emoji': '🥰',
    },
    {
      'prompt': 'What is your favorite memory of us together when we met in person?',
      'tag': 'Deep',
      'emoji': '✨',
    },
    {
      'prompt': 'What was your very first impression of my profile or photo?',
      'tag': 'Funny',
      'emoji': '😂',
    },
    {
      'prompt': 'If you could relive any single day of our relationship, which day would it be?',
      'tag': 'Soulmate',
      'emoji': '💖',
    },
  ];

  final List<Map<String, String>> _darePrompts = [
    {
      'prompt': 'Send a 15-second voice whisper singing the chorus of our song!',
      'tag': 'Spicy',
      'emoji': '🎤',
    },
    {
      'prompt': 'Change your phone wallpaper to a silly couple selfie for 24 hours!',
      'tag': 'Fun',
      'emoji': '📸',
    },
    {
      'prompt': 'Send a 100-word love letter describing what you love most about me!',
      'tag': 'Romantic',
      'emoji': '✍️',
    },
    {
      'prompt': 'Call me right now and whisper 3 sweet things before hanging up!',
      'tag': 'Wild',
      'emoji': '📞',
    },
    {
      'prompt': 'Recreate our very first photo together and send it right now!',
      'tag': 'Nostalgic',
      'emoji': '📷',
    },
  ];

  void _nextPrompt({bool earnedXp = true}) {
    if (earnedXp) {
      VibrationService.success();
      setState(() {
        _xpTotal += 50;
      });
      if (widget.relId != null) {
        _cloudService.addCoupleXp(widget.relId!, 50);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('+50 XP! Completed challenge! 🔥')),
      );
    } else {
      VibrationService.light();
    }

    final list = _isTruthMode ? _truthPrompts : _darePrompts;
    setState(() {
      _currentPromptIndex = (_currentPromptIndex + 1) % list.length;
    });
  }

  void _sendChallengeToPartner(Map<String, String> item) async {
    if (widget.relId == null) return;
    VibrationService.heavy();
    final myName = AuthService().currentUser?.displayName ?? 'You';
    final myUid = _cloudService.currentUid ?? AuthService().currentUid;

    await _gameService.sendTruthOrDareChallenge(
      widget.relId!,
      type: _isTruthMode ? 'Truth' : 'Dare',
      prompt: item['prompt']!,
      senderName: myName,
      senderUid: myUid,
      tag: item['tag']!,
      emoji: item['emoji']!,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Challenge dispatched to ${widget.partnerName ?? 'Partner'}! 🚀'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _isTruthMode ? _truthPrompts : _darePrompts;
    final item = list[_currentPromptIndex % list.length];
    final relId = widget.relId;
    final pName = widget.partnerName ?? 'Partner';
    final currentUid = _cloudService.currentUid ?? AuthService().currentUid ?? 'u1';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: relId != null ? _gameService.streamTruthOrDare(relId) : const Stream.empty(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final incomingPrompt = data?['prompt'] as String?;
        final incomingSender = data?['senderName'] as String?;
        final incomingSenderUid = data?['senderUid'] as String?;
        final incomingType = data?['type'] as String? ?? 'Dare';
        final incomingStatus = data?['status'] as String?;
        final isIncomingActive = incomingPrompt != null &&
            incomingStatus == 'sent' &&
            ((incomingSenderUid != null && incomingSenderUid != currentUid) ||
                (incomingSenderUid == null &&
                    incomingSender != null &&
                    incomingSender != (AuthService().currentUser?.displayName ?? 'You')));

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
                          'Truth or Dare',
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
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.butter, width: 1.5),
                        ),
                        child: Text(
                          '⭐ $_xpTotal XP',
                          style: AppTextStyles.caption.copyWith(color: AppColors.butterText, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),

                  // Incoming Partner Challenge Banner (Live Cloud)
                  if (isIncomingActive) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.butterSoft,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.butter, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 24)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$pName has challenged you to a $incomingType!',
                                  style: AppTextStyles.heading.copyWith(color: AppColors.butterText, fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            incomingPrompt,
                            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          PrimaryButton(
                            text: 'I Completed It! (+50 XP) 🎉',
                            onPressed: () {
                              VibrationService.success();
                              if (relId != null) {
                                _gameService.completeTruthOrDareChallenge(relId);
                                _cloudService.addCoupleXp(relId, 50);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Mode Selector Tabs (Page 50)
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
                              VibrationService.light();
                              setState(() {
                                _isTruthMode = true;
                                _currentPromptIndex = 0;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isTruthMode ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Truth 💭',
                                style: AppTextStyles.heading.copyWith(
                                  fontSize: 14,
                                  color: _isTruthMode ? Colors.white : AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              VibrationService.light();
                              setState(() {
                                _isTruthMode = false;
                                _currentPromptIndex = 0;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isTruthMode ? AppColors.partner : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Dare 🌶️',
                                style: AppTextStyles.heading.copyWith(
                                  fontSize: 14,
                                  color: !_isTruthMode ? Colors.white : AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Big Card (Page 50)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: _isTruthMode ? AppColors.primary : AppColors.partner,
                        width: 2.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isTruthMode ? AppColors.pinkSoft : AppColors.partnerSoft,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            '${item['emoji']} ${item['tag']!.toUpperCase()}',
                            style: AppTextStyles.label.copyWith(
                              color: _isTruthMode ? AppColors.primary : AppColors.partnerText,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          item['prompt']!,
                          style: AppTextStyles.title1.copyWith(fontSize: 22, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        MascotHeart(
                          color: _isTruthMode ? MascotColor.pink : MascotColor.violet,
                          size: 64,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _nextPrompt(earnedXp: true),
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: _isTruthMode ? AppColors.primary : AppColors.partner,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            alignment: Alignment.center,
                            child: Text('Done! (+50 XP) ✅', style: AppTextStyles.button.copyWith(fontSize: 14)),
                          ),
                        ),
                      ),
                      if (relId != null) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _sendChallengeToPartner(item),
                            child: Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(color: _isTruthMode ? AppColors.primary : AppColors.partner, width: 2),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Dare $pName 🚀',
                                style: AppTextStyles.button.copyWith(
                                  color: _isTruthMode ? AppColors.primary : AppColors.partner,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _nextPrompt(earnedXp: false),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Skip to next ⏭️',
                        style: AppTextStyles.button.copyWith(color: AppColors.muted),
                      ),
                    ),
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
