import 'package:equatable/equatable.dart';
import 'package:klikin/domain/entities/loop_config.dart';
import 'package:klikin/domain/entities/target_point.dart';
import 'package:uuid/uuid.dart';

enum ProfileMode { singlePoint, multiPoint }

class ClickProfile extends Equatable {
  final String id;
  final String name;
  final ProfileMode mode;
  final LoopConfig loopConfig;
  final List<TargetPoint> targets;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClickProfile({
    required this.id,
    required this.name,
    this.mode = ProfileMode.singlePoint,
    this.loopConfig = const LoopConfig(),
    this.targets = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClickProfile.createDefault({
    String? id,
    String name = 'Profil Ketukan 1',
    ProfileMode mode = ProfileMode.singlePoint,
  }) {
    final now = DateTime.now();
    return ClickProfile(
      id: id ?? const Uuid().v4(),
      name: name,
      mode: mode,
      loopConfig: const LoopConfig(loopType: LoopType.infinite),
      targets: const [
        TargetPoint(index: 1, x: 540, y: 1200, delayAfterMs: 500, pressDurationMs: 50),
      ],
      createdAt: now,
      updatedAt: now,
    );
  }

  ClickProfile copyWith({
    String? id,
    String? name,
    ProfileMode? mode,
    LoopConfig? loopConfig,
    List<TargetPoint>? targets,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClickProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      loopConfig: loopConfig ?? this.loopConfig,
      targets: targets ?? this.targets,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        mode,
        loopConfig,
        targets,
        createdAt,
        updatedAt,
      ];
}
