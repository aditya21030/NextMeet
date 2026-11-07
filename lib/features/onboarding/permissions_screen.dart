import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import 'find_your_other_half_screen.dart';

/// Last Step of Onboarding: Stay Close With a Few Taps (Permissions)
/// Strictly following NextMeet Redesign.pdf (Page 8)
class PermissionsScreen extends StatefulWidget {
  final String userName;
  final String nickname;
  final MascotColor mascotColor;
  final String yourCity;
  final String theirCity;
  final DateTime togetherSince;
  final DateTime lastTimeMet;
  final DateTime? nextMeetup;
  final String? initialInviteCode;

  const PermissionsScreen({
    super.key,
    required this.userName,
    required this.nickname,
    required this.mascotColor,
    required this.yourCity,
    required this.theirCity,
    required this.togetherSince,
    required this.lastTimeMet,
    this.nextMeetup,
    this.initialInviteCode,
  });

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _notificationAllowed = false;
  bool _locationAllowed = false;
  bool _photosAllowed = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final notif = await Permission.notification.isGranted;
    final loc = await Permission.location.isGranted;
    final photos = await Permission.photos.isGranted || await Permission.storage.isGranted;
    if (mounted) {
      setState(() {
        _notificationAllowed = notif;
        _locationAllowed = loc;
        _photosAllowed = photos;
      });
    }
  }

  Future<void> _requestNotification() async {
    VibrationService.light();
    final status = await Permission.notification.request();
    if (mounted) {
      setState(() => _notificationAllowed = status.isGranted);
    }
  }

  Future<void> _requestLocation() async {
    VibrationService.light();
    final status = await Permission.location.request();
    if (mounted) {
      setState(() => _locationAllowed = status.isGranted);
    }
  }

  Future<void> _requestPhotos() async {
    VibrationService.light();
    final status = await Permission.photos.request();
    if (mounted) {
      setState(() => _photosAllowed = status.isGranted);
    }
  }

  void _handleContinue() {
    VibrationService.light();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FindYourOtherHalfScreen(
          userName: widget.userName,
          nickname: widget.nickname,
          mascotColor: widget.mascotColor,
          yourCity: widget.yourCity,
          theirCity: widget.theirCity,
          togetherSince: widget.togetherSince,
          lastTimeMet: widget.lastTimeMet,
          nextMeetup: widget.nextMeetup,
          initialInviteCode: widget.initialInviteCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
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
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.ink, size: 16),
                    ),
                  ),
                  Text(
                    'Last step',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Smiling Mascot Heart
              Center(
                child: MascotHeart(
                  color: widget.mascotColor,
                  size: 96,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Stay close with a few taps',
                style: AppTextStyles.display.copyWith(fontSize: 26),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'You can change any of these later in Settings.',
                style: AppTextStyles.body.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Permission 1: Notifications
              _permissionRow(
                icon: Icons.notifications_none_rounded,
                iconColor: AppColors.primary,
                title: 'Notifications',
                subtitle: 'Hugs, whispers and meetup reminders',
                isAllowed: _notificationAllowed,
                onRequest: _requestNotification,
              ),

              const SizedBox(height: 14),

              // Permission 2: Location
              _permissionRow(
                icon: Icons.location_on_outlined,
                iconColor: AppColors.partner,
                title: 'Location',
                subtitle: 'Distance and your time zone. Never shared with anyone else.',
                isAllowed: _locationAllowed,
                onRequest: _requestLocation,
              ),

              const SizedBox(height: 14),

              // Permission 3: Photos and camera
              _permissionRow(
                icon: Icons.camera_alt_outlined,
                iconColor: AppColors.butterText,
                title: 'Photos and camera',
                subtitle: 'Add memories and send moments',
                isAllowed: _photosAllowed,
                onRequest: _requestPhotos,
              ),

              const SizedBox(height: 24),

              // Continue Button
              PrimaryButton(
                text: 'Continue',
                onPressed: _handleContinue,
              ),
              const SizedBox(height: 12),

              // Not now Button
              Center(
                child: TextButton(
                  onPressed: _handleContinue,
                  child: Text(
                    'Not now',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _permissionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isAllowed,
    required VoidCallback onRequest,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.heading.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.25)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isAllowed ? null : onRequest,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isAllowed ? AppColors.pinkSoft : AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                isAllowed ? 'Allowed' : 'Allow',
                style: AppTextStyles.caption.copyWith(
                  color: isAllowed ? AppColors.primary : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
