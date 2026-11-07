import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import 'game_win_modal.dart';

/// NextMeet Romantic Couple Word Search
/// Find sweet hidden love words together in an 8x8 letter garden!
class CoupleWordSearchScreen extends StatefulWidget {
  final String? relId;
  final String? partnerName;
  const CoupleWordSearchScreen({super.key, this.relId, this.partnerName});

  @override
  State<CoupleWordSearchScreen> createState() => _CoupleWordSearchScreenState();
}

class _CoupleWordSearchScreenState extends State<CoupleWordSearchScreen> {
  // Predefined 8x8 romantic letter garden
  final List<List<String>> _grid = const [
    ['S', 'O', 'U', 'L', 'M', 'A', 'T', 'E'],
    ['C', 'W', 'H', 'I', 'S', 'P', 'E', 'R'],
    ['U', 'H', 'E', 'A', 'R', 'T', 'S', 'K'],
    ['D', 'L', 'O', 'V', 'E', 'L', 'Y', 'I'],
    ['D', 'S', 'W', 'E', 'E', 'T', 'Y', 'S'],
    ['L', 'U', 'T', 'R', 'U', 'S', 'T', 'S'],
    ['E', 'B', 'L', 'U', 'S', 'H', 'Y', 'E'],
    ['F', 'O', 'R', 'E', 'V', 'E', 'R', 'S'],
  ];

  // Target romantic words and their definitions
  final List<Map<String, dynamic>> _wordBank = [
    {'word': 'SOULMATE', 'hint': 'Two halves of one soul ✨', 'emoji': '💍'},
    {'word': 'FOREVER', 'hint': 'Always by your side ♾️', 'emoji': '⏳'},
    {'word': 'CUDDLE', 'hint': 'Warm sleepy hugs in bed 🧸', 'emoji': '🫂'},
    {'word': 'KISSES', 'hint': 'Sweet touches on your lips 💋', 'emoji': '💋'},
    {'word': 'WHISPER', 'hint': 'Late night secrets at 2 AM 🌙', 'emoji': '🤫'},
    {'word': 'HEARTS', 'hint': 'Beating in rhythm with yours 💓', 'emoji': '💖'},
    {'word': 'SWEET', 'hint': 'Tender like morning syrup 🍯', 'emoji': '🍯'},
    {'word': 'LOVELY', 'hint': 'How you look every day 🌸', 'emoji': '✨'},
  ];

  final Set<String> _foundWords = {};
  final List<Point<int>> _selectedCells = [];
  final Set<String> _permanentlyFoundCells = {};

  void _onCellTap(int row, int col) {
    VibrationService.light();

    setState(() {
      final cellPoint = Point(row, col);
      if (_selectedCells.contains(cellPoint)) {
        _selectedCells.remove(cellPoint);
      } else {
        _selectedCells.add(cellPoint);
      }

      // Check if current selection forms any target word
      final currentLetters = _selectedCells.map((p) => _grid[p.x][p.y]).join();
      final reversedLetters = currentLetters.split('').reversed.join();

      for (final item in _wordBank) {
        final target = item['word'] as String;
        if (!_foundWords.contains(target)) {
          if (currentLetters == target || reversedLetters == target) {
            // Word found!
            _foundWords.add(target);
            for (final p in _selectedCells) {
              _permanentlyFoundCells.add('${p.x}_${p.y}');
            }
            _selectedCells.clear();
            VibrationService.success();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Found "${item['word']}"! ${item['emoji']} ${item['hint']}'),
                backgroundColor: AppColors.primary,
                duration: const Duration(milliseconds: 1400),
              ),
            );

            // Check if game won
            if (_foundWords.length >= 6) {
              _onGameComplete();
            }
            break;
          }
        }
      }
    });
  }

  void _clearSelection() {
    VibrationService.light();
    setState(() {
      _selectedCells.clear();
    });
  }

  void _onGameComplete() {
    if (widget.relId != null) {
      CloudRelationshipService().addCoupleXp(widget.relId!, 130);
    }
    GameWinModal.show(
      context,
      gameTitle: 'Romantic Word Search',
      winnerName: '${_foundWords.length} Words Found!',
      partnerName: widget.partnerName ?? 'Partner',
      score1: _foundWords.length,
      score2: _wordBank.length,
      xpEarned: 130,
      relId: widget.relId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSelectionWord = _selectedCells.map((p) => _grid[p.x][p.y]).join();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Romantic Word Search',
          style: AppTextStyles.title2.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.partnerSoft,
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                ),
                child: Text(
                  '${_foundWords.length}/${_wordBank.length}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.partnerText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // Selected Letters Preview Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentSelectionWord.isEmpty
                            ? 'Tap adjacent letters to spell words...'
                            : currentSelectionWord,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: currentSelectionWord.isEmpty ? AppColors.textSecondary : AppColors.primary,
                        ),
                      ),
                    ),
                    if (_selectedCells.isNotEmpty)
                      GestureDetector(
                        onTap: _clearSelection,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(AppRadius.badge),
                          ),
                          child: Text(
                            'Clear',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 8x8 Word Search Grid
              AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: 64,
                    itemBuilder: (context, index) {
                      final r = index ~/ 8;
                      final c = index % 8;
                      final letter = _grid[r][c];

                      final isSelected = _selectedCells.contains(Point(r, c));
                      final isFound = _permanentlyFoundCells.contains('${r}_$c');

                      Color cellBg = Colors.transparent;
                      Color textColor = AppColors.textPrimary;
                      Border? border;

                      if (isSelected) {
                        cellBg = AppColors.primary;
                        textColor = Colors.white;
                      } else if (isFound) {
                        cellBg = AppColors.mintSoft;
                        textColor = AppColors.mintText;
                        border = Border.all(color: AppColors.mint, width: 1);
                      }

                      return GestureDetector(
                        onTap: () => _onCellTap(r, c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: cellBg,
                            borderRadius: BorderRadius.circular(6),
                            border: border,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            letter,
                            style: AppTextStyles.title2.copyWith(
                              fontSize: 15,
                              color: textColor,
                              fontWeight: isSelected || isFound ? FontWeight.w900 : FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Word Bank Checklist
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Word Garden', style: AppTextStyles.heading.copyWith(fontSize: 16)),
              ),
              const SizedBox(height: 6),

              Expanded(
                child: ListView.separated(
                  itemCount: _wordBank.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = _wordBank[index];
                    final word = item['word'] as String;
                    final isFound = _foundWords.contains(word);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isFound ? AppColors.mintSoft.withValues(alpha: 0.5) : AppColors.card,
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                        border: Border.all(
                          color: isFound ? AppColors.mint : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(item['emoji'] as String, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  word,
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    decoration: isFound ? TextDecoration.lineThrough : null,
                                    color: isFound ? AppColors.mintText : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  item['hint'] as String,
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isFound)
                            const Icon(Icons.check_circle_rounded, color: AppColors.mintText, size: 20)
                          else
                            const Icon(Icons.circle_outlined, color: AppColors.border, size: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),

              if (_foundWords.length >= 6) ...[
                const SizedBox(height: 8),
                PrimaryButton(
                  text: 'Claim Word Garden XP ✨',
                  isLoading: false,
                  onPressed: _onGameComplete,
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class Point<T> {
  final T x;
  final T y;
  const Point(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}
