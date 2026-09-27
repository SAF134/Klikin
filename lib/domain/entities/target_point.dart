import 'package:equatable/equatable.dart';

class TargetPoint extends Equatable {
  final int index;
  final int x;
  final int y;
  final int pressDurationMs;
  final int delayAfterMs;

  const TargetPoint({
    required this.index,
    required this.x,
    required this.y,
    this.pressDurationMs = 50,
    this.delayAfterMs = 500,
  });

  TargetPoint copyWith({
    int? index,
    int? x,
    int? y,
    int? pressDurationMs,
    int? delayAfterMs,
  }) {
    return TargetPoint(
      index: index ?? this.index,
      x: x ?? this.x,
      y: y ?? this.y,
      pressDurationMs: pressDurationMs ?? this.pressDurationMs,
      delayAfterMs: delayAfterMs ?? this.delayAfterMs,
    );
  }

  @override
  List<Object?> get props => [index, x, y, pressDurationMs, delayAfterMs];
}
