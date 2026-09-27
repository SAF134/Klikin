import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klikin/core/theme/app_colors.dart';
import 'package:klikin/core/theme/app_typography.dart';
import 'package:klikin/domain/entities/click_profile.dart';
import 'package:klikin/domain/entities/loop_config.dart';
import 'package:klikin/domain/entities/target_point.dart';
import 'package:klikin/presentation/bloc/permission/permission_bloc.dart';
import 'package:klikin/presentation/bloc/permission/permission_event.dart';
import 'package:klikin/presentation/bloc/permission/permission_state.dart';
import 'package:klikin/presentation/bloc/profile/profile_bloc.dart';
import 'package:klikin/presentation/bloc/profile/profile_event.dart';
import 'package:klikin/presentation/bloc/profile/profile_state.dart';
import 'package:klikin/presentation/bloc/service/service_bloc.dart';
import 'package:klikin/presentation/bloc/service/service_event.dart';
import 'package:klikin/presentation/bloc/service/service_state.dart';
import 'package:klikin/presentation/screens/permission_wizard_screen.dart';
import 'package:klikin/presentation/screens/profile_detail_screen.dart';
import 'package:klikin/presentation/screens/profile_preset_screen.dart';
import 'package:klikin/presentation/widgets/common/millisecond_stepper.dart';
import 'package:klikin/presentation/widgets/common/pill_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  ProfileMode _selectedMode = ProfileMode.singlePoint;
  int _defaultDelayMs = 500;
  int _pressDurationMs = 50;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<PermissionBloc>().add(const CheckPermissionsEvent());
    context.read<ProfileBloc>().add(const LoadProfilesEvent());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<PermissionBloc>().add(const CheckPermissionsEvent());
    }
  }

  void _onToggleService(BuildContext context, bool isAllGranted, ProfileState profileState, ServiceState serviceState) {
    if (!isAllGranted) {
      PermissionWizardScreen.show(context);
      return;
    }

    if (serviceState.isOverlayActive) {
      context.read<ServiceBloc>().add(const StopOverlayEvent());
    } else {
      final activeProfile = profileState.activeProfile ??
          ClickProfile(
            id: 'temp_profile',
            name: _selectedMode == ProfileMode.singlePoint ? 'Single Target' : 'Multi Target',
            mode: _selectedMode,
            loopConfig: const LoopConfig(loopType: LoopType.infinite),
            targets: [
              TargetPoint(
                index: 1,
                x: 540,
                y: 1200,
                delayAfterMs: _defaultDelayMs,
                pressDurationMs: _pressDurationMs,
              ),
              if (_selectedMode == ProfileMode.multiPoint)
                TargetPoint(
                  index: 2,
                  x: 720,
                  y: 1500,
                  delayAfterMs: _defaultDelayMs,
                  pressDurationMs: _pressDurationMs,
                ),
            ],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

      context.read<ServiceBloc>().add(StartOverlayEvent(activeProfile));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgObsidian,
      appBar: AppBar(
        title: Text('Klikin', style: AppTypography.displayLg.copyWith(fontSize: 22)),
        actions: [
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSlate,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.strokeSubtle),
                    ),
                    child: Text(
                      '${state.profiles.length}/5 Profil',
                      style: AppTypography.labelSm.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<PermissionBloc, PermissionState>(
        builder: (context, permState) {
          return BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, profileState) {
              return BlocBuilder<ServiceBloc, ServiceState>(
                builder: (context, serviceState) {
                  return Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          children: [
                            // 1. Permission Warning Banner
                            if (!permState.isAllGranted) ...[
                              _buildPermissionBanner(context),
                              const SizedBox(height: 20),
                            ],

                            // 2. Mode Selector
                            Text('MODE OPERASI', style: AppTypography.labelSm),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildModeCard(
                                    title: 'Single-Point',
                                    description: '1 Titik Berulang',
                                    isSelected: _selectedMode == ProfileMode.singlePoint,
                                    onTap: () => setState(() => _selectedMode = ProfileMode.singlePoint),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildModeCard(
                                    title: 'Multi-Point',
                                    description: 'Urutan 1, 2, 3..',
                                    isSelected: _selectedMode == ProfileMode.multiPoint,
                                    onTap: () => setState(() => _selectedMode = ProfileMode.multiPoint),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // 3. Active Profile Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('PROFIL AKTIF', style: AppTypography.labelSm),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const ProfilePresetScreen()),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.electricEmerald,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text('Kelola Semua'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildActiveProfileCard(context, profileState.activeProfile),

                            const SizedBox(height: 24),

                            // 4. Quick Interval Settings
                            Text('PENGATURAN CEPAT', style: AppTypography.labelSm),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.strokeSubtle),
                              ),
                              child: Column(
                                children: [
                                  MillisecondStepper(
                                    label: 'Jeda Antar Ketukan (Delay)',
                                    valueMs: _defaultDelayMs,
                                    minMs: 25,
                                    stepMs: 50,
                                    onChanged: (val) => setState(() => _defaultDelayMs = val),
                                  ),
                                  const Divider(color: AppColors.strokeSubtle, height: 28),
                                  MillisecondStepper(
                                    label: 'Durasi Tekan (Touch Down)',
                                    valueMs: _pressDurationMs,
                                    minMs: 20,
                                    maxMs: 2000,
                                    stepMs: 10,
                                    onChanged: (val) => setState(() => _pressDurationMs = val),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Sticky Bottom Action Area
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceSlate,
                          border: Border(top: BorderSide(color: AppColors.strokeSubtle)),
                        ),
                        child: SafeArea(
                          child: PillButton(
                            text: serviceState.isOverlayActive
                                ? 'HENTIKAN PANEL MELAYANG'
                                : 'MULAI PANEL MELAYANG',
                            variant: serviceState.isOverlayActive
                                ? PillButtonVariant.destructive
                                : PillButtonVariant.primary,
                            icon: serviceState.isOverlayActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
                            onPressed: () => _onToggleService(
                              context,
                              permState.isAllGranted,
                              profileState,
                              serviceState,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPermissionBanner(BuildContext context) {
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
                  'Izin Sistem Diperlukan',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Aktifkan izin Aksesibilitas & Overlay untuk memulai.',
                  style: AppTypography.bodyMd.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => PermissionWizardScreen.show(context),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.safetyAmber,
              foregroundColor: AppColors.textDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Setup', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceSlate : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.electricEmerald : AppColors.strokeSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? AppColors.electricEmerald : AppColors.textTertiary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(description, style: AppTypography.labelSm),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveProfileCard(BuildContext context, ClickProfile? profile) {
    if (profile == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.strokeSubtle),
        ),
        child: Row(
          children: [
            const Icon(Icons.bookmark_border, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Belum Ada Profil Tersimpan', style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary)),
                  Text('Konfigurasi sesi default sedang digunakan.', style: AppTypography.labelSm),
                ],
              ),
            ),
          ],
        ),
      );
    }

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
              Text(
                profile.name,
                style: AppTypography.titleMd.copyWith(fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileDetailScreen(profile: profile),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildChip('${profile.targets.length} Target'),
              const SizedBox(width: 8),
              _buildChip(profile.mode == ProfileMode.multiPoint ? 'Multi-Point' : 'Single-Point'),
              const SizedBox(width: 8),
              _buildChip(profile.loopConfig.loopType == LoopType.infinite ? 'Loop Tak Terbatas' : 'Loop Terbatas'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSlate,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.strokeSubtle),
      ),
      child: Text(label, style: AppTypography.labelSm.copyWith(fontSize: 10)),
    );
  }
}
