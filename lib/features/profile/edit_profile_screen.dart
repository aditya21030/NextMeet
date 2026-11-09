import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/flat_components.dart';
import 'app_customise_screen.dart';

/// Modernized NextMeet Profile & Names Screen
/// Focused on Mascot-Driven Identity without obsolete profile pictures
class EditProfileScreen extends StatefulWidget {
  final String relationshipId;
  final RelationshipModel relationship;
  final bool isPartner;

  const EditProfileScreen({
    super.key,
    required this.relationshipId,
    required this.relationship,
    required this.isPartner,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _nickController;
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final String currentUid = AuthService().currentUid ?? '';

    final String currentName = widget.isPartner
        ? widget.relationship.getPartnerPetName(currentUid)
        : widget.relationship.getMyRealName(currentUid);

    final String partnerNick = widget.relationship.getPartnerPetName(currentUid);

    _nameController = TextEditingController(text: currentName);
    _nickController = TextEditingController(text: partnerNick);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nickController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final String newName = _nameController.text.trim();
    final String newNick = _nickController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a display name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    VibrationService.medium();

    try {
      final String currentUid = AuthService().currentUid ?? '';
      final bool isMe1 = currentUid == widget.relationship.uid1;

      if (widget.isPartner) {
        // Updating partner's nickname
        if (isMe1) {
          await _cloudService.updateProfile(widget.relationshipId, nick1: newName);
        } else {
          await _cloudService.updateProfile(widget.relationshipId, nick2: newName);
        }
      } else {
        // Updating own name and optionally partner's nickname
        if (isMe1) {
          await _cloudService.updateProfile(
            widget.relationshipId,
            name1: newName,
            nick1: newNick.isNotEmpty ? newNick : null,
          );
        } else {
          await _cloudService.updateProfile(
            widget.relationshipId,
            name2: newName,
            nick2: newNick.isNotEmpty ? newNick : null,
          );
        }
      }

      if (mounted) {
        VibrationService.success();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully! ✨'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        VibrationService.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Modern Top Bar
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
                      widget.isPartner ? 'Partner Nickname' : 'Edit Profile & Names',
                      style: AppTextStyles.title2.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mascot Hero Card (Replacing obsolete profile picture)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.hero),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          MascotHeart(
                            color: widget.isPartner ? MascotColor.violet : MascotColor.pink,
                            size: 80,
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.pinkSoft,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              'MASCOT IDENTITY 💖',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.isPartner
                                ? "What you call your partner across NextMeet"
                                : "In NextMeet, you are represented by your intimate mascot heart instead of a public profile photo.",
                            style: AppTextStyles.caption.copyWith(color: AppColors.muted, height: 1.4),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () {
                              VibrationService.light();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AppCustomiseScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.butterSoft,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(color: AppColors.butter, width: 1.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.celebration_rounded, color: AppColors.butterText, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Customize Hats & Themes 👑',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.butterText,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Input Section: Display Name
                    _buildInputCard(
                      label: widget.isPartner ? "PARTNER'S NAME" : 'YOUR DISPLAY NAME',
                      hint: 'Enter display name',
                      controller: _nameController,
                      icon: Icons.person_rounded,
                      iconColor: AppColors.primary,
                    ),

                    if (!widget.isPartner) ...[
                      const SizedBox(height: 16),
                      // Input Section: Partner's Pet Name
                      _buildInputCard(
                        label: "PARTNER'S SWEET NICKNAME (OPTIONAL)",
                        hint: 'e.g. Honey, Bibaaa, My Love',
                        controller: _nickController,
                        icon: Icons.favorite_rounded,
                        iconColor: AppColors.partner,
                        helperText: 'This pet name will appear on your home screen and widgets.',
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Primary Save Button
                    PrimaryButton(
                      text: 'Save Changes ✨',
                      isLoading: _isLoading,
                      onPressed: _saveProfile,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.ink.withValues(alpha: 0.6),
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
              icon: Icon(icon, color: iconColor, size: 22),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              helperText,
              style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11),
            ),
          ),
        ],
      ],
    );
  }
}
