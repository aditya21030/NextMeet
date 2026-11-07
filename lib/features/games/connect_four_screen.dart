import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/couple_game_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import 'game_win_modal.dart';

/// NextMeet Hearts in a Row (Connect Four) Couple Game
/// 7 columns x 6 rows real-time multiplayer with strict turn enforcement.
class ConnectFourScreen extends StatefulWidget {
  final String? relId;
  final String? partnerName;
  final String? partnerUid;
  const ConnectFourScreen({super.key, this.relId, this.partnerName, this.partnerUid});

  @override
  State<ConnectFourScreen> createState() => _ConnectFourScreenState();
}

class _ConnectFourScreenState extends State<ConnectFourScreen> {
  static const int rows = 6;
  static const int cols = 7;

  final CoupleGameService _gameService = CoupleGameService();
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  late bool _isOnlineMode;

  // Local Pass & Play state
  List<int> _localBoard = List.filled(rows * cols, 0); // 0: empty, 1: pink, 2: violet
  bool _localIsPlayer1 = true;
  int _localScoreYou = 0;
  int _localScorePartner = 0;

  String? _lastShownWinnerRound;

  @override
  void initState() {
    super.initState();
    _isOnlineMode = widget.relId != null && widget.relId!.isNotEmpty;
    if (_isOnlineMode) {
      _initOnline();
    }
  }

  Future<void> _initOnline() async {
    final relId = widget.relId!;
    final rel = _cloudService.cachedRelationship;
    final myUid = _cloudService.currentUid ?? AuthService().currentUid ?? 'u1';
    final firstTurn = rel?.uid1 ?? myUid;
    await _gameService.initConnectFour(relId, firstTurn);
  }

  void _resetGame(String? relId, String myUid, String partnerUid) async {
    VibrationService.light();
    if (_isOnlineMode && relId != null) {
      await _gameService.resetConnectFour(relId, myUid);
    } else {
      setState(() {
        _localBoard = List.filled(rows * cols, 0);
        _localIsPlayer1 = true;
      });
    }
  }

  int _findLowestEmptyRow(List<int> board, int col) {
    for (int r = rows - 1; r >= 0; r--) {
      if (board[r * cols + col] == 0) {
        return r;
      }
    }
    return -1;
  }

  bool _checkConnectFourWin(List<int> board, int player) {
    // Horizontal
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c <= cols - 4; c++) {
        if (board[r * cols + c] == player &&
            board[r * cols + (c + 1)] == player &&
            board[r * cols + (c + 2)] == player &&
            board[r * cols + (c + 3)] == player) {
          return true;
        }
      }
    }
    // Vertical
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r <= rows - 4; r++) {
        if (board[r * cols + c] == player &&
            board[(r + 1) * cols + c] == player &&
            board[(r + 2) * cols + c] == player &&
            board[(r + 3) * cols + c] == player) {
          return true;
        }
      }
    }
    // Diagonal down-right (\)
    for (int r = 0; r <= rows - 4; r++) {
      for (int c = 0; c <= cols - 4; c++) {
        if (board[r * cols + c] == player &&
            board[(r + 1) * cols + (c + 1)] == player &&
            board[(r + 2) * cols + (c + 2)] == player &&
            board[(r + 3) * cols + (c + 3)] == player) {
          return true;
        }
      }
    }
    // Diagonal up-right (/)
    for (int r = 3; r < rows; r++) {
      for (int c = 0; c <= cols - 4; c++) {
        if (board[r * cols + c] == player &&
            board[(r - 1) * cols + (c + 1)] == player &&
            board[(r - 2) * cols + (c + 2)] == player &&
            board[(r - 3) * cols + (c + 3)] == player) {
          return true;
        }
      }
    }
    return false;
  }

  void _handleColumnDrop({
    required int col,
    required bool isOnline,
    required String? relId,
    required String myUid,
    required String partnerUid,
    required bool isUser1,
    required List<int> currentBoard,
    required String currentTurnUid,
    required int scoreYou,
    required int scorePartner,
  }) async {
    final lowestRow = _findLowestEmptyRow(currentBoard, col);
    if (lowestRow == -1) return; // Column full

    if (isOnline) {
      // TURN ENFORCEMENT
      if (currentTurnUid != myUid) {
        VibrationService.error();
        final pName = widget.partnerName ?? 'Partner';
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("It's $pName's turn to drop a heart! ⏳"),
            backgroundColor: AppColors.partner,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      VibrationService.medium();
      final playerPiece = isUser1 ? 1 : 2;
      final newBoard = List<int>.from(currentBoard);
      newBoard[lowestRow * cols + col] = playerPiece;

      final isWin = _checkConnectFourWin(newBoard, playerPiece);
      final isDraw = !isWin && !newBoard.contains(0);

      if (isWin) {
        await _gameService.makeConnectFourMove(
          relId!,
          newBoard,
          partnerUid,
          winner: playerPiece == 1 ? 'u1' : 'u2',
          incrementU1: playerPiece == 1,
          incrementU2: playerPiece == 2,
        );
        _cloudService.addCoupleXp(relId, 120);
      } else if (isDraw) {
        await _gameService.makeConnectFourMove(
          relId!,
          newBoard,
          partnerUid,
          winner: 'draw',
        );
      } else {
        await _gameService.makeConnectFourMove(
          relId!,
          newBoard,
          partnerUid,
        );
      }
    } else {
      // Pass & Play
      VibrationService.medium();
      final playerPiece = _localIsPlayer1 ? 1 : 2;
      setState(() {
        _localBoard[lowestRow * cols + col] = playerPiece;
        _localIsPlayer1 = !_localIsPlayer1;
      });

      final isWin = _checkConnectFourWin(_localBoard, playerPiece);
      if (isWin) {
        if (playerPiece == 1) _localScoreYou += 1;
        if (playerPiece == 2) _localScorePartner += 1;

        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          GameWinModal.show(
            context,
            gameTitle: 'Hearts in a Row',
            winnerName: playerPiece == 1 ? 'You (Pink)' : '${widget.partnerName ?? 'Partner'} (Violet)',
            score1: _localScoreYou,
            score2: _localScorePartner,
            xpEarned: 120,
            onRematch: () => _resetGame(null, myUid, partnerUid),
            relId: widget.relId,
          );
        });
      }
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
          ? _gameService.streamConnectFour(relId)
          : const Stream.empty(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        List<int> board;
        String currentTurnUid;
        int scoreYou;
        int scorePartner;
        String? winner;

        if (_isOnlineMode && data != null) {
          final rawBoard = data['board'] as List<dynamic>?;
          board = rawBoard != null ? rawBoard.map((e) => (e as num).toInt()).toList() : List.filled(rows * cols, 0);
          currentTurnUid = data['currentTurn'] as String? ?? myUid;
          scoreYou = (data['scoreU1'] as num?)?.toInt() ?? 0;
          scorePartner = (data['scoreU2'] as num?)?.toInt() ?? 0;
          winner = data['winner'] as String?;

          if (winner != null && winner.isNotEmpty && _lastShownWinnerRound != '${winner}_${scoreYou}_$scorePartner') {
            _lastShownWinnerRound = '${winner}_${scoreYou}_$scorePartner';
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final didIWin = winner == (isUser1 ? 'u1' : 'u2');
              GameWinModal.show(
                context,
                gameTitle: 'Hearts in a Row',
                winnerName: didIWin ? 'You' : pName,
                score1: scoreYou,
                score2: scorePartner,
                xpEarned: 120,
                onRematch: () => _resetGame(relId, myUid, partnerUid),
                relId: relId,
              );
            });
          }
        } else {
          board = _localBoard;
          currentTurnUid = _localIsPlayer1 ? myUid : partnerUid;
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
                      Text('Hearts in a Row', style: AppTextStyles.title2.copyWith(fontSize: 18)),
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

                  // Score & Turn Pill
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                            const MascotHeart(color: MascotColor.pink, size: 32),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('You', style: AppTextStyles.heading.copyWith(fontSize: 13, color: AppColors.primary)),
                                Text('$scoreYou wins', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isMyTurn ? AppColors.pinkSoft : AppColors.partnerSoft,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: isMyTurn ? AppColors.primary : AppColors.partner, width: 1.5),
                          ),
                          child: Text(
                            isMyTurn ? 'Your Turn! 💖' : "Waiting for $pName...",
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isMyTurn ? AppColors.primary : AppColors.partnerText,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(pName, style: AppTextStyles.heading.copyWith(fontSize: 13, color: AppColors.partner)),
                                Text('$scorePartner wins', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                              ],
                            ),
                            const SizedBox(width: 8),
                            const MascotHeart(color: MascotColor.violet, size: 32),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Drop Column Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(cols, (c) {
                      return GestureDetector(
                        onTap: () {
                          _handleColumnDrop(
                            col: c,
                            isOnline: _isOnlineMode,
                            relId: relId,
                            myUid: myUid,
                            partnerUid: 'u2',
                            isUser1: isUser1,
                            currentBoard: board,
                            currentTurnUid: currentTurnUid,
                            scoreYou: scoreYou,
                            scorePartner: scorePartner,
                          );
                        },
                        child: Container(
                          width: 44,
                          height: 32,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isMyTurn ? AppColors.primary.withValues(alpha: 0.15) : AppColors.card,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.arrow_downward_rounded,
                            size: 18,
                            color: isMyTurn ? AppColors.primary : AppColors.muted,
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 8),

                  // Connect Four Board (7 cols x 6 rows)
                  Container(
                    width: 340,
                    height: 295,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.partnerSoft,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.partner.withValues(alpha: 0.5), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.partner.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: rows * cols,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemBuilder: (context, index) {
                        final col = index % cols;
                        final cellVal = board[index];

                        return GestureDetector(
                          onTap: () {
                            _handleColumnDrop(
                              col: col,
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
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: cellVal == 1
                                  ? const MascotHeart(color: MascotColor.pink, size: 34)
                                  : (cellVal == 2
                                      ? const MascotHeart(color: MascotColor.violet, size: 34)
                                      : Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: AppColors.border.withValues(alpha: 0.5),
                                            shape: BoxShape.circle,
                                          ),
                                        )),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Connect 4 hearts in a row horizontally, vertically, or diagonally!',
                    style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                    textAlign: TextAlign.center,
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
