import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';

class VoiceWhispersScreen extends StatefulWidget {
  final String relId;
  const VoiceWhispersScreen({super.key, required this.relId});

  @override
  State<VoiceWhispersScreen> createState() => _VoiceWhispersScreenState();
}

class _VoiceWhispersScreenState extends State<VoiceWhispersScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isRecording = false;
  String? _recordingPath;
  String? _currentlyPlayingUrl;
  bool _isPlaying = false;
  DateTime? _recordingStartTime;
  StreamSubscription? _playerSubscription;

  @override
  void initState() {
    super.initState();
    _playerSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = (state == PlayerState.playing));
      }
    });
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingUrl = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _playerSubscription?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        _recordingPath = '${directory.path}/whisper_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        const config = RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100);
        await _audioRecorder.start(config, path: _recordingPath!);
        
        setState(() {
          _isRecording = true;
          _recordingStartTime = DateTime.now();
        });
        VibrationService.medium();
      } else {
      // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission required! 🎙️')));
      }
    } catch (e) {
      print('Error starting record: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    try {
      final path = await _audioRecorder.stop();
      final duration = DateTime.now().difference(_recordingStartTime ?? DateTime.now());
      
      setState(() => _isRecording = false);
      VibrationService.success();
      
      if (path != null && duration.inMilliseconds > 500) {
        _showSendDialog(File(path));
      } else {
        print('Recording too short, discarding.');
      }
    } catch (e) {
      print('Error stopping record: $e');
    }
  }

  void _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  void _showSendDialog(File audioFile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Send Whisper? 📼', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('This audio clip will be added to your shared cassette library.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cloudService.addVoiceWhisper(widget.relId, audioFile);
              VibrationService.success();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('SEND TAPE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _playWhisper(String url) async {
    try {
      if (_currentlyPlayingUrl == url && _isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_isPlaying) await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(url));
        setState(() => _currentlyPlayingUrl = url);
      }
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark mode for vintage feel
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        ),
        title: const Text('VOICE WHISPERS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildTapeVisualizer(),
          const SizedBox(height: 40),
          Expanded(child: _buildWhisperList()),
          _buildRecordButton(),
        ],
      ),
    );
  }

  Widget _buildTapeVisualizer() {
    return Center(
      child: FadeInDown(
        child: Container(
          width: 300, height: 180,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 10))],
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Container(
                height: 40, width: double.infinity,
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                child: const Center(child: Text('SIDE A - OUR STORIES', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCassetteWheel(),
                  _buildCassetteWheel(),
                ],
              ),
              const Spacer(),
              const Text('NEXTMEET MASTER TAPE', style: TextStyle(color: Colors.white24, fontSize: 8, letterSpacing: 2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCassetteWheel() {
    return Pulse(
      animate: _isPlaying,
      infinite: true,
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24, width: 2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 20, height: 20,
            decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }

  Widget _buildWhisperList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _cloudService.streamVoiceWhispers(widget.relId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.library_music_rounded, color: Colors.white24, size: 48),
                const SizedBox(height: 16),
                Text('No whispers yet...', style: AppTextStyles.bodyM.copyWith(color: Colors.white30)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final url = data['audioUrl'] as String;
            final sentBy = data['sentBy'] as String;
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            final isMe = sentBy == _cloudService.currentUid;
            final isCurrent = _currentlyPlayingUrl == url && _isPlaying;

            return FadeInLeft(
              delay: Duration(milliseconds: index * 100),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => _playWhisper(url),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isCurrent ? AppColors.primary : Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Icon(isCurrent ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, 
                             color: isCurrent ? AppColors.primary : Colors.white70, size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isMe ? 'My Whisper' : 'Partner\'s Whisper', 
                                   style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('${timestamp.day}/${timestamp.month} - ${timestamp.hour}:${timestamp.minute}', 
                                   style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                        ),
                        if (isCurrent)
                          Pulse(
                            infinite: true,
                            child: const Icon(Icons.graphic_eq_rounded, color: AppColors.primary, size: 24),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecordButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
      child: Column(
        children: [
          Text(_isRecording ? 'RECORDING... 🎙️' : 'HOLD TO RECORD WHISPER', 
               style: TextStyle(color: _isRecording ? Colors.red : Colors.white38, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _toggleRecording,
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopRecording(),
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red : Colors.white10,
                shape: BoxShape.circle,
                border: Border.all(color: _isRecording ? Colors.redAccent.withValues(alpha: 0.5) : Colors.white24, width: 4),
                boxShadow: _isRecording ? [BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 20)] : null,
              ),
              child: Icon(_isRecording ? Icons.stop_rounded : Icons.keyboard_voice_rounded, 
                          color: Colors.white, size: 32),
            ),
          ),
        ],
      ),
    );
  }
}
