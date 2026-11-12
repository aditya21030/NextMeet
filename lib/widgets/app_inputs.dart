import 'package:flutter/material.dart';
import '../core/constants.dart';

class AppInputs {
  static InputDecoration premiumInput(
    String label, {
    IconData? icon,
    String? hint,
    Widget? suffixIcon,
    Color? fillColor,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: AppColors.muted, size: 20) : null,
      suffixIcon: suffixIcon,
      labelStyle: AppTextStyles.body.copyWith(
        color: AppColors.muted,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: AppTextStyles.caption.copyWith(
        color: AppColors.muted.withValues(alpha: 0.85),
      ),
      filled: true,
      fillColor: fillColor ?? AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.danger, width: 2.0),
      ),
    );
  }

  static BoxDecoration premiumInputDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadius.input),
  );
}
