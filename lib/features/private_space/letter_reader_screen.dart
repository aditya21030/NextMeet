import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import 'new_letter_screen.dart';

/// NextMeet Letter Reader Screen (Stationery View & Reactions)
/// Strictly following NextMeet Redesign.pdf (Page 64)
class LetterReaderScreen extends StatefulWidget {
  final String title;
  final String content;
  final String date;
  final String sender;
  final Color sealColor;

  const LetterReaderScreen({
    super.key,
    required this.title,
    required this.content,
    required this.date,
    required this.sender,
    this.sealColor = AppColors.primary,
  });

  @override
  State<LetterReaderScreen> createState() => _LetterReaderScreenState();
}

class _LetterReaderScreenState extends State<LetterReaderScreen> {
  bool _hasLoved = false;
  final List<String> _reactions = ['❤️', '🥺', '🥰', '✨'];

  void _shareLetter() {
    VibrationService.light();
    final message =
        '${widget.title}\n\n${widget.content}\n\n— Always yours, ${widget.sender} (${widget.date})\n\nSent via NextMeet ❤️';
    Share.share(message, subject: widget.title);
  }

  void _saveToMemories() {
    VibrationService.success();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved this letter to your Memories gallery! 💌✨'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Top Navigation Bar
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
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: AppColors.ink),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Letter from ${widget.sender}',
                      style: AppTextStyles.title2.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _shareLetter,
                    icon: const Icon(Icons.share_outlined,
                        color: AppColors.ink, size: 22),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Scrollable Warm Stationery Letter
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBFD), // Warm parchment pink tint
                    borderRadius: BorderRadius.circular(AppRadius.hero),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Wax Seal Emblem (Page 64)
                      Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: widget.sealColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.favorite_rounded,
                                color: Colors.white, size: 24),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Date Pill
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border:
                                Border.all(color: AppColors.border, width: 1.0),
                          ),
                          child: Text(
                            widget.date,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Letter Title
                      Text(
                        widget.title,
                        style: AppTextStyles.title1.copyWith(
                          fontSize: 22,
                          color: AppColors.ink,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 8),
                      Container(height: 1.5, color: AppColors.border),
                      const SizedBox(height: 16),

                      // Heartfelt Body Content
                      Text(
                        widget.content,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 16,
                          height: 1.7,
                          color: AppColors.ink,
                          letterSpacing: 0.2,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Signoff
                      Align(
                        alignment: Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Forever yours,',
                              style: AppTextStyles.caption.copyWith(
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.sender,
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 18,
                                color: widget.sealColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Action Bar (Reactions, Save, Reply) - Page 64
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  // Reaction Pill
                  GestureDetector(
                    onTap: () {
                      VibrationService.medium();
                      setState(() => _hasLoved = !_hasLoved);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _hasLoved ? AppColors.pinkSoft : Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: _hasLoved
                              ? AppColors.primary
                              : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _hasLoved
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _hasLoved ? 'Loved' : 'React',
                            style: AppTextStyles.button.copyWith(
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Save to Memories Button
                  GestureDetector(
                    onTap: _saveToMemories,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: const Icon(Icons.bookmark_border_rounded,
                          color: AppColors.ink, size: 20),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Reply Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        VibrationService.light();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NewLetterScreen(),
                          ),
                        );
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Write Reply ✍️',
                          style: AppTextStyles.button
                              .copyWith(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
