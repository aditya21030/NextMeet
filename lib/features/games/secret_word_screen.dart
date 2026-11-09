import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import 'game_win_modal.dart';

/// NextMeet Wordle for Lovers (Secret Love Word)
/// 5-letter romantic word guessing game with tactile letter evaluations.
class SecretWordScreen extends StatefulWidget {
  final String? relId;
  final String? partnerName;
  const SecretWordScreen({super.key, this.relId, this.partnerName});

  @override
  State<SecretWordScreen> createState() => _SecretWordScreenState();
}

class _SecretWordScreenState extends State<SecretWordScreen> {
  final List<String> _words = [
    'HEART', 'SWEET', 'DREAM', 'TOUCH', 'HONEY', 'SMILE',
    'MAGIC', 'FLAME', 'KISSY', 'ANGEL', 'TRUST', 'CHARM',
  ];

  late String _secretWord;
  final List<String> _guesses = [];
  String _currentGuess = '';
  final int _maxGuesses = 6;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    setState(() {
      _words.shuffle();
      _secretWord = _words.first;
      _guesses.clear();
      _currentGuess = '';
      _isGameOver = false;
    });
  }

  void _onKeyPress(String key) {
    if (_isGameOver) return;
    VibrationService.light();

    if (key == 'ENTER') {
      if (_currentGuess.length == 5) {
        _submitGuess();
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Word must be 5 letters! 🔤'),
            duration: Duration(milliseconds: 1000),
          ),
        );
      }
    } else if (key == 'BACK') {
      if (_currentGuess.isNotEmpty) {
        setState(() {
          _currentGuess = _currentGuess.substring(0, _currentGuess.length - 1);
        });
      }
    } else {
      if (_currentGuess.length < 5) {
        setState(() {
          _currentGuess += key;
        });
      }
    }
  }

  void _submitGuess() {
    final guess = _currentGuess.toUpperCase();
    setState(() {
      _guesses.add(guess);
      _currentGuess = '';
    });

    if (guess == _secretWord) {
      _isGameOver = true;
      VibrationService.success();
      if (widget.relId != null) {
        CloudRelationshipService().addCoupleXp(widget.relId!, 120);
      }
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        GameWinModal.show(
          context,
          gameTitle: 'Secret Love Word',
          winnerName: 'You Solved "$_secretWord"!',
          partnerName: widget.partnerName ?? 'Partner',
          score1: _guesses.length,
          score2: _maxGuesses,
          xpEarned: 120,
          onRematch: _startNewGame,
          relId: widget.relId,
        );
      });
    } else if (_guesses.length >= _maxGuesses) {
      _isGameOver = true;
      VibrationService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('The secret word was "$_secretWord"! 💕 Try again!'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Color _getTileColor(String letter, int index, String rowWord) {
    if (letter.isEmpty) return Colors.white;
    if (_secretWord[index] == letter) {
      return AppColors.mint;
    }
    if (_secretWord.contains(letter)) {
      return AppColors.butter;
    }
    return AppColors.borderStrong;
  }

  Color _getKeyColor(String key) {
    bool isGreen = false;
    bool isYellow = false;
    bool isGrey = false;

    for (final guess in _guesses) {
      for (int i = 0; i < guess.length; i++) {
        if (guess[i] == key) {
          if (_secretWord[i] == key) {
            isGreen = true;
          } else if (_secretWord.contains(key)) {
            isYellow = true;
          } else {
            isGrey = true;
          }
        }
      }
    }

    if (isGreen) return AppColors.mint;
    if (isYellow) return AppColors.butter;
    if (isGrey) return AppColors.border;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Row(
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
                      'Secret Love Word',
                      style: AppTextStyles.title2.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: _startNewGame,
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
            ),

            const SizedBox(height: 12),

            Text(
              'Guess the 5-letter romantic word in 6 tries 💌',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),

            const SizedBox(height: 12),

            // 6 Rows x 5 Letters Grid
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 270,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_maxGuesses, (r) {
                      String rowWord = '';
                      bool isCurrentRow = false;
                      if (r < _guesses.length) {
                        rowWord = _guesses[r];
                      } else if (r == _guesses.length) {
                        rowWord = _currentGuess;
                        isCurrentRow = true;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(5, (c) {
                            final letter = c < rowWord.length ? rowWord[c] : '';
                            Color tileColor = Colors.white;
                            Color textColor = AppColors.ink;

                            if (!isCurrentRow && r < _guesses.length) {
                              tileColor = _getTileColor(letter, c, rowWord);
                              textColor = tileColor == AppColors.mint ? Colors.white : AppColors.ink;
                            }

                            return Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: tileColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: letter.isNotEmpty ? AppColors.primary : AppColors.border,
                                  width: letter.isNotEmpty ? 2 : 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                letter,
                                style: AppTextStyles.display.copyWith(
                                  fontSize: 20,
                                  color: textColor,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

            // Keyboard
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  _keyboardRow(['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P']),
                  const SizedBox(height: 6),
                  _keyboardRow(['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L']),
                  const SizedBox(height: 6),
                  _keyboardRow(['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'BACK']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _keyboardRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((k) {
        final isSpecial = k == 'ENTER' || k == 'BACK';
        final keyColor = _getKeyColor(k);

        return GestureDetector(
          onTap: () => _onKeyPress(k),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 42,
            width: isSpecial ? 54 : 30,
            decoration: BoxDecoration(
              color: keyColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            alignment: Alignment.center,
            child: isSpecial
                ? (k == 'BACK'
                    ? const Icon(Icons.backspace_outlined, size: 16, color: AppColors.ink)
                    : Text('GO', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w900, color: AppColors.primary)))
                : Text(k, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink)),
          ),
        );
      }).toList(),
    );
  }
}
