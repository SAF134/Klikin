import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klikin/core/theme/app_colors.dart';
import 'package:klikin/core/theme/app_typography.dart';
import 'package:klikin/domain/entities/click_profile.dart';
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
import 'package:klikin/presentation/widgets/common/status_chip.dart';
import 'package:klikin/presentation/widgets/dashboard/active_profile_card.dart';
import 'package:klikin/presentation/widgets/dashboard/dashboard_empty_state.dart';
import 'package:klikin/presentation/widgets/dashboard/permission_banner.dart';

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
    final newProfile = ClickProfile.createDefault();

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
                  child: StatusChip(
                    label: '${state.profiles.length}/5 Profil',
                    borderRadius: BorderRadius.circular(999),
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
                              const PermissionBanner(),
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
                              ActiveProfileCard(
                                profile: profileState.activeProfile!,
                                onEdit: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ProfileDetailScreen(profile: profileState.activeProfile!),
                                    ),
                                  );
                                },
                              )
                            else
                              DashboardEmptyState(
                                onCreateProfile: () => _openCreateProfile(context),
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
}
