import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/vibration_service.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/theme_service.dart';
import '../../widgets/flat_components.dart';
import 'unpair_confirmation_modal.dart';

/// NextMeet Partner Details Screen
/// Strictly following NextMeet Redesign.pdf (Page 69)
class PartnerDetailsScreen extends StatelessWidget {
  final RelationshipModel relationship;
  final String relationshipId;

  const PartnerDetailsScreen({
    super.key,
    required this.relationship,
    required this.relationshipId,
  });

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUid;
    final partnerName = relationship.getPartnerName(currentUid);
    final rawCity = relationship.getPartnerLocation(currentUid);
    final partnerCity = rawCity.isNotEmpty ? rawCity : 'Location not shared yet';
    final partnerBattery = relationship.getPartnerBattery(currentUid);
    final partnerTimezone = relationship.getPartnerTimezoneOffset(currentUid);
    final inviteCode = relationship.inviteCode ?? '839201';

    final now = DateTime.now();
    final partnerTime = now.toUtc().add(Duration(minutes: partnerTimezone));
    final partnerTimeStr = DateFormat('h:mm a').format(partnerTime);
    final daysTogether = DateTime.now().difference(relationship.anniversaryDate).inDays.abs();
    final activeDist = relationship.computedDistance > 0 ? relationship.computedDistance : relationship.distanceKm;
    final distStr = activeDist > 0
        ? '${NumberFormat("#,###").format(activeDist.round())} km'
        : 'Nearby';

    return Scaffold(
      backgroundColor: ThemeService.instance.backgroundColor,
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
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: AppColors.ink),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Partner Details',
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

              // Partner Hero Mascot Card (Page 69)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.partnerSoft,
                  borderRadius: BorderRadius.circular(AppRadius.hero),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    MascotHeart(
                      color: ThemeService.instance.partnerMascotColor,
                      size: 80,
                      accessory: ThemeService.instance.partnerMascotAccessory,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      partnerName,
                      style: AppTextStyles.title1.copyWith(
                        fontSize: 24,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.mint,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Online now • $partnerCity',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.partnerText,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Battery & Timezone Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.border, width: 1.0),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.battery_charging_full_rounded,
                                color: AppColors.mintText, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '$partnerBattery%',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                                width: 1, height: 16, color: AppColors.border),
                            const SizedBox(width: 14),
                            const Icon(Icons.access_time_rounded,
                                color: AppColors.partner, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              partnerTimeStr,
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Shared Stats Row
              Row(
                children: [
                  Expanded(
                    child: MetricTile(
                      label: 'Together',
                      value: '$daysTogether d',
                      icon: Icons.favorite_rounded,
                      iconColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricTile(
                      label: 'Streak',
                      value: '${relationship.streakCount} days',
                      icon: Icons.local_fire_department_rounded,
                      iconColor: AppColors.coral,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricTile(
                      label: 'Distance',
                      value: distStr,
                      icon: Icons.airplanemode_active_rounded,
                      iconColor: AppColors.partner,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Invite Code Card (Page 69)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Couple invite code', style: AppTextStyles.caption),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            inviteCode,
                            style: AppTextStyles.display.copyWith(
                              fontSize: 26,
                              letterSpacing: 3.0,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                VibrationService.success();
                                Clipboard.setData(
                                    ClipboardData(text: inviteCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Code copied to clipboard! 📋✨'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.pinkSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.copy_rounded,
                                    color: AppColors.primary, size: 18),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                VibrationService.light();
                                Share.share(
                                  'Join me on NextMeet! Our couple pairing code is $inviteCode ❤️',
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.partnerSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.share_outlined,
                                    color: AppColors.partner, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Danger Zone: Unpair Button (Page 69 & 70)
              GestureDetector(
                onTap: () {
                  UnpairConfirmationModal.show(
                    context,
                    partnerName: partnerName,
                    relationshipId: relationshipId,
                  );
                },
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.danger, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.heart_broken_rounded,
                          color: AppColors.danger, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Unpair from $partnerName',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.danger,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
