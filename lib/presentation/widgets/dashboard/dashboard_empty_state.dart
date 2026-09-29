import 'package:flutter/material.dart';
import 'package:klikin/core/theme/app_colors.dart';
import 'package:klikin/core/theme/app_typography.dart';

class DashboardEmptyState extends StatelessWidget {
  final VoidCallback onCreateProfile;

  const DashboardEmptyState({
    super.key,
    required this.onCreateProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.strokeSubtle),
      ),
      child: Column(
        children: [
          const Icon(Icons.playlist_add_rounded, size: 48, color: AppColors.electricEmerald),
          const SizedBox(height: 14),
          Text('Belum Ada Profil Ketukan', style: AppTypography.titleMd),
          const SizedBox(height: 6),
          Text(
            'Buat profil pertama Anda untuk menentukan mode operasi, jumlah titik, jeda antar ketukan, dan durasi tekan.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCreateProfile,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Buat Profil Pertama'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricEmerald,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
