import 'dart:convert';
import 'package:klikin/data/models/loop_config_model.dart';
import 'package:klikin/data/models/target_point_model.dart';
import 'package:klikin/domain/entities/click_profile.dart';

class ClickProfileModel extends ClickProfile {
  const ClickProfileModel({
    required super.id,
    required super.name,
    super.mode,
    super.loopConfig,
    super.targets,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ClickProfileModel.fromEntity(ClickProfile entity) {
    return ClickProfileModel(
      id: entity.id,
      name: entity.name,
      mode: entity.mode,
      loopConfig: entity.loopConfig,
      targets: entity.targets,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory ClickProfileModel.fromMap(Map<String, dynamic> map) {
    final modeStr = map['mode'] as String? ?? 'SINGLE_POINT';
    final mode = (modeStr == 'MULTI_POINT')
        ? ProfileMode.multiPoint
        : ProfileMode.singlePoint;

    final targetsList = (map['targets'] as List<dynamic>?)
            ?.map((e) => TargetPointModel.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];

    final loopConfigMap = map['loopConfig'] != null
        ? Map<String, dynamic>.from(map['loopConfig'] as Map)
        : <String, dynamic>{};

    return ClickProfileModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Untitled Profile',
      mode: mode,
      loopConfig: LoopConfigModel.fromMap(loopConfigMap),
      targets: targetsList,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mode': mode == ProfileMode.multiPoint ? 'MULTI_POINT' : 'SINGLE_POINT',
      'loopConfig': LoopConfigModel.fromEntity(loopConfig).toMap(),
      'targets': targets.map((t) => TargetPointModel.fromEntity(t).toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());

  factory ClickProfileModel.fromJson(String source) =>
      ClickProfileModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
