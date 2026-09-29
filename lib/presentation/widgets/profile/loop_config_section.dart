import 'package:flutter/material.dart';
import 'package:klikin/core/theme/app_colors.dart';
import 'package:klikin/core/theme/app_typography.dart';
import 'package:klikin/domain/entities/loop_config.dart';

class LoopConfigSection extends StatelessWidget {
  final LoopType loopType;
  final int loopCount;
  final ValueChanged<LoopType> onLoopTypeChanged;
  final ValueChanged<int> onLoopCountChanged;

  const LoopConfigSection({
    super.key,
    required this.loopType,
    required this.loopCount,
    required this.onLoopTypeChanged,
    required this.onLoopCountChanged,
  });

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceSlate : AppColors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.electricEmerald : AppColors.strokeSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.bodyMd.copyWith(
              color: isSelected ? AppColors.electricEmerald : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PENGATURAN SIKLUS (LOOP)', style: AppTypography.labelSm),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildChoiceChip(
                label: 'Tak Terbatas',
                isSelected: loopType == LoopType.infinite,
                onTap: () => onLoopTypeChanged(LoopType.infinite),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildChoiceChip(
                label: 'Berdasarkan Hitungan',
                isSelected: loopType == LoopType.finiteCount,
                onTap: () => onLoopTypeChanged(LoopType.finiteCount),
              ),
            ),
          ],
        ),
        if (loopType == LoopType.finiteCount) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.strokeSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Jumlah Siklus:', style: AppTypography.bodyMd),
                Row(
                  children: [
                    IconButton(
                      onPressed: loopCount > 100
                          ? () => onLoopCountChanged(loopCount - 100)
                          : null,
                      icon: const Icon(Icons.remove, size: 18),
                    ),
                    Text('$loopCount x', style: AppTypography.dataLg.copyWith(fontSize: 16)),
                    IconButton(
                      onPressed: () => onLoopCountChanged(loopCount + 100),
                      icon: const Icon(Icons.add, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
