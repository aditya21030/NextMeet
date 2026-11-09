import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';

/// NextMeet Granular Notifications & Quiet Hours Screen
/// Strictly following NextMeet Redesign.pdf (Page 72)
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _masterNotifications = true;
  bool _touchAlerts = true;
  bool _loveLetters = true;
  bool _momentsAlerts = true;
  bool _tripAlerts = true;
  bool _quietHoursEnabled = true;

  TimeOfDay _quietStart = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);

  int? _snoozedHours;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _masterNotifications = prefs.getBool('notif_master') ?? true;
      _touchAlerts = prefs.getBool('notif_touches') ?? true;
      _loveLetters = prefs.getBool('notif_letters') ?? true;
      _momentsAlerts = prefs.getBool('notif_moments') ?? true;
      _tripAlerts = prefs.getBool('notif_trips') ?? true;
      _quietHoursEnabled = prefs.getBool('notif_quiet_hours') ?? true;
      final startHour = prefs.getInt('notif_quiet_start_h') ?? 23;
      final startMin = prefs.getInt('notif_quiet_start_m') ?? 0;
      _quietStart = TimeOfDay(hour: startHour, minute: startMin);
      final endHour = prefs.getInt('notif_quiet_end_h') ?? 7;
      final endMin = prefs.getInt('notif_quiet_end_m') ?? 0;
      _quietEnd = TimeOfDay(hour: endHour, minute: endMin);
    });
  }

  Future<void> _setPrefBool(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }

  Future<void> _setQuietTime(String prefix, TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${prefix}_h', time.hour);
    await prefs.setInt('${prefix}_m', time.minute);
  }

  void _snooze(int hours) {
    VibrationService.medium();
    setState(() => _snoozedHours = hours);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notifications paused for $hours hours 🌙'),
        backgroundColor: AppColors.ink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadPreferences,
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
                  Expanded(
                    child: Text(
                      'Notifications',
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

              // Master Switch Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.pinkSoft,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Allow Notifications',
                              style: AppTextStyles.title1
                                  .copyWith(fontSize: 16, color: AppColors.primary)),
                          Text('Receive touch pulses and love alerts',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Switch(
                      value: _masterNotifications,
                      onChanged: (v) {
                        VibrationService.light();
                        setState(() => _masterNotifications = v);
                        _setPrefBool('notif_master', v);
                      },
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Granular Alert Switches (Page 72)
              Text('Couple Alerts',
                  style: AppTextStyles.heading.copyWith(fontSize: 16)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    _alertSwitch(
                      icon: Icons.touch_app_rounded,
                      color: AppColors.primary,
                      title: 'Touches & Kisses',
                      subtitle: 'When partner taps Miss You, Hug, or Touch',
                      value: _touchAlerts,
                      onChanged: (v) {
                        setState(() => _touchAlerts = v);
                        _setPrefBool('notif_touches', v);
                      },
                    ),
                    const Divider(height: 16, color: AppColors.border),
                    _alertSwitch(
                      icon: Icons.mail_rounded,
                      color: AppColors.partner,
                      title: 'Love Letters',
                      subtitle: 'When a new sealed letter is delivered',
                      value: _loveLetters,
                      onChanged: (v) {
                        setState(() => _loveLetters = v);
                        _setPrefBool('notif_letters', v);
                      },
                    ),
                    const Divider(height: 16, color: AppColors.border),
                    _alertSwitch(
                      icon: Icons.camera_alt_rounded,
                      color: AppColors.mintText,
                      title: 'Moments Daily Photo',
                      subtitle: "When partner snaps today's split moment",
                      value: _momentsAlerts,
                      onChanged: (v) {
                        setState(() => _momentsAlerts = v);
                        _setPrefBool('notif_moments', v);
                      },
                    ),
                    const Divider(height: 16, color: AppColors.border),
                    _alertSwitch(
                      icon: Icons.airplanemode_active_rounded,
                      color: AppColors.butterText,
                      title: 'Trips & Calendar',
                      subtitle: 'Flight countdowns and milestone reminders',
                      value: _tripAlerts,
                      onChanged: (v) {
                        setState(() => _tripAlerts = v);
                        _setPrefBool('notif_trips', v);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Quiet Hours Schedule (Page 72)
              Text('Quiet Hours / Sleep Mode',
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
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Enable Quiet Hours',
                                  style: AppTextStyles.title2
                                      .copyWith(fontSize: 15)),
                              Text(
                                  'Mute non-urgent notifications during sleep',
                                  style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        Switch(
                          value: _quietHoursEnabled,
                          onChanged: (v) {
                            VibrationService.light();
                            setState(() => _quietHoursEnabled = v);
                            _setPrefBool('notif_quiet_hours', v);
                          },
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                    if (_quietHoursEnabled) ...[
                      const Divider(height: 20, color: AppColors.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _timePickerBox('Bedtime', _quietStart, (t) {
                            setState(() => _quietStart = t);
                            _setQuietTime('notif_quiet_start', t);
                          }),
                          Container(
                              width: 1, height: 32, color: AppColors.border),
                          _timePickerBox('Wake up', _quietEnd, (t) {
                            setState(() => _quietEnd = t);
                            _setQuietTime('notif_quiet_end', t);
                          }),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Quick Snooze Bar (Page 72)
              Text('Pause All Alerts',
                  style: AppTextStyles.heading.copyWith(fontSize: 16)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _snoozeChip(1, '1 Hour'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _snoozeChip(8, '8 Hours'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _snoozeChip(24, '24 Hours'),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _alertSwitch({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.title2.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Switch(
          value: _masterNotifications && value,
          onChanged: _masterNotifications ? onChanged : null,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _timePickerBox(
      String label, TimeOfDay time, ValueChanged<TimeOfDay> onPicked) {
    return GestureDetector(
      onTap: () async {
        final picked =
            await showTimePicker(context: context, initialTime: time);
        if (picked != null) {
          if (!mounted) return;
          onPicked(picked);
        }
      },
      child: Column(
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(time.format(context),
              style: AppTextStyles.heading.copyWith(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _snoozeChip(int hours, String label) {
    final isSelected = _snoozedHours == hours;
    return GestureDetector(
      onTap: () => _snooze(hours),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? AppColors.ink : AppColors.border,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.button.copyWith(
            color: isSelected ? Colors.white : AppColors.ink,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
