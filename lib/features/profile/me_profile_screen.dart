import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/models/memory_model.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'edit_location_screen.dart';
import 'nextmeet_plus_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_security_screen.dart';
import 'help_feedback_screen.dart';
import 'partner_details_screen.dart';
import 'settings_screen.dart';
import 'app_customise_screen.dart';
import 'widgets_showcase_screen.dart';
import 'wrapped_story_screen.dart';

/// NextMeet "Me" Profile Hub Screen
/// Strictly following NextMeet Redesign.pdf (Page 67)
class MeProfileScreen extends StatefulWidget {
  const MeProfileScreen({super.key});

  @override
  State<MeProfileScreen> createState() => _MeProfileScreenState();
}

class _MeProfileScreenState extends State<MeProfileScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, snapshot) {
        final rel = snapshot.data;
        final currentUid = _cloudService.currentUid;
        final myName = rel?.getMyName(currentUid) ?? 'You';
        final partnerName = rel?.getPartnerName(currentUid) ?? 'Partner';
        final streak = rel?.streakCount ?? 0;
        final currentRel = rel ??
            RelationshipModel(
              uid1: _cloudService.currentUid ?? 'u1',
              uid2: 'u2',
              userName1: myName,
              userName2: partnerName,
              anniversaryDate: DateTime.now(),
              lastMeetingDate: DateTime.now(),
              nextMeetingDate: DateTime.now(),
              distanceKm: 0.0,
              loveQuote: 'Close, even when you are apart.',
            );
        final String relId = rel?.id ?? 'default_rel';
        final bool isPartner =
            rel != null && rel.uid2 == _cloudService.currentUid;

        final anniversary = rel?.anniversaryDate;
        final daysTogether = anniversary != null
            ? DateTime.now().difference(anniversary).inDays.abs()
            : 0;
        final anniversaryStr = anniversary != null
            ? 'Together since\n${DateFormat('d MMM yyyy').format(anniversary)}'
            : 'Together\nIn Love';

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: RefreshIndicator(
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
                  const SizedBox(height: 12),
                  // Top Bar: "Me" + Settings Cog
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Me', style: AppTextStyles.display.copyWith(fontSize: 28)),
                      IconButton(
                        onPressed: () {
                          VibrationService.light();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings_outlined, color: AppColors.ink, size: 24),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Header Couple Card (Page 67)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.pinkSoft.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppRadius.hero),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const MascotHeart(color: MascotColor.pink, size: 68),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 84,
                              child: Text(
                                myName,
                                style: AppTextStyles.heading.copyWith(fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 18),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              anniversaryStr,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const MascotHeart(color: MascotColor.violet, size: 68),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 84,
                              child: Text(
                                partnerName,
                                style: AppTextStyles.heading.copyWith(fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 3 Stat Boxes (Page 67)
                  StreamBuilder<List<MemoryModel>>(
                    stream: _cloudService.streamMemories(relId),
                    builder: (context, memSnap) {
                      final memCount = memSnap.data?.length ?? 0;
                      return Row(
                        children: [
                          Expanded(
                            child: _statBox('$daysTogether', 'days together'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _statBox('$streak', 'day streak'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _statBox('$memCount', 'memories'),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // NextMeet+ Upsell Banner (Butter, Page 67)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.butterSoft,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.butter, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NextMeet+',
                                style: AppTextStyles.heading.copyWith(
                                  color: AppColors.butterText,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'More storage, extra vault space and custom themes.',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.butterText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            VibrationService.light();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => NextMeetPlusScreen(relId: relId)),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              'Try it',
                              style: AppTextStyles.button.copyWith(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Menu Rows (Page 67)
                  _menuItem(
                    icon: Icons.person_outline_rounded,
                    iconBg: AppColors.pinkSoft,
                    iconColor: AppColors.primary,
                    title: 'Account',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            relationshipId: relId,
                            relationship: currentRel,
                            isPartner: false,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  _menuItem(
                    icon: Icons.location_on_outlined,
                    iconBg: AppColors.mintSoft,
                    iconColor: AppColors.mintText,
                    title: 'Location & Distance',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditLocationScreen(
                            relationship: currentRel,
                            relationshipId: relId,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  _menuItem(
                    icon: Icons.favorite_border_rounded,
                    iconBg: AppColors.partnerSoft,
                    iconColor: AppColors.partner,
                    title: 'Partner connection',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PartnerDetailsScreen(
                            relationship: currentRel,
                            relationshipId: relId,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  _menuItem(
                    icon: Icons.notifications_none_rounded,
                    iconBg: AppColors.butterSoft,
                    iconColor: AppColors.butterText,
                    title: 'Notifications and haptics',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  _menuItem(
                    icon: Icons.lock_outline_rounded,
                    iconBg: AppColors.pinkSoft,
                    iconColor: AppColors.primary,
                    title: 'Privacy and Vault PIN',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacySecurityScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  _menuItem(
                    icon: Icons.palette_outlined,
                    iconBg: AppColors.butterSoft,
                    iconColor: AppColors.butterText,
                    title: 'Customize mascots and theme',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AppCustomiseScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  _menuItem(
                    icon: Icons.widgets_outlined,
                    iconBg: AppColors.mintSoft,
                    iconColor: AppColors.mintText,
                    title: 'Home screen widgets',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WidgetsShowcaseScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  _menuItem(
                    icon: Icons.auto_stories_rounded,
                    iconBg: AppColors.partnerSoft,
                    iconColor: AppColors.partner,
                    title: 'NextMeet Wrapped 2026',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WrappedStoryScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  _menuItem(
                    icon: Icons.help_outline_rounded,
                    iconBg: AppColors.partnerSoft,
                    iconColor: AppColors.partner,
                    title: 'Help and feedback',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HelpFeedbackScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  _menuItem(
                    icon: Icons.logout_rounded,
                    iconBg: AppColors.danger.withValues(alpha: 0.1),
                    iconColor: AppColors.danger,
                    title: 'Log out',
                    titleColor: AppColors.danger,
                    onTap: () => _showLogoutDialog(context),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      );
      },
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    VibrationService.heavy();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.hero)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Log Out?',
                style: AppTextStyles.title1.copyWith(fontSize: 20),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of NextMeet? Your couple memories, shared map, and love letters will remain safe in the cloud.',
          style: AppTextStyles.body.copyWith(color: AppColors.muted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppTextStyles.button.copyWith(color: AppColors.ink)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Log Out', style: AppTextStyles.button.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      VibrationService.medium();
      try {
        await AuthService().signOut();
      } catch (e) {
        debugPrint('Logout notice: $e');
      }
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _statBox(String number, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              number,
              style: AppTextStyles.title1.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        VibrationService.light();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: titleColor != null ? titleColor.withValues(alpha: 0.3) : AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.heading.copyWith(fontSize: 15, color: titleColor ?? AppColors.ink),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: titleColor ?? AppColors.muted, size: 16),
          ],
        ),
      ),
    );
  }
}
