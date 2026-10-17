import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:google_fonts/google_fonts.dart';

import '../core/constants.dart';
import '../core/daily_love_notes.dart';
import '../core/models/relationship_model.dart';
import '../core/services/cloud_relationship_service.dart';
import '../core/services/vibration_service.dart';
import 'primary_button.dart';

class ScratchLoveNoteCard extends StatefulWidget {
  final RelationshipModel relationship;
  final String currentUid;

  const ScratchLoveNoteCard({
    super.key,
    required this.relationship,
    required this.currentUid,
  });

  @override
  State<ScratchLoveNoteCard> createState() => _ScratchLoveNoteCardState();
}

class _ScratchLoveNoteCardState extends State<ScratchLoveNoteCard> with SingleTickerProviderStateMixin {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final List<List<Offset>> _strokes = [];
  bool _isScratched = false;
  bool _isLoading = true;
  double _scratchProgress = 0.0;
  int _pointCount = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _checkDailyScratchStatus();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkDailyScratchStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = DailyLoveNotes.getTodayKey();
      final bool alreadyScratched = prefs.getBool('scratch_note_${todayKey}_${widget.currentUid}') ?? false;
      if (mounted) {
        setState(() {
          _isScratched = alreadyScratched;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markScratched() async {
    if (_isScratched) return;
    VibrationService.success();
    _fadeController.forward();
    setState(() => _isScratched = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = DailyLoveNotes.getTodayKey();
      await prefs.setBool('scratch_note_${todayKey}_${widget.currentUid}', true);
    } catch (_) {}
  }

  void _onPanStart(DragStartDetails details) {
    if (_isScratched) return;
    HapticFeedback.selectionClick();
    setState(() {
      _strokes.add([details.localPosition]);
      _pointCount++;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isScratched) return;
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.last.add(details.localPosition);
        _pointCount++;
        _scratchProgress = (_pointCount / 45.0).clamp(0.0, 1.0);
      });

      if (_pointCount % 6 == 0) {
        HapticFeedback.selectionClick();
      }

      // Once threshold is reached, automatically unlock the note!
      if (_scratchProgress >= 1.0 && !_isScratched) {
        _markScratched();
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_scratchProgress >= 0.75 && !_isScratched) {
      _markScratched();
    }
  }

  void _showWriteNoteSheet(BuildContext context, String partnerName, String todayKey) {
    final TextEditingController textController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: AppSpacing.l,
            right: AppSpacing.l,
            top: AppSpacing.l,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.l,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text('LOVE NOTE FOR $partnerName', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Leave a secret love note under foil 💌',
                style: AppTextStyles.h3.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                'When $partnerName rubs off the scratch-off foil today, your personal words will be revealed!',
                style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: textController,
                autofocus: true,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Whisper something sweet, romantic, or comforting...',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Send Love Note 💌',
                isLoading: isSubmitting,
                onPressed: () async {
                  final text = textController.text.trim();
                  if (text.isEmpty) return;
                  setModalState(() => isSubmitting = true);
                  VibrationService.success();
                  await _cloudService.submitCustomScratchNote(widget.relationship.id!, todayKey, text);
                  if (mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() => textController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    final today = DateTime.now();
    final todayKey = DailyLoveNotes.getTodayKey(today);
    final partnerName = widget.relationship.getDisplayPartnerName(widget.currentUid);
    final customPartnerNote = widget.relationship.getPartnerCustomScratchNote(widget.currentUid, todayKey);
    final curatedNote = DailyLoveNotes.getNoteForDate(today);
    final displayNote = (customPartnerNote != null && customPartnerNote.isNotEmpty) ? customPartnerNote : curatedNote;
    final isCustomFromPartner = customPartnerNote != null && customPartnerNote.isNotEmpty;
    final dateString = DateFormat('MMMM d, yyyy').format(today).toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: FadeInUp(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE11D48).withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFE11D48).withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Pill
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.mark_email_unread_rounded, color: Color(0xFFE11D48), size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'DAILY LOVE NOTE',
                          style: AppTextStyles.bodyS.copyWith(
                            color: const Color(0xFFE11D48),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isScratched ? const Color(0xFFF1F5F9) : const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isScratched ? Icons.nights_stay_rounded : Icons.auto_awesome_rounded,
                            size: 12,
                            color: _isScratched ? AppColors.textSecondary : const Color(0xFFE11D48),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isScratched ? 'Resets at midnight' : 'Scratch to reveal',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _isScratched ? AppColors.textSecondary : const Color(0xFFE11D48),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // The Scratch Envelope Card Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        // Layer 1: Parchment Secret Love Letter (Under)
                        Positioned.fill(
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFDF9), // Vintage warm cream parchment
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFF3E8E2), width: 1.5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Envelope Header
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'TO: ${widget.relationship.getMyName(widget.currentUid).toUpperCase()}',
                                          style: const TextStyle(
                                            color: Color(0xFF881337),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 10,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dateString,
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFE2A9B5)),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'AIRMAIL ✈️',
                                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFFE11D48)),
                                      ),
                                    ),
                                  ],
                                ),

                                // The Love Note Content
                                Expanded(
                                  child: Center(
                                    child: SingleChildScrollView(
                                      child: Text(
                                        '“$displayNote”',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.cormorantGaramond(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w700,
                                          fontStyle: FontStyle.italic,
                                          color: const Color(0xFF1E293B),
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Footer Signature
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    isCustomFromPartner
                                        ? '— With love, $partnerName 💖'
                                        : '— Daily Note ✨',
                                    style: TextStyle(
                                      color: isCustomFromPartner ? const Color(0xFFE11D48) : Colors.grey.shade600,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Layer 2: Scratch Foil Foreground (Rendered only if not fully scratched)
                        if (!_isScratched)
                          Positioned.fill(
                            child: GestureDetector(
                              onPanStart: _onPanStart,
                              onPanUpdate: _onPanUpdate,
                              onPanEnd: _onPanEnd,
                              child: CustomPaint(
                                painter: _ScratchFoilPainter(strokes: _strokes),
                                child: Container(),
                              ),
                            ),
                          ),

                        // Layer 3: Smooth Fade Out Animation when scratched
                        if (_isScratched && _fadeController.isAnimating)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: CustomPaint(
                                  painter: _ScratchFoilPainter(strokes: _strokes),
                                  child: Container(),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Call to Action
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!_isScratched)
                      Row(
                        children: [
                          const Icon(Icons.touch_app_rounded, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Scratch gently to reveal',
                            style: AppTextStyles.bodyS.copyWith(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Text(
                            'Revealed for today',
                            style: AppTextStyles.bodyS.copyWith(fontSize: 11, color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    TextButton.icon(
                      onPressed: () {
                        VibrationService.medium();
                        _showWriteNoteSheet(context, partnerName, todayKey);
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFFE11D48)),
                      label: Text(
                        'Write Note',
                        style: AppTextStyles.bodyS.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFE11D48),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Hardware-Accelerated Skia Foil Painter
class _ScratchFoilPainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _ScratchFoilPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Layer with saveLayer so BlendMode.clear cuts through the foil cleanly!
    canvas.saveLayer(rect, Paint());

    // 1. Draw Rose-Gold Metallic Foil Background
    final foilPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFE8B4B8), // Soft Rose Gold
          Color(0xFFF6D6D9), // Highlight
          Color(0xFFD49B9F), // Rich Rose
          Color(0xFFF9E4E6), // Highlight
          Color(0xFFC78287), // Shadow Rose Gold
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));
    canvas.drawRRect(rrect, foilPaint);

    // 2. Draw Decorative Stamp Pattern on Foil
    final borderPaint = Paint()
      ..color = const Color(0x60FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(rrect.deflate(8), borderPaint);

    // Center Instructions Emboss
    final textPainter = TextPainter(
      text: const TextSpan(
        text: "✨ SCRATCH WITH LOVE ✨\nRub your finger to open envelope",
        style: TextStyle(
          color: Color(0xCC881337),
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
          height: 1.4,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: size.width - 40);
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
    );

    // 3. Clear user scratches with Skia BlendMode.clear
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 42.0;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 21.0, clearPaint);
      } else {
        final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, clearPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScratchFoilPainter oldDelegate) {
    return true;
  }
}
