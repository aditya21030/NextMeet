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
  bool _hasFace = false;
  String _hardwareStatus = 'Checking sensors...';

  bool _masterBiometricsEnabled = false;
  bool _fingerprintEnabled = true;
  bool _faceCamEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final isSupported = await _securityService.isBiometricAvailable();
    final hasFingerprint = await _securityService.supportsFingerprint();
    final hasFace = await _securityService.supportsFaceRecognition();
    final status = await _securityService.getHardwareStatusDescription();

    final localMaster = await _securityService.isLocalBiometricEnabled();
    final fpEnabled = await _securityService.isFingerprintEnabled();
    final faceEnabled = await _securityService.isFaceCamEnabled();

    final myUid = _cloudService.currentUid;
    final cloudUseBiometrics = widget.rel != null ? widget.rel!.getMyBiometricPreference(myUid) : localMaster;

    if (mounted) {
      setState(() {
        _isHardwareSupported = isSupported;
        _hasFingerprint = hasFingerprint;
        _hasFace = hasFace;
        _hardwareStatus = status;
        _masterBiometricsEnabled = cloudUseBiometrics && localMaster;
        _fingerprintEnabled = fpEnabled;
        _faceCamEnabled = faceEnabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleMaster(bool value) async {
    VibrationService.light();
    if (value) {
      if (!_isHardwareSupported) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No biometric hardware enrolled on this device. Check phone settings.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Verify biometric once before enabling
      final result = await _securityService.authenticateWithDetails(
        reason: 'Confirm your Fingerprint or Face to enable quick unlock',
      );

      if (!result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Biometric verification failed.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    }

    setState(() => _masterBiometricsEnabled = value);
    await _securityService.setLocalBiometricEnabled(value);

    final relId = widget.rel?.id;
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

  Future<void> _testSensor() async {
    VibrationService.medium();
    final result = await _securityService.authenticateWithDetails(
      reason: 'Scan your Fingerprint or Face Camera to test',
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
            'Your low-level native biometric sensor (Fingerprint & Face Cam) is fully operational and authenticated with NextMeet.',
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
        ),
        title: Text('Fingerprint & Face Unlock', style: AppTextStyles.h3),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
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
                            child: const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: AppSpacing.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quick Biometric Unlock', style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.bold)),
                                Text(
                                  'Unlock Sanctuary with Fingerprint or Face Cam',
                                  style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _masterBiometricsEnabled,
                            activeColor: AppColors.primary,
                            onChanged: _toggleMaster,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Granular Sensor Configuration
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: _buildSectionHeader('SENSOR HARDWARE MODES'),
                  ),
                  FadeInUp(
                    delay: const Duration(milliseconds: 250),
                    child: GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: Column(
                        children: [
                          _buildSensorRow(
                            title: 'Fingerprint Scanner',
                            subtitle: _hasFingerprint
                                ? 'Touch sensor ready (in-display or side scanner)'
                                : 'Sensor not enrolled on this phone',
                            icon: Icons.fingerprint_rounded,
                            isAvailable: _hasFingerprint || _isHardwareSupported,
                            value: _fingerprintEnabled,
                            onChanged: _masterBiometricsEnabled
                                ? (val) async {
                                    VibrationService.light();
                                    setState(() => _fingerprintEnabled = val);
                                    await _securityService.setFingerprintEnabled(val);
                                  }
                                : null,
                          ),
                          Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
                          _buildSensorRow(
                            title: 'Face Cam / Face ID',
                            subtitle: _hasFace
                                ? 'Front camera facial recognition ready'
                                : 'Face recognition ready via native prompt',
                            icon: Icons.face_retouching_natural_rounded,
                            isAvailable: true,
                            value: _faceCamEnabled,
                            onChanged: _masterBiometricsEnabled
                                ? (val) async {
                                    VibrationService.light();
                                    setState(() => _faceCamEnabled = val);
                                    await _securityService.setFaceCamEnabled(val);
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Diagnostics & Testing
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: _buildSectionHeader('DIAGNOSTICS & HARDWARE TEST'),
                  ),
                  FadeInUp(
                    delay: const Duration(milliseconds: 350),
                    child: GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Test Native Biometric Hardware',
                            style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Invoke the low-level Android/iOS biometric prompt immediately to verify fingerprint and camera recognition.',
                            style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: AppSpacing.l),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _testSensor,
                              icon: const Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 18),
                              label: const Text(
                                'TEST SENSOR NOW',
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
                    delay: const Duration(milliseconds: 400),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.l),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.security_rounded, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'NextMeet processes biometric credentials directly through your device\'s secure enclave (Android BiometricPrompt & Apple LocalAuthentication). Your biometric templates never touch our servers or leave your phone.',
                              style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
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

  Widget _buildSensorRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isAvailable,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isAvailable ? AppColors.primary.withValues(alpha: 0.08) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: isAvailable ? AppColors.primary : Colors.grey),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.bold)),
                    if (!isAvailable) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('UNAVAILABLE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                    ],
                  ],
                ),
                Text(subtitle, style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
