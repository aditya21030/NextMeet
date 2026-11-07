import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/models/memory_model.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';

/// NextMeet Memory Detail & Comments Screen
/// Strictly following NextMeet Redesign.pdf (Page 22)
class MemoryDetailScreen extends StatefulWidget {
  final MemoryModel? memory;
  final String? title;
  final String? date;
  final String? location;
  final String? imageUrl;
  final String? emotion;

  const MemoryDetailScreen({
    super.key,
    this.memory,
    this.title,
    this.date,
    this.location,
    this.imageUrl,
    this.emotion,
  });

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  bool _initialized = false;
  final List<Map<String, String>> _comments = [];

  void _initComments(String partnerName, String myName) {
    if (_initialized) return;
    _initialized = true;
    _comments.addAll([
      {
        'author': partnerName,
        'avatarColor': 'violet',
        'time': '2 hours ago',
        'text': 'I still remember this day! 😂 Best sunset ever.',
      },
      {
        'author': myName,
        'avatarColor': 'pink',
        'time': '1 hour ago',
        'text': 'Can we go back next trip please? Miss this so much ❤️',
      },
    ]);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addComment(String text, String myName) {
    if (text.trim().isEmpty) return;
    VibrationService.light();
    setState(() {
      _comments.add({
        'author': myName,
        'avatarColor': 'pink',
        'time': 'Just now',
        'text': text.trim(),
      });
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUid;

    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, relSnap) {
        final rel = relSnap.data;
        final myName = rel?.getMyName(currentUid) ?? 'You';
        final partnerName = rel?.getPartnerName(currentUid) ?? 'Partner';
        _initComments(partnerName, myName);

        final title = widget.memory?.caption ?? widget.title ?? 'Sunset by the beach';
        final date = widget.date ?? 'Special Memory';
        final location = widget.location ?? (rel?.getMyLocation(currentUid).isNotEmpty == true ? rel!.getMyLocation(currentUid) : 'Shared Memory');
        final emotion = widget.emotion ?? 'Happy';
        final imageUrl = widget.memory?.imageUrl ?? widget.imageUrl;

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
                  Text('Memory', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: const Icon(Icons.share_outlined, size: 18, color: AppColors.ink),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero Photo (Page 22)
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        color: AppColors.pinkSoft,
                        borderRadius: BorderRadius.circular(AppRadius.hero),
                        border: Border.all(color: AppColors.border, width: 1.5),
                        image: imageUrl != null && imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: imageUrl == null || imageUrl.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const MascotHeart(color: MascotColor.pink, size: 68),
                                const SizedBox(height: 12),
                                Text('Sunset in Goa', style: AppTextStyles.heading.copyWith(color: AppColors.primary)),
                              ],
                            )
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Title & Emotion row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: AppTextStyles.title1.copyWith(fontSize: 22)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.place_rounded, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(location, style: AppTextStyles.caption.copyWith(color: AppColors.ink)),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.muted),
                                  const SizedBox(width: 4),
                                  Text(date, style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.mintSoft,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: AppColors.mint, width: 1),
                          ),
                          child: Text(
                            '✨ $emotion',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.mintText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Memory Description
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Text(
                        'We sat on the sand until the sun dipped completely under the horizon. '
                        'The waves were warm and you promised we would come back here every year. '
                        'One of the sweetest days of our journey.',
                        style: AppTextStyles.body.copyWith(height: 1.5, color: AppColors.ink),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Comments Section Header
                    Row(
                      children: [
                        const Icon(Icons.mode_comment_outlined, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Comments (${_comments.length})',
                          style: AppTextStyles.heading.copyWith(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Comments List
                    ..._comments.map((comment) {
                      final isPink = comment['avatarColor'] == 'pink';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MascotHeart(
                              color: isPink ? MascotColor.pink : MascotColor.violet,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        comment['author']!,
                                        style: AppTextStyles.heading.copyWith(fontSize: 14),
                                      ),
                                      Text(
                                        comment['time']!,
                                        style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comment['text']!,
                                    style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.ink),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Comment Input Bar (Page 22)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.input),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              style: AppTextStyles.body.copyWith(color: AppColors.ink),
                              decoration: const InputDecoration(
                                hintText: 'Leave a love note...',
                                hintStyle: TextStyle(color: AppColors.muted, fontSize: 13),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onSubmitted: (t) => _addComment(t, myName),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _addComment('❤️', myName);
                            },
                            child: const Text('❤️', style: TextStyle(fontSize: 18)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _addComment(_commentController.text, myName),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
        },
      );
    }
}
