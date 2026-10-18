import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/security_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';
import '../../widgets/glass_card.dart';

class BiometricSecurityScreen extends StatefulWidget {
  final RelationshipModel? rel;

  const BiometricSecurityScreen({super.key, this.rel});

  @override
  State<BiometricSecurityScreen> createState() => _BiometricSecurityScreenState();
}

class _BiometricSecurityScreenState extends State<BiometricSecurityScreen> {
  final SecurityService _securityService = SecurityService();
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  bool _isLoading = true;
  bool _isHardwareSupported = false;
  bool _hasFingerprint = false;
  String _hardwareStatus = 'Checking sensors...';

  bool _masterBiometricsEnabled = false;
  bool _isEnrolling = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final isSupported = await _securityService.isBiometricAvailable();
    final hasFingerprint = await _securityService.supportsFingerprint();
    final status = await _securityService.getHardwareStatusDescription();

    final localMaster = await _securityService.isLocalBiometricEnabled();

    final myUid = _cloudService.currentUid;
    final cloudUseBiometrics = widget.rel != null ? widget.rel!.getMyBiometricPreference(myUid) : localMaster;

    if (mounted) {
      setState(() {
        _isHardwareSupported = isSupported;
        _hasFingerprint = hasFingerprint;
        _hardwareStatus = status;
        _masterBiometricsEnabled = cloudUseBiometrics && localMaster;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleMaster(bool value, String? relId) async {
    VibrationService.light();
    if (value) {
      if (!_isHardwareSupported) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No biometric hardware enrolled on this phone. Check phone settings.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final result = await _securityService.authenticateWithDetails(
        reason: 'Confirm your Fingerprint to enable biometric unlock',
      );

      if (!result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Biometric verification cancelled.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    }

    setState(() => _masterBiometricsEnabled = value);
    await _securityService.setLocalBiometricEnabled(value);

    if (relId != null) {
      await _cloudService.updateBiometricPreference(relId, value);
    }

    VibrationService.success();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Biometric access enabled! 🔒' : 'Biometric access turned off'),
          backgroundColor: value ? AppColors.success : AppColors.textSecondary,
        ),
      );
    }
  }

  Future<void> _enrollSlot({
    required String type,
    required String? relId,
    required String slotName,
  }) async {
    if (_isEnrolling) return;
    VibrationService.light();

    setState(() => _isEnrolling = true);

    try {
      // Fingerprint uses hardware biometric sensor
      if (!_isHardwareSupported) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No fingerprint sensor detected on this phone.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final result = await _securityService.authenticateWithDetails(
        reason: 'Touch your fingerprint sensor to enroll your single slot (1/1)',
        biometricOnly: true,
      );

      if (!mounted) return;

      if (result.success) {
        if (relId != null) {
          await _cloudService.updateBiometricSlot(relId, type: type, enrolled: true);
        }
        await _securityService.setFingerprintEnabled(true);
        await _securityService.setLocalBiometricEnabled(true);
        setState(() => _masterBiometricsEnabled = true);

        VibrationService.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$slotName (1/1) enrolled successfully! 🔒✨'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        VibrationService.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Enrollment cancelled or not recognized.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isEnrolling = false);
    }
  }

  Future<void> _testOrRescanSlot({
    required String type,
    required String slotName,
  }) async {
    VibrationService.medium();

    // Fingerprint test: hardware biometric sensor
    final result = await _securityService.authenticateWithDetails(
      reason: 'Touch your fingerprint sensor to verify hardware responsiveness',
      biometricOnly: true,
    );

    if (!mounted) return;

    if (result.success) {
      VibrationService.success();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          title: Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 24),
              const SizedBox(width: 10),
              Text('$slotName Verified!', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: Text(
            'Your $slotName slot (1/1) is active, verified, and functioning perfectly.',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
              ),
              child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      VibrationService.error();
      if (result.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _removeSlot({
    required String type,
    required String? relId,
    required String slotName,
  }) async {
    VibrationService.medium();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('Remove $slotName?'),
        content: Text(
          'Are you sure you want to remove your $slotName (Slot 1/1)? You can re-enroll it anytime.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
            ),
            child: const Text('REMOVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && relId != null) {
      await _cloudService.updateBiometricSlot(relId, type: type, enrolled: false);
      await _securityService.setFingerprintEnabled(false);
      VibrationService.success();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$slotName slot (1/1) removed.'),
            backgroundColor: AppColors.textSecondary,
          ),
        );
      }
    }
  }

  Future<void> _testGeneralSensor() async {
    VibrationService.medium();
    final result = await _securityService.authenticateWithDetails(
      reason: 'Scan your Fingerprint to test hardware',
      biometricOnly: false,
    );

    if (!mounted) return;

    if (result.success) {
      VibrationService.success();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          title: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: AppColors.success, size: 24),
              SizedBox(width: 10),
              Text('Sensor Verified! ✨', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: const Text(
            'Your low-level native biometric sensor (Fingerprint) is fully operational and authenticated with NextMeet.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
              ),
              child: const Text('GREAT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      VibrationService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Verification test failed or was cancelled.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      initialData: widget.rel,
      builder: (context, snapshot) {
        final rel = snapshot.data ?? widget.rel;
        final myUid = _cloudService.currentUid;
        final relId = rel?.id;
        final partnerName = rel != null ? rel.getPartnerName(myUid) : 'Partner';

        final myFpEnrolled = rel != null ? rel.isMyFingerprintEnrolled(myUid) : false;
        final partnerFpEnrolled = rel != null ? rel.isPartnerFingerprintEnrolled(myUid) : false;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
            ),
            title: Text('Fingerprint Security', style: AppTextStyles.h3),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Banner
                      FadeInUp(
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.l),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isHardwareSupported
                                  ? [const Color(0xFF10B981).withValues(alpha: 0.12), const Color(0xFF059669).withValues(alpha: 0.04)]
                                  : [Colors.orange.withValues(alpha: 0.12), Colors.orange.withValues(alpha: 0.04)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            border: Border.all(
                              color: _isHardwareSupported
                                  ? const Color(0xFF10B981).withValues(alpha: 0.25)
                                  : Colors.orange.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _isHardwareSupported
                                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                      : Colors.orange.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isHardwareSupported ? Icons.shield_rounded : Icons.info_outline_rounded,
                                  color: _isHardwareSupported ? const Color(0xFF059669) : Colors.orange,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.m),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _hardwareStatus,
                                      style: AppTextStyles.bodyM.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _isHardwareSupported ? const Color(0xFF065F46) : Colors.brown,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isHardwareSupported
                                          ? 'Hardware security enclave active'
                                          : 'Register biometrics in your phone settings',
                                      style: AppTextStyles.bodyS.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Master Toggle Section
                      FadeInUp(
                        delay: const Duration(milliseconds: 100),
                        child: _buildSectionHeader('BIOMETRIC ACCESS'),
                      ),
                      FadeInUp(
                        delay: const Duration(milliseconds: 150),
                        child: GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.m),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.lock_open_rounded, color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(width: AppSpacing.m),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Quick Biometric Unlock', style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.bold)),
                                    Text(
                                      'Unlock Sanctuary instantly with enrolled slots',
                                      style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _masterBiometricsEnabled,
                                activeColor: AppColors.primary,
                                onChanged: (val) => _toggleMaster(val, relId),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // User 1 Slot Section (Your Fingerprint Slot)
                      FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        child: _buildSectionHeader('YOUR BIOMETRIC SLOT (1 OF 1)'),
                      ),
                      FadeInUp(
                        delay: const Duration(milliseconds: 220),
                        child: Text(
                          'Each user has exactly 1 Fingerprint slot to guarantee pairing integrity.',
                          style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 11.5),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),

                      // Your Fingerprint Slot
                      FadeInUp(
                        delay: const Duration(milliseconds: 240),
                        child: _buildUserSlotCard(
                          title: 'Fingerprint Slot (1/1)',
                          icon: Icons.fingerprint_rounded,
                          isEnrolled: myFpEnrolled,
                          isAvailable: _hasFingerprint || _isHardwareSupported,
                          enrolledSubtitle: 'Your 1 registered fingerprint is active for Sanctuary unlock.',
                          emptySubtitle: 'No fingerprint registered yet. Enroll your single slot.',
                          onEnroll: () => _enrollSlot(
                            type: 'fingerprint',
                            relId: relId,
                            slotName: 'Fingerprint',
                          ),
                          onTest: () => _testOrRescanSlot(
                            type: 'fingerprint',
                            slotName: 'Fingerprint',
                          ),
                          onRemove: () => _removeSlot(
                            type: 'fingerprint',
                            relId: relId,
                            slotName: 'Fingerprint',
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Partner Slot Section (Read-only status)
                      FadeInUp(
                        delay: const Duration(milliseconds: 300),
                        child: _buildSectionHeader("${partnerName.toUpperCase()}'S BIOMETRIC SLOT (1 OF 1)"),
                      ),
                      FadeInUp(
                        delay: const Duration(milliseconds: 320),
                        child: Text(
                          'Partner biometric credentials are setup directly on their own device.',
                          style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 11.5),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),

                      // Partner's Fingerprint Slot
                      FadeInUp(
                        delay: const Duration(milliseconds: 340),
                        child: _buildPartnerSlotCard(
                          title: 'Fingerprint Slot (1/1)',
                          icon: Icons.fingerprint_rounded,
                          isEnrolled: partnerFpEnrolled,
                          partnerName: partnerName,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Diagnostics & Testing
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: _buildSectionHeader('DIAGNOSTICS & SENSOR TEST'),
                      ),
                      FadeInUp(
                        delay: const Duration(milliseconds: 420),
                        child: GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.l),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Test Low-Level Hardware Prompt',
                                style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Trigger the low-level Android/iOS biometric prompt immediately to test hardware responsiveness.',
                                style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(height: AppSpacing.l),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _testGeneralSensor,
                                  icon: const Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 18),
                                  label: const Text(
                                    'TEST HARDWARE SENSOR',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                      fontSize: 12,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Privacy & Security Notice
                      FadeInUp(
                        delay: const Duration(milliseconds: 450),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.m),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.l),
                            border: Border.all(color: Colors.pink.shade50),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.security_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'NextMeet processes biometric credentials directly through your device\'s native hardware enclave (Android BiometricPrompt & Apple LocalAuthentication). Raw biometric data is never stored on servers or shared with anyone.',
                                  style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 11, height: 1.45),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
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
          color: AppColors.textSecondary.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildUserSlotCard({
    required String title,
    required IconData icon,
    required bool isEnrolled,
    required bool isAvailable,
    required String enrolledSubtitle,
    required String emptySubtitle,
    required VoidCallback onEnroll,
    required VoidCallback onTest,
    required VoidCallback onRemove,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isEnrolled
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : (isAvailable ? AppColors.primary.withValues(alpha: 0.08) : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isEnrolled
                      ? const Color(0xFF059669)
                      : (isAvailable ? AppColors.primary : Colors.grey),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      isEnrolled ? enrolledSubtitle : emptySubtitle,
                      style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isEnrolled
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isEnrolled
                        ? const Color(0xFF10B981).withValues(alpha: 0.3)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  isEnrolled ? '1/1 ENROLLED' : '0/1 EMPTY',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: isEnrolled ? const Color(0xFF059669) : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.m),
          if (isEnrolled) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTest,
                    icon: const Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                    label: const Text(
                      'TEST / RE-SCAN',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                  label: const Text(
                    'REMOVE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isAvailable && !_isEnrolling ? onEnroll : null,
                icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                label: Text(
                  'ENROLL $title (SLOT 1/1)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, letterSpacing: 0.5, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartnerSlotCard({
    required String title,
    required IconData icon,
    required bool isEnrolled,
    required String partnerName,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEnrolled
                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isEnrolled ? const Color(0xFF059669) : Colors.grey,
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  isEnrolled
                      ? '$partnerName has enrolled their 1 slot on their device.'
                      : 'Waiting for $partnerName to enroll on their device.',
                  style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isEnrolled
                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                  : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isEnrolled
                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                    : Colors.amber.shade200,
              ),
            ),
            child: Text(
              isEnrolled ? '1/1 ENROLLED' : '0/1 WAITING',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: isEnrolled ? const Color(0xFF059669) : Colors.amber.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
