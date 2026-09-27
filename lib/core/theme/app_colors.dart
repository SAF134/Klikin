import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Base Background & Canvas
  static const Color bgObsidian = Color(0xFF0B0E14);
  static const Color surfaceSlate = Color(0xFF151922);
  static const Color surfaceFloating = Color(0xF01C2230); // 94% Alpha
  static const Color cardBg = Color(0xFF161B26);

  // Borders & Strokes
  static const Color strokeSubtle = Color(0xFF2A3245);
  static const Color strokeFocus = Color(0xFF3D4863);

  // State & Brand Accents
  static const Color electricEmerald = Color(0xFF00E599); // Running / Primary CTA
  static const Color safetyAmber = Color(0xFFFFB020);     // Paused / Warning
  static const Color crimsonAlert = Color(0xFFFF4757);    // Stop / Error / Destructive
  static const Color cyanTarget = Color(0xFF00C2FF);      // Target Pin Default
  static const Color yellowFocus = Color(0xFFFFD600);     // Active / Dragged Pin

  // Typography
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textDark = Color(0xFF0B0E14);
}
