import 'package:flutter/material.dart';
import 'package:klikin/core/theme/app_colors.dart';
import 'package:klikin/core/theme/app_typography.dart';
import 'package:klikin/domain/entities/click_profile.dart';
import 'package:klikin/domain/entities/loop_config.dart';
import 'package:klikin/presentation/widgets/common/status_chip.dart';
import 'package:klikin/presentation/widgets/common/target_index_badge.dart';

class ActiveProfileCard extends StatelessWidget {
  final ClickProfile profile;
  final VoidCallback onEdit;

  const ActiveProfileCard({
    super.key,
    required this.profile,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isMulti = profile.mode == ProfileMode.multiPoint;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.electricEmerald, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  profile.name,
                  style: AppTypography.titleMd.copyWith(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                tooltip: 'Edit Profil',
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              StatusChip(
                label: isMulti ? 'Multi-Point (${profile.targets.length} Titik)' : 'Single-Point (1 Titik)',
                isHighlighted: true,
              ),
              StatusChip(
                label: profile.loopConfig.loopType == LoopType.infinite
                    ? 'Loop: Tak Terbatas'
                    : 'Loop: ${profile.loopConfig.maxCount}x',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.strokeSubtle, height: 1),
          const SizedBox(height: 12),
          Text('KONFIGURASI TITIK TARGET:', style: AppTypography.labelSm.copyWith(fontSize: 10)),
          const SizedBox(height: 8),
          ...profile.targets.map((t) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  TargetIndexBadge(index: t.index, radius: 10, fontSize: 10),
                  const SizedBox(width: 8),
                  Text('Titik ${t.index}:', style: AppTypography.bodyMd.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text(
                    'Jeda ${t.delayAfterMs} ms  •  Tekan ${t.pressDurationMs} ms',
                    style: AppTypography.dataSm.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
