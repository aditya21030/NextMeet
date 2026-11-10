import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/theme_service.dart';
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
/// Strictly following NextMeet Modern Design System & Redesign Specs
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

  void _showLogoutDialog() {
    VibrationService.heavy();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (dialogCtx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Log Out of NextMeet?', style: AppTextStyles.title2.copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              'Your couple memories, shared map, and love letters will remain securely backed up in the cloud.',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(dialogCtx),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text('Cancel', style: AppTextStyles.button.copyWith(color: AppColors.ink)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      VibrationService.medium();
                      Navigator.pop(dialogCtx);
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
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      alignment: Alignment.center,
                      child: Text('Log Out', style: AppTextStyles.button.copyWith(color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
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
        final myLocation = currentRel.getMyLocation(currentUid).split(',').first.trim();

        return Scaffold(
          backgroundColor: ThemeService.instance.backgroundColor,
          body: SafeArea(
            child: RefreshIndicator(
              color: ThemeService.instance.primaryColor,
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
                    // Modern Top Bar
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
                            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Settings',
                            style: AppTextStyles.title2.copyWith(fontSize: 18),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // SECTION 1: ACCOUNT & PERSONALIZATION
                    _buildSectionHeader('ACCOUNT & PERSONALIZATION'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.hero),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          _settingsTile(
                            icon: Icons.person_rounded,
                            iconColor: AppColors.primary,
                            iconBg: AppColors.pinkSoft,
                            title: 'Edit Profile & Names',
                            subtitle: 'Change your display name and sweet nickname',
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
                          Divider(height: 1, indent: 64, endIndent: 16, color: AppColors.border),
                          _settingsTile(
                            icon: Icons.location_on_rounded,
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
                          Divider(height: 1, indent: 64, endIndent: 16, color: AppColors.border),
                          _settingsTile(
                            icon: Icons.lock_outline_rounded,
                            iconColor: AppColors.primary,
                            iconBg: AppColors.pinkSoft,
                            title: 'Change Password',
                            subtitle: 'Update your account login password',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
                              );
                            },
                          ),
                          Divider(height: 1, indent: 64, endIndent: 16, color: AppColors.border),
                          _settingsTile(
                            icon: Icons.celebration_rounded,
                            iconColor: AppColors.butterText,
                            iconBg: AppColors.butterSoft,
                            title: 'Customize Mascots & Themes',
                            subtitle: 'Personalize hats, accessories, and colors',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AppCustomiseScreen()),
                              );
                            },
                          ),
                          Divider(height: 1, indent: 64, endIndent: 16, color: AppColors.border),
                          _settingsTile(
                            icon: Icons.widgets_rounded,
                            iconColor: AppColors.partner,
                            iconBg: AppColors.partnerSoft,
                            title: 'Home Screen Widgets',
                            subtitle: 'Preview and add couple widgets to home screen',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const WidgetsShowcaseScreen()),
                              );
                            },
                          ),
                          Divider(height: 1, indent: 64, endIndent: 16, color: AppColors.border),
                          _settingsTile(
                            icon: Icons.auto_stories_rounded,
                            iconColor: AppColors.primary,
                            iconBg: AppColors.pinkSoft,
                            title: 'NextMeet Wrapped 2026',
                            subtitle: 'Relive your year of love, distance, and memories',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const WrappedStoryScreen()),
                              );
                            },
                          ),
                          Divider(height: 1, indent: 64, endIndent: 16, color: AppColors.border),
                          _settingsTile(
                            icon: Icons.stars_rounded,
                            iconColor: AppColors.butterText,
                            iconBg: AppColors.butterSoft,
                            title: currentRel.isPlus ? 'Manage NextMeet+ Pro' : 'NextMeet+ Pro Subscription',
                            subtitle: currentRel.isPlus
                                ? 'Active plan, benefits & renewal details'
                                : 'One plan covers both hearts • 100% ad-free',
                            onTap: () {
                              if (currentRel.isPlus) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ManageSubscriptionScreen()),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => NextMeetPlusScreen(relId: relId)),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SECTION 2: HAPTICS & TACTILE FEEDBACK
                    _buildSectionHeader('HAPTICS & TACTILE FEEDBACK'),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Vibration Strength',
                                  style: AppTextStyles.title2.copyWith(fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
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

                    // SECTION 3: NOTIFICATIONS & PRIVACY
                    _buildSectionHeader('NOTIFICATIONS & PRIVACY'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.hero),
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
                                MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
                              );
                            },
                          ),
                          Divider(height: 1, indent: 64, endIndent: 16, color: AppColors.border),
                          _settingsTile(
                            icon: Icons.lock_outline_rounded,
                            iconColor: AppColors.primary,
                            iconBg: AppColors.pinkSoft,
                            title: 'Privacy & Vault Security',
                            subtitle: 'Vault PIN, biometric unlock, and location privacy',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const PrivacySecurityScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SECTION 4: BATTERY & SYNC
                    _buildSectionHeader('BATTERY & PERFORMANCE'),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.hero),
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

                    // SECTION 5: SUPPORT & LEGAL
                    _buildSectionHeader('SUPPORT & LEGAL'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.hero),
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
                                MaterialPageRoute(builder: (context) => const HelpFeedbackScreen()),
                              );
                            },
                          ),
                          Divider(height: 1, indent: 64, endIndent: 16, color: AppColors.border),
                          _settingsTile(
                            icon: Icons.description_outlined,
                            iconColor: AppColors.mintText,
                            iconBg: AppColors.mintSoft,
                            title: 'Terms & Privacy Policy',
                            subtitle: 'Our privacy commitment and terms of service',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const TermsPolicyScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SECTION 6: SESSION
                    _buildSectionHeader('SESSION'),
                    GestureDetector(
                      onTap: _showLogoutDialog,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(AppRadius.hero),
                          border: Border.all(color: Colors.red.shade200, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Log Out',
                                    style: AppTextStyles.heading.copyWith(color: Colors.redAccent, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Sign out of your NextMeet account safely',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Colors.redAccent, size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // App Version Footer
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'NextMeet for Couples',
                            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Version 1.0.39+86 • Private Couple Space',
                            style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.ink.withValues(alpha: 0.6),
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          fontSize: 11,
        ),
      ),
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
    return InkWell(
      onTap: () {
        VibrationService.light();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppRadius.hero),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.heading.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
          ],
        ),
      ),
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
              Text(title, style: AppTextStyles.heading.copyWith(fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11)),
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
