import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';
import '../../widgets/glass_card.dart';

class PrivateSpaceSettingsScreen extends StatefulWidget {
  const PrivateSpaceSettingsScreen({super.key});

  @override
  State<PrivateSpaceSettingsScreen> createState() => _PrivateSpaceSettingsScreenState();
}

class _PrivateSpaceSettingsScreenState extends State<PrivateSpaceSettingsScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  void _handleChangePin(String relId, RelationshipModel rel) {
    VibrationService.medium();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text('Change Private PIN?'),
        content: const Text('This will clear the current PIN for both of you. You will be redirected to the lock screen to set a new 4-digit code. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cloudService.updatePrivateSpacePin(relId, null);
              await _cloudService.cancelPinReset(relId); // clear any pending reset state
              VibrationService.success();
              if (mounted) {
                // Pop back out the whole way to the main app, so next time they open private space they must set a PIN.
                Navigator.of(context).popUntil((route) => route.isFirst);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Private PIN cleared! Please set a new one. ✨')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('CLEAR & CHANGE PIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Auto-lock Timeout', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.l),
            ...options.map((opt) => ListTile(
              title: Text(opt, style: AppTextStyles.bodyM.copyWith(
                fontWeight: opt == current ? FontWeight.bold : FontWeight.normal,
                color: opt == current ? AppColors.primary : AppColors.textPrimary,
              )),
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
            title: Text('Private Space Settings', style: AppTextStyles.h3),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInUp(child: _buildSectionHeader('SECURITY')),
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      children: [
                        _buildSettingRow(
                          'Change PIN',
                          rel.pinResetRequestBy != null ? 'Verification in progress...' : 'Update your security code',
                          Icons.pin_rounded,
                          trailing: rel.pinResetRequestBy != null 
                            ? const Icon(Icons.mark_email_unread_rounded, color: Colors.orange, size: 20)
                            : null,
                          onTap: () => _handleChangePin(relId, rel),
                        ),
                        Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
                        _buildSettingRow(
                          'Screen Timeout',
                          'Locks when app is inactive',
                          Icons.timer_rounded,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                            child: Text(rel.privateSpaceTimeout, style: AppTextStyles.bodyS.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ),
                          onTap: () => _showTimeoutPicker(relId, rel.privateSpaceTimeout),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: _buildSectionHeader('CONTENT MANAGEMENT'),
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
                                  Text('Secret Photos Storage', style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.bold)),
                                  Text('${(rel.privateSpaceStorageBytes / (1024 * 1024)).toStringAsFixed(1)} MB of ${limitMb.toInt()} MB used', style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
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
                          Text(
                            'Clear Private Space Data',
                            style: AppTextStyles.bodyM.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'NextMeet Private Space v1.0.38',
                        style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your privacy is our priority',
                        style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      }
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
  void _showClearDataDialog(String relId) {
    VibrationService.medium();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text('Clear All Data?'),
        content: const Text('This will permanently delete ALL your secret photos, love letters, and private notes from both this device and Firebase Storage. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
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
            child: const Text('CLEAR DATA', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
