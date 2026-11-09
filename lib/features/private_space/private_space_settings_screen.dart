import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/security_service.dart';
import '../../core/models/relationship_model.dart';
import '../../widgets/primary_button.dart';
import '../profile/nextmeet_plus_screen.dart';
import '../profile/biometric_security_screen.dart';
import 'reset_vault_pin_screen.dart';

/// Modernized NextMeet Vault Settings Screen
/// Aligned with NextMeet Design System and Monetize.md
class PrivateSpaceSettingsScreen extends StatefulWidget {
  final String? relId;
  const PrivateSpaceSettingsScreen({super.key, this.relId});

  @override
  State<PrivateSpaceSettingsScreen> createState() => _PrivateSpaceSettingsScreenState();
}

class _PrivateSpaceSettingsScreenState extends State<PrivateSpaceSettingsScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final SecurityService _securityService = SecurityService();

  void _handleChangePin(String relId, RelationshipModel rel) {
    VibrationService.medium();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChangePinSheet(
        relId: relId,
        rel: rel,
        cloudService: _cloudService,
      ),
    );
  }

  void _showTimeoutPicker(String relId, String current) {
    VibrationService.light();
    final List<String> options = ['Immediately', 'After 1 Minute', 'After 5 Minutes', 'Never'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
            const SizedBox(height: 18),
            Text('Auto-lock Timeout', style: AppTextStyles.title2.copyWith(fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              'Choose how quickly your Vault locks when inactive',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...options.map((opt) {
              final isSelected = opt == current;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.pinkSoft.withValues(alpha: 0.5) : AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    opt,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.ink,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                      : null,
                  onTap: () async {
                    VibrationService.medium();
                    await _cloudService.updatePrivateSpaceTimeout(relId, opt);
                    if (mounted) Navigator.pop(context);
                  },
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog(String relId) {
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
              child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Clear All Vault Data?', style: AppTextStyles.title2.copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              'This permanently deletes all secret photos and love letters in your Vault from both phones and cloud backup. This action cannot be reversed.',
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
                      VibrationService.heavy();
                      Navigator.pop(dialogCtx);
                      await _cloudService.clearPrivateSpaceData(relId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vault data has been cleared 🗑️'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      alignment: Alignment.center,
                      child: Text('Delete All', style: AppTextStyles.button.copyWith(color: Colors.white)),
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
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final rel = snapshot.data;
        final relId = widget.relId ?? rel?.id ?? '';
        final partnerName = rel?.getPartnerName(_cloudService.currentUid) ?? 'Partner';
        final bool isPlus = rel?.isPlus ?? false;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Modern Top Header
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
                          'Vault Settings',
                          style: AppTextStyles.title2.copyWith(fontSize: 18),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          VibrationService.medium();
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border, width: 1.5),
                          ),
                          child: const Icon(Icons.lock_rounded, size: 18, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Settings Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // SECTION 1: SECURITY & PIN
                        _buildSectionHeader('VAULT SECURITY & PIN'),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.hero),
                            border: Border.all(color: AppColors.border, width: 1.5),
                          ),
                          child: Column(
                            children: [
                              _buildSettingRow(
                                title: 'Change Vault PIN',
                                sub: rel?.pinResetRequestBy != null
                                    ? 'Reset request pending partner approval...'
                                    : 'Update your 4-digit secret key',
                                icon: Icons.pin_rounded,
                                iconBg: AppColors.pinkSoft,
                                iconColor: AppColors.primary,
                                trailing: rel?.pinResetRequestBy != null
                                    ? const Icon(Icons.mark_email_unread_rounded, color: Colors.orange, size: 20)
                                    : null,
                                onTap: rel != null ? () => _handleChangePin(relId, rel) : null,
                              ),
                              Divider(height: 1, indent: 64, endIndent: 16, color: AppColors.border),
                              _buildSettingRow(
                                title: 'Reset PIN via Partner',
                                sub: '2-person mutual verification flow',
                                icon: Icons.lock_reset_rounded,
                                iconBg: AppColors.partnerSoft,
                                iconColor: AppColors.partner,
                                onTap: () {
                                  VibrationService.light();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ResetVaultPinScreen(
                                        partnerName: partnerName,
                                        relId: relId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Divider(height: 1, indent: 64, endIndent: 16, color: AppColors.border),
                              _buildSettingRow(
                                title: 'Biometric Unlock',
                                sub: 'Use fingerprint for instant access',
                                icon: Icons.fingerprint_rounded,
                                iconBg: AppColors.mintSoft,
                                iconColor: AppColors.mintText,
                                trailing: Switch(
                                  value: rel?.getMyBiometricPreference(_cloudService.currentUid) ?? false,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) async {
                                    VibrationService.light();
                                    if (val) {
                                      final result = await _securityService.authenticateWithDetails(
                                        reason: 'Scan fingerprint to enable Vault biometric unlock',
                                      );
                                      if (!result.success) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(result.errorMessage ?? 'Biometrics not available on this device'),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                        return;
                                      }
                                      if (relId.isNotEmpty) {
                                        await _cloudService.updateBiometricPreference(relId, true);
                                      }
                                      await _securityService.setLocalBiometricEnabled(true);
                                      VibrationService.success();
                                    } else {
                                      if (relId.isNotEmpty) {
                                        await _cloudService.updateBiometricPreference(relId, false);
                                      }
                                      await _securityService.setLocalBiometricEnabled(false);
                                    }
                                    if (mounted) setState(() {});
                                  },
                                ),
                              ),
                              Divider(height: 1, indent: 64, endIndent: 16, color: AppColors.border),
                              _buildSettingRow(
                                title: 'Sensor Diagnostics',
                                sub: 'Hardware enclave options & sensor tests',
                                icon: Icons.security_rounded,
                                iconBg: AppColors.butterSoft,
                                iconColor: AppColors.butterText,
                                onTap: rel != null ? () {
                                  VibrationService.light();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => BiometricSecurityScreen(rel: rel)),
                                  );
                                } : null,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // SECTION 2: AUTO-LOCK & PRIVACY
                        _buildSectionHeader('AUTO-LOCK & TIMEOUT'),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.hero),
                            border: Border.all(color: AppColors.border, width: 1.5),
                          ),
                          child: Column(
                            children: [
                              _buildSettingRow(
                                title: 'Auto-lock Timeout',
                                sub: 'Locks when app switches or goes inactive',
                                icon: Icons.timer_rounded,
                                iconBg: AppColors.pinkSoft,
                                iconColor: AppColors.primary,
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.pinkSoft,
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Text(
                                    rel?.privateSpaceTimeout ?? 'Immediately',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                onTap: relId.isNotEmpty
                                    ? () => _showTimeoutPicker(relId, rel?.privateSpaceTimeout ?? 'Immediately')
                                    : null,
                              ),
                              Divider(height: 1, indent: 64, endIndent: 16, color: AppColors.border),
                              _buildSettingRow(
                                title: 'Lock Vault Now',
                                sub: 'Instantly exit and require PIN to return',
                                icon: Icons.lock_outline_rounded,
                                iconBg: AppColors.partnerSoft,
                                iconColor: AppColors.partner,
                                onTap: () {
                                  VibrationService.medium();
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // SECTION 3: STORAGE & BACKUP (Monetize.md)
                        _buildSectionHeader('VAULT STORAGE & BACKUP'),
                        StreamBuilder<QuerySnapshot>(
                          stream: relId.isNotEmpty ? _cloudService.streamPrivatePhotos(relId) : Stream.empty(),
                          builder: (context, photoSnap) {
                            final photoCount = photoSnap.data?.docs.length ?? 0;
                            final maxPhotos = 30;
                            final progress = isPlus ? 1.0 : (photoCount / maxPhotos).clamp(0.0, 1.0);

                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppRadius.hero),
                                border: Border.all(color: AppColors.border, width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: isPlus ? AppColors.butterSoft : AppColors.pinkSoft,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          isPlus ? Icons.cloud_done_rounded : Icons.photo_library_rounded,
                                          color: isPlus ? AppColors.butterText : AppColors.primary,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    isPlus ? 'Unlimited 4K Vault Active' : 'Basic Vault (Up to 30 Photos)',
                                                    style: AppTextStyles.heading.copyWith(fontSize: 15),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (isPlus) ...[
                                                  const SizedBox(width: 6),
                                                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              isPlus
                                                  ? '$photoCount photos saved • 100% 4K original quality'
                                                  : '$photoCount of $maxPhotos photos saved (Free tier)',
                                              style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: isPlus ? 1.0 : progress,
                                      minHeight: 6,
                                      backgroundColor: AppColors.border.withValues(alpha: 0.5),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isPlus ? AppColors.mint : (progress >= 0.9 ? Colors.orange : AppColors.primary),
                                      ),
                                    ),
                                  ),
                                  if (!isPlus) ...[
                                    const SizedBox(height: 14),
                                    GestureDetector(
                                      onTap: () {
                                        VibrationService.medium();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => NextMeetPlusScreen(relId: relId)),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: AppColors.pinkSoft,
                                          borderRadius: BorderRadius.circular(AppRadius.card),
                                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.stars_rounded, color: AppColors.primary, size: 20),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Upgrade to NextMeet+ for Unlimited 4K Vault & Audio Archive ✨',
                                                style: AppTextStyles.caption.copyWith(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // SECTION 4: DANGER ZONE
                        _buildSectionHeader('DANGER ZONE'),
                        GestureDetector(
                          onTap: relId.isNotEmpty ? () => _showClearDataDialog(relId) : null,
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
                                  child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Clear Private Vault Data',
                                        style: AppTextStyles.heading.copyWith(color: Colors.redAccent, fontSize: 15),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Permanently delete secret photos & letters',
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

                        // Footer version
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'NextMeet Sanctum Vault • v1.0.39',
                                style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'End-to-End Encrypted Couple Space 🔒',
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
              ],
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

  Widget _buildSettingRow({
    required String title,
    required String sub,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.hero),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.heading.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(sub, style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11)),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Modern Tactile PIN Change Sheet
class _ChangePinSheet extends StatefulWidget {
  final String relId;
  final RelationshipModel rel;
  final CloudRelationshipService cloudService;

  const _ChangePinSheet({
    required this.relId,
    required this.rel,
    required this.cloudService,
  });

  @override
  State<_ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends State<_ChangePinSheet> {
  int _step = 0; // 0: current, 1: new, 2: confirm
  String _entered = '';
  String? _newPin;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    final isResetApproved = widget.rel.pinResetRequestBy == widget.cloudService.currentUid && widget.rel.pinResetApproved;
    _step = (widget.rel.privateSpacePin == null || isResetApproved) ? 1 : 0;
  }

  void _onDigit(String digit) {
    if (_entered.length >= 4) return;
    setState(() => _entered += digit);
    if (_entered.length == 4) {
      _processInput(_entered);
    }
  }

  void _onBackspace() {
    if (_entered.isNotEmpty) {
      VibrationService.light();
      setState(() => _entered = _entered.substring(0, _entered.length - 1));
    }
  }

  Future<void> _processInput(String pin) async {
    if (_step == 0) {
      // Verify current PIN
      if (pin == widget.rel.privateSpacePin) {
        VibrationService.success();
        setState(() {
          _step = 1;
          _entered = '';
        });
      } else {
        VibrationService.error();
        setState(() => _hasError = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Current PIN is incorrect ❌')),
          );
        }
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) setState(() { _entered = ''; _hasError = false; });
      }
    } else if (_step == 1) {
      VibrationService.medium();
      setState(() {
        _newPin = pin;
        _step = 2;
        _entered = '';
      });
    } else if (_step == 2) {
      if (pin == _newPin) {
        await widget.cloudService.updatePrivateSpacePin(widget.relId, pin);
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('vault_pin', pin);
        } catch (_) {}
        VibrationService.success();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vault PIN updated successfully! 🔐✨'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        VibrationService.error();
        setState(() => _hasError = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PINs did not match. Enter new PIN again.')),
          );
        }
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _newPin = null;
            _step = 1;
            _entered = '';
            _hasError = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String titleText;
    String subText;

    if (_step == 0) {
      titleText = 'Verify Current PIN 🔐';
      subText = 'Enter your current 4-digit Vault code';
    } else if (_step == 1) {
      titleText = 'Set New PIN 🔒';
      subText = 'Choose a fresh 4-digit secret key';
    } else {
      titleText = 'Confirm New PIN ✨';
      subText = 'Re-enter your new 4-digit code to confirm';
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 32),
              Expanded(
                child: Text(
                  titleText,
                  style: AppTextStyles.title2.copyWith(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: AppColors.muted, size: 20),
              ),
            ],
          ),
          Text(subText, style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
          const SizedBox(height: 24),
          // Romantic Heart PIN Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isFilled = index < _entered.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: isFilled ? 20 : 16,
                height: isFilled ? 20 : 16,
                decoration: BoxDecoration(
                  color: _hasError ? Colors.redAccent : (isFilled ? AppColors.primary : Colors.white),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _hasError
                        ? Colors.redAccent
                        : (isFilled ? AppColors.primary : AppColors.border),
                    width: 2,
                  ),
                ),
                child: isFilled
                    ? const Center(child: Icon(Icons.favorite_rounded, size: 10, color: Colors.white))
                    : null,
              );
            }),
          ),
          const SizedBox(height: 28),
          // Tactile Numeric Dialpad
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNumBtn('1'),
                  _buildNumBtn('2'),
                  _buildNumBtn('3'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNumBtn('4'),
                  _buildNumBtn('5'),
                  _buildNumBtn('6'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNumBtn('7'),
                  _buildNumBtn('8'),
                  _buildNumBtn('9'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(width: 68, height: 68),
                  _buildNumBtn('0'),
                  GestureDetector(
                    onTap: _onBackspace,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: const Icon(Icons.backspace_outlined, size: 22, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_step == 0)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                final partnerName = widget.rel.getPartnerName(widget.cloudService.currentUid);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResetVaultPinScreen(
                      partnerName: partnerName,
                      relId: widget.relId,
                    ),
                  ),
                );
              },
              child: Text(
                'Forgot current PIN? Reset via partner approval',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildNumBtn(String n) {
    return GestureDetector(
      onTap: () {
        VibrationService.light();
        _onDigit(n);
      },
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Center(
          child: Text(
            n,
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
