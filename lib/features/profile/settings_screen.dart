import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../auth/login_screen.dart';
import '../auth/reset_password_screen.dart';
import 'app_customise_screen.dart';
import 'edit_location_screen.dart';
import 'edit_profile_screen.dart';
import 'help_feedback_screen.dart';
import 'manage_subscription_screen.dart';
import 'nextmeet_plus_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_security_screen.dart';
import 'terms_policy_screen.dart';
import 'widgets_showcase_screen.dart';
import 'wrapped_story_screen.dart';

/// NextMeet General Settings Screen
/// Strictly following NextMeet Redesign.pdf (Page 71)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  int _hapticLevel = 2; // 0: Off, 1: Subtle, 2: Crisp, 3: Deep
  bool _heartbeatVibration = true;
  bool _soundEffects = true;
  bool _batterySaver = false;

  final List<String> _hapticLabels = ['Off', 'Subtle', 'Crisp', 'Deep'];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final hLevel = prefs.getInt('settings_haptic_level') ?? 2;
    VibrationService.hapticLevel = hLevel;
    setState(() {
      _hapticLevel = hLevel;
      _heartbeatVibration = prefs.getBool('settings_heartbeat_vibration') ?? true;
      _soundEffects = prefs.getBool('settings_sound_effects') ?? true;
      _batterySaver = prefs.getBool('settings_battery_saver') ?? false;
    });
  }

  Future<void> _setHaptic(int level) async {
    VibrationService.hapticLevel = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('settings_haptic_level', level);
  }

  Future<void> _setHeartbeat(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_heartbeat_vibration', v);
  }

  Future<void> _setSound(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_sound_effects', v);
  }

  Future<void> _setBatterySaver(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_battery_saver', v);
  }

  Future<void> _showLogoutDialog() async {
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
            Text('Log Out?', style: AppTextStyles.title1.copyWith(fontSize: 20)),
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
        debugPrint('Signout notice: $e');
      }
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUid;

    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, snapshot) {
        final rel = snapshot.data;
        final relId = rel?.id ?? 'default_rel';
        final currentRel = rel ??
            RelationshipModel(
              uid1: currentUid ?? 'u1',
              uid2: 'u2',
              userName1: 'You',
              userName2: 'Partner',
              anniversaryDate: DateTime.now(),
              lastMeetingDate: DateTime.now(),
              nextMeetingDate: DateTime.now(),
              distanceKm: 0.0,
              loveQuote: 'Close, even when you are apart.',
            );
        final myLocation = currentRel.getMyLocation(currentUid);

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
                  // Top Bar
                  Row(
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
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 16, color: AppColors.ink),
                        ),
                      ),
                      Text('Settings',
                          style: AppTextStyles.title2.copyWith(fontSize: 18)),
                      const SizedBox(width: 40),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Section: Account
                  Text('Account & Location', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        _settingsTile(
                          icon: Icons.person_outline_rounded,
                          iconColor: AppColors.primary,
                          iconBg: AppColors.pinkSoft,
                          title: 'Edit Profile & Photo',
                          subtitle: 'Change your display name and couple avatar',
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
                        const Divider(height: 1, color: AppColors.border),
                        _settingsTile(
                          icon: Icons.location_on_outlined,
                          iconColor: AppColors.mintText,
                          iconBg: AppColors.mintSoft,
                          title: 'Edit Location & Distance',
                          subtitle: myLocation.isNotEmpty
                              ? 'Current: $myLocation'
                              : 'Set your city or auto-detect with GPS',
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
                        const Divider(height: 1, color: AppColors.border),
                        _settingsTile(
                          icon: Icons.lock_outline_rounded,
                          iconColor: AppColors.primary,
                          iconBg: AppColors.pinkSoft,
                          title: 'Change Password',
                          subtitle: 'Update your login password',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ResetPasswordScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _settingsTile(
                          icon: Icons.palette_outlined,
                          iconColor: AppColors.partner,
                          iconBg: AppColors.partnerSoft,
                          title: 'Customize Mascots & Theme',
                          subtitle: 'Personalize hats, accessories, and colors',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const AppCustomiseScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _settingsTile(
                          icon: Icons.widgets_outlined,
                          iconColor: AppColors.mintText,
                          iconBg: AppColors.mintSoft,
                          title: 'Home Screen Widgets',
                          subtitle: 'Preview and add couple widgets to home screen',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const WidgetsShowcaseScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _settingsTile(
                          icon: Icons.auto_stories_rounded,
                          iconColor: AppColors.primary,
                          iconBg: AppColors.pinkSoft,
                          title: 'NextMeet Wrapped 2026',
                          subtitle: 'Relive your year of love, distance, and memories',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const WrappedStoryScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _settingsTile(
                          icon: Icons.workspace_premium_rounded,
                          iconColor: AppColors.butterText,
                          iconBg: AppColors.butterSoft,
                          title: currentRel.isPlus ? 'Manage NextMeet+ VIP' : 'NextMeet+ VIP Subscription',
                          subtitle: currentRel.isPlus
                              ? 'Active plan, benefits & renewal details'
                              : 'One plan covers both hearts • 100% ad-free',
                          onTap: () {
                            if (currentRel.isPlus) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const ManageSubscriptionScreen()),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => NextMeetPlusScreen(relId: relId)),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section: Haptics & Vibration (Page 71)
                  Text('Haptics & Feedback',
                      style: AppTextStyles.heading.copyWith(fontSize: 16)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Vibration Strength', style: AppTextStyles.title2.copyWith(fontSize: 15)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.pinkSoft,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                _hapticLabels[_hapticLevel],
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.border,
                            thumbColor: AppColors.primary,
                            overlayColor: AppColors.primary.withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: _hapticLevel.toDouble(),
                            min: 0,
                            max: 3,
                            divisions: 3,
                            onChanged: (val) {
                              final intLevel = val.toInt();
                              setState(() => _hapticLevel = intLevel);
                              _setHaptic(intLevel);
                              if (intLevel > 0) VibrationService.medium();
                            },
                          ),
                        ),
                        const Divider(height: 20, color: AppColors.border),
                        _switchRow(
                          title: 'Heartbeat Double-Pulse',
                          subtitle: 'Tactile rhythmic heartbeat sync vibrations',
                          value: _heartbeatVibration,
                          onChanged: (v) {
                            VibrationService.light();
                            setState(() => _heartbeatVibration = v);
                            _setHeartbeat(v);
                          },
                        ),
                        const Divider(height: 20, color: AppColors.border),
                        _switchRow(
                          title: 'In-App Sound Effects',
                          subtitle: 'Subtle chimes on sending kisses and hugs',
                          value: _soundEffects,
                          onChanged: (v) {
                            VibrationService.light();
                            setState(() => _soundEffects = v);
                            _setSound(v);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section: Notifications & Privacy (Pages 72-73)
                  Text('Notifications & Privacy',
                      style: AppTextStyles.heading.copyWith(fontSize: 16)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        _settingsTile(
                          icon: Icons.notifications_none_rounded,
                          iconColor: AppColors.butterText,
                          iconBg: AppColors.butterSoft,
                          title: 'Notification Preferences',
                          subtitle: 'Custom alert sounds, touch alerts, and quiet hours',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const NotificationSettingsScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _settingsTile(
                          icon: Icons.lock_outline_rounded,
                          iconColor: AppColors.primary,
                          iconBg: AppColors.pinkSoft,
                          title: 'Privacy & Vault PIN',
                          subtitle: 'Vault PIN, biometric unlock, and location privacy',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const PrivacySecurityScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section: Background & Battery
                  Text('Battery & Sync', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: _switchRow(
                      title: 'Battery Saver Mode',
                      subtitle: 'Update distance and location every 30 mins instead of 5 mins',
                      value: _batterySaver,
                      onChanged: (v) {
                        VibrationService.light();
                        setState(() => _batterySaver = v);
                        _setBatterySaver(v);
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section: Support & Legal (Page 74)
                  Text('Support & Legal', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        _settingsTile(
                          icon: Icons.help_outline_rounded,
                          iconColor: AppColors.partner,
                          iconBg: AppColors.partnerSoft,
                          title: 'Help & Feedback',
                          subtitle: 'Frequently asked questions and support contact',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const HelpFeedbackScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _settingsTile(
                          icon: Icons.description_outlined,
                          iconColor: AppColors.mintText,
                          iconBg: AppColors.mintSoft,
                          title: 'Terms & Privacy Policy',
                          subtitle: 'Our privacy commitment and terms of service',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const TermsPolicyScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section: Session & Logout
                  Text('Session', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: ListTile(
                      onTap: _showLogoutDialog,
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
                      ),
                      title: Text(
                        'Log Out',
                        style: AppTextStyles.heading.copyWith(fontSize: 15, color: AppColors.danger),
                        maxLines: 1,
                      ),
                      subtitle: Text(
                        'Sign out of your NextMeet account',
                        style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 12),
                        maxLines: 1,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.danger, size: 14),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Version
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'NextMeet for Couples',
                          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Version 1.0.43',
                          style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      );
      },
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: () {
        VibrationService.light();
        onTap();
      },
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: AppTextStyles.heading.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.muted, size: 14),
    );
  }

  Widget _switchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.title2.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }
}
