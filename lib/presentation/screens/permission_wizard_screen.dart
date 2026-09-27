import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klikin/core/theme/app_colors.dart';
import 'package:klikin/core/theme/app_typography.dart';
import 'package:klikin/presentation/bloc/permission/permission_bloc.dart';
import 'package:klikin/presentation/bloc/permission/permission_event.dart';
import 'package:klikin/presentation/bloc/permission/permission_state.dart';
import 'package:klikin/presentation/widgets/common/pill_button.dart';

class PermissionWizardScreen extends StatefulWidget {
  const PermissionWizardScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PermissionWizardScreen(),
    );
  }

  @override
  State<PermissionWizardScreen> createState() => _PermissionWizardScreenState();
}

class _PermissionWizardScreenState extends State<PermissionWizardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<PermissionBloc>().add(const CheckPermissionsEvent());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Auto-recheck saat pengguna kembali dari halaman Settings OS
      context.read<PermissionBloc>().add(const CheckPermissionsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceSlate,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.strokeFocus, width: 1.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        child: BlocConsumer<PermissionBloc, PermissionState>(
          listener: (context, state) {
            if (state.isAllGranted) {
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.strokeSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Izin Sistem Diperlukan', style: AppTypography.titleMd),
                const SizedBox(height: 8),
                Text(
                  'Klikin membutuhkan 2 izin sistem Android agar dapat menampilkan panel kendali melayang dan menginjeksi ketukan presisi.',
                  style: AppTypography.bodyMd,
                ),
                const SizedBox(height: 24),

                // Step 1: Draw Over Other Apps
                _buildPermissionCard(
                  step: '1',
                  title: 'Tampilkan di Atas Aplikasi Lain',
                  description: 'Diperlukan untuk memunculkan dock panel kendali dan pin target.',
                  isGranted: state.hasOverlayPermission,
                  onAction: () {
                    context.read<PermissionBloc>().add(const RequestOverlayPermissionEvent());
                  },
                ),

                const SizedBox(height: 14),

                // Step 2: Accessibility Service
                _buildPermissionCard(
                  step: '2',
                  title: 'Layanan Aksesibilitas (Klikin)',
                  description: 'Diperlukan untuk mengeksekusi ketukan otomatis fisik tanpa root.',
                  isGranted: state.hasAccessibilityPermission,
                  onAction: () {
                    context.read<PermissionBloc>().add(const RequestAccessibilityPermissionEvent());
                  },
                ),

                const SizedBox(height: 28),

                PillButton(
                  text: state.isAllGranted ? 'Semua Izin Aktif' : 'Tutup Panduan',
                  variant: state.isAllGranted ? PillButtonVariant.primary : PillButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String step,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted ? AppColors.electricEmerald.withValues(alpha: 0.5) : AppColors.strokeSubtle,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: isGranted ? AppColors.electricEmerald : AppColors.surfaceSlate,
            child: Text(
              step,
              style: TextStyle(
                color: isGranted ? AppColors.textDark : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isGranted
                            ? AppColors.electricEmerald.withValues(alpha: 0.15)
                            : AppColors.crimsonAlert.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isGranted ? 'AKTIF' : 'NONAKTIF',
                        style: AppTypography.labelSm.copyWith(
                          color: isGranted ? AppColors.electricEmerald : AppColors.crimsonAlert,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(description, style: AppTypography.bodyMd.copyWith(fontSize: 12)),
                if (!isGranted) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Buka Pengaturan'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.electricEmerald,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
