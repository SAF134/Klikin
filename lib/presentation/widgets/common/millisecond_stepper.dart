import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:klikin/core/theme/app_colors.dart';
import 'package:klikin/core/theme/app_typography.dart';

class MillisecondStepper extends StatelessWidget {
  final String label;
  final int valueMs;
  final int minMs;
  final int maxMs;
  final int stepMs;
  final ValueChanged<int> onChanged;

  const MillisecondStepper({
    super.key,
    required this.label,
    required this.valueMs,
    this.minMs = 25, // Batas minimal 25ms sesuai Golden Rules
    this.maxMs = 60000,
    this.stepMs = 50,
    required this.onChanged,
  });

  void _increment() {
    HapticFeedback.selectionClick();
    final next = (valueMs + stepMs).clamp(minMs, maxMs);
    onChanged(next);
  }

  void _decrement() {
    HapticFeedback.selectionClick();
    final prev = (valueMs - stepMs).clamp(minMs, maxMs);
    onChanged(prev);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
            ),
            Text(
              '$valueMs ms',
              style: AppTypography.dataLg.copyWith(color: AppColors.electricEmerald),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Decrement Button
            IconButton.filled(
              onPressed: valueMs > minMs ? _decrement : null,
              icon: const Icon(Icons.remove, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceSlate,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.strokeSubtle),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Quick-select chips
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [50, 100, 250, 500, 1000].map((preset) {
                    final isSelected = valueMs == preset;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text('$preset ms'),
                        labelStyle: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.textDark : AppColors.textSecondary,
                        ),
                        selectedColor: AppColors.electricEmerald,
                        backgroundColor: AppColors.surfaceSlate,
                        side: BorderSide(
                          color: isSelected ? AppColors.electricEmerald : AppColors.strokeSubtle,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          onChanged(preset);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Increment Button
            IconButton.filled(
              onPressed: valueMs < maxMs ? _increment : null,
              icon: const Icon(Icons.add, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceSlate,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.strokeSubtle),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
