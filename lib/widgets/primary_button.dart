import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/services/vibration_service.dart';

class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;
  final Color? color;
  final Color? textColor;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
    this.color,
    this.textColor,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
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
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.m),
            gradient: (widget.isSecondary || widget.color != null) ? null : AppColors.primaryGradient,
            color: widget.color ?? (widget.isSecondary ? Colors.white : null),
            boxShadow: _isPressed 
              ? [const BoxShadow(color: Color(0x33FF5E7D), blurRadius: 10, offset: Offset(0, 4))]
              : (widget.isSecondary ? AppColors.softShadow : AppColors.buttonShadow),
            border: widget.isSecondary ? Border.all(color: AppColors.divider, width: 1.5) : null,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 20, color: widget.isSecondary ? AppColors.primary : Colors.white),
                        const SizedBox(width: AppSpacing.s),
                      ],
                      Text(
                        widget.text,
                        style: AppTextStyles.button.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: widget.textColor ?? (widget.isSecondary ? AppColors.primary : Colors.white),
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
