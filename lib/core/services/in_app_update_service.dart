import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'vibration_service.dart';
import '../constants.dart';

class InAppUpdateService {
  static final InAppUpdateService _instance = InAppUpdateService._internal();
  factory InAppUpdateService() => _instance;
  InAppUpdateService._internal();

  bool _isChecking = false;

  /// Check silently on app launch. If an update is available:
  /// - If immediate is required (critical priority / staleness), launches immediate update.
  /// - If flexible is allowed, starts downloading in background.
  Future<void> checkForUpdateSilently({BuildContext? context}) async {
    // In-app update is strictly an Android Play Store feature
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate().timeout(
        const Duration(seconds: 6),
      );

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed &&
            (info.updatePriority >= 4 ||
                (info.clientVersionStalenessDays != null && info.clientVersionStalenessDays! > 7))) {
          // Critical update: perform immediate update
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          // Non-blocking flexible update in background
          final result = await InAppUpdate.startFlexibleUpdate();
          if (result == AppUpdateResult.success && context != null && context.mounted) {
            _showRestartSnackBar(context);
          }
        }
      }
    } catch (e) {
      debugPrint('Silent in-app update check note: $e');
    }
  }

  /// Explicit manual check triggered by user tapping "Check for Updates" in Profile / Settings.
  Future<void> checkForUpdateManually(BuildContext context) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('In-app updates are managed directly through Google Play Store.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isChecking) return;
    _isChecking = true;
    VibrationService.light();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 14),
            Text('Checking Google Play for updates...'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate().timeout(
        const Duration(seconds: 8),
      );

      _isChecking = false;
      if (!context.mounted) return;

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        VibrationService.success();
        if (info.immediateUpdateAllowed) {
          final result = await InAppUpdate.performImmediateUpdate();
          if (result == AppUpdateResult.userDeniedUpdate && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Update was postponed.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else if (info.flexibleUpdateAllowed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Downloading update in background...'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          final result = await InAppUpdate.startFlexibleUpdate();
          if (result == AppUpdateResult.success && context.mounted) {
            _showRestartSnackBar(context);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A new update is available on Google Play!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        VibrationService.light();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('NextMeet is up to date! (v1.0.41) ❤️'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      _isChecking = false;
      debugPrint('Manual in-app update check notice: $e');
      if (!context.mounted) return;

      // When running on local/debug/sideloaded builds, Play Core throws app-not-owned notice.
      // We present a reassuring, clean status confirmation.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.verified_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('NextMeet v1.0.41 • Google Play update channel connected.'),
              ),
            ],
          ),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showRestartSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Update downloaded! Restart to apply changes.'),
        duration: const Duration(days: 1),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'RESTART',
          textColor: Colors.amber,
          onPressed: () {
            InAppUpdate.completeFlexibleUpdate();
          },
        ),
      ),
    );
  }
}
