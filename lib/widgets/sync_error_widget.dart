import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'primary_button.dart';

class SyncErrorWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final bool showLogout;
  final VoidCallback? onLogout;

  const SyncErrorWidget({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    this.showLogout = false,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sync_problem_rounded,
                size: 64,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sync issue detected',
              style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'RETRY SYNC ✨',
              onPressed: onRetry,
            ),
            if (showLogout) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onLogout,
                child: Text(
                  'Sign Out & Reset Account',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
