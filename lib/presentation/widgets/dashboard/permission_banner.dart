import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klikin/core/theme/app_colors.dart';
import 'package:klikin/core/theme/app_typography.dart';
import 'package:klikin/presentation/bloc/permission/permission_bloc.dart';
import 'package:klikin/presentation/bloc/permission/permission_event.dart';
import 'package:klikin/presentation/bloc/permission/permission_state.dart';
import 'package:klikin/presentation/screens/permission_wizard_screen.dart';

class PermissionBanner extends StatelessWidget {
  const PermissionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PermissionBloc, PermissionState>(
      builder: (context, permState) {
        final isAccessibilityOnly = permState.hasOverlayPermission && !permState.hasAccessibilityPermission;

        final title = isAccessibilityOnly
            ? 'Layanan Aksesibilitas Terputus'
            : 'Izin Sistem Diperlukan';

        final description = isAccessibilityOnly
            ? 'Layanan dihentikan sistem Android. Ketuk Sambungkan untuk memulihkan.'
            : 'Aktifkan izin Aksesibilitas & Overlay untuk memulai.';

        final buttonText = isAccessibilityOnly ? 'Sambungkan' : 'Setup';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.safetyAmber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.safetyAmber.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.safetyAmber, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTypography.bodyMd.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  if (isAccessibilityOnly) {
                    context.read<PermissionBloc>().add(const RequestAccessibilityPermissionEvent());
                  } else {
                    PermissionWizardScreen.show(context);
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.safetyAmber,
                  foregroundColor: AppColors.textDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}
