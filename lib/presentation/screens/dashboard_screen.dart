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
import 'package:klikin/presentation/widgets/common/pill_button.dart';
import 'package:uuid/uuid.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
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

  void _openCreateProfile(BuildContext context) {
    final newProfile = ClickProfile(
      id: const Uuid().v4(),
      name: 'Profil Ketukan 1',
      mode: ProfileMode.singlePoint,
      loopConfig: const LoopConfig(loopType: LoopType.infinite),
      targets: const [
        TargetPoint(index: 1, x: 540, y: 1200, delayAfterMs: 500, pressDurationMs: 50),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileDetailScreen(profile: newProfile, isNew: true),
      ),
    );
  }

  void _onToggleService(
    BuildContext context,
    bool isAllGranted,
    ProfileState profileState,
    ServiceState serviceState,
  ) {
    if (!isAllGranted) {
      PermissionWizardScreen.show(context);
      return;
    }

    if (profileState.activeProfile == null) {
      _openCreateProfile(context);
      return;
    }

    if (serviceState.isOverlayActive) {
      context.read<ServiceBloc>().add(const StopOverlayEvent());
    } else {
      context.read<ServiceBloc>().add(StartOverlayEvent(profileState.activeProfile!));
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
                  final hasProfile = profileState.activeProfile != null;

                  return Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          children: [
                            // 1. Permission Warning Banner (jika belum lengkap)
                            if (!permState.isAllGranted) ...[
                              _buildPermissionBanner(context),
                              const SizedBox(height: 20),
                            ],

                            // 2. Active Profile Section Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('PROFIL AKTIF', style: AppTypography.labelSm),
                                if (profileState.profiles.isNotEmpty)
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

                            // 3. Active Profile Content / Onboarding Empty State
                            if (profileState.activeProfile != null)
                              _buildActiveProfileCard(context, profileState.activeProfile!)
                            else
                              _buildNoProfileCard(context),
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
                            text: !hasProfile
                                ? 'BUAT PROFIL TERLEBIH DAHULU'
                                : (serviceState.isOverlayActive
                                    ? 'HENTIKAN PANEL MELAYANG'
                                    : 'MULAI PANEL MELAYANG'),
                            variant: !hasProfile
                                ? PillButtonVariant.secondary
                                : (serviceState.isOverlayActive
                                    ? PillButtonVariant.destructive
                                    : PillButtonVariant.primary),
                            icon: !hasProfile
                                ? Icons.add_circle_outline
                                : (serviceState.isOverlayActive
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded),
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

  Widget _buildNoProfileCard(BuildContext context) {
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
              onPressed: () => _openCreateProfile(context),
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

  Widget _buildActiveProfileCard(BuildContext context, ClickProfile profile) {
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildChip(
                isMulti ? 'Multi-Point (${profile.targets.length} Titik)' : 'Single-Point (1 Titik)',
                isHighlighted: true,
              ),
              _buildChip(
                profile.loopConfig.loopType == LoopType.infinite
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
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: AppColors.cyanTarget,
                    child: Text(
                      '${t.index}',
                      style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
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

  Widget _buildChip(String label, {bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.electricEmerald.withValues(alpha: 0.15) : AppColors.surfaceSlate,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHighlighted ? AppColors.electricEmerald : AppColors.strokeSubtle,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.labelSm.copyWith(
          color: isHighlighted ? AppColors.electricEmerald : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
