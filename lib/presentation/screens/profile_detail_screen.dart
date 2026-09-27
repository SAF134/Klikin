import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klikin/core/theme/app_colors.dart';
import 'package:klikin/core/theme/app_typography.dart';
import 'package:klikin/domain/entities/click_profile.dart';
import 'package:klikin/domain/entities/loop_config.dart';
import 'package:klikin/domain/entities/target_point.dart';
import 'package:klikin/presentation/bloc/profile/profile_bloc.dart';
import 'package:klikin/presentation/bloc/profile/profile_event.dart';
import 'package:klikin/presentation/widgets/common/millisecond_stepper.dart';
import 'package:klikin/presentation/widgets/common/pill_button.dart';

class ProfileDetailScreen extends StatefulWidget {
  final ClickProfile profile;

  const ProfileDetailScreen({super.key, required this.profile});

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
    if (_targets.isEmpty) {
      _targets.add(const TargetPoint(index: 1, x: 540, y: 1200, delayAfterMs: 500, pressDurationMs: 50));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final updated = widget.profile.copyWith(
      name: _nameController.text.trim().isEmpty ? 'Untitled Profile' : _nameController.text.trim(),
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

  void _addTarget() {
    setState(() {
      final nextIndex = _targets.length + 1;
      _targets.add(TargetPoint(
        index: nextIndex,
        x: 540,
        y: 1200 + (nextIndex * 100),
        delayAfterMs: 500,
        pressDurationMs: 50,
      ));
    });
  }

  void _removeTarget(int index) {
    if (_targets.length <= 1) return;
    setState(() {
      _targets.removeAt(index);
      // Re-index remaining targets
      for (int i = 0; i < _targets.length; i++) {
        _targets[i] = _targets[i].copyWith(index: i + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgObsidian,
      appBar: AppBar(
        title: const Text('Edit Konfigurasi Profil'),
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

                // 2. Loop Configuration
                Text('PENGATURAN SIKLUS (LOOP)', style: AppTypography.labelSm),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildChoiceChip(
                        label: 'Tak Terbatas',
                        isSelected: _loopType == LoopType.infinite,
                        onTap: () => setState(() => _loopType = LoopType.infinite),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildChoiceChip(
                        label: 'Berdasarkan Hitungan',
                        isSelected: _loopType == LoopType.finiteCount,
                        onTap: () => setState(() => _loopType = LoopType.finiteCount),
                      ),
                    ),
                  ],
                ),

                if (_loopType == LoopType.finiteCount) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.strokeSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Jumlah Siklus:', style: AppTypography.bodyMd),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _loopCount > 100
                                  ? () => setState(() => _loopCount -= 100)
                                  : null,
                              icon: const Icon(Icons.remove, size: 18),
                            ),
                            Text('$_loopCount x', style: AppTypography.dataLg.copyWith(fontSize: 16)),
                            IconButton(
                              onPressed: () => setState(() => _loopCount += 100),
                              icon: const Icon(Icons.add, size: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // 3. Targets List Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TITIK TARGET (${_targets.length})', style: AppTypography.labelSm),
                    TextButton.icon(
                      onPressed: _addTarget,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Tambah Titik'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.electricEmerald),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                ..._targets.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final target = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
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
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.cyanTarget,
                                    child: Text(
                                      '${target.index}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Koordinat: X=${target.x}, Y=${target.y}',
                                    style: AppTypography.dataSm,
                                  ),
                                ],
                              ),
                              if (_targets.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18, color: AppColors.crimsonAlert),
                                  onPressed: () => _removeTarget(idx),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          MillisecondStepper(
                            label: 'Jeda setelah titik ${target.index}',
                            valueMs: target.delayAfterMs,
                            minMs: 25,
                            stepMs: 50,
                            onChanged: (newDelay) {
                              setState(() {
                                _targets[idx] = target.copyWith(delayAfterMs: newDelay);
                              });
                            },
                          ),
                        ],
                      ),
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
                text: 'SIMPAN PERUBAHAN',
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
