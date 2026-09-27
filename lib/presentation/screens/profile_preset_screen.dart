import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klikin/core/theme/app_colors.dart';
import 'package:klikin/core/theme/app_typography.dart';
import 'package:klikin/domain/entities/click_profile.dart';
import 'package:klikin/domain/entities/loop_config.dart';
import 'package:klikin/domain/entities/target_point.dart';
import 'package:klikin/presentation/bloc/profile/profile_bloc.dart';
import 'package:klikin/presentation/bloc/profile/profile_event.dart';
import 'package:klikin/presentation/bloc/profile/profile_state.dart';
import 'package:klikin/presentation/screens/profile_detail_screen.dart';
import 'package:klikin/presentation/widgets/common/pill_button.dart';
import 'package:uuid/uuid.dart';

class ProfilePresetScreen extends StatelessWidget {
  const ProfilePresetScreen({super.key});

  void _createNewProfile(BuildContext context, ProfileState state) {
    if (state.isMaxSlotsReached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Batas maksimal 5 slot profil telah tercapai.'),
          backgroundColor: AppColors.crimsonAlert,
        ),
      );
      return;
    }

    final newProfile = ClickProfile(
      id: const Uuid().v4(),
      name: 'Profil Baru ${state.profiles.length + 1}',
      mode: ProfileMode.singlePoint,
      loopConfig: const LoopConfig(loopType: LoopType.infinite),
      targets: const [
        TargetPoint(index: 1, x: 540, y: 1200, delayAfterMs: 500, pressDurationMs: 50),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    context.read<ProfileBloc>().add(SaveProfileEvent(newProfile));

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileDetailScreen(profile: newProfile)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgObsidian,
      appBar: AppBar(
        title: const Text('Kelola Profil Preset'),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: AppColors.crimsonAlert),
            );
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.successMessage!), backgroundColor: AppColors.electricEmerald),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.electricEmerald),
            );
          }

          return Column(
            children: [
              Expanded(
                child: state.profiles.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        itemCount: state.profiles.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final profile = state.profiles[index];
                          final isActive = state.activeProfile?.id == profile.id;
                          return _buildProfileItem(context, profile, isActive);
                        },
                      ),
              ),

              // Bottom Button: Tambah Profil (jika belum 5 slot)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceSlate,
                  border: Border(top: BorderSide(color: AppColors.strokeSubtle)),
                ),
                child: SafeArea(
                  child: PillButton(
                    text: 'BUAT PROFIL BARU (${state.profiles.length}/5)',
                    icon: Icons.add,
                    variant: state.isMaxSlotsReached ? PillButtonVariant.secondary : PillButtonVariant.primary,
                    onPressed: state.isMaxSlotsReached ? null : () => _createNewProfile(context, state),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.layers_clear_outlined, size: 56, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text('Belum Ada Profil Tersimpan', style: AppTypography.titleMd),
            const SizedBox(height: 8),
            Text(
              'Simpan konfigurasi titik target dan jeda waktu favorit Anda agar tidak perlu mengatur ulang setiap sesi.',
              style: AppTypography.bodyMd,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, ClickProfile profile, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.electricEmerald : AppColors.strokeSubtle,
          width: isActive ? 1.5 : 1,
        ),
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
                  style: AppTypography.titleMd.copyWith(fontSize: 16),
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.electricEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'AKTIF',
                    style: AppTypography.labelSm.copyWith(color: AppColors.electricEmerald),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${profile.targets.length} Target Points • ${profile.mode == ProfileMode.multiPoint ? "Multi-Point" : "Single-Point"}',
            style: AppTypography.bodyMd.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.crimsonAlert),
                onPressed: () {
                  context.read<ProfileBloc>().add(DeleteProfileEvent(profile.id));
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ProfileDetailScreen(profile: profile)),
                  );
                },
              ),
              const SizedBox(width: 8),
              if (!isActive)
                TextButton(
                  onPressed: () {
                    context.read<ProfileBloc>().add(SelectActiveProfileEvent(profile));
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.surfaceSlate,
                    foregroundColor: AppColors.electricEmerald,
                  ),
                  child: const Text('Gunakan'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
