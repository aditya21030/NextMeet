import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/couple_game_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import 'game_win_modal.dart';

/// NextMeet Couple Tic-Tac-Toe Game
/// Supports Real-Time Online Multiplayer with Strict Turn Enforcement & Pass-and-Play
class TicTacToeScreen extends StatefulWidget {
  final String? relId;
  final String? partnerName;
  final String? partnerUid;
  const TicTacToeScreen({super.key, this.relId, this.partnerName, this.partnerUid});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  final CoupleGameService _gameService = CoupleGameService();
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  // Mode: Online (Strict Real-time with Partner) vs Pass & Play (Local single phone)
  late bool _isOnlineMode;

  // Local state for Pass & Play
  List<String> _localBoard = List.filled(9, '');
  bool _localIsPlayerX = true;
  int _localScoreYou = 0;
  int _localScorePartner = 0;
  String? _recentReaction;

  // Track win modal shown per round to avoid duplicate popups
  String? _lastShownWinnerRound;

  final List<String> _quickReactions = [
    'Haha no way! 😂',
    'Wait what?! 😮',
    'I love you! 💖',
    'Good move! 🔥',
    'Your turn! ⏰',
  ];

  @override
  void initState() {
    super.initState();
    _isOnlineMode = widget.relId != null && widget.relId!.isNotEmpty;
    if (_isOnlineMode) {
      _initOnlineSession();
    }
  }

  Future<void> _initOnlineSession() async {
    final relId = widget.relId!;
    final rel = _cloudService.cachedRelationship;
    final myUid = _cloudService.currentUid ?? AuthService().currentUid ?? 'u1';
    final firstTurn = rel?.uid1 ?? myUid;
    await _gameService.initTicTacToe(relId, firstTurn);
  }

  void _resetGame(String? relId, String myUid, String partnerUid) async {
    VibrationService.light();
    if (_isOnlineMode && relId != null) {
      // Toggle who goes first in next round
      await _gameService.resetTicTacToe(relId, myUid);
    } else {
      setState(() {
        _localBoard = List.filled(9, '');
        _localIsPlayerX = true;
      });
    }
  }

  void _handleCellTap({
    required int index,
    required bool isOnline,
    required String? relId,
    required String myUid,
    required String partnerUid,
    required bool isUser1,
    required List<String> currentBoard,
    required String currentTurnUid,
    required int scoreYou,
    required int scorePartner,
  }) async {
    if (currentBoard[index].isNotEmpty) return;

    if (isOnline) {
      // STRICT TURN ENFORCEMENT: Only the user whose turn it is can play!
      if (currentTurnUid != myUid) {
        VibrationService.error();
        final pName = widget.partnerName ?? 'Partner';
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("It's $pName's turn! Waiting for their move... ⏳"),
            backgroundColor: AppColors.partner,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // It is my turn!
      VibrationService.light();
      final mySymbol = isUser1 ? 'X' : 'O';
      final newBoard = List<String>.from(currentBoard);
      newBoard[index] = mySymbol;

      final winner = _checkWinner(newBoard);
      final isDraw = winner == null && !newBoard.contains('');

      if (winner != null) {
        final winnerUid = winner == 'X' ? (isUser1 ? myUid : partnerUid) : (isUser1 ? partnerUid : myUid);
        final didIWin = winnerUid == myUid;

        await _gameService.makeTicTacToeMove(
          relId!,
          newBoard,
          partnerUid,
          winner: winner,
          incrementU1: winner == 'X',
          incrementU2: winner == 'O',
        );

        if (didIWin) {
          _cloudService.addCoupleXp(relId, 100);
        }
      } else if (isDraw) {
        await _gameService.makeTicTacToeMove(
          relId!,
          newBoard,
          partnerUid,
          winner: 'draw',
        );
      } else {
        // Next player's turn
        await _gameService.makeTicTacToeMove(
          relId!,
          newBoard,
          partnerUid,
        );
      }
    } else {
      // Pass & Play mode
      VibrationService.light();
      setState(() {
        _localBoard[index] = _localIsPlayerX ? 'X' : 'O';
        _localIsPlayerX = !_localIsPlayerX;
      });

      final winner = _checkWinner(_localBoard);
      if (winner != null) {
        if (winner == 'X') _localScoreYou += 1;
        if (winner == 'O') _localScorePartner += 1;

        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          GameWinModal.show(
            context,
            gameTitle: 'Tic-Tac-Toe',
            winnerName: winner == 'X' ? 'You (Pink)' : '${widget.partnerName ?? 'Partner'} (Violet)',
            score1: _localScoreYou,
            score2: _localScorePartner,
            xpEarned: 100,
            onRematch: () => _resetGame(null, myUid, partnerUid),
            relId: widget.relId,
          );
        });
      } else if (!_localBoard.contains('')) {
        // Draw
        VibrationService.medium();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("It's a draw! Two hearts beat as one 💕"),
            backgroundColor: AppColors.partner,
            action: SnackBarAction(
              label: 'Restart',
              textColor: Colors.white,
              onPressed: () => _resetGame(null, myUid, partnerUid),
            ),
          ),
        );
      }
    }
  }

  String? _checkWinner(List<String> board) {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // cols
      [0, 4, 8], [2, 4, 6], // diagonals
    ];

    for (var line in lines) {
      if (board[line[0]].isNotEmpty &&
          board[line[0]] == board[line[1]] &&
          board[line[0]] == board[line[2]]) {
        return board[line[0]];
      }
    }
    return null;
  }

  void _onReactionTap(String reaction, String? relId) {
    VibrationService.light();
    setState(() => _recentReaction = reaction);
    if (_isOnlineMode && relId != null) {
      final myName = AuthService().currentUser?.displayName ?? 'You';
      _gameService.sendGameReaction(relId, 'tictactoe', reaction, myName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rel = _cloudService.cachedRelationship;
    final myUid = _cloudService.currentUid ?? AuthService().currentUid ?? 'u1';
    final relId = widget.relId;
    final pName = widget.partnerName ?? 'Partner';
    final isUser1 = myUid == rel?.uid1;
    final partnerUid = widget.partnerUid ?? rel?.getPartnerUid(myUid) ?? (isUser1 ? rel?.uid2 : rel?.uid1) ?? 'partner_uid';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: (_isOnlineMode && relId != null)
          ? _gameService.streamTicTacToe(relId)
          : const Stream.empty(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        // Determine online state
        List<String> board;
        String currentTurnUid;
        int scoreYou;
        int scorePartner;
        String? winner;

        final mySymbol = isUser1 ? 'X' : 'O';
        final partnerSymbol = isUser1 ? 'O' : 'X';

        if (_isOnlineMode && data != null) {
          final rawBoard = data['board'] as List<dynamic>?;
          board = rawBoard != null ? rawBoard.map((e) => e.toString()).toList() : List.filled(9, '');
          currentTurnUid = data['currentTurn'] as String? ?? myUid;
          scoreYou = isUser1 ? ((data['scoreU1'] as num?)?.toInt() ?? 0) : ((data['scoreU2'] as num?)?.toInt() ?? 0);
          scorePartner = isUser1 ? ((data['scoreU2'] as num?)?.toInt() ?? 0) : ((data['scoreU1'] as num?)?.toInt() ?? 0);
          winner = data['winner'] as String?;

          final onlineReaction = data['lastReaction'] as String?;
          if (onlineReaction != null && onlineReaction.isNotEmpty) {
            _recentReaction = onlineReaction;
          }

          // Trigger win celebration modal if winner decided and not yet shown
          if (winner != null && winner.isNotEmpty && _lastShownWinnerRound != '${winner}_${scoreYou}_$scorePartner') {
            _lastShownWinnerRound = '${winner}_${scoreYou}_$scorePartner';
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (winner == 'draw') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("It's a draw! Two hearts beat as one 💕"),
                    backgroundColor: AppColors.partner,
                    action: SnackBarAction(
                      label: 'Restart',
                      textColor: Colors.white,
                      onPressed: () => _resetGame(relId, myUid, partnerUid),
                    ),
                  ),
                );
              } else {
                final didIWin = winner == mySymbol;
                GameWinModal.show(
                  context,
                  gameTitle: 'Tic-Tac-Toe',
                  winnerName: didIWin ? 'You' : pName,
                  score1: scoreYou,
                  score2: scorePartner,
                  xpEarned: 100,
                  onRematch: () => _resetGame(relId, myUid, partnerUid),
                  relId: relId,
                );
              }
            });
          }
        } else {
          board = _localBoard;
          currentTurnUid = _localIsPlayerX ? myUid : partnerUid;
          scoreYou = _localScoreYou;
          scorePartner = _localScorePartner;
          winner = null;
        }

        final isMyTurn = currentTurnUid == myUid;

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
                      Text('Tic-Tac-Toe', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                      GestureDetector(
                        onTap: () => _resetGame(relId, myUid, partnerUid),
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

                  // Mode Toggle: Online Live vs Pass & Play
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
                                  const SnackBar(content: Text('Pair with your partner to enable Live Online mode! ❤️')),
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
                                  Icon(
                                    Icons.wifi_tethering_rounded,
                                    size: 16,
                                    color: _isOnlineMode ? Colors.white : AppColors.ink,
                                  ),
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
                                  Icon(
                                    Icons.phone_android_rounded,
                                    size: 16,
                                    color: !_isOnlineMode ? Colors.white : AppColors.ink,
                                  ),
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

                  // Couple Scores & Turn Indicator (Page 49)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.hero),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // You
                        Row(
                          children: [
                            const MascotHeart(color: MascotColor.pink, size: 36),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('You (X)', style: AppTextStyles.heading.copyWith(fontSize: 13, color: AppColors.primary)),
                                Text('$scoreYou wins', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                              ],
                            ),
                          ],
                        ),
                        // Active Turn Indicator
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMyTurn ? AppColors.pinkSoft : AppColors.partnerSoft,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: isMyTurn ? AppColors.primary : AppColors.partner,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isMyTurn ? AppColors.primary : AppColors.partner,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isMyTurn ? 'Your Turn! ✨' : "Waiting for $pName...",
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isMyTurn ? AppColors.primary : AppColors.partnerText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Partner
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('$pName (O)', style: AppTextStyles.heading.copyWith(fontSize: 13, color: AppColors.partner)),
                                Text('$scorePartner wins', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                              ],
                            ),
                            const SizedBox(width: 8),
                            const MascotHeart(color: MascotColor.violet, size: 36),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Real-time Turn Warning / Helper Banner
                  if (_isOnlineMode && !isMyTurn) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.partnerSoft,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_clock_rounded, size: 16, color: AppColors.partner),
                          const SizedBox(width: 6),
                          Text(
                            "Turn locked to $pName's phone",
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.partnerText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_recentReaction != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.butterSoft,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(_recentReaction!, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // 3x3 Game Board (Page 49)
                  Center(
                    child: Container(
                      width: 320,
                      height: 320,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: (_isOnlineMode && !isMyTurn) ? AppColors.borderStrong : AppColors.primary.withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 9,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemBuilder: (context, index) {
                          final val = board[index];
                          final isCellEmpty = val.isEmpty;
                          final isClickable = isCellEmpty && (!_isOnlineMode || isMyTurn);

                          return GestureDetector(
                            onTap: () {
                              _handleCellTap(
                                index: index,
                                isOnline: _isOnlineMode,
                                relId: relId,
                                myUid: myUid,
                                partnerUid: partnerUid,
                                isUser1: isUser1,
                                currentBoard: board,
                                currentTurnUid: currentTurnUid,
                                scoreYou: scoreYou,
                                scorePartner: scorePartner,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: isClickable ? Colors.white : AppColors.background,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isClickable ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: val.isEmpty
                                    ? null
                                    : (val == 'X'
                                        ? const MascotHeart(color: MascotColor.pink, size: 54)
                                        : const MascotHeart(color: MascotColor.violet, size: 54)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quick Reaction Pills (Page 49)
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickReactions.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final reaction = _quickReactions[index];
                        return GestureDetector(
                          onTap: () => _onReactionTap(reaction, relId),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: Text(
                              reaction,
                              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink),
                            ),
                          ),
                        );
                      },
                    ),
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
}
