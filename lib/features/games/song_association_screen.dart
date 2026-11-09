import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import 'game_win_modal.dart';

/// NextMeet Song Association
/// Race against the 15-second timer to think of a song containing the romantic keyword!
class SongAssociationScreen extends StatefulWidget {
  final String? relId;
  final String? partnerName;
  const SongAssociationScreen({super.key, this.relId, this.partnerName});

  @override
  State<SongAssociationScreen> createState() => _SongAssociationScreenState();
}

class _SongAssociationScreenState extends State<SongAssociationScreen> {
  final List<String> _keywords = [
    'LOVE', 'KISS', 'BABY', 'FOREVER', 'NIGHT',
    'HEART', 'DREAM', 'HOLD', 'TOUCH', 'STARS',
  ];

  int _currentIndex = 0;
  int _secondsLeft = 15;
  Timer? _timer;
  int _score = 0;
  bool _isPlaying = false;
  final TextEditingController _songController = TextEditingController();

  @override
  void dispose() {
    _timer?.cancel();
    _songController.dispose();
    super.dispose();
  }

  void _startRound() {
    _songController.clear();
    setState(() {
      _secondsLeft = 15;
      _isPlaying = true;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
        if (_secondsLeft <= 3) {
          VibrationService.light();
        }
      } else {
        timer.cancel();
        _onTimeUp();
      }
    });
  }

  void _onTimeUp() {
    VibrationService.error();
    setState(() => _isPlaying = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time\'s up! ⏰ Next word!'), duration: Duration(milliseconds: 1000)),
    );
    _advanceWord();
  }

  void _onSubmitSong() {
    final text = _songController.text.trim();
    if (text.isEmpty) return;

    _timer?.cancel();
    VibrationService.success();
    _score += 1;
    setState(() => _isPlaying = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Awesome song! "$text" 🎵 +50 XP'), duration: const Duration(milliseconds: 1000)),
    );

    _advanceWord();
  }

  void _advanceWord() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_currentIndex < _keywords.length - 1) {
        setState(() {
          _currentIndex++;
        });
        _startRound();
      } else {
        if (widget.relId != null) {
          CloudRelationshipService().addCoupleXp(widget.relId!, _score * 40);
        }
        GameWinModal.show(
          context,
          gameTitle: 'Song Association',
          winnerName: 'Score: $_score / ${_keywords.length} Songs!',
          partnerName: widget.partnerName ?? 'Partner',
          score1: _score,
          score2: _keywords.length - _score,
          xpEarned: _score * 40,
          relId: widget.relId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final word = _keywords[_currentIndex];

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
                  Expanded(
                    child: Text(
                      'Song Association',
                      style: AppTextStyles.title2.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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

              const SizedBox(height: 24),

              // Timer Circular Progress
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: _secondsLeft / 15.0,
                      strokeWidth: 8,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(
                        _secondsLeft <= 3 ? AppColors.danger : AppColors.primary,
                      ),
                    ),
                  ),
                  Text(
                    '$_secondsLeft',
                    style: AppTextStyles.display.copyWith(
                      fontSize: 32,
                      color: _secondsLeft <= 3 ? AppColors.danger : AppColors.ink,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Keyword Hero Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.hero),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    Text('Keyword ${_currentIndex + 1} of ${_keywords.length}', style: AppTextStyles.caption),
                    const SizedBox(height: 12),
                    Text(
                      word,
                      style: AppTextStyles.display.copyWith(
                        fontSize: 36,
                        color: AppColors.primary,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Name or sing any song containing this word!',
                      style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_isPlaying) ...[
                TextField(
                  controller: _songController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'e.g. Can\'t Help Falling In Love',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                      onPressed: _onSubmitSong,
                    ),
                  ),
                  onSubmitted: (_) => _onSubmitSong(),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: 'Submit Song 🎵',
                  onPressed: _onSubmitSong,
                ),
              ] else ...[
                PrimaryButton(
                  text: 'Start Round ⏱️',
                  onPressed: _startRound,
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
