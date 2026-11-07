import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import 'game_win_modal.dart';

/// NextMeet Couple Memory Match Card Game
/// Strictly following NextMeet Redesign.pdf (Page 52)
class MemoryMatchScreen extends StatefulWidget {
  final String? relId;
  const MemoryMatchScreen({super.key, this.relId});

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen> {
  final List<String> _emojis = ['💖', '💌', '☕', '✈️', '💍', '📸', '🍕', '🎉'];
  late List<String> _cards;
  late List<bool> _revealed;
  late List<bool> _matched;
  int? _firstFlippedIndex;
  bool _isBusy = false;
  int _turns = 0;
  int _pairsFound = 0;
  Timer? _flipTimer;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    _flipTimer?.cancel();
    _completeTimer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    _cards = [..._emojis, ..._emojis]..shuffle();
    _revealed = List.filled(16, false);
    _matched = List.filled(16, false);
    _firstFlippedIndex = null;
    _isBusy = false;
    _turns = 0;
    _pairsFound = 0;
  }

  void _onCardTap(int index) {
    if (_isBusy || _revealed[index] || _matched[index]) return;

    VibrationService.light();
    setState(() {
      _revealed[index] = true;
    });

    if (_firstFlippedIndex == null) {
      _firstFlippedIndex = index;
    } else {
      _turns += 1;
      _isBusy = true;
      final first = _firstFlippedIndex!;
      final second = index;

      if (_cards[first] == _cards[second]) {
        // Matched!
        VibrationService.success();
        setState(() {
          _matched[first] = true;
          _matched[second] = true;
          _pairsFound += 1;
          _firstFlippedIndex = null;
          _isBusy = false;
        });

        if (_pairsFound == _emojis.length) {
          // Completed
          _completeTimer?.cancel();
          _completeTimer = Timer(const Duration(milliseconds: 400), () {
            if (!mounted) return;
            GameWinModal.show(
              context,
              relId: widget.relId,
              gameTitle: 'Memory Match',
              winnerName: 'Both of You',
              score1: _pairsFound,
              score2: _turns,
              xpEarned: 140,
              onRematch: () => setState(_startNewGame),
            );
          });
        }
      } else {
        // Did not match
        _flipTimer?.cancel();
        _flipTimer = Timer(const Duration(milliseconds: 900), () {
          if (mounted) {
            setState(() {
              _revealed[first] = false;
              _revealed[second] = false;
              _firstFlippedIndex = null;
              _isBusy = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  Text('Memory Match', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                  GestureDetector(
                    onTap: () => setState(_startNewGame),
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

              const SizedBox(height: 16),

              // Pairs Found and Turns Tracker (Page 52)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Text('PAIRS FOUND', style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.muted)),
                          const SizedBox(height: 2),
                          Text('$_pairsFound / ${_emojis.length}', style: AppTextStyles.heading.copyWith(color: AppColors.primary, fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Text('TURNS', style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.muted)),
                          const SizedBox(height: 2),
                          Text('$_turns', style: AppTextStyles.heading.copyWith(color: AppColors.partner, fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 4x4 Cards Grid (Page 52)
              Center(
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 16,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      final isRevealed = _revealed[index] || _matched[index];
                      final isMatched = _matched[index];

                      return GestureDetector(
                        onTap: () => _onCardTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isMatched
                                ? AppColors.mintSoft
                                : (isRevealed ? Colors.white : AppColors.pinkSoft),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isMatched ? AppColors.mint : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: isRevealed
                                ? Text(_cards[index], style: const TextStyle(fontSize: 28))
                                : const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 24),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Bottom hint
              Text(
                'Find all 8 romantic matching pairs together 💕',
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
