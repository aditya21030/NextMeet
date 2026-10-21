import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/security_service.dart';
import '../../core/models/relationship_model.dart';
import '../../widgets/glass_card.dart';
import '../profile/nextmeet_plus_screen.dart';
import '../profile/biometric_security_screen.dart';

class PrivateSpaceSettingsScreen extends StatefulWidget {
  const PrivateSpaceSettingsScreen({super.key});

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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text('Auto-lock Timeout', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Choose how quickly Sanctuary locks when inactive',
              style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.l),
            ...options.map((opt) => ListTile(
              title: Text(
                opt,
                style: AppTextStyles.bodyM.copyWith(
                  fontWeight: opt == current ? FontWeight.bold : FontWeight.normal,
                  color: opt == current ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              trailing: opt == current ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
              onTap: () {
                _cloudService.updatePrivateSpaceTimeout(relId, opt);
                Navigator.pop(context);
                VibrationService.medium();
              },
            )),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog(String relId) {
    VibrationService.medium();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text('Clear All Private Data? ⚠️'),
        content: const Text(
          'This will permanently delete ALL secret photos and love letters in your Sanctuary from both this phone and the cloud. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              VibrationService.success();
              Navigator.pop(context);

              await _cloudService.clearPrivateSpaceData(relId);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Private Space data has been deep-cleaned. 🗑️'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('CLEAR DATA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.id == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final rel = snapshot.data!;
        final relId = rel.id!;
        final bool isPlus = rel.isPlus;
        final double limitMb = isPlus ? AppSubscription.plusSecretPhotoVaultBytes / (1024 * 1024) : 20.0;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
            ),
            title: Text('Sanctuary Settings', style: AppTextStyles.h3),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInUp(child: _buildSectionHeader('SECURITY & ACCESS')),
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      children: [
                        _buildSettingRow(
                          'Change Sanctuary PIN',
                          rel.pinResetRequestBy != null
                              ? 'Reset approval in progress...'
                              : 'Update your 4-digit security code',
                          Icons.pin_rounded,
                          trailing: rel.pinResetRequestBy != null
                              ? const Icon(Icons.mark_email_unread_rounded, color: Colors.orange, size: 20)
                              : null,
                          onTap: () => _handleChangePin(relId, rel),
                        ),
                        Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
                        _buildSettingRow(
                          'Biometric Unlock',
                          'Use Fingerprint for fast access',
                          Icons.fingerprint_rounded,
                          trailing: Switch(
                            value: rel.getMyBiometricPreference(_cloudService.currentUid),
                            activeColor: AppColors.primary,
                            onChanged: (val) async {
                              VibrationService.light();
                              if (val) {
                                final result = await _securityService.authenticateWithDetails(
                                  reason: 'Scan Fingerprint to enable biometric unlock',
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
                                await _cloudService.updateBiometricPreference(relId, true);
                                await _securityService.setLocalBiometricEnabled(true);
                                VibrationService.success();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Biometric unlock enabled! 🔒✨')),
                                  );
                                }
                              } else {
                                await _cloudService.updateBiometricPreference(relId, false);
                                await _securityService.setLocalBiometricEnabled(false);
                              }
                            },
                          ),
                        ),
                        Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
                        _buildSettingRow(
                          'Configure Fingerprint Lock',
                          'Hardware sensor options and sensor test',
                          Icons.security_rounded,
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => BiometricSecurityScreen(rel: rel)),
                            );
                          },
                        ),
                        Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
                        _buildSettingRow(
                          'Screen Timeout',
                          'Auto-locks when app goes inactive',
                          Icons.timer_rounded,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              rel.privateSpaceTimeout,
                              style: AppTextStyles.bodyS.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () => _showTimeoutPicker(relId, rel.privateSpaceTimeout),
                        ),
                        Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
                        _buildSettingRow(
                          'Lock Sanctuary Now',
                          'Immediately exit and require PIN to return',
                          Icons.lock_rounded,
                          onTap: () {
                            VibrationService.medium();
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: _buildSectionHeader('ENCRYPTED STORAGE'),
                ),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.storage_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: AppSpacing.m),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Encrypted Vault Storage',
                                        style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      if (isPlus) ...[
                                        const SizedBox(width: 6),
                                        const Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    '${(rel.privateSpaceStorageBytes / (1024 * 1024)).toStringAsFixed(1)} MB of ${limitMb.toInt()} MB used',
                                    style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.l),
                        SizedBox(
                          height: 6,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (rel.privateSpaceStorageBytes / (limitMb * 1024 * 1024)).clamp(0.0, 1.0),
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        ),
                        if (!isPlus) ...[
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => NextMeetPlusScreen(relId: relId)),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.stars_rounded, color: AppColors.primary, size: 18),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Upgrade to NextMeet+ for 150 MB Vault ✨',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
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
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: _buildSectionHeader('DANGER ZONE'),
                ),
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: InkWell(
                    onTap: () => _showClearDataDialog(relId),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20),
                          ),
                          const SizedBox(width: AppSpacing.l),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Clear Private Space Data',
                                  style: AppTextStyles.bodyM.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Permanently delete secret photos & letters',
                                  style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'NextMeet Private Sanctuary v1.0.43',
                        style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'End-to-End Encrypted Couple Space',
                        style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.m),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: AppColors.textSecondary.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildSettingRow(String title, String sub, IconData icon, {VoidCallback? onTap, Widget? trailing}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.bold)),
                  Text(sub, style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right_rounded, color: AppColors.divider.withValues(alpha: 0.8)),
          ],
        ),
      ),
    );
  }
}

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
  // Step 0: Enter current PIN (if PIN exists)
  // Step 1: Enter new PIN
  // Step 2: Confirm new PIN
  int _step = 0;
  String _entered = '';
  String? _newPin;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // If no existing PIN or reset was approved by partner, jump straight to new PIN
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
      // Entered new PIN
      VibrationService.medium();
      setState(() {
        _newPin = pin;
        _step = 2;
        _entered = '';
      });
    } else if (_step == 2) {
      // Confirm new PIN
      if (pin == _newPin) {
        await widget.cloudService.updatePrivateSpacePin(widget.relId, pin);
        VibrationService.success();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sanctuary PIN updated successfully! 🔐✨'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        VibrationService.error();
        setState(() => _hasError = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PINs did not match. Try entering new PIN again.')),
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
      subText = 'Enter your current 4-digit Sanctuary code';
    } else if (_step == 1) {
      titleText = 'Set New PIN 🔒';
      subText = 'Choose a fresh 4-digit secret key';
    } else {
      titleText = 'Confirm New PIN ✨';
      subText = 'Re-enter your new 4-digit code to confirm';
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 32),
              Text(
                titleText,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
              ),
            ],
          ),
          Text(subText, style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          // PIN Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isFilled = index < _entered.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: isFilled ? 18 : 16,
                height: isFilled ? 18 : 16,
                decoration: BoxDecoration(
                  color: _hasError ? Colors.red : (isFilled ? AppColors.primary : Colors.white),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _hasError ? Colors.red : (isFilled ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3)),
                    width: 2,
                  ),
                  boxShadow: isFilled
                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8)]
                      : null,
                ),
                child: isFilled
                    ? const Center(child: Icon(Icons.favorite_rounded, size: 9, color: Colors.white))
                    : null,
              );
            }),
          ),
          const SizedBox(height: 24),
          // Numeric Dialpad
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
                  const SizedBox(width: 64, height: 64),
                  _buildNumBtn('0'),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _onBackspace,
                      borderRadius: BorderRadius.circular(32),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.backspace_outlined, size: 20, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_step == 0)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await widget.cloudService.requestPinReset(widget.relId);
                VibrationService.success();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reset request sent to your partner for approval! ⏳')),
                  );
                }
              },
              child: const Text('Forgot current PIN?', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildNumBtn(String n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          VibrationService.light();
          _onDigit(n);
        },
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.pink.shade50),
          ),
          child: Center(
            child: Text(
              n,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
