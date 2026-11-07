import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import 'game_win_modal.dart';

/// NextMeet Emoji Cipher
/// Guess famous romantic movies & songs from emoji clues!
class EmojiCipherScreen extends StatefulWidget {
  final String? relId;
  final String? partnerName;
  const EmojiCipherScreen({super.key, this.relId, this.partnerName});

  @override
  State<EmojiCipherScreen> createState() => _EmojiCipherScreenState();
}

class _EmojiCipherScreenState extends State<EmojiCipherScreen> {
  int _currentIndex = 0;
  String _typedAnswer = '';
  int _score = 0;

  final List<Map<String, dynamic>> _puzzles = [
    {
      'emojis': '🚢 🧊 💔 🚪',
      'category': 'Movie',
      'answer': 'TITANIC',
      'hint': 'Jack and Rose, "Never let go"',
    },
    {
      'emojis': '🦁 👑 🌅 🐗',
      'category': 'Movie',
      'answer': 'LION KING',
      'hint': 'Can you feel the love tonight?',
    },
    {
      'emojis': '🪐 🚀 ⏳ 👨‍👧',
      'category': 'Movie',
      'answer': 'INTERSTELLAR',
      'hint': 'Love is the one thing that transcends time and space',
    },
    {
      'emojis': '💃 🕺 🎹 🎷 🌃',
      'category': 'Movie',
      'answer': 'LA LA LAND',
      'hint': 'City of stars, are you shining just for me?',
    },
    {
      'emojis': '☕ ☔ 📖 💑',
      'category': 'Date Idea',
      'answer': 'BOOKSTORE',
      'hint': 'Cozy coffee & reading books on a rainy day',
    },
  ];

  void _onLetterTap(String letter) {
    final target = (_puzzles[_currentIndex]['answer'] as String).replaceAll(' ', '');
    if (_typedAnswer.length < target.length) {
      VibrationService.light();
      setState(() {
        _typedAnswer += letter;
      });

      if (_typedAnswer.length == target.length) {
        _verifyAnswer();
      }
    }
  }

  void _onBackspace() {
    if (_typedAnswer.isNotEmpty) {
      VibrationService.light();
      setState(() {
        _typedAnswer = _typedAnswer.substring(0, _typedAnswer.length - 1);
      });
    }
  }

  void _verifyAnswer() {
    final target = (_puzzles[_currentIndex]['answer'] as String).replaceAll(' ', '');
    if (_typedAnswer == target) {
      VibrationService.success();
      _score += 1;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correct! 🎉 +60 XP'), duration: Duration(milliseconds: 1000)),
      );

      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        if (_currentIndex < _puzzles.length - 1) {
          setState(() {
            _currentIndex += 1;
            _typedAnswer = '';
          });
        } else {
          // Finished
          if (widget.relId != null) {
            CloudRelationshipService().addCoupleXp(widget.relId!, 120);
          }
          GameWinModal.show(
            context,
            gameTitle: 'Emoji Cipher',
            winnerName: 'Solved All Puzzles!',
            partnerName: widget.partnerName ?? 'Partner',
            score1: _score,
            score2: _puzzles.length,
            xpEarned: 120,
            relId: widget.relId,
          );
        }
      });
    } else {
      VibrationService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not quite! Try again! 💭'), duration: Duration(milliseconds: 1000)),
      );
      setState(() {
        _typedAnswer = '';
      });
    }
  }

  List<String> _getScrambledPool(String answer) {
    final clean = answer.replaceAll(' ', '');
    final chars = clean.split('');
    const extra = ['E', 'A', 'R', 'T', 'O', 'S', 'L', 'N'];
    final pool = [...chars, ...extra.take(12 - chars.length)]..shuffle();
    return pool;
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = _puzzles[_currentIndex];
    final target = (puzzle['answer'] as String).replaceAll(' ', '');
    final pool = _getScrambledPool(puzzle['answer'] as String);

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
                  Text('Emoji Cipher', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.butterSoft,
                      borderRadius: BorderRadius.circular(AppRadius.badge),
                    ),
                    child: Text(
                      '${_currentIndex + 1}/${_puzzles.length}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.butterText, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Clue Card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.hero),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.pinkSoft,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        puzzle['category'] as String,
                        style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      puzzle['emojis'] as String,
                      style: const TextStyle(fontSize: 42, letterSpacing: 8),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Hint: ${puzzle['hint']}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Answer Slots
              Center(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: List.generate(target.length, (i) {
                    final letter = i < _typedAnswer.length ? _typedAnswer[i] : '';
                    return Container(
                      width: 36,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: letter.isNotEmpty ? AppColors.primary : AppColors.border,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        letter,
                        style: AppTextStyles.title1.copyWith(fontSize: 18, color: AppColors.primary),
                      ),
                    );
                  }),
                ),
              ),

              const Spacer(),

              // Scrambled Letter Tiles
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ...pool.map((char) {
                    return GestureDetector(
                      onTap: () => _onLetterTap(char),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(char, style: AppTextStyles.title1.copyWith(fontSize: 18, color: AppColors.ink)),
                      ),
                    );
                  }),
                  GestureDetector(
                    onTap: _onBackspace,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.pinkSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.backspace_outlined, size: 20, color: AppColors.primary),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
