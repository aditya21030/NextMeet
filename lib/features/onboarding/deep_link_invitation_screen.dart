import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import '../auth/create_account_screen.dart';
import '../auth/login_screen.dart';

/// Deep Link Invitation Screen (Partner Invited Flow)
/// Strictly following NextMeet Redesign.pdf (Page 10)
class DeepLinkInvitationScreen extends StatelessWidget {
  final String inviterName;
  final String inviteCode;

  const DeepLinkInvitationScreen({
    super.key,
    required this.inviterName,
    required this.inviteCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // Full pink canvas top
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Top Envelope & Smiling Mascot (Page 10)
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 200,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 24),
                          ),
                        ],
                      ),
                    ),
                    const Positioned(
                      top: -50,
                      child: MascotHeart(
                        color: MascotColor.pink,
                        size: 96,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Bottom White Sheet
            Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Private invitation badge
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.pinkSoft,
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                      ),
                      child: Text(
                        'Private invitation',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    '$inviterName invited you\nto NextMeet',
                    style: AppTextStyles.display.copyWith(fontSize: 28, height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A private space for just the two of you. Create an account to join.',
                    style: AppTextStyles.body.copyWith(color: AppColors.muted),
                  ),

                  const SizedBox(height: 24),

                  // Invite code applied card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: AppColors.mintSoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, color: AppColors.mintText, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invite code applied',
                              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              inviteCode,
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 18,
                                letterSpacing: 2,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  PrimaryButton(
                    text: 'Join $inviterName',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateAccountScreen(
                            initialInviteCode: inviteCode,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(
                              initialInviteCode: inviteCode,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'I already have an account',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
