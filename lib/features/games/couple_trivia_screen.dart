import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import 'game_win_modal.dart';

/// NextMeet Couple Trivia Battle
/// Fast-paced romantic & pop culture trivia quiz for couples.
class CoupleTriviaScreen extends StatefulWidget {
  final String? relId;
  final String? partnerName;
  const CoupleTriviaScreen({super.key, this.relId, this.partnerName});

  @override
  State<CoupleTriviaScreen> createState() => _CoupleTriviaScreenState();
}

class _CoupleTriviaScreenState extends State<CoupleTriviaScreen> {
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _answered = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Which country celebrates "Valentine\'s Day" as Friend\'s Day?',
      'options': ['Finland', 'Japan', 'Italy', 'Brazil'],
      'correct': 0,
      'fact': 'In Finland, Ystävänpäivä focuses on celebrating friendship! 🇫🇮',
    },
    {
      'question': 'In the movie "Titanic", what is the name of the famous blue diamond?',
      'options': ['Heart of the Ocean', 'Star of Hope', 'Tears of Atlantis', 'Blue Moon'],
      'correct': 0,
      'fact': 'Rose wears the fictional Heart of the Ocean necklace. 💎',
    },
    {
      'question': 'Which hormone is scientifically nicknamed the "Cuddle Hormone"?',
      'options': ['Dopamine', 'Oxytocin', 'Serotonin', 'Endorphin'],
      'correct': 1,
      'fact': 'Oxytocin is released during hugs, kisses, and touches! 🤗',
    },
    {
      'question': 'In Shakespeare\'s Romeo & Juliet, where is the famous balcony scene located?',
      'options': ['Florence', 'Rome', 'Verona', 'Venice'],
      'correct': 2,
      'fact': 'Verona, Italy attracts millions of lovers every year! 🏰',
    },
    {
      'question': 'What does holding hands with someone you love scientifically do?',
      'options': ['Increases body heat', 'Lowers physical pain & stress', 'Accelerates sleep', 'Improves vision'],
      'correct': 1,
      'fact': 'Hand-holding syncs brain waves and calms the nervous system. 🤝',
    },
  ];

  void _onAnswerSelected(int index) {
    if (_answered) return;
    VibrationService.medium();

    final correct = _questions[_currentIndex]['correct'] as int;
    final isCorrect = index == correct;

    if (isCorrect) {
      _score += 1;
      VibrationService.success();
    } else {
      VibrationService.error();
    }

    setState(() {
      _selectedAnswer = index;
      _answered = true;
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex += 1;
          _selectedAnswer = null;
          _answered = false;
        });
      } else {
        // Complete
        if (widget.relId != null) {
          CloudRelationshipService().addCoupleXp(widget.relId!, _score * 30);
        }
        GameWinModal.show(
          context,
          gameTitle: 'Couple Trivia Battle',
          winnerName: 'Score: $_score / ${_questions.length} Correct!',
          partnerName: widget.partnerName ?? 'Partner',
          score1: _score,
          score2: _questions.length - _score,
          xpEarned: _score * 30,
          relId: widget.relId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];

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
                  Text('Couple Trivia Battle', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.mintSoft,
                      borderRadius: BorderRadius.circular(AppRadius.badge),
                    ),
                    child: Text(
                      'Score: $_score',
                      style: AppTextStyles.caption.copyWith(color: AppColors.mintText, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _questions.length,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),

              const SizedBox(height: 24),

              // Question Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.hero),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      'Question ${_currentIndex + 1} of ${_questions.length}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      q['question'] as String,
                      style: AppTextStyles.title1.copyWith(fontSize: 19, height: 1.3),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4 Choice Options
              Expanded(
                child: ListView.separated(
                  itemCount: (q['options'] as List<String>).length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = (q['options'] as List<String>)[index];
                    final isCorrect = index == q['correct'];
                    final isSelected = index == _selectedAnswer;

                    Color bg = Colors.white;
                    Color border = AppColors.border;
                    Color textColor = AppColors.ink;

                    if (_answered) {
                      if (isCorrect) {
                        bg = AppColors.mintSoft;
                        border = AppColors.mint;
                        textColor = AppColors.mintText;
                      } else if (isSelected) {
                        bg = AppColors.pinkSoft;
                        border = AppColors.danger;
                        textColor = AppColors.danger;
                      }
                    }

                    return GestureDetector(
                      onTap: () => _onAnswerSelected(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: border, width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                option,
                                style: AppTextStyles.heading.copyWith(fontSize: 15, color: textColor),
                              ),
                            ),
                            if (_answered && isCorrect)
                              const Icon(Icons.check_circle_rounded, color: AppColors.mintText, size: 22)
                            else if (_answered && isSelected && !isCorrect)
                              const Icon(Icons.cancel_rounded, color: AppColors.danger, size: 22),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              if (_answered)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    q['fact'] as String,
                    style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
