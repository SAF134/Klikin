import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klikin/core/theme/app_colors.dart';
import 'package:klikin/core/theme/app_typography.dart';
import 'package:klikin/domain/entities/click_profile.dart';
import 'package:klikin/domain/entities/loop_config.dart';
import 'package:klikin/domain/entities/target_point.dart';
import 'package:klikin/presentation/bloc/profile/profile_bloc.dart';
import 'package:klikin/presentation/bloc/profile/profile_event.dart';
import 'package:klikin/presentation/widgets/common/pill_button.dart';
import 'package:klikin/presentation/widgets/profile/loop_config_section.dart';
import 'package:klikin/presentation/widgets/profile/target_card_item.dart';

class ProfileDetailScreen extends StatefulWidget {
  final ClickProfile profile;
  final bool isNew;

  const ProfileDetailScreen({
    super.key,
    required this.profile,
    this.isNew = false,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  late TextEditingController _nameController;
  late ProfileMode _mode;
  late LoopType _loopType;
  late int _loopCount;
  late List<TargetPoint> _targets;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _mode = widget.profile.mode;
    _loopType = widget.profile.loopConfig.loopType;
    _loopCount = widget.profile.loopConfig.maxCount ?? 1000;
    _targets = List.from(widget.profile.targets);

    // Validasi inisialisasi titik target sesuai mode
    if (_mode == ProfileMode.singlePoint) {
      if (_targets.isEmpty) {
        _targets.add(const TargetPoint(index: 1, x: 540, y: 1200, delayAfterMs: 500, pressDurationMs: 50));
      } else if (_targets.length > 1) {
        _targets = [_targets.first.copyWith(index: 1)];
      }
    } else {
      // Multi-point wajib minimal 2 titik
      if (_targets.isEmpty) {
        _targets = [
          const TargetPoint(index: 1, x: 540, y: 1200, delayAfterMs: 500, pressDurationMs: 50),
          const TargetPoint(index: 2, x: 720, y: 1500, delayAfterMs: 500, pressDurationMs: 50),
        ];
      } else if (_targets.length == 1) {
        _targets.add(const TargetPoint(index: 2, x: 720, y: 1500, delayAfterMs: 500, pressDurationMs: 50));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onModeChanged(ProfileMode newMode) {
    if (_mode == newMode) return;
    setState(() {
      _mode = newMode;
      if (_mode == ProfileMode.singlePoint) {
        // Pindah ke single point: kunci tepat 1 titik
        if (_targets.length > 1) {
          _targets = [_targets.first.copyWith(index: 1)];
        }
      } else {
        // Pindah ke multi point: otomatis minimal 2 titik
        if (_targets.length < 2) {
          _targets.add(TargetPoint(
            index: 2,
            x: 720,
            y: 1500,
            delayAfterMs: 500,
            pressDurationMs: 50,
          ));
        }
      }
    });
  }

  void _addTarget() {
    if (_mode != ProfileMode.multiPoint) return;
    setState(() {
      final nextIndex = _targets.length + 1;
      _targets.add(TargetPoint(
        index: nextIndex,
        x: 540,
        y: (1200 + (nextIndex * 120)).clamp(200, 2200),
        delayAfterMs: 500,
        pressDurationMs: 50,
      ));
    });
  }

  void _removeTarget(int index) {
    // Multi-point tidak boleh kurang dari 2 titik
    if (_targets.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mode Multi-Point membutuhkan minimal 2 titik target.'),
          backgroundColor: AppColors.safetyAmber,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _targets.removeAt(index);
      // Re-index remaining targets
      for (int i = 0; i < _targets.length; i++) {
        _targets[i] = _targets[i].copyWith(index: i + 1);
      }
    });
  }

  void _saveProfile() {
    final profileName = _nameController.text.trim().isEmpty ? 'Profil Tanpa Nama' : _nameController.text.trim();

    final updated = widget.profile.copyWith(
      name: profileName,
      mode: _mode,
      loopConfig: LoopConfig(
        loopType: _loopType,
        maxCount: _loopType == LoopType.finiteCount ? _loopCount : null,
      ),
      targets: _targets,
      updatedAt: DateTime.now(),
    );

    context.read<ProfileBloc>().add(SaveProfileEvent(updated));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgObsidian,
      appBar: AppBar(
        title: Text(widget.isNew ? 'Buat Profil Baru' : 'Edit Konfigurasi Profil'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. Profile Name Field
                Text('NAMA PROFIL', style: AppTypography.labelSm),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'Contoh: Farming Auto-Battle',
                    hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.strokeSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.electricEmerald),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Mode Selector (Single-Point vs Multi-Point)
                Text('MODE OPERASI', style: AppTypography.labelSm),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildChoiceChip(
                        label: 'Single-Point (1 Titik)',
                        isSelected: _mode == ProfileMode.singlePoint,
                        onTap: () => _onModeChanged(ProfileMode.singlePoint),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildChoiceChip(
                        label: 'Multi-Point (Banyak Titik)',
                        isSelected: _mode == ProfileMode.multiPoint,
                        onTap: () => _onModeChanged(ProfileMode.multiPoint),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 3. Loop Configuration
                LoopConfigSection(
                  loopType: _loopType,
                  loopCount: _loopCount,
                  onLoopTypeChanged: (type) => setState(() => _loopType = type),
                  onLoopCountChanged: (count) => setState(() => _loopCount = count),
                ),

                const SizedBox(height: 28),

                // 4. Targets List Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _mode == ProfileMode.singlePoint
                          ? 'TITIK TARGET (1 TITIK)'
                          : 'TITIK TARGET (${_targets.length}) — MINIMAL 2',
                      style: AppTypography.labelSm,
                    ),
                    if (_mode == ProfileMode.multiPoint)
                      TextButton.icon(
                        onPressed: _addTarget,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Tambah Titik'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.electricEmerald),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Target Cards with per-target delay and press duration
                ..._targets.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final target = entry.value;
                  final canRemove = _mode == ProfileMode.multiPoint && _targets.length > 2;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TargetCardItem(
                      target: target,
                      canRemove: canRemove,
                      onRemove: () => _removeTarget(idx),
                      onDelayChanged: (newDelay) {
                        setState(() {
                          _targets[idx] = target.copyWith(delayAfterMs: newDelay);
                        });
                      },
                      onPressDurationChanged: (newDuration) {
                        setState(() {
                          _targets[idx] = target.copyWith(pressDurationMs: newDuration);
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // Bottom Save Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSlate,
              border: Border(top: BorderSide(color: AppColors.strokeSubtle)),
            ),
            child: SafeArea(
              child: PillButton(
                text: widget.isNew ? 'SIMPAN & AKTIFKAN PROFIL' : 'SIMPAN PERUBAHAN',
                onPressed: _saveProfile,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
}
