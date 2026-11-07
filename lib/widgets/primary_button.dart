import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/services/vibration_service.dart';

enum ButtonVariant { primary, soft, dark, secondary, outline }

class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isSecondary;
  final ButtonVariant variant;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final double height;
  final double? width;
  final double borderRadius;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.color,
    this.textColor,
    this.height = 54,
    this.width,
    this.borderRadius = AppRadius.pill,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveVariant = widget.isSecondary ? ButtonVariant.secondary : widget.variant;

    Color backgroundColor;
    Color foregroundColor;
    Border? border;

    switch (effectiveVariant) {
      case ButtonVariant.primary:
        backgroundColor = widget.color ?? (_isPressed ? AppColors.primaryDark : AppColors.primary);
        foregroundColor = widget.textColor ?? Colors.white;
        border = null;
        break;
      case ButtonVariant.soft:
        backgroundColor = widget.color ?? AppColors.pinkSoft;
        foregroundColor = widget.textColor ?? AppColors.primary;
        border = null;
        break;
      case ButtonVariant.dark:
        backgroundColor = widget.color ?? AppColors.ink;
        foregroundColor = widget.textColor ?? Colors.white;
        border = null;
        break;
      case ButtonVariant.secondary:
      case ButtonVariant.outline:
        backgroundColor = widget.color ?? Colors.white;
        foregroundColor = widget.textColor ?? AppColors.ink;
        border = Border.all(color: AppColors.border, width: 1.5);
        break;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        if (!widget.isLoading) {
          VibrationService.light();
          widget.onPressed();
        }
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: backgroundColor,
            border: border,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: foregroundColor,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: widget.width != null ? MainAxisSize.min : MainAxisSize.max,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 20, color: foregroundColor),
                        const SizedBox(width: AppSpacing.s),
                      ],
                      Text(
                        widget.text,
                        style: AppTextStyles.button.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: foregroundColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
