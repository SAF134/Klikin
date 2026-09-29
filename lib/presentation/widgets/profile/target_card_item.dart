import 'package:flutter/material.dart';
import 'package:klikin/core/theme/app_colors.dart';
import 'package:klikin/core/theme/app_typography.dart';
import 'package:klikin/domain/entities/target_point.dart';
import 'package:klikin/presentation/widgets/common/millisecond_stepper.dart';
import 'package:klikin/presentation/widgets/common/target_index_badge.dart';

class TargetCardItem extends StatelessWidget {
  final TargetPoint target;
  final bool canRemove;
  final VoidCallback? onRemove;
  final ValueChanged<int> onDelayChanged;
  final ValueChanged<int> onPressDurationChanged;

  const TargetCardItem({
    super.key,
    required this.target,
    required this.canRemove,
    this.onRemove,
    required this.onDelayChanged,
    required this.onPressDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.strokeSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  TargetIndexBadge(index: target.index, radius: 13, fontSize: 12),
                  const SizedBox(width: 10),
                  Text(
                    'Titik ${target.index}',
                    style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (canRemove)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.crimsonAlert),
                  tooltip: 'Hapus Titik',
                  onPressed: onRemove,
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Setting 1: Jeda Antar Ketukan (Delay)
          MillisecondStepper(
            label: 'Jeda Setelah Titik ${target.index} (Delay)',
            valueMs: target.delayAfterMs,
            minMs: 25,
            stepMs: 50,
            onChanged: onDelayChanged,
          ),
          const Divider(color: AppColors.strokeSubtle, height: 24),
          // Setting 2: Durasi Lama Tekan (Press Duration)
          MillisecondStepper(
            label: 'Lama Tekan Titik ${target.index} (Touch Down)',
            valueMs: target.pressDurationMs,
            minMs: 20,
            maxMs: 2000,
            stepMs: 10,
            onChanged: onPressDurationChanged,
          ),
        ],
      ),
    );
  }
}
