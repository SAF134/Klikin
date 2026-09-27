import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:klikin/core/theme/app_colors.dart';

enum PillButtonVariant { primary, secondary, destructive }

class PillButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final PillButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  const PillButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = PillButtonVariant.primary,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case PillButtonVariant.primary:
        bg = onPressed == null
            ? AppColors.surfaceSlate
            : AppColors.electricEmerald;
        textColor = onPressed == null ? AppColors.textTertiary : AppColors.textDark;
        break;
      case PillButtonVariant.secondary:
        bg = AppColors.surfaceSlate;
        textColor = AppColors.textPrimary;
        border = const BorderSide(color: AppColors.strokeSubtle, width: 1);
        break;
      case PillButtonVariant.destructive:
        bg = AppColors.crimsonAlert.withValues(alpha: 0.15);
        textColor = AppColors.crimsonAlert;
        border = BorderSide(color: AppColors.crimsonAlert.withValues(alpha: 0.4), width: 1);
        break;
    }

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed == null || isLoading
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed!();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textDark),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: textColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
