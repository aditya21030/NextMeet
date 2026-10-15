import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import '../../widgets/premium_decision_sheet.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';

class ChatScreen extends StatefulWidget {
  final String relationshipId;
  final String partnerName;
  final String partnerUid;

  const ChatScreen({
    super.key,
    required this.relationshipId,
    required this.partnerName,
    required this.partnerUid,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;
  Stream<QuerySnapshot>? _messageStream;
  StreamSubscription? _relationshipSubscription;
  RelationshipModel? _relationship;
  
  // Multimedia State
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _currentlyPlayingUrl;
  bool _isUploading = false;

  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _messageStream = FirebaseFirestore.instance
        .collection('relationships')
        .doc(widget.relationshipId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
        
    _relationshipSubscription = _cloudService.streamRelationship().listen((rel) {
      if (mounted) setState(() => _relationship = rel);
    });

    // Mark messages as seen when opening and while open
    _messageSubscription = _messageStream?.listen((_) {
      _cloudService.markMessagesAsSeen(widget.relationshipId);
    });

    _cloudService.updateActivity(widget.relationshipId);
    _cloudService.markMessagesAsSeen(widget.relationshipId);
  }

  @override
  void dispose() {
    _relationshipSubscription?.cancel();
    _messageSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _sendMessage({String? text, String? imageUrl, String? voiceUrl, String type = 'text'}) async {
    final messageText = text ?? _messageController.text.trim();
    if (messageText.isEmpty && imageUrl == null && voiceUrl == null) return;

    if (type == 'text') _messageController.clear();
    VibrationService.light();

    try {
      await _cloudService.sendChatMessage(
        widget.relationshipId,
        text: messageText.isNotEmpty ? messageText : null,
        imageUrl: imageUrl,
        voiceUrl: voiceUrl,
        type: type,
      );
      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source, 
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 60,
      );
      if (image != null) {
        setState(() => _isUploading = true);
        final url = await _cloudService.uploadChatFile(widget.relationshipId, File(image.path), 'image');
        _sendMessage(imageUrl: url, type: 'image');
        setState(() => _isUploading = false);
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() => _isUploading = false);
    }
  }

  // Waveform state
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  double _currentAmplitude = -40.0;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  double _dragOffset = 0.0;

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(const RecordConfig(), path: path);
        _amplitudeSubscription = _audioRecorder.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((amp) {
          if (mounted) setState(() => _currentAmplitude = amp.current);
        });

        _recordingSeconds = 0;
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) setState(() => _recordingSeconds++);
        });

        setState(() {
          _isRecording = true;
          _dragOffset = 0;
        });
        VibrationService.medium();
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    try {
      _amplitudeSubscription?.cancel();
      _recordingTimer?.cancel();
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      
      if (path != null && !cancel) {
        setState(() => _isUploading = true);
        final url = await _cloudService.uploadChatFile(widget.relationshipId, File(path), 'voice');
        _sendMessage(voiceUrl: url, type: 'voice');
        setState(() => _isUploading = false);
      }
      
      if (cancel) {
        VibrationService.light();
      }
    } catch (e) {
      print('Error stopping recording: $e');
      setState(() => _isUploading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getThemeConfig(_relationship?.chatBackgroundIndex ?? 0);

    return Scaffold(
      backgroundColor: theme.appBarColor, // Base color for transition
      appBar: AppBar(
        backgroundColor: theme.brightness == Brightness.dark ? theme.appBarColor : Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.iconColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: (widget.partnerUid == _relationship?.uid1 ? _relationship?.userPhoto1 : _relationship?.userPhoto2) != null
                  ? NetworkImage(widget.partnerUid == _relationship?.uid1 ? _relationship!.userPhoto1! : _relationship!.userPhoto2!)
                  : NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=${widget.partnerUid}'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.partnerName, 
                    style: AppTextStyles.h3.copyWith(fontSize: 16, color: theme.textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  StreamBuilder<RelationshipModel?>(
                    stream: _cloudService.streamRelationship(),
                    builder: (context, snapshot) {
                      final rel = snapshot.data;
                      return Text(
                        _getActiveStatus(rel), 
                        style: AppTextStyles.bodyS.copyWith(
                          color: _getActiveStatus(rel) == 'Active now' ? AppColors.success : theme.textColor.withValues(alpha: 0.6), 
                          fontWeight: FontWeight.bold, 
                          fontSize: 10
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_relationship?.isPlus == true)
            IconButton(
              onPressed: _showThemePicker,
              icon: Icon(Icons.palette_rounded, color: theme.iconColor == Colors.white ? Colors.white70 : AppColors.primary, size: 24),
              tooltip: 'Chat Theme',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: theme.decoration,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _messageStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(AppSpacing.l),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final bool isMe = data['senderUid'] == _currentUid;
                          final timestamp = data['timestamp'] as Timestamp?;
                          
                          // Date Separator Logic
                          bool showDateSeparator = false;
                          String dateLabel = '';
                          
                          if (timestamp != null) {
                            final DateTime date = timestamp.toDate();
                            final DateTime now = DateTime.now();
                            
                            if (index == docs.length - 1) {
                              showDateSeparator = true;
                            } else {
                              final prevData = docs[index + 1].data() as Map<String, dynamic>;
                              final prevTimestamp = prevData['timestamp'] as Timestamp?;
                              if (prevTimestamp != null) {
                                final DateTime prevDate = prevTimestamp.toDate();
                                if (date.year != prevDate.year || date.month != prevDate.month || date.day != prevDate.day) {
                                  showDateSeparator = true;
                                }
                              }
                            }
                            
                            if (showDateSeparator) {
                              if (date.year == now.year && date.month == now.month && date.day == now.day) {
                                dateLabel = 'TODAY';
                              } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
                                dateLabel = 'YESTERDAY';
                              } else {
                                dateLabel = DateFormat('MMMM d, y').format(date).toUpperCase();
                              }
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              children: [
                                if (showDateSeparator) _buildDateSeparator(dateLabel, theme),
                                Align(
                                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                  child: _buildMessageBubble(
                                    id: docs[index].id,
                                    text: data['text'],
                                    isMe: isMe,
                                    time: timestamp != null ? DateFormat('HH:mm').format(timestamp.toDate()) : '...',
                                    imageUrl: data['imageUrl'],
                                    voiceUrl: data['voiceUrl'],
                                    type: data['type'] ?? 'text',
                                    isSeen: data['isSeen'] ?? false,
                                    theme: theme,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildInputArea(theme),
              ],
            ),
            if (_isRecording) _buildRecordingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingOverlay() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: FadeInUp(
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
          ),
          child: Row(
            children: [
              Transform.translate(
                offset: Offset(_dragOffset < 0 ? 0 : -_dragOffset, 0),
                child: Row(
                  children: [
                    ElasticIn(
                      child: const Icon(Icons.mic_rounded, color: Colors.redAccent, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Recording', 
                              style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.bold, color: Colors.redAccent)
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_recordingSeconds ~/ 60}:${(_recordingSeconds % 60).toString().padLeft(2, '0')}',
                              style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 150,
                          height: 20,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(10, (index) {
                              final height = 4.0 + (math.Random(index).nextDouble() * 16.0 * (_currentAmplitude + 60) / 60);
                              return Container(
                                width: 3,
                                height: height.clamp(2.0, 20.0),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Opacity(
                opacity: (1.0 - (_dragOffset / 80)).clamp(0.0, 1.0),
                child: Row(
                  children: [
                    const Icon(Icons.keyboard_arrow_left_rounded, color: AppColors.textSecondary, size: 20),
                    Text(
                      'Slide to cancel', 
                      style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)
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

  String _getActiveStatus(RelationshipModel? rel) {
    if (rel == null) return 'Offline';
    final lastActive = widget.partnerUid == rel.uid1 ? rel.user1LastActive : rel.user2LastActive;
    if (lastActive == null) return 'Offline';
    
    final diff = DateTime.now().difference(lastActive);
    if (diff.inMinutes < 5) return 'Active now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(lastActive);
  }

  Widget _buildDateSeparator(String label, ChatThemeConfig theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Expanded(child: Divider(color: theme.textColor.withValues(alpha: 0.1), thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label,
              style: AppTextStyles.bodyS.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: theme.textColor.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(child: Divider(color: theme.textColor.withValues(alpha: 0.1), thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String id,
    String? text, 
    required bool isMe, 
    required String time,
    String? imageUrl,
    String? voiceUrl,
    String type = 'text',
    bool isSeen = false,
    required ChatThemeConfig theme,
  }) {
    return GestureDetector(
      onLongPress: () => _confirmDeleteMessage(id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (type == 'image' && imageUrl != null)
              GestureDetector(
                onTap: () {
                  // Show full screen image
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(imageUrl, fit: BoxFit.cover),
                  ),
                ),
              ),
            
            if (type == 'voice' && voiceUrl != null)
              _buildVoiceMessage(voiceUrl, isMe, theme),

            if (text != null && text.isNotEmpty)
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe 
                    ? AppColors.primary 
                    : (theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.12) : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(24),
                    topRight: const Radius.circular(24),
                    bottomLeft: Radius.circular(isMe ? 24 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isMe ? AppColors.primary : Colors.black).withValues(alpha: isMe ? 0.3 : 0.05),
                      blurRadius: isMe ? 15 : 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                  border: isMe ? null : Border.all(
                    color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.08) : AppColors.primary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: type == 'sticker' && text.startsWith('assets/')
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(text, width: 120, height: 120, fit: BoxFit.contain),
                    )
                  : Text(
                      text,
                      style: AppTextStyles.bodyM.copyWith(
                        color: isMe ? Colors.white : theme.textColor,
                        fontWeight: isMe ? FontWeight.w600 : FontWeight.w500,
                        letterSpacing: 0.1,
                        height: 1.3,
                      ),
                    ),
              ),
            
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: AppTextStyles.bodyS.copyWith(
                    fontSize: 10, 
                    color: theme.textColor.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isSeen ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: isSeen ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.4),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceMessage(String url, bool isMe, ChatThemeConfig theme) {
    final bool isPlaying = _currentlyPlayingUrl == url;
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe 
          ? AppColors.primary 
          : (theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.12) : Colors.white),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isMe ? AppColors.primary : Colors.black).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: isMe ? null : Border.all(
          color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : AppColors.primary.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _playVoice(url),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isMe ? Colors.white.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, 
                color: isMe ? Colors.white : AppColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(15, (index) {
                    final height = 4.0 + (math.Random(index).nextDouble() * 12.0);
                    return Container(
                      width: 2,
                      height: isPlaying ? (height * (0.8 + math.sin(index + DateTime.now().millisecondsSinceEpoch/100) * 0.2)) : height,
                      decoration: BoxDecoration(
                        color: isMe ? Colors.white.withValues(alpha: 0.6) : theme.textColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  'Voice Note', 
                  style: AppTextStyles.bodyS.copyWith(
                    fontSize: 10, 
                    color: isMe ? Colors.white.withValues(alpha: 0.8) : theme.textColor.withValues(alpha: 0.6),
                    fontWeight: FontWeight.bold,
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMessage(String messageId) {
    VibrationService.medium();
    showPremiumDecisionSheet(
      context: context,
      title: 'Delete Message?',
      subtitle: 'This will permanently remove this memory from your shared world. ❤️',
      actionText: 'DELETE FOR BOTH',
      actionColor: Colors.redAccent,
      icon: Icons.delete_sweep_rounded,
      onAction: () async {
        Navigator.pop(context); // Close sheet
        await _cloudService.deleteChatMessage(widget.relationshipId, messageId);
        VibrationService.success();
      },
    );
  }

  Future<void> _playVoice(String url) async {
    VibrationService.light();
    if (_currentlyPlayingUrl == url) {
      await _audioPlayer.pause();
      setState(() => _currentlyPlayingUrl = null);
    } else {
      await _audioPlayer.play(UrlSource(url));
      setState(() => _currentlyPlayingUrl = url);
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _currentlyPlayingUrl = null);
      });
    }
  }

  Widget _buildInputArea(ChatThemeConfig theme) {
    final bool hasText = _messageController.text.trim().isNotEmpty;
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 8, 16, 
        math.max(16, MediaQuery.of(context).padding.bottom + 8)
      ),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  minHeight: 3, 
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          
          if (_isRecording)
            FadeIn(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic_rounded, color: Colors.redAccent, size: 14),
                    const SizedBox(width: 8),
                    const Text('Recording Whisper...', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          
          Container(
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Minimalist '+' Button
                _buildInputIcon(
                  Icons.add_rounded, 
                  _showAttachmentMenu,
                  theme.brightness == Brightness.dark ? Colors.white60 : Colors.grey.shade500
                ),
                
                // Unified Text Field
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLines: 5,
                    minLines: 1,
                    onChanged: (val) => setState(() {}),
                    style: AppTextStyles.bodyM.copyWith(
                      color: theme.brightness == Brightness.dark ? Colors.white : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Share a thought...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontSize: 14, 
                        color: theme.brightness == Brightness.dark ? Colors.white38 : Colors.grey.shade400,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                
                // Sticker Button (Embedded)
                _buildInputIcon(
                  Icons.emoji_emotions_rounded, 
                  _showStickerPicker,
                  theme.brightness == Brightness.dark ? Colors.white60 : Colors.grey.shade500,
                  size: 22
                ),

                const SizedBox(width: 4),

                // Primary Action Button (Send/Mic) - Integrated Gradient Pill
                GestureDetector(
                  onLongPressStart: (_) => !hasText ? _startRecording() : null,
                  onLongPressEnd: (_) => !hasText ? _stopRecording() : null,
                  onTap: hasText ? () => _sendMessage() : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: hasText ? AppColors.primaryGradient : null,
                      color: hasText ? null : (theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasText ? Icons.send_rounded : Icons.mic_rounded,
                      color: hasText ? Colors.white : (theme.brightness == Brightness.dark ? Colors.white70 : AppColors.primary),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputIcon(IconData icon, VoidCallback onTap, Color color, {double size = 26}) {
    return IconButton(
      onPressed: onTap,
      splashRadius: 20,
      icon: Icon(icon, color: color, size: size),
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SEND ATTACHMENT', style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(Icons.image_rounded, 'Gallery', Colors.blue, () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                }),
                _buildAttachmentOption(Icons.camera_alt_rounded, 'Camera', Colors.orange, () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                }),
                _buildAttachmentOption(Icons.emoji_emotions_rounded, 'Stickers', Colors.pink, () {
                  Navigator.pop(context);
                  _showStickerPicker();
                }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.bodyS),
      ],
    );
  }

  
  void _showStickerPicker() {
    final List<Map<String, dynamic>> allStickers = [
      // Assets First
      {'val': 'assets/images/stickers/cosmic_love.png', 'name': 'Cosmic Love', 'premium': true, 'isAsset': true},
      {'val': 'assets/images/stickers/neon_pulse.png', 'name': 'Neon Pulse', 'premium': true, 'isAsset': true},
      {'val': 'assets/images/stickers/steampunk_cupid.png', 'name': 'Clockwork Cupid', 'premium': true, 'isAsset': true},
      {'val': 'assets/images/stickers/quantum_bond.png', 'name': 'Quantum Bond', 'premium': true, 'isAsset': true},
      {'val': 'assets/images/stickers/cyberpunk_rose.png', 'name': 'Cyber Rose', 'premium': true, 'isAsset': true},
      {'val': 'assets/images/stickers/ethereal_hug.png', 'name': 'Ethereal Hug', 'premium': true, 'isAsset': true},
      
      // Emojis (Now Premium)
      {'val': '❤️', 'name': 'Love', 'premium': true},
      {'val': '😘', 'name': 'Kiss', 'premium': true},
      {'val': '🔥', 'name': 'Hot', 'premium': true},
      {'val': '✨', 'name': 'Sparkle', 'premium': true},
      {'val': '🥺', 'name': 'Pleading', 'premium': true},
      {'val': '🎉', 'name': 'Party', 'premium': true},
      {'val': '🌹', 'name': 'Rose', 'premium': true},
      {'val': '🌈', 'name': 'Rainbow', 'premium': true},
      {'val': '🧸', 'name': 'Teddy', 'premium': true},
      {'val': '💖', 'name': 'Pink Heart', 'premium': true},
      {'val': '♾️', 'name': 'Eternal Bond', 'premium': true},
      {'val': '💓', 'name': 'Heartbeat Sync', 'premium': true},
      {'val': '🧩', 'name': 'Missing Piece', 'premium': true},
      {'val': '🏰', 'name': 'Our Sanctuary', 'premium': true},
      {'val': '💋', 'name': 'Digital Kiss', 'premium': true},
      {'val': '🔒', 'name': 'Love Locked', 'premium': true},
      {'val': '🌠', 'name': 'Shooting Star', 'premium': true},
      {'val': '🌙', 'name': 'Moon & Back', 'premium': true},
      {'val': '💘', 'name': 'Cupid\'s Arrow', 'premium': true},
      {'val': '🥀', 'name': 'Rose Petals', 'premium': true},
      {'val': '🤗', 'name': 'Warm Embrace', 'premium': true},
      {'val': '🤝', 'name': 'Hand in Hand', 'premium': true},
      {'val': '🔥', 'name': 'Twin Flame', 'premium': true},
      {'val': '💌', 'name': 'Love Letter', 'premium': true},
      {'val': '🕵️‍♀️', 'name': 'Secret Heart', 'premium': true},
      {'val': '💎', 'name': 'Precious Moment', 'premium': true},
      {'val': '🧚‍♂️', 'name': 'Fairy Tale', 'premium': true},
      {'val': '👩‍❤️‍👨', 'name': 'You & Me', 'premium': true},
      {'val': '🙏', 'name': 'Pure Devotion', 'premium': true},
      {'val': '🌴', 'name': 'Sweet Escape', 'premium': true},
      {'val': '🌌', 'name': 'Midnight Hugs', 'premium': true},
      {'val': '☀️', 'name': 'Morning Sun', 'premium': true},
      {'val': '👋', 'name': 'Gentle Touch', 'premium': true},
      {'val': '🌊', 'name': 'Deep Connection', 'premium': true},
      {'val': '❤️‍🔥', 'name': 'Wild Hearts', 'premium': true},
      {'val': '🗣️', 'name': 'Soul Echo', 'premium': true},
      {'val': '😄', 'name': 'Boundless Joy', 'premium': true},
      {'val': '🍀', 'name': 'Serendipity', 'premium': true},
      {'val': '🧭', 'name': 'True North', 'premium': true},
      {'val': '👁️', 'name': 'Sparkling Eyes', 'premium': true},
      {'val': '🤫', 'name': 'Soft Whispers', 'premium': true},
      {'val': '💍', 'name': 'Eternal Promise', 'premium': true},
      {'val': '🎖️', 'name': 'Rose Gold Love', 'premium': true},
      {'val': '🌃', 'name': 'Starlit Date', 'premium': true},
      {'val': '🏆', 'name': 'Heart of Gold', 'premium': true},
      {'val': '🪄', 'name': 'Magic Touch', 'premium': true},
      {'val': '🌸', 'name': 'Lovely Day', 'premium': true},
      {'val': '🍯', 'name': 'Sweetest Vibe', 'premium': true},
      {'val': '💡', 'name': 'Radiant Love', 'premium': true},
      {'val': '🎨', 'name': 'Vibrant Soul', 'premium': true},
      {'val': '🎼', 'name': 'Harmony', 'premium': true},
      {'val': '🎻', 'name': 'Symphony of Us', 'premium': true},
      {'val': '☄️', 'name': 'Celestial Love', 'premium': true},
      {'val': '🌻', 'name': 'Infinite Bloom', 'premium': true},
      {'val': '🎇', 'name': 'Pure Magic', 'premium': true},
      {'val': '🏛️', 'name': 'Our Legacy', 'premium': true},
      {'val': '🍬', 'name': 'Sweetest Heart', 'premium': true},
      {'val': '🦋', 'name': 'Butterfly Effect', 'premium': true},
      {'val': '🕊️', 'name': 'Peaceful Love', 'premium': true},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 4, 
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)),
            ),
            Text('SEND UNIQUE ROMANTIC STICKER', style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Text('NextMeet+ Exclusive Collection ✨', style: AppTextStyles.bodyS.copyWith(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Expanded(
              child: _buildStickerGrid(allStickers),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerGrid(List<Map<String, dynamic>> stickers) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, 
        mainAxisSpacing: 16, 
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: stickers.length,
      itemBuilder: (context, index) {
        final sticker = stickers[index];
        return GestureDetector(
          onTap: () => _handleStickerSelection(sticker),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                 BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (sticker['isAsset'] == true)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(sticker['val'], width: 45, height: 45, fit: BoxFit.contain),
                  )
                else
                  Text(
                    sticker['val'], 
                    style: TextStyle(
                      fontSize: 32,
                      shadows: [
                         Shadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 10),
                      ],
                    )
                  ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    sticker['name'], 
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                const Icon(Icons.stars_rounded, size: 12, color: AppColors.primary),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleStickerSelection(Map<String, dynamic> sticker) {
    Navigator.pop(context);
    _sendMessage(text: sticker['val'], type: 'sticker');
    VibrationService.light();
  }

  void _showThemePicker() {
    VibrationService.medium();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('CHOOSE CHAT THEME', style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 24),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Custom Option (Premium)
                  if (_relationship?.isPlus == true)
                    _buildCustomBackgroundOption(),
                    
                  _buildThemeOption(0, 'Pristine', [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)]),
                  _buildThemeOption(1, 'Midnight', [const Color(0xFF0F172A), const Color(0xFF1E293B)]),
                  _buildThemeOption(2, 'Sunset', [const Color(0xFFFF8B8B), const Color(0xFFFFB3B3)]),
                  _buildThemeOption(3, 'Emerald', [const Color(0xFF064E3B), const Color(0xFF065F46)]),
                  _buildThemeOption(4, 'Lavender', [const Color(0xFF4C1D95), const Color(0xFF6B21A8)]),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(int index, String name, List<Color> colors) {
    final bool isSelected = _relationship?.chatBackgroundIndex == index;
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        await _cloudService.updateChatBackground(widget.relationshipId, index);
        VibrationService.success();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 80,
        child: Column(
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppColors.primary : Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(color: (isSelected ? AppColors.primary : Colors.black).withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: isSelected ? const Icon(Icons.check_circle_rounded, color: Colors.white, shadows: [Shadow(color: Colors.black26, blurRadius: 10)]) : null,
            ),
            const SizedBox(height: 8),
            Text(name, style: AppTextStyles.bodyS.copyWith(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? AppColors.primary : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomBackgroundOption() {
    final bool isCustom = (_relationship?.chatBackgroundIndex ?? 0) == -1;
    final String? customUrl = _relationship?.customChatBackgroundUrl;

    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        _pickCustomBackground();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 80,
        child: Column(
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                image: customUrl != null ? DecorationImage(image: NetworkImage(customUrl), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.2), BlendMode.darken)) : null,
                border: Border.all(color: isCustom ? AppColors.primary : Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(color: (isCustom ? AppColors.primary : Colors.black).withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: customUrl == null 
                  ? const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 28)
                  : (isCustom ? const Icon(Icons.check_circle_rounded, color: Colors.white, shadows: [Shadow(color: Colors.black26, blurRadius: 10)]) : null),
            ),
            const SizedBox(height: 8),
            Text('Custom', style: AppTextStyles.bodyS.copyWith(fontSize: 10, fontWeight: isCustom ? FontWeight.bold : FontWeight.w500, color: isCustom ? AppColors.primary : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomBackground() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() => _isUploading = true);
        await _cloudService.updateCustomChatBackground(widget.relationshipId, File(image.path));
        setState(() => _isUploading = false);
        VibrationService.success();
      }
    } catch (e) {
      print('Error picking background: $e');
      setState(() => _isUploading = false);
    }
  }

  ChatThemeConfig _getThemeConfig(int index) {
    // Check for custom background override
    final customUrl = _relationship?.customChatBackgroundUrl;
    if (index == -1 && customUrl != null) {
      return ChatThemeConfig(
        appBarColor: Colors.black,
        textColor: Colors.white,
        iconColor: Colors.white,
        brightness: Brightness.dark,
        decoration: BoxDecoration(
          color: Colors.black,
          image: DecorationImage(
            image: NetworkImage(customUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.3), BlendMode.darken),
          ),
        ),
      );
    }

    switch (index) {
      case 1: // Midnight Oasis (Deep Space)
        return ChatThemeConfig(
          appBarColor: const Color(0xFF0F172A),
          textColor: Colors.white,
          iconColor: Colors.white70,
          brightness: Brightness.dark,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            ),
            image: DecorationImage(
              image: NetworkImage('https://www.transparenttextures.com/patterns/stardust.png'),
              opacity: 0.2,
              repeat: ImageRepeat.repeat,
            ),
          ),
        );
      case 2: // Sunset Glow (Warm Romance)
        return ChatThemeConfig(
          appBarColor: const Color(0xFFFF5E7E),
          textColor: Colors.white,
          iconColor: Colors.white,
          brightness: Brightness.dark,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFF5E7E), Color(0xFFFF9A8B)],
            ),
          ),
        );
      case 3: // Emerald Dream (Enchanted Forest)
        return ChatThemeConfig(
          appBarColor: const Color(0xFF064E3B),
          textColor: Colors.white,
          iconColor: Colors.white70,
          brightness: Brightness.dark,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF064E3B), Color(0xFF065F46)],
            ),
            image: DecorationImage(
              image: NetworkImage('https://www.transparenttextures.com/patterns/leaf.png'),
              opacity: 0.05,
              repeat: ImageRepeat.repeat,
            ),
          ),
        );
      case 4: // Lavender Mist (Royal Cosmos)
        return ChatThemeConfig(
          appBarColor: const Color(0xFF4C1D95),
          textColor: Colors.white,
          iconColor: Colors.white,
          brightness: Brightness.dark,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)], 
            ),
          ),
        );
      default: // Pristine (Clean Minimalist)
        return ChatThemeConfig(
          appBarColor: Colors.white,
          textColor: AppColors.textPrimary,
          iconColor: AppColors.textPrimary,
          brightness: Brightness.light,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            image: DecorationImage(
              image: NetworkImage('https://www.transparenttextures.com/patterns/cubes.png'),
              opacity: 0.03,
              repeat: ImageRepeat.repeat,
            ),
          ),
        );
    }
  }
}

class ChatThemeConfig {
  final Color appBarColor;
  final Color textColor;
  final Color iconColor;
  final Brightness brightness;
  final BoxDecoration decoration;

  ChatThemeConfig({
    required this.appBarColor,
    required this.textColor,
    required this.iconColor,
    required this.brightness,
    required this.decoration,
  });
}
