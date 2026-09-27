import 'package:klikin/domain/entities/target_point.dart';

class TargetPointModel extends TargetPoint {
  const TargetPointModel({
    required super.index,
    required super.x,
    required super.y,
    super.pressDurationMs,
    super.delayAfterMs,
  });

  factory TargetPointModel.fromEntity(TargetPoint entity) {
    return TargetPointModel(
      index: entity.index,
      x: entity.x,
      y: entity.y,
      pressDurationMs: entity.pressDurationMs,
      delayAfterMs: entity.delayAfterMs,
    );
  }

  factory TargetPointModel.fromMap(Map<String, dynamic> map) {
    return TargetPointModel(
      index: (map['index'] as num?)?.toInt() ?? 1,
      x: (map['x'] as num?)?.toInt() ?? 0,
      y: (map['y'] as num?)?.toInt() ?? 0,
      pressDurationMs: (map['pressDurationMs'] as num?)?.toInt() ?? 50,
      delayAfterMs: (map['delayAfterMs'] as num?)?.toInt() ?? 500,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'x': x,
      'y': y,
      'pressDurationMs': pressDurationMs,
      'delayAfterMs': delayAfterMs,
    };
  }
}
