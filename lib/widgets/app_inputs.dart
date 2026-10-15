import 'package:flutter/material.dart';
import '../core/constants.dart';

class AppInputs {
  static InputDecoration premiumInput(String label, {IconData? icon, String? hint}) {
    return InputDecoration(
      hintText: hint ?? label,
      prefixIcon: icon != null ? Icon(icon, color: AppColors.primary.withValues(alpha: 0.8), size: 20) : null,
      labelStyle: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
      hintStyle: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.35)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.never,
    );
  }

  static BoxDecoration premiumInputDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadius.m),
    boxShadow: AppColors.inputShadow,
  );
}
