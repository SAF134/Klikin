import 'package:equatable/equatable.dart';

enum LoopType { infinite, finiteCount, timer }

class LoopConfig extends Equatable {
  final LoopType loopType;
  final int? maxCount;
  final int? durationMinutes;

  const LoopConfig({
    this.loopType = LoopType.infinite,
    this.maxCount,
    this.durationMinutes,
  });

  LoopConfig copyWith({
    LoopType? loopType,
    int? maxCount,
    int? durationMinutes,
  }) {
    return LoopConfig(
      loopType: loopType ?? this.loopType,
      maxCount: maxCount ?? this.maxCount,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  @override
  List<Object?> get props => [loopType, maxCount, durationMinutes];
}
