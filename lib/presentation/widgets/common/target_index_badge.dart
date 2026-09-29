import 'package:flutter/material.dart';
import 'package:klikin/core/theme/app_colors.dart';

class TargetIndexBadge extends StatelessWidget {
  final int index;
  final double radius;
  final double fontSize;

  const TargetIndexBadge({
    super.key,
    required this.index,
    this.radius = 11,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.cyanTarget,
      child: Text(
        '$index',
        style: TextStyle(
          color: Colors.black,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
