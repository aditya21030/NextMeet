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

/// NextMeet Rock, Paper, Kiss
/// Romantic twist on RPS with real-time simultaneous card reveal & playful forfeits!
class RockPaperScissorsScreen extends StatefulWidget {
  final String? relId;
  final String? partnerName;
  final String? partnerUid;
  const RockPaperScissorsScreen({super.key, this.relId, this.partnerName, this.partnerUid});

  @override
  State<RockPaperScissorsScreen> createState() => _RockPaperScissorsScreenState();
}

class _RockPaperScissorsScreenState extends State<RockPaperScissorsScreen> {
  final CoupleGameService _gameService = CoupleGameService();
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  late bool _isOnlineMode;

  final List<Map<String, dynamic>> _moves = [
    {'name': 'Rock', 'emoji': '🪨', 'beats': ['Scissors']},
    {'name': 'Paper', 'emoji': '📄', 'beats': ['Rock', 'Kiss']},
    {'name': 'Scissors', 'emoji': '✂️', 'beats': ['Paper']},
    {'name': 'Kiss', 'emoji': '💋', 'beats': ['Rock', 'Scissors']},
  ];

  // Local Pass & Play state
  String? _localP1Move;
  String? _localP2Move;
  bool _localP1Turn = true;
  int _localScore1 = 0;
  int _localScore2 = 0;
  bool _localRevealed = false;

  String? _lastShownRoundKey;

  @override
  void initState() {
    super.initState();
    _isOnlineMode = widget.relId != null && widget.relId!.isNotEmpty;
  }

  void _onMoveTap(String moveName, String myUid, String? relId) async {
    VibrationService.medium();
    if (_isOnlineMode && relId != null) {
      await _gameService.submitRPSMove(relId, myUid, moveName);
    } else {
      if (_localP1Turn) {
        setState(() {
          _localP1Move = moveName;
          _localP1Turn = false;
        });
      } else {
        setState(() {
          _localP2Move = moveName;
          _localRevealed = true;
          _resolveLocalRound();
        });
      }
    }
  }

  void _resolveLocalRound() {
    final m1 = _moves.firstWhere((m) => m['name'] == _localP1Move);
    final p2Move = _localP2Move;

    if (_localP1Move == p2Move) {
      // Tie
    } else if ((m1['beats'] as List<String>).contains(p2Move)) {
      _localScore1++;
      VibrationService.success();
    } else {
      _localScore2++;
      VibrationService.success();
    }

    if (_localScore1 >= 3 || _localScore2 >= 3) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        GameWinModal.show(
          context,
          gameTitle: 'Rock Paper Kiss',
          winnerName: _localScore1 >= _localScore2 ? 'You Won! 🏆' : '${widget.partnerName ?? 'Partner'} Won! 🏆',
          partnerName: widget.partnerName ?? 'Partner',
          score1: _localScore1,
          score2: _localScore2,
          xpEarned: 100,
          onRematch: _resetLocal,
          relId: widget.relId,
        );
      });
    }
  }

  void _nextRound(String? relId, {int? s1, int? s2}) async {
    VibrationService.light();
    if (_isOnlineMode && relId != null) {
      await _gameService.nextRPSRound(relId, scoreU1: s1, scoreU2: s2);
    } else {
      setState(() {
        _localP1Move = null;
        _localP2Move = null;
        _localP1Turn = true;
        _localRevealed = false;
      });
    }
  }

  void _resetLocal() {
    setState(() {
      _localP1Move = null;
      _localP2Move = null;
      _localP1Turn = true;
      _localScore1 = 0;
      _localScore2 = 0;
      _localRevealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rel = _cloudService.cachedRelationship;
    final myUid = _cloudService.currentUid ?? AuthService().currentUid ?? 'u1';
    final relId = widget.relId;
    final pName = widget.partnerName ?? 'Partner';
    final isUser1 = myUid == rel?.uid1;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: (_isOnlineMode && relId != null)
          ? _gameService.streamRockPaperKiss(relId)
          : const Stream.empty(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        String? myMove;
        String? partnerMove;
        bool bothPicked = false;
        int score1 = 0;
        int score2 = 0;
        int round = 1;

        if (_isOnlineMode && data != null) {
          final moves = (data['moves'] as Map<String, dynamic>?) ?? {};
          round = (data['round'] as num?)?.toInt() ?? 1;
          score1 = (data['scoreU1'] as num?)?.toInt() ?? 0;
          score2 = (data['scoreU2'] as num?)?.toInt() ?? 0;

          myMove = moves[myUid] as String?;
          for (final entry in moves.entries) {
            if (entry.key != myUid) {
              partnerMove = entry.value as String?;
              break;
            }
          }
          bothPicked = myMove != null && partnerMove != null;

          if (bothPicked) {
            final roundKey = '${round}_${myMove}_$partnerMove';
            if (_lastShownRoundKey != roundKey) {
              _lastShownRoundKey = roundKey;
              // Check who scored
              final myMoveData = _moves.firstWhere((m) => m['name'] == myMove);
              final partnerWon = !((myMoveData['beats'] as List<String>).contains(partnerMove)) && (myMove != partnerMove);
              final iWon = (myMoveData['beats'] as List<String>).contains(partnerMove);

              if (iWon) {
                if (isUser1) score1++;
                if (!isUser1) score2++;
                VibrationService.success();
              } else if (partnerWon) {
                if (isUser1) score2++;
                if (!isUser1) score1++;
                VibrationService.error();
              }

              if (score1 >= 3 || score2 >= 3) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  final didIWin = (isUser1 && score1 >= 3) || (!isUser1 && score2 >= 3);
                  if (relId != null) {
                    _cloudService.addCoupleXp(relId, 100);
                  }
                  GameWinModal.show(
                    context,
                    gameTitle: 'Rock Paper Kiss',
                    winnerName: didIWin ? 'You Won! 🏆' : '$pName Won! 🏆',
                    partnerName: pName,
                    score1: isUser1 ? score1 : score2,
                    score2: isUser1 ? score2 : score1,
                    xpEarned: 100,
                    onRematch: () => relId != null ? _gameService.resetRPSGame(relId) : _resetLocal(),
                    relId: relId,
                  );
                });
              }
            }
          }
        } else {
          myMove = _localP1Move;
          partnerMove = _localP2Move;
          bothPicked = _localRevealed;
          score1 = _localScore1;
          score2 = _localScore2;
        }

        final myScore = isUser1 ? score1 : score2;
        final partnerScore = isUser1 ? score2 : score1;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Column(
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
                      Text('Rock Paper Kiss', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                      GestureDetector(
                        onTap: () {
                          if (_isOnlineMode && relId != null) {
                            _gameService.resetRPSGame(relId);
                          } else {
                            _resetLocal();
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border, width: 1.5),
                          ),
                          child: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.ink),
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

                  const SizedBox(height: 14),

                  // Scoreboard
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.hero),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const MascotHeart(color: MascotColor.pink, size: 34),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('You', style: AppTextStyles.heading.copyWith(fontSize: 13, color: AppColors.primary)),
                                Text('$myScore wins', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.butterSoft,
                            borderRadius: BorderRadius.circular(AppRadius.badge),
                          ),
                          child: Text('First to 3 Wins', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w800, color: AppColors.butterText)),
                        ),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(pName, style: AppTextStyles.heading.copyWith(fontSize: 13, color: AppColors.partner)),
                                Text('$partnerScore wins', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                              ],
                            ),
                            const SizedBox(width: 8),
                            const MascotHeart(color: MascotColor.violet, size: 34),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Battle Arena: Cards Face-off
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Your Card
                      _playerCard(
                        title: 'You',
                        color: AppColors.primary,
                        moveName: myMove,
                        isRevealed: bothPicked || (!_isOnlineMode && _localP1Move != null && !_localP1Turn),
                        isWaiting: myMove == null,
                      ),
                      const SizedBox(width: 16),
                      Text('VS', style: AppTextStyles.display.copyWith(fontSize: 22, color: AppColors.muted)),
                      const SizedBox(width: 16),
                      // Partner Card
                      _playerCard(
                        title: pName,
                        color: AppColors.partner,
                        moveName: partnerMove,
                        isRevealed: bothPicked,
                        isWaiting: partnerMove == null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Status Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Text(
                      bothPicked
                          ? (myMove == partnerMove
                              ? "It's a tie! Both chose $myMove! 💕"
                              : ((_moves.firstWhere((m) => m['name'] == myMove)['beats'] as List<String>).contains(partnerMove)
                                  ? 'You won this round! 🎉'
                                  : '$pName won this round! ✨'))
                          : (myMove != null
                              ? 'Your move is locked! Waiting for $pName... ⏳'
                              : (!_isOnlineMode && !_localP1Turn ? "Pass phone to $pName to pick!" : 'Pick your romantic move! 👇')),
                      style: AppTextStyles.heading.copyWith(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Move Selection Chips
                  if (!bothPicked) ...[
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _moves.length,
                      itemBuilder: (context, index) {
                        final m = _moves[index];
                        final name = m['name'] as String;
                        final emoji = m['emoji'] as String;
                        final isSelected = myMove == name;

                        return GestureDetector(
                          onTap: myMove == null
                              ? () => _onMoveTap(name, myUid, relId)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 8),
                                Text(
                                  name,
                                  style: AppTextStyles.heading.copyWith(
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    PrimaryButton(
                      text: 'Next Round →',
                      onPressed: () => _nextRound(relId, s1: score1, s2: score2),
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

  Widget _playerCard({
    required String title,
    required Color color,
    required String? moveName,
    required bool isRevealed,
    required bool isWaiting,
  }) {
    String emoji = '❓';
    String display = 'Picking...';
    if (moveName != null) {
      if (isRevealed) {
        final match = _moves.firstWhere((m) => m['name'] == moveName, orElse: () => {'emoji': '✨'});
        emoji = match['emoji'] as String;
        display = moveName;
      } else {
        emoji = '🔒';
        display = 'Locked in';
      }
    }

    return Container(
      width: 130,
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 10),
          Text(emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text(display, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)),
        ],
      ),
    );
  }
}
