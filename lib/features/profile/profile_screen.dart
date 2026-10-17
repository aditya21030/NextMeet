import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/relationship_model.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/primary_button.dart';
import 'package:share_plus/share_plus.dart';
import '../private_space/lock_screen.dart';
import 'terms_policy_screen.dart';
import '../auth/login_screen.dart';
import '../onboarding/setup_couple_screen.dart';
import 'package:intl/intl.dart';
import 'nextmeet_plus_screen.dart';
import 'haptic_preferences_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final AuthService _authService = AuthService();

  bool _notificationsEnabled = true;


  void _handleLogout() {
    VibrationService.medium();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('Logout Session?', style: AppTextStyles.h3),
        content: const Text('Are you sure you want to log out from this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              VibrationService.success();
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
            ),
            child: const Text('LOGOUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  int _calculateTogetherDays(DateTime? createdAt) {
    if (createdAt == null) return 0;
    return DateTime.now().difference(createdAt).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data?.id == null) {
          return _buildUnpairedProfile(context);
        }

        final rel = snapshot.data!;
        final relId = rel.id!;
        final currentUid = _authService.currentUid;
        final bool isMe1 = currentUid == rel.uid1;
        
        final myName = rel.getMyRealName(currentUid);
        final partnerName = rel.getDisplayPartnerName(currentUid);
        final myLoc = isMe1 ? (rel.userLocation1 ?? '') : (rel.userLocation2 ?? '');
        final partnerLoc = rel.getPartnerLocation(currentUid);
        final myPhoto = rel.getMyPhoto(currentUid);
        final partnerPhoto = rel.getPartnerPhoto(currentUid);
        final partnerUid = rel.getPartnerUid(currentUid);
        final togetherDays = _calculateTogetherDays(rel.createdAt);

        // Map preferences from RelationshipModel
        // Assume notifications enabled for now as we don't have a specific field, but let's just use local for now or add a field if needed.
        // For simplicity, let's just stick to syncing biometrics which we have a field for.

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Text('Profile', style: AppTextStyles.h3),
            centerTitle: true,
          ),
          body: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.background,
                  AppColors.background,
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
              child: Column(
                children: [
                  // Profile Avatars
                  FadeInDown(
                    child: Center(
                      child: Hero(
                        tag: 'profile_avatars',
                        child: SizedBox(
                          width: 130,
                          height: 90,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: rel.isPlus ? [
                                      BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2),
                                      ...AppColors.premiumShadow,
                                    ] : AppColors.premiumShadow,
                                    border: Border.all(
                                      color: rel.isPlus ? const Color(0xFF6366F1) : Colors.white, 
                                      width: rel.isPlus ? 3 : 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 40,
                                    backgroundColor: Colors.white,
                                    backgroundImage: myPhoto.isNotEmpty 
                                        ? CachedNetworkImageProvider(myPhoto)
                                        : NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=$currentUid') as ImageProvider,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: rel.isPlus ? [
                                      BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2),
                                      ...AppColors.premiumShadow,
                                    ] : AppColors.premiumShadow,
                                    border: Border.all(
                                      color: rel.isPlus ? const Color(0xFF6366F1) : Colors.white, 
                                      width: rel.isPlus ? 3 : 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 40,
                                    backgroundColor: Colors.white,
                                    backgroundImage: partnerPhoto.isNotEmpty 
                                        ? CachedNetworkImageProvider(partnerPhoto)
                                        : NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=$partnerUid') as ImageProvider,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient: rel.isPlus ? AppColors.accentGradient : AppColors.primaryGradient,
                                      shape: BoxShape.circle,
                                      boxShadow: AppColors.buttonShadow,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: Icon(
                                      rel.isPlus ? Icons.auto_awesome_rounded : Icons.favorite_rounded, 
                                      color: Colors.white, 
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                '$myName ❤️ $partnerName', 
                                style: AppTextStyles.h2,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildBadge('Together $togetherDays Days ❤️'),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Connected in NextMeet 🌍', 
                              style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // PRIVATE SPACE OVAL BADGE
                        GestureDetector(
                          onTap: () {
                            VibrationService.medium();
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivateSpaceLockScreen()));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.m),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                              border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shield_rounded, color: Colors.pinkAccent, size: 14),
                                const SizedBox(width: 8),
                                Text(
                                  'PRIVATE SPACE', 
                                  style: TextStyle(
                                    color: Colors.pinkAccent, 
                                    fontSize: 10, 
                                    fontWeight: FontWeight.w900, 
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.pinkAccent, size: 10),
                              ],
                            ),
                          ),
                        ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                  // INVITE PARTNER SECTION (ONLY FOR SOLO USERS)
                  if (rel.uid2 == null) ...[
                    FadeInUp(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.l),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          boxShadow: AppColors.softShadow,
                          border: Border.all(color: const Color(0x1AFF5E7D)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                                  child: const Icon(Icons.share_rounded, color: AppColors.primary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Text('REMAINING CONNECTION', style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w900)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Waiting for $partnerName',
                              style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Share your magic code to sync hearts',
                              style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(AppRadius.m),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Text(
                                rel.inviteCode ?? 'CODE_NOT_FOUND',
                                style: AppTextStyles.h2.copyWith(letterSpacing: 4, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(height: 20),
                            PrimaryButton(
                              text: 'Share Invite Link ✨',
                              onPressed: () {
                                VibrationService.medium();
                                Share.share(
                                  'Hey! Join me on NextMeet ❤️ Use my invite code: ${rel.inviteCode}\n\nDownload App: [Your App Link Here]',
                                  subject: 'Connect our hearts on NextMeet ✨',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  
                  // Couple Info Section
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: Column(
                      children: [
                        _buildSectionHeader('COUPLE INFO'),
                        GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.l),
                          child: Column(
                            children: [
                                _buildProfileRow(myName, (myLoc.isEmpty) ? 'Set Location' : myLoc, Icons.person_rounded, true, () {
                                  VibrationService.medium();
                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(
                                      builder: (context) => EditProfileScreen(
                                        relationshipId: relId, 
                                        relationship: rel, 
                                        isPartner: false, // Always false for 'Me' row
                                      ),
                                    ),
                                  );
                                }),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(height: 1, thickness: 0.5),
                                ),
                                _buildProfileRow(partnerName, partnerLoc.isEmpty ? 'Not Provided' : partnerLoc, Icons.favorite_rounded, true, () {
                                  VibrationService.medium();
                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(
                                      builder: (context) => EditProfileScreen(
                                        relationshipId: relId, 
                                        relationship: rel, 
                                        isPartner: true, // Edit partner pet nickname
                                      ),
                                    ),
                                  );
                                }),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Divider(height: 1, thickness: 0.5),
                              ),
                              
                              // Relocated Couple Info Button
                              OutlinedButton(
                                onPressed: () => _showCoupleInfoDialog(rel),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 18),
                                    const SizedBox(width: 8),
                                    Text('COUPLE INFO & MILESTONES ✨', style: AppTextStyles.button.copyWith(color: AppColors.primary, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  // NEXTMEET+ ENTRY (Converted from Private Space)
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: GestureDetector(
                      onTap: () {
                        VibrationService.medium();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => NextMeetPlusScreen(relId: relId)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
                        decoration: BoxDecoration(
                          gradient: rel.isPlus ? AppColors.accentGradient : AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(AppRadius.l),
                          boxShadow: AppColors.buttonShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                              child: Icon(rel.isPlus ? Icons.stars_rounded : Icons.workspace_premium_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: AppSpacing.m),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'NextMeet', 
                                          style: AppTextStyles.bodyL.copyWith(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                                        ),
                                        TextSpan(
                                          text: '+', 
                                          style: AppTextStyles.bodyL.copyWith(color: const Color(0xFFFF5E7D), fontWeight: FontWeight.w900, fontSize: 18),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    rel.isPlus ? 'Manage your premium experience' : 'Unlock the ultimate digital sanctuary', 
                                    style: AppTextStyles.bodyS.copyWith(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppRadius.circle),
                              ),
                              child: Text(
                                rel.isPlus ? 'MANAGE' : 'UPGRADE', 
                                style: AppTextStyles.bodyS.copyWith(
                                  color: rel.isPlus ? const Color(0xFF6366F1) : AppColors.primary, 
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xxl),

                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: RepaintBoundary(
                      child: Column(
                        children: [
                          _buildSectionHeader('PREFERENCES'),
                          GlassCard(
                            padding: const EdgeInsets.all(AppSpacing.m),
                            child: Column(
                              children: [
                                _buildPreferenceToggle('Notifications', Icons.notifications_active_rounded, Colors.blue, _notificationsEnabled, (val) {
                                  VibrationService.light();
                                  setState(() => _notificationsEnabled = val);
                                  _cloudService.updateRelationshipDetails(relId, {'notificationsEnabled': val});
                                }),
                                if (rel.isPlus) ...[
                                  const Divider(height: 16, thickness: 0.5),
                                  _buildPreferenceRow(
                                    'Elite Signature ❤️', 
                                    Icons.vibration_rounded, 
                                    AppColors.primary,
                                    () {
                                      VibrationService.medium();
                                      Navigator.push(
                                        context, 
                                        MaterialPageRoute(builder: (context) => HapticPreferencesScreen(rel: rel))
                                      );
                                    }
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  


                  
                  // Legal Section
                  FadeInUp(
                    delay: const Duration(milliseconds: 450),
                    child: Column(
                      children: [
                        _buildSectionHeader('LEGAL & ABOUT'),
                        GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.m),
                          child: Column(
                            children: [
                              _buildPreferenceRow(
                                'Help & Support', 
                                Icons.help_outline_rounded, 
                                Colors.purple,
                                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen())),
                              ),
                              const Divider(height: 16, thickness: 0.5),
                              _buildPreferenceRow(
                                'Terms of Service', 
                                Icons.description_rounded, 
                                Colors.amber,
                                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsPolicyScreen(
                                  title: 'Terms of Service',
                                  content: 'Welcome to NextMeet. By using this application, you agree to our terms. NextMeet provides a shared digital sanctuary for couples to enhance their connection through shared memories, synchronized planning, and secure private communication.\n\n1. TERMS OF USE\nBy accessing NextMeet, you agree to use the service for personal, non-commercial purposes only. You are responsible for all content shared within your relationship space.\n\n2. ACCOUNT SECURITY\nYou are responsible for maintaining the confidentiality of your account credentials. All activities under your account are your responsibility.\n\n3. SERVICE LIMITATIONS\nWhile we strive for 100% uptime, NextMeet is provided "as is". We reserve the right to modify or discontinue features to improve the user experience.',
                                ))),
                              ),
                              const Divider(height: 16, thickness: 0.5),
                              _buildPreferenceRow(
                                'Privacy Policy', 
                                Icons.privacy_tip_rounded, 
                                Colors.teal,
                                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsPolicyScreen(
                                  title: 'Privacy Policy',
                                  content: 'Your privacy is our utmost priority at NextMeet. This policy outlines how we handle your data.\n\n1. DATA COLLECTION\nWe collect minimal information required for synchronization, including your names, moods, and shared trip details. This data is used solely to provide "couple-sync" features.\n\n2. PRIVATE SPACE ENCRYPTION\nContent shared in your "Private Space" is intended ONLY for you and your partner. We implement industry-standard security to protect your shared sanctuary.\n\n3. THIRD-PARTY DISCLOSURE\nNextMeet does NOT sell, trade, or otherwise transfer your personal information to outside parties. Your data belongs to your relationship.',
                                ))),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: PrimaryButton(
                      text: 'Log Out Session',
                      onPressed: _handleLogout,
                      color: Colors.white,
                      textColor: Colors.redAccent.shade100,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    delay: const Duration(milliseconds: 550),
                    child: Text(
                      'Partner since ${DateFormat('dd MMMM yyyy').format(rel.createdAt ?? rel.anniversaryDate)} ❤️',
                      style: AppTextStyles.bodyS.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Text(
        text, 
        style: const TextStyle(
          color: AppColors.primary, 
          fontSize: 10, 
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.m),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 1.5, 
            color: AppColors.textSecondary.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow(String name, String location, IconData icon, bool canEdit, VoidCallback onTap) {
    return InkWell(
      onTap: canEdit ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.m),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name, 
                    style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location, 
                    style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (canEdit) const Icon(Icons.edit_note_rounded, color: AppColors.divider, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceToggle(String title, IconData icon, Color color, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Text(
              title, 
              style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceRow(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        VibrationService.light();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Text(
                title, 
                style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.divider.withValues(alpha: 0.8)),
          ],
        ),
      ),
    );
  }
  Future<void> _showCoupleInfoDialog(RelationshipModel data) async {
    VibrationService.light();
    final String currentUid = _cloudService.currentUid ?? '';
    final bool isUser1 = currentUid == data.uid1;
    
    final myNicknameForPartnerController = TextEditingController(
      text: isUser1 ? data.user1PartnerNickname : data.user2PartnerNickname
    );
    
    final partnersNicknameForMe = isUser1 ? (data.user2PartnerNickname ?? 'No nickname yet') : (data.user1PartnerNickname ?? 'No nickname yet');

    DateTime selectedAnniversary = data.anniversaryDate;
    DateTime selectedNextMeeting = data.nextMeetingDate;
    DateTime selectedLastMeeting = data.lastMeetingDate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Couple Info ✨', style: AppTextStyles.h1.copyWith(fontSize: 28)),
                      const SizedBox(height: AppSpacing.m),
                      Text(
                        'Customize your shared journey and milestones.',
                        style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      
                      _buildDialogSectionTitle('PET NAMES'),
                      const SizedBox(height: AppSpacing.m),
                      TextField(
                        controller: myNicknameForPartnerController,
                        decoration: InputDecoration(
                          hintText: 'e.g. My Love, Sweetie',
                          prefixIcon: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 20),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5))),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.favorite_border_rounded, color: AppColors.textSecondary, size: 20),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('What my partner calls me', style: AppTextStyles.bodyS.copyWith(fontSize: 10, color: AppColors.textSecondary)),
                                Text(partnersNicknameForMe, style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      _buildDialogSectionTitle('MILESTONES'),
                      const SizedBox(height: AppSpacing.m),
                      _buildDateSelector(
                        label: 'Anniversary', 
                        date: selectedAnniversary, 
                        icon: Icons.auto_awesome_rounded,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context, 
                            initialDate: selectedAnniversary, 
                            firstDate: DateTime(1900), 
                            lastDate: DateTime.now(),
                          );
                          if (date != null) setModalState(() => selectedAnniversary = date);
                        },
                      ),
                      const SizedBox(height: AppSpacing.m),
                      _buildDateSelector(
                        label: 'Next Meetup', 
                        date: selectedNextMeeting, 
                        icon: Icons.flight_takeoff_rounded,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context, 
                            initialDate: selectedNextMeeting, 
                            firstDate: DateTime.now(), 
                            lastDate: DateTime.now().add(const Duration(days: 1000)),
                          );
                          if (date != null) setModalState(() => selectedNextMeeting = date);
                        },
                      ),
                      const SizedBox(height: AppSpacing.m),
                      _buildDateSelector(
                        label: 'Last Meeting Date',
                        date: selectedLastMeeting,
                        icon: Icons.history_toggle_off_rounded,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context, 
                            initialDate: selectedLastMeeting, 
                            firstDate: DateTime(2000), 
                            lastDate: DateTime.now(),
                          );
                          if (date != null) setModalState(() => selectedLastMeeting = date);
                        },
                      ),
                      
                      const SizedBox(height: AppSpacing.xxl),
                      PrimaryButton(
                        text: 'Save Couple Info',
                        onPressed: () async {
                          final updates = <String, dynamic>{
                            'anniversaryDate': selectedAnniversary,
                            'nextMeetingDate': selectedNextMeeting,
                            'lastMeetingDate': selectedLastMeeting,
                          };

                          if (isUser1) {
                            updates['user1PartnerNickname'] = myNicknameForPartnerController.text;
                          } else {
                            updates['user2PartnerNickname'] = myNicknameForPartnerController.text;
                          }

                          await _cloudService.updateRelationshipDetails(data.id!, updates);
                          if (mounted) Navigator.pop(context);
                          VibrationService.success();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    myNicknameForPartnerController.dispose();
  }

  Widget _buildDialogSectionTitle(String title) {
    return Text(title, style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1.2));
  }

  Widget _buildDateSelector({required String label, required DateTime date, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodyS.copyWith(fontSize: 10, color: AppColors.textSecondary)),
                Text(
                  "${date.day} ${_getMonthName(date.month)} ${date.year}", 
                  style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.bold)
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.divider),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildUnpairedProfile(BuildContext context) {
    final user = _authService.currentUser;
    final displayName = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!
        : 'NextMeet User';
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Profile', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.background,
              AppColors.background,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
          child: Column(
            children: [
              const SizedBox(height: 12),
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.person_rounded, size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(displayName, style: AppTextStyles.h2),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(email, style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
              ],
              const SizedBox(height: 8),
              _buildBadge('Not Paired'),
              const SizedBox(height: AppSpacing.xl),

              // Connect card
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(height: 12),
                    const Text('Connect With Partner', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(
                      'Pair with your partner to share live distance, memories, countdowns, and your private sanctuary.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      text: 'Connect Now',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SetupCoupleScreen()));
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // PREFERENCES
              _buildSectionHeader('PREFERENCES'),
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  children: [
                    _buildPreferenceToggle('Notifications', Icons.notifications_active_rounded, Colors.blue, _notificationsEnabled, (val) {
                      VibrationService.light();
                      setState(() => _notificationsEnabled = val);
                    }),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // LEGAL & ABOUT
              _buildSectionHeader('LEGAL & ABOUT'),
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  children: [
                    _buildPreferenceRow(
                      'Help & Support', 
                      Icons.help_outline_rounded, 
                      Colors.purple,
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen())),
                    ),
                    const Divider(height: 16, thickness: 0.5),
                    _buildPreferenceRow(
                      'Terms of Service', 
                      Icons.description_rounded, 
                      Colors.amber,
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsPolicyScreen(
                        title: 'Terms of Service',
                        content: 'Welcome to NextMeet. By using this application, you agree to our terms.',
                      ))),
                    ),
                    const Divider(height: 16, thickness: 0.5),
                    _buildPreferenceRow(
                      'Privacy Policy', 
                      Icons.privacy_tip_rounded, 
                      Colors.teal,
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsPolicyScreen(
                        title: 'Privacy Policy',
                        content: 'Your privacy is our utmost priority at NextMeet.',
                      ))),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              PrimaryButton(
                text: 'Log Out Session',
                onPressed: _handleLogout,
                color: Colors.white,
                textColor: Colors.redAccent.shade100,
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
