import 'package:klikin/domain/entities/loop_config.dart';

class LoopConfigModel extends LoopConfig {
  const LoopConfigModel({
    super.loopType,
    super.maxCount,
    super.durationMinutes,
  });

  factory LoopConfigModel.fromEntity(LoopConfig entity) {
    return LoopConfigModel(
      loopType: entity.loopType,
      maxCount: entity.maxCount,
      durationMinutes: entity.durationMinutes,
    );
  }

  factory LoopConfigModel.fromMap(Map<String, dynamic> map) {
    final typeStr = map['loopType'] as String? ?? 'INFINITE';
    LoopType loopType;
    switch (typeStr) {
      case 'FINITE_COUNT':
        loopType = LoopType.finiteCount;
        break;
      case 'TIMER':
        loopType = LoopType.timer;
        break;
      default:
        loopType = LoopType.infinite;
    }

    return LoopConfigModel(
      loopType: loopType,
      maxCount: (map['maxCount'] as num?)?.toInt(),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    String typeStr;
    switch (loopType) {
      case LoopType.finiteCount:
        typeStr = 'FINITE_COUNT';
        break;
      case LoopType.timer:
        typeStr = 'TIMER';
        break;
      case LoopType.infinite:
        typeStr = 'INFINITE';
        break;
    }

    return {
      'loopType': typeStr,
      'maxCount': maxCount,
      'durationMinutes': durationMinutes,
    };
  }
}
