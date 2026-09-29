import 'package:flutter/material.dart';
import 'package:klikin/core/theme/app_colors.dart';
import 'package:klikin/core/theme/app_typography.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final bool isHighlighted;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;

  const StatusChip({
    super.key,
    required this.label,
    this.isHighlighted = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(6);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.electricEmerald.withValues(alpha: 0.15)
            : AppColors.surfaceSlate,
        borderRadius: radius,
        border: Border.all(
          color: isHighlighted ? AppColors.electricEmerald : AppColors.strokeSubtle,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.labelSm.copyWith(
          color: isHighlighted ? AppColors.electricEmerald : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
