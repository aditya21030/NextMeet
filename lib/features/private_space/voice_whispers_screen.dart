import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';

import '../../core/constants.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../profile/nextmeet_plus_screen.dart';

class VoiceWhispersScreen extends StatefulWidget {
  final RelationshipModel rel;

  const VoiceWhispersScreen({super.key, required this.rel});

  @override
  State<VoiceWhispersScreen> createState() => _VoiceWhispersScreenState();
}

class _VoiceWhispersScreenState extends State<VoiceWhispersScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  int _recordDurationSeconds = 0;
  Timer? _recordTimer;
  String? _recordingPath;
  bool _isUploading = false;

  String? _currentlyPlayingId;
  PlayerState _playerState = PlayerState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  @override
  void initState() {
    super.initState();
    _playerStateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _playerState = state);
    });

    _positionSub = _audioPlayer.onPositionChanged.listen((pos) {
      if (!mounted) return;
      setState(() => _currentPosition = pos);
    });

    _durationSub = _audioPlayer.onDurationChanged.listen((dur) {
      if (!mounted) return;
      setState(() => _totalDuration = dur);
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!widget.rel.isPlus) {
      _showUpgradeSheet();
      return;
    }

    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/whisper_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        VibrationService.medium();
        setState(() {
          _isRecording = true;
          _recordDurationSeconds = 0;
          _recordingPath = path;
        });

        _recordTimer?.cancel();
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          setState(() => _recordDurationSeconds++);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required to record whispers.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopAndSendRecording() async {
    _recordTimer?.cancel();
    if (!_isRecording) return;

    try {
      final path = await _audioRecorder.stop();
      VibrationService.success();
      setState(() {
        _isRecording = false;
        _isUploading = true;
      });

      final filePath = path ?? _recordingPath;
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          await _cloudService.addVoiceWhisper(widget.rel.id!, file);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Secret Voice Whisper sealed and sent! 🎙️✨'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save voice note ❌')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    try {
      await _audioRecorder.stop();
    } catch (_) {}
    if (_recordingPath != null) {
      try {
        final file = File(_recordingPath!);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    VibrationService.light();
    setState(() {
      _isRecording = false;
      _recordDurationSeconds = 0;
      _recordingPath = null;
    });
  }

  Future<void> _togglePlayWhisper(String whisperId, String url) async {
    VibrationService.light();
    if (_currentlyPlayingId == whisperId && _playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      if (_currentlyPlayingId != whisperId) {
        await _audioPlayer.stop();
        setState(() {
          _currentlyPlayingId = whisperId;
          _currentPosition = Duration.zero;
          _totalDuration = Duration.zero;
        });
      }
      await _audioPlayer.play(UrlSource(url));
    }
  }

  Future<void> _deleteWhisper(String whisperId, String url) async {
    VibrationService.medium();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Voice Whisper?'),
        content: const Text('This private recording will be permanently deleted from the vault.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (_currentlyPlayingId == whisperId) {
        await _audioPlayer.stop();
        setState(() => _currentlyPlayingId = null);
      }
      await _cloudService.deleteVoiceWhisper(widget.rel.id!, whisperId, url);
      VibrationService.success();
    }
  }

  void _showUpgradeSheet() {
    VibrationService.medium();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB703).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic_external_on_rounded, size: 40, color: Color(0xFFFB8500)),
            ),
            const SizedBox(height: 16),
            const Text(
              'NextMeet+ Secret Voice Whispers 🎙️',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Record and preserve intimate audio moments, bedtime whispers, and private confessions encrypted inside your Couple Sanctuary.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => NextMeetPlusScreen(relId: widget.rel.id!)));
                },
                icon: const Icon(Icons.stars_rounded, color: Colors.white),
                label: const Text('UNLOCK WITH NEXTMEET+', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final partnerName = widget.rel.getDisplayPartnerName(_cloudService.currentUid);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
        ),
        title: const Text(
          'VOICE WHISPERS',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2, color: AppColors.textPrimary),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _cloudService.streamVoiceWhispers(widget.rel.id!),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          return Column(
            children: [
              // Header Info Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lock_rounded, size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Encrypted Voice Archive', style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            'Intimate voice notes heard only by you and $partnerName',
                            style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (!widget.rel.isPlus)
                      GestureDetector(
                        onTap: _showUpgradeSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFFB703), Color(0xFFFB8500)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('PRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(height: 16),

              // Whispers List
              Expanded(
                child: docs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.mic_none_rounded, size: 48, color: AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              Text('No Voice Whispers Yet', style: AppTextStyles.h3),
                              const SizedBox(height: 8),
                              Text(
                                'Record a secret voice message for $partnerName.\nHold the microphone below to begin.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.l, 8, AppSpacing.l, 100),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final String url = data['audioUrl'] ?? '';
                          final String sentBy = data['sentBy'] ?? '';
                          final isMe = sentBy == _cloudService.currentUid;
                          final Timestamp? ts = data['timestamp'] as Timestamp?;
                          final timeStr = ts != null ? DateFormat('MMM d, h:mm a').format(ts.toDate()) : 'Recently';

                          final isPlaying = _currentlyPlayingId == doc.id && _playerState == PlayerState.playing;

                          return FadeInUp(
                            delay: Duration(milliseconds: index * 60),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isPlaying ? AppColors.primary.withValues(alpha: 0.4) : Colors.pink.shade50),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: isPlaying ? 0.08 : 0.03),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Play/Pause circular button
                                  InkWell(
                                    onTap: () => _togglePlayWhisper(doc.id, url),
                                    borderRadius: BorderRadius.circular(25),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isPlaying ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: isPlaying ? Colors.white : AppColors.primary,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Details and waveform placeholder
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              isMe ? 'You' : partnerName,
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.background,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                timeStr,
                                                style: const TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        // Subtle audio progress indicator
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(3),
                                          child: LinearProgressIndicator(
                                            value: isPlaying && _totalDuration.inMilliseconds > 0
                                                ? (_currentPosition.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0)
                                                : 0.0,
                                            minHeight: 4,
                                            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isMe)
                                    IconButton(
                                      onPressed: () => _deleteWhisper(doc.id, url),
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary, size: 18),
                                      tooltip: 'Delete Whisper',
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Recording Bar Bottom Area
              Container(
                padding: const EdgeInsets.fromLTRB(AppSpacing.l, 14, AppSpacing.l, 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, -4)),
                  ],
                ),
                child: _isRecording
                    ? Row(
                        children: [
                          IconButton(
                            onPressed: _cancelRecording,
                            icon: const Icon(Icons.close_rounded, color: Colors.red),
                            tooltip: 'Cancel',
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDuration(_recordDurationSeconds),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.red),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _stopAndSendRecording,
                            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                            label: const Text('SEND WHISPER', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.rel.isPlus ? 'Tap to Record Voice Whisper' : 'NextMeet+ Voice Vault',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                                ),
                                Text(
                                  widget.rel.isPlus ? 'Encrypted and sent straight to sanctuary' : 'Intimate audio notes exclusive to Plus',
                                  style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _isUploading
                              ? const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(color: AppColors.primary),
                                )
                              : Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _startRecording,
                                    borderRadius: BorderRadius.circular(30),
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: AppColors.primaryGradient,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.35),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
                                    ),
                                  ),
                                ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
