import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import 'voice_whisper_recording_modal.dart';

/// NextMeet Voice Whispers Feed Screen
/// Strictly following NextMeet Redesign.pdf (Pages 65-66)
class VoiceWhispersScreen extends StatefulWidget {
  final RelationshipModel rel;

  const VoiceWhispersScreen({super.key, required this.rel});

  @override
  State<VoiceWhispersScreen> createState() => _VoiceWhispersScreenState();
}

class _VoiceWhispersScreenState extends State<VoiceWhispersScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  bool _isPlaying = false;
  double _playbackProgress = 0.0;
  String _nowPlayingTitle = 'Good morning sunshine ☀️';
  String _nowPlayingAuthor = 'Partner';
  String _nowPlayingDuration = '0:24';
  String? _selectedWhisperId;
  Timer? _playbackTimer;

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    VibrationService.light();
    setState(() {
      _isPlaying = !_isPlaying;
    });
    _playbackTimer?.cancel();
    if (_isPlaying) {
      if (_playbackProgress >= 1.0) _playbackProgress = 0.0;
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _playbackProgress += 0.02;
          if (_playbackProgress >= 1.0) {
            _playbackProgress = 1.0;
            _isPlaying = false;
            timer.cancel();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _cloudService.currentUid;
    final partnerName = widget.rel.getPartnerName(myUid);
    final myName = widget.rel.getMyName(myUid);

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
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
                    ),
                  ),
                  Text('Voice Whispers', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                  GestureDetector(
                    onTap: () => VoiceWhisperRecordingModal.show(
                      context,
                      relId: widget.rel.id,
                      partnerName: partnerName,
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.partner,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Scrollable Feed
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _cloudService.streamVoiceWhispers(widget.rel.id ?? ''),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];

                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.partner));
                  }

                  if (docs.isNotEmpty) {
                    final selectedDoc = docs.firstWhere(
                      (d) => d.id == _selectedWhisperId,
                      orElse: () => docs.first,
                    );
                    final topData = selectedDoc.data() as Map<String, dynamic>;
                    _nowPlayingTitle = topData['title'] ?? 'Voice Whisper';
                    final isMe = topData['senderUid'] == myUid;
                    _nowPlayingAuthor = isMe ? myName : partnerName;
                    _nowPlayingDuration = topData['duration'] ?? '0:24';
                  }

                  return RefreshIndicator(
                    color: AppColors.partner,
                    onRefresh: () async {
                      if (mounted) setState(() {});
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Now-Playing Audio Player Card (Page 65)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.hero),
                            border: Border.all(color: AppColors.border, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.partnerSoft,
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                    ),
                                    child: Text(
                                      docs.isNotEmpty ? 'LATEST WHISPER' : 'AUDIO PREVIEW',
                                      style: AppTextStyles.label.copyWith(color: AppColors.partnerText, fontSize: 10),
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.volume_up_rounded, color: AppColors.partner, size: 20),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(_nowPlayingTitle, style: AppTextStyles.title2.copyWith(fontSize: 18)),
                              const SizedBox(height: 2),
                              Text('From $_nowPlayingAuthor • $_nowPlayingDuration', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                              const SizedBox(height: 16),

                              // Waveform progress visualizer
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: _togglePlay,
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: const BoxDecoration(
                                        color: AppColors.partner,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: _isPlaying ? _playbackProgress : 0.0,
                                            minHeight: 8,
                                            backgroundColor: AppColors.partnerSoft,
                                            valueColor: const AlwaysStoppedAnimation(AppColors.partner),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(_isPlaying ? '0:11' : '0:00', style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.muted)),
                                            Text(_nowPlayingDuration, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.muted)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Record New Whisper Banner (Page 65)
                        GestureDetector(
                          onTap: () => VoiceWhisperRecordingModal.show(
                            context,
                            relId: widget.rel.id,
                            partnerName: partnerName,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.partnerSoft,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              border: Border.all(color: AppColors.partnerLight, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: AppColors.partner,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.mic_rounded, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Leave a Whisper for $partnerName',
                                        style: AppTextStyles.heading.copyWith(fontSize: 14, color: AppColors.partnerText),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Your voice will make their heart skip a beat 💕',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.partnerText.withValues(alpha: 0.8),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Whisper History List
                        Text('Past Whispers', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                        const SizedBox(height: 12),

                        if (docs.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              border: Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: Column(
                              children: [
                                const MascotHeart(color: MascotColor.violet, size: 54),
                                const SizedBox(height: 12),
                                Text('No voice whispers yet', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  'Record a quick 10-second audio note to send your partner warm butterflies.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                                ),
                              ],
                            ),
                          )
                        else
                          ...docs.map((doc) {
                            final item = doc.data() as Map<String, dynamic>;
                            final title = item['title'] ?? 'Voice Whisper';
                            final duration = item['duration'] ?? '0:20';
                            final senderUid = item['senderUid'] ?? '';
                            final isMe = senderUid == myUid;
                            final author = isMe ? myName : partnerName;
                            final ts = (item['timestamp'] as Timestamp?)?.toDate();
                            final timeStr = ts != null ? DateFormat('d MMM, h:mm a').format(ts) : 'Just now';

                            return Dismissible(
                              key: ValueKey(doc.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(AppRadius.card),
                                ),
                                child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                              ),
                              onDismissed: (_) {
                                VibrationService.light();
                                _cloudService.deleteVoiceWhisper(widget.rel.id ?? '', doc.id);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppRadius.card),
                                  border: Border.all(color: AppColors.border, width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    MascotHeart(
                                      color: isMe ? MascotColor.pink : MascotColor.violet,
                                      size: 36,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: AppTextStyles.heading.copyWith(fontSize: 14),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$author • $timeStr • $duration',
                                            style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        VibrationService.light();
                                        _playbackTimer?.cancel();
                                        setState(() {
                                          _selectedWhisperId = doc.id;
                                          _nowPlayingTitle = title;
                                          _nowPlayingAuthor = author;
                                          _nowPlayingDuration = duration;
                                          _isPlaying = true;
                                          _playbackProgress = 0.0;
                                        });
                                        _playbackTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
                                          if (!mounted) {
                                            timer.cancel();
                                            return;
                                          }
                                          setState(() {
                                            _playbackProgress += 0.02;
                                            if (_playbackProgress >= 1.0) {
                                              _playbackProgress = 1.0;
                                              _isPlaying = false;
                                              timer.cancel();
                                            }
                                          });
                                        });
                                      },
                                      icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.partner, size: 32),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
