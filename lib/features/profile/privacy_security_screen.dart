import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../private_space/create_vault_pin_screen.dart';
import '../private_space/reset_vault_pin_screen.dart';

/// NextMeet Privacy & Security Settings Screen
/// Strictly following NextMeet Redesign.pdf (Page 73)
class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _biometricUnlock = true;
  bool _lockOnMinimize = true;
  bool _cityOnlyLocation = false;

  void _exportData() {
    VibrationService.success();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing your couple data archive. Download link will be emailed! 📦✨'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showDeleteAccountDialog() {
    VibrationService.heavy();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.hero),
        ),
        title: Text('Delete Account?', style: AppTextStyles.title1.copyWith(fontSize: 20)),
        content: Text(
          'This will permanently delete your NextMeet account, all encrypted vault photos, love letters, and streak history. This action cannot be undone.',
          style: AppTextStyles.body.copyWith(color: AppColors.muted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.button.copyWith(color: AppColors.ink)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion requested.'),
                  backgroundColor: AppColors.danger,
                ),
              );
            },
            child: Text('Delete Permanently', style: AppTextStyles.button.copyWith(color: AppColors.danger)),
          ),
        ],
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
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.ink),
                    ),
                  ),
                  Text('Privacy & Security', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                  const SizedBox(width: 40),
                ],
              ),

              const SizedBox(height: 20),

              // Vault PIN Management (Page 73)
              Text('Sanctum Vault PIN', style: AppTextStyles.heading.copyWith(fontSize: 16)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    _tile(
                      icon: Icons.pin_rounded,
                      color: AppColors.primary,
                      title: 'Change 4-Digit PIN',
                      subtitle: 'Set a new secure PIN for the photo vault',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CreateVaultPinScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _tile(
                      icon: Icons.sync_lock_rounded,
                      color: AppColors.partner,
                      title: 'Reset PIN Protocol',
                      subtitle: 'Forgot PIN? Request 2-person partner approval',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ResetVaultPinScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Biometrics & Lock Policy (Page 73)
              Text('Lock Policy', style: AppTextStyles.heading.copyWith(fontSize: 16)),
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
                    _switchRow(
                      icon: Icons.fingerprint_rounded,
                      color: AppColors.mintText,
                      title: 'Fingerprint / Face ID',
                      subtitle: 'Unlock vault with biometric sensor',
                      value: _biometricUnlock,
                      onChanged: (v) {
                        VibrationService.light();
                        setState(() => _biometricUnlock = v);
                      },
                    ),
                    const Divider(height: 16, color: AppColors.border),
                    _switchRow(
                      icon: Icons.timer_outlined,
                      color: AppColors.butterText,
                      title: 'Lock on App Exit',
                      subtitle: 'Instantly lock vault when switching apps',
                      value: _lockOnMinimize,
                      onChanged: (v) {
                        VibrationService.light();
                        setState(() => _lockOnMinimize = v);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Location Privacy (Page 73)
              Text('Location Privacy', style: AppTextStyles.heading.copyWith(fontSize: 16)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: _switchRow(
                  icon: Icons.location_city_rounded,
                  color: AppColors.partner,
                  title: 'City-Level Location Only',
                  subtitle: 'Show city name instead of exact street coordinates',
                  value: _cityOnlyLocation,
                  onChanged: (v) {
                    VibrationService.light();
                    setState(() => _cityOnlyLocation = v);
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Data Management & Account Deletion
              Text('Data Ownership', style: AppTextStyles.heading.copyWith(fontSize: 16)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    _tile(
                      icon: Icons.download_rounded,
                      color: AppColors.ink,
                      title: 'Download Couple Data',
                      subtitle: 'Export an encrypted .zip of photos and letters',
                      onTap: _exportData,
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _tile(
                      icon: Icons.delete_forever_rounded,
                      color: AppColors.danger,
                      title: 'Delete Account',
                      subtitle: 'Permanently remove your account and paired data',
                      onTap: _showDeleteAccountDialog,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required Color color,
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
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: AppTextStyles.heading.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.muted, size: 14),
    );
  }

  Widget _switchRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
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
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }
}
