import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/relationship_model.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import 'new_letter_screen.dart';
import 'letter_reader_screen.dart';

/// NextMeet Love Letters Hub Screen
/// Strictly following NextMeet Redesign.pdf (Pages 62-64)
class LoveLettersScreen extends StatefulWidget {
  const LoveLettersScreen({super.key});

  @override
  State<LoveLettersScreen> createState() => _LoveLettersScreenState();
}

class _LoveLettersScreenState extends State<LoveLettersScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  int _selectedTabIndex = 0;

  Color _getSealColor(String? sealName) {
    switch (sealName) {
      case 'Imperial Violet':
        return AppColors.partner;
      case 'Golden Sun':
        return AppColors.butterText;
      case 'Blush Rose':
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUser?.uid;

    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, relSnapshot) {
        final rel = relSnapshot.data;
        final relId = rel?.id;
        final partnerName = rel?.getPartnerName(currentUid) ?? 'Partner';

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
                      Expanded(
                        child: Text(
                          'Love Letters',
                          style: AppTextStyles.title2.copyWith(fontSize: 18),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          VibrationService.light();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewLetterScreen(
                                relId: relId,
                                partnerName: partnerName,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Real Letters Stream
                Expanded(
                  child: relId == null
                      ? _buildEmptyState(relId, partnerName)
                      : StreamBuilder<QuerySnapshot>(
                          stream: _cloudService.streamLoveLetters(relId),
                          builder: (context, lettersSnapshot) {
                            if (lettersSnapshot.connectionState == ConnectionState.waiting &&
                                !lettersSnapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              );
                            }

                            final docs = lettersSnapshot.data?.docs ?? [];
                            final now = DateTime.now();

                            final inboxDocs = <QueryDocumentSnapshot>[];
                            final sentDocs = <QueryDocumentSnapshot>[];
                            final lockedDocs = <QueryDocumentSnapshot>[];

                            for (final d in docs) {
                              final data = d.data() as Map<String, dynamic>;
                              final senderId = data['senderId'] as String?;
                              final unlockTs = data['unlockDate'] as Timestamp?;
                              final unlockDate = unlockTs?.toDate();

                              final isLocked = unlockDate != null && unlockDate.isAfter(now);
                              if (isLocked) {
                                lockedDocs.add(d);
                              } else if (senderId != null && senderId == currentUid) {
                                sentDocs.add(d);
                              } else {
                                inboxDocs.add(d);
                              }
                            }

                            final tabs = [
                              'Inbox (${inboxDocs.length})',
                              'Sent (${sentDocs.length})',
                              'Locked (${lockedDocs.length})',
                            ];

                            final currentDocs = _selectedTabIndex == 0
                                ? inboxDocs
                                : _selectedTabIndex == 1
                                    ? sentDocs
                                    : lockedDocs;

                            return Column(
                              children: [
                                // Tab Selector
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                                  child: Row(
                                    children: tabs.asMap().entries.map((entry) {
                                      final idx = entry.key;
                                      final label = entry.value;
                                      final isSelected = _selectedTabIndex == idx;

                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            VibrationService.light();
                                            setState(() => _selectedTabIndex = idx);
                                          },
                                          child: Container(
                                            margin: EdgeInsets.only(right: idx < tabs.length - 1 ? 8 : 0),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            decoration: BoxDecoration(
                                              color: isSelected ? AppColors.primary : Colors.white,
                                              borderRadius: BorderRadius.circular(AppRadius.pill),
                                              border: Border.all(
                                                color: isSelected ? AppColors.primary : AppColors.border,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                label,
                                                style: AppTextStyles.heading.copyWith(
                                                  fontSize: 12,
                                                  color: isSelected ? Colors.white : AppColors.ink,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                Expanded(
                                  child: currentDocs.isEmpty
                                      ? _buildEmptyState(relId, partnerName)
                                      : RefreshIndicator(
                                          color: AppColors.primary,
                                          onRefresh: () async {
                                            if (mounted) setState(() {});
                                          },
                                          child: SingleChildScrollView(
                                            physics: const AlwaysScrollableScrollPhysics(),
                                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                                            child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              // If locked letters exist and on inbox or locked tab, show hero banner
                                              if (lockedDocs.isNotEmpty && _selectedTabIndex != 1)
                                                _buildLockedHeroBanner(lockedDocs.first),

                                              Text(
                                                _selectedTabIndex == 0
                                                    ? 'Received Letters'
                                                    : _selectedTabIndex == 1
                                                        ? 'Sent Letters'
                                                        : 'Time-Locked Letters',
                                                style: AppTextStyles.heading.copyWith(fontSize: 16),
                                              ),
                                              const SizedBox(height: 10),

                                              ...currentDocs.map((doc) => _buildLetterCard(doc, currentUid)),
                                              const SizedBox(height: 24),
                                            ],
                                          ),
                                        ),
                                      ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLockedHeroBanner(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final unlockTs = data['unlockDate'] as Timestamp?;
    final unlockDate = unlockTs?.toDate();
    final daysLeft = unlockDate != null ? unlockDate.difference(DateTime.now()).inDays : 0;
    final timeStr = daysLeft > 1 ? 'In $daysLeft days' : (daysLeft == 1 ? 'Tomorrow' : 'Opens soon');

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.pinkSoft.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('💌', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.butter,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'SEALED 🔒',
                        style: AppTextStyles.label.copyWith(color: AppColors.butterText, fontSize: 9),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(timeStr, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  data['title']?.toString() ?? 'Sealed Letter',
                  style: AppTextStyles.heading.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterCard(QueryDocumentSnapshot doc, String? currentUid) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title']?.toString() ?? 'Love Letter';
    final content = data['content']?.toString() ?? '';
    final senderName = data['senderName']?.toString() ?? 'Partner';
    final senderId = data['senderId'] as String?;
    final sealName = data['sealColor'] as String?;
    final sealColor = _getSealColor(sealName);
    final isMe = senderId != null && senderId == currentUid;

    final unlockTs = data['unlockDate'] as Timestamp?;
    final unlockDate = unlockTs?.toDate();
    final isLocked = unlockDate != null && unlockDate.isAfter(DateTime.now());

    final ts = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy').format(ts);

    return GestureDetector(
      onTap: () {
        VibrationService.light();
        if (isLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sealed with $sealName wax until ${DateFormat("dd MMM yyyy").format(unlockDate)}! 🔒💌'),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LetterReaderScreen(
                title: title,
                content: content,
                date: dateStr,
                sender: isMe ? 'You' : senderName,
                sealColor: sealColor,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: sealColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isLocked ? Icons.lock_outline_rounded : Icons.mail_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isMe ? 'Sent by You' : 'From $senderName',
                        style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        dateStr,
                        style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: AppTextStyles.heading.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLocked ? 'Sealed until ${DateFormat("dd MMM yyyy").format(unlockDate)} 🔒' : content,
                    style: AppTextStyles.body.copyWith(color: AppColors.muted, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String? relId, String partnerName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MascotHeart(color: MascotColor.pink, size: 72),
            const SizedBox(height: 16),
            Text(
              'No letters yet',
              style: AppTextStyles.title2.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Pour your heart out in a sealed letter with custom stationery and wax seal.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: '+ Write Love Letter',
              height: 44,
              onPressed: () {
                VibrationService.light();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewLetterScreen(relId: relId, partnerName: partnerName),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
