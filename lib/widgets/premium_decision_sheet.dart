import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/constants.dart';
import '../core/services/vibration_service.dart';

class PremiumDecisionSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionText;
  final Color actionColor;
  final IconData? icon;
  final VoidCallback onAction;

  const PremiumDecisionSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onAction,
    this.actionColor = AppColors.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Glassy Backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.black.withValues(alpha: 0.1)),
              ),
            ),
          ),
          
          // Sheet Content
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, -10)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: actionColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: actionColor, size: 32),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  Text(
                    title,
                    style: AppTextStyles.h2.copyWith(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  
                  // Action Button
                  GestureDetector(
                    onTap: () {
                      VibrationService.medium();
                      onAction();
                    },
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        color: actionColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: actionColor.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          actionText,
                          style: AppTextStyles.button.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Cancel Button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: Text(
                      'NOT NOW',
                      style: AppTextStyles.bodyM.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper to show the sheet
Future<T?> showPremiumDecisionSheet<T>({
  required BuildContext context,
  required String title,
  required String subtitle,
  required String actionText,
  required VoidCallback onAction,
  Color actionColor = AppColors.primary,
  IconData? icon,
}) {
  VibrationService.medium();
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => PremiumDecisionSheet(
      title: title,
      subtitle: subtitle,
      actionText: actionText,
      onAction: onAction,
      actionColor: actionColor,
      icon: icon,
    ),
  );
}
