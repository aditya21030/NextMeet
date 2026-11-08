import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../widgets/flat_components.dart';
import 'heartbeat_sync_modal.dart';
import '../private_space/love_letters_screen.dart';
import 'memories_screen.dart';

/// NextMeet Notifications Hub Screen
/// Strictly following NextMeet Redesign.pdf (Page 20)
class NotificationsScreen extends StatelessWidget {
  final String partnerName;
  final RelationshipModel? rel;
  const NotificationsScreen({super.key, this.partnerName = 'Partner', this.rel});

  String _formatTimeAgo(DateTime? time) {
    if (time == null) return 'Recently';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(time);
  }

  Map<String, dynamic> _getActivityStyle(String type) {
    switch (type.toLowerCase()) {
      case 'hug':
        return {
          'icon': Icons.all_inclusive_rounded,
          'bg': AppColors.partnerSoft,
          'color': AppColors.partner,
        };
      case 'touch':
        return {
          'icon': Icons.touch_app_rounded,
          'bg': AppColors.pinkSoft,
          'color': AppColors.primary,
        };
      case 'miss':
      case 'heartbeat':
        return {
          'icon': Icons.favorite_rounded,
          'bg': AppColors.pinkSoft,
          'color': AppColors.primary,
        };
      case 'memory':
        return {
          'icon': Icons.photo_rounded,
          'bg': AppColors.mintSoft,
          'color': AppColors.mintText,
        };
      case 'letter':
        return {
          'icon': Icons.mail_outline_rounded,
          'bg': AppColors.butterSoft,
          'color': AppColors.butterText,
        };
      case 'trip':
        return {
          'icon': Icons.flight_takeoff_rounded,
          'bg': AppColors.partnerSoft,
          'color': AppColors.partner,
        };
      default:
        return {
          'icon': Icons.notifications_rounded,
          'bg': AppColors.pinkSoft,
          'color': AppColors.primary,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final cloudService = CloudRelationshipService();

    return StreamBuilder<RelationshipModel?>(
      stream: cloudService.streamRelationship(),
      builder: (context, relSnapshot) {
        final activeRel = rel ?? relSnapshot.data;
        final relId = activeRel?.id;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
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
                              child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.ink, size: 16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Notifications',
                            style: AppTextStyles.display.copyWith(fontSize: 26),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          VibrationService.light();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All notifications marked as read ✨')),
                          );
                        },
                        child: Text(
                          'Mark all read',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Real Activity Stream
                Expanded(
                  child: relId == null
                      ? _buildEmptyState()
                      : StreamBuilder<QuerySnapshot>(
                          stream: cloudService.streamActivities(relId),
                          builder: (context, actSnapshot) {
                            if (actSnapshot.connectionState == ConnectionState.waiting &&
                                !actSnapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              );
                            }

                            final docs = actSnapshot.data?.docs ?? [];
                            if (docs.isEmpty) {
                              return _buildEmptyState();
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: 8),
                              itemCount: docs.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final doc = docs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final type = data['type']?.toString() ?? 'general';
                                final message = data['message']?.toString() ?? 'Activity update';
                                final ts = (data['timestamp'] as Timestamp?)?.toDate();
                                final style = _getActivityStyle(type);

                                return _notificationCard(
                                  icon: style['icon'] as IconData,
                                  iconBg: style['bg'] as Color,
                                  iconColor: style['color'] as Color,
                                  title: message,
                                  subtitle: _formatTimeAgo(ts),
                                  onTap: () {
                                    VibrationService.light();
                                    if (type == 'letter') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const LoveLettersScreen()),
                                      );
                                    } else if (type == 'memory') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const MemoriesScreen()),
                                      );
                                    } else if (type == 'heartbeat' || type == 'touch' || type == 'hug' || type == 'miss') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => HeartbeatSyncModal(partnerName: partnerName),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MascotHeart(color: MascotColor.pink, size: 64),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: AppTextStyles.title2.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(
            'No new notifications right now ❤️',
            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _notificationCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.heading.copyWith(fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
