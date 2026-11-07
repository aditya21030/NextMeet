import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';

/// NextMeet Fullscreen Voice Whisper Recording Modal
/// Strictly following NextMeet Redesign.pdf (Page 66)
class VoiceWhisperRecordingModal extends StatefulWidget {
  final String? relId;
  final String? partnerName;

  const VoiceWhisperRecordingModal({
    super.key,
    this.relId,
    this.partnerName,
  });

  static void show(BuildContext context, {String? relId, String? partnerName}) {
    VibrationService.medium();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceWhisperRecordingModal(
        relId: relId,
        partnerName: partnerName,
      ),
    );
  }

  @override
  State<VoiceWhisperRecordingModal> createState() => _VoiceWhisperRecordingModalState();
}

class _VoiceWhisperRecordingModalState extends State<VoiceWhisperRecordingModal> {
  int _seconds = 0;
  Timer? _timer;
  final math.Random _random = math.Random();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_seconds < 60) {
        setState(() => _seconds += 1);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sendWhisper() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    VibrationService.heavy();
    final pName = widget.partnerName ?? 'Partner';
    final durationStr = '0:${_seconds.toString().padLeft(2, '0')}';

    if (widget.relId != null) {
      try {
        await CloudRelationshipService().addVoiceWhisper(
          widget.relId!,
          'Voice Whisper ($durationStr)',
          durationStr,
        );
      } catch (e) {
        debugPrint('Error saving whisper: $e');
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Voice whisper sent to $pName! 🎙️💕')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = '00:${_seconds.toString().padLeft(2, '0')}';

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.partner, // Violet canvas (Page 66)
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SingleChildScrollView(
        child: Column(
          children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Text(
            'Recording Whisper...',
            style: AppTextStyles.title1.copyWith(color: Colors.white, fontSize: 24),
          ),
          const SizedBox(height: 6),
          Text(
            'Keep it sweet and under 60 seconds',
            style: AppTextStyles.body.copyWith(color: Colors.white70),
          ),

          const SizedBox(height: 24),

          // Waveform Animation (Page 66)
          SizedBox(
            height: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(24, (index) {
                final barHeight = 16.0 + (_random.nextDouble() * 64.0);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: 5,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 24),

          // Timer Display
          Text(
            timeStr,
            style: AppTextStyles.display.copyWith(
              color: Colors.white,
              fontSize: 36,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 24),

          // Stop & Send Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Cancel
              GestureDetector(
                onTap: () {
                  VibrationService.light();
                  Navigator.pop(context);
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                ),
              ),

              // Send Button
              GestureDetector(
                onTap: _sendWhisper,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.send_rounded, color: AppColors.partner, size: 32),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Text(
            'Tap checkmark to send to ${widget.partnerName ?? "Partner"}',
            style: AppTextStyles.caption.copyWith(color: Colors.white60),
          ),
        ],
      ),
    ),
  );
}
}
