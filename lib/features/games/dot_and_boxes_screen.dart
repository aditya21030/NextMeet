import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/couple_game_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import 'game_win_modal.dart';

/// NextMeet Dots & Heart Boxes
/// Capture boxes on a 4x4 dot grid with Mascot Hearts.
/// Supports Real-Time Online Multiplayer with Strict Turn Enforcement & Pass-and-Play
class DotAndBoxesScreen extends StatefulWidget {
  final String? relId;
  final String? partnerName;
  final String? partnerUid;
  const DotAndBoxesScreen({super.key, this.relId, this.partnerName, this.partnerUid});

  @override
  State<DotAndBoxesScreen> createState() => _DotAndBoxesScreenState();
}

class _DotAndBoxesScreenState extends State<DotAndBoxesScreen> {
  static const int gridSize = 4; // 4x4 dots = 3x3 boxes (9 boxes)

  final CoupleGameService _gameService = CoupleGameService();
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  late bool _isOnlineMode;

  // Local state for Pass & Play
  List<int> _localHLines = List.filled(12, 0); // 0: none, 1: player1, 2: player2
  List<int> _localVLines = List.filled(12, 0); // 0: none, 1: player1, 2: player2
  List<int> _localBoxes = List.filled(9, 0); // 0: none, 1: player1, 2: player2
  bool _localIsPlayer1 = true;
  int _localScore1 = 0;
  int _localScore2 = 0;

  String? _lastShownWinnerRound;

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
    await _gameService.initDotsAndBoxes(relId, firstTurn);
  }

  void _resetGame(String? relId, String myUid, String partnerUid) async {
    VibrationService.light();
    if (_isOnlineMode && relId != null) {
      await _gameService.resetDotsAndBoxes(relId, myUid);
    } else {
      setState(() {
        _localHLines = List.filled(12, 0);
        _localVLines = List.filled(12, 0);
        _localBoxes = List.filled(9, 0);
        _localIsPlayer1 = true;
        _localScore1 = 0;
        _localScore2 = 0;
      });
    }
  }

  void _onEdgeTap({
    required bool isHorizontal,
    required int row,
    required int col,
    required bool isOnline,
    required String? relId,
    required String myUid,
    required String partnerUid,
    required bool isUser1,
    required List<int> currentHLines,
    required List<int> currentVLines,
    required List<int> currentBoxes,
    required String currentTurnUid,
    required int score1,
    required int score2,
  }) async {
    final pName = widget.partnerName ?? 'Partner';

    if (isOnline) {
      // TURN ENFORCEMENT
      if (currentTurnUid != myUid) {
        VibrationService.error();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("It's $pName's turn to draw a line! ⏳"),
            backgroundColor: AppColors.partner,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final playerVal = (isOnline ? isUser1 : _localIsPlayer1) ? 1 : 2;

    final newHLines = List<int>.from(currentHLines);
    final newVLines = List<int>.from(currentVLines);
    final newBoxes = List<int>.from(currentBoxes);
    int newScore1 = score1;
    int newScore2 = score2;

    if (isHorizontal) {
      final idx = row * 3 + col;
      if (newHLines[idx] != 0) return;
      newHLines[idx] = playerVal;
    } else {
      final idx = row * 4 + col;
      if (newVLines[idx] != 0) return;
      newVLines[idx] = playerVal;
    }

    VibrationService.light();

    // Check newly formed boxes
    bool boxCompleted = false;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final boxIdx = r * 3 + c;
        if (newBoxes[boxIdx] == 0) {
          final top = newHLines[r * 3 + c] != 0;
          final bottom = newHLines[(r + 1) * 3 + c] != 0;
          final left = newVLines[r * 4 + c] != 0;
          final right = newVLines[r * 4 + (c + 1)] != 0;

          if (top && bottom && left && right) {
            newBoxes[boxIdx] = playerVal;
            if (playerVal == 1) newScore1++;
            if (playerVal == 2) newScore2++;
            boxCompleted = true;
          }
        }
      }
    }

    // Determine next turn:
    // In Dots & Boxes, capturing a box gives a bonus turn!
    final nextTurnUid = boxCompleted ? myUid : partnerUid;

    if (boxCompleted) {
      VibrationService.success();
    }

    String? winner;
    if (newScore1 + newScore2 == 9) {
      winner = newScore1 > newScore2 ? 'u1' : (newScore2 > newScore1 ? 'u2' : 'draw');
      if (relId != null) {
        _cloudService.addCoupleXp(relId, 120);
      }
    }

    if (isOnline && relId != null) {
      await _gameService.makeDotsAndBoxesMove(
        relId,
        hLines: newHLines,
        vLines: newVLines,
        boxes: newBoxes,
        nextTurnUid: nextTurnUid,
        scoreU1: newScore1,
        scoreU2: newScore2,
        winner: winner,
      );
    } else {
      setState(() {
        _localHLines = newHLines;
        _localVLines = newVLines;
        _localBoxes = newBoxes;
        _localScore1 = newScore1;
        _localScore2 = newScore2;
        if (!boxCompleted) {
          _localIsPlayer1 = !_localIsPlayer1;
        }
      });

      if (winner != null) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          GameWinModal.show(
            context,
            gameTitle: 'Dots & Heart Boxes',
            winnerName: newScore1 >= newScore2 ? 'You (Pink)' : '$pName (Violet)',
            partnerName: pName,
            score1: newScore1,
            score2: newScore2,
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
          ? _gameService.streamDotsAndBoxes(relId)
          : const Stream.empty(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        List<int> hLines;
        List<int> vLines;
        List<int> boxes;
        String currentTurnUid;
        int score1;
        int score2;
        String? winner;

        if (_isOnlineMode && data != null) {
          hLines = ((data['hLines'] as List<dynamic>?) ?? List.filled(12, 0)).map((e) => (e as num).toInt()).toList();
          vLines = ((data['vLines'] as List<dynamic>?) ?? List.filled(12, 0)).map((e) => (e as num).toInt()).toList();
          boxes = ((data['boxes'] as List<dynamic>?) ?? List.filled(9, 0)).map((e) => (e as num).toInt()).toList();
          currentTurnUid = data['currentTurn'] as String? ?? myUid;
          score1 = (data['scoreU1'] as num?)?.toInt() ?? 0;
          score2 = (data['scoreU2'] as num?)?.toInt() ?? 0;
          winner = data['winner'] as String?;

          if (winner != null && winner.isNotEmpty && _lastShownWinnerRound != '${winner}_${score1}_$score2') {
            _lastShownWinnerRound = '${winner}_${score1}_$score2';
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final didIWin = winner == (isUser1 ? 'u1' : 'u2');
              GameWinModal.show(
                context,
                gameTitle: 'Dots & Heart Boxes',
                winnerName: didIWin ? 'You' : pName,
                score1: score1,
                score2: score2,
                xpEarned: 120,
                onRematch: () => _resetGame(relId, myUid, partnerUid),
                relId: relId,
              );
            });
          }
        } else {
          hLines = _localHLines;
          vLines = _localVLines;
          boxes = _localBoxes;
          currentTurnUid = _localIsPlayer1 ? myUid : partnerUid;
          score1 = _localScore1;
          score2 = _localScore2;
          winner = null;
        }

        final isMyTurn = currentTurnUid == myUid;
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
                      Text('Dots & Heart Boxes', style: AppTextStyles.title2.copyWith(fontSize: 18)),
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

                  // Scores Pill & Active Turn
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
                                Text('$myScore boxes', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isMyTurn ? AppColors.pinkSoft : AppColors.partnerSoft,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: isMyTurn ? AppColors.primary : AppColors.partner, width: 1.5),
                          ),
                          child: Text(
                            isMyTurn ? 'Your Turn ✨' : "Waiting for $pName...",
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
                                Text('$partnerScore boxes', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                              ],
                            ),
                            const SizedBox(width: 8),
                            const MascotHeart(color: MascotColor.violet, size: 34),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4x4 Grid Board
                  Container(
                    width: 320,
                    height: 320,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final dotSpacing = constraints.maxWidth / 3;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Boxes Fill Layer
                            for (int r = 0; r < 3; r++)
                              for (int c = 0; c < 3; c++)
                                Positioned(
                                  left: c * dotSpacing + 8,
                                  top: r * dotSpacing + 8,
                                  width: dotSpacing - 16,
                                  height: dotSpacing - 16,
                                  child: boxes[r * 3 + c] == 0
                                      ? const SizedBox.shrink()
                                      : Center(
                                          child: MascotHeart(
                                            color: boxes[r * 3 + c] == 1 ? MascotColor.pink : MascotColor.violet,
                                            size: 44,
                                          ),
                                        ),
                                ),

                            // Horizontal Lines
                            for (int r = 0; r < 4; r++)
                              for (int c = 0; c < 3; c++)
                                Positioned(
                                  left: c * dotSpacing + 8,
                                  top: r * dotSpacing - 6,
                                  width: dotSpacing - 16,
                                  height: 20,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _onEdgeTap(
                                      isHorizontal: true,
                                      row: r,
                                      col: c,
                                      isOnline: _isOnlineMode,
                                      relId: relId,
                                      myUid: myUid,
                                      partnerUid: partnerUid,
                                      isUser1: isUser1,
                                      currentHLines: hLines,
                                      currentVLines: vLines,
                                      currentBoxes: boxes,
                                      currentTurnUid: currentTurnUid,
                                      score1: score1,
                                      score2: score2,
                                    ),
                                    child: Center(
                                      child: Container(
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: hLines[r * 3 + c] == 0
                                              ? AppColors.border.withValues(alpha: 0.5)
                                              : (hLines[r * 3 + c] == 1 ? AppColors.primary : AppColors.partner),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                            // Vertical Lines
                            for (int r = 0; r < 3; r++)
                              for (int c = 0; c < 4; c++)
                                Positioned(
                                  left: c * dotSpacing - 6,
                                  top: r * dotSpacing + 8,
                                  width: 20,
                                  height: dotSpacing - 16,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _onEdgeTap(
                                      isHorizontal: false,
                                      row: r,
                                      col: c,
                                      isOnline: _isOnlineMode,
                                      relId: relId,
                                      myUid: myUid,
                                      partnerUid: partnerUid,
                                      isUser1: isUser1,
                                      currentHLines: hLines,
                                      currentVLines: vLines,
                                      currentBoxes: boxes,
                                      currentTurnUid: currentTurnUid,
                                      score1: score1,
                                      score2: score2,
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 6,
                                        decoration: BoxDecoration(
                                          color: vLines[r * 4 + c] == 0
                                              ? AppColors.border.withValues(alpha: 0.5)
                                              : (vLines[r * 4 + c] == 1 ? AppColors.primary : AppColors.partner),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                            // Dots (4x4)
                            for (int r = 0; r < 4; r++)
                              for (int c = 0; c < 4; c++)
                                Positioned(
                                  left: c * dotSpacing - 6,
                                  top: r * dotSpacing - 6,
                                  width: 12,
                                  height: 12,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.ink,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                          ],
                        );
                      },
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
