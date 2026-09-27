import 'package:equatable/equatable.dart';

class ServiceState extends Equatable {
  final String status; // 'IDLE', 'ARMED', 'RUNNING', 'PAUSED', 'ERROR'
  final bool isOverlayActive;
  final int currentLoop;
  final int totalLoops;
  final int activeTargetIndex;
  final String? errorMessage;
  final String? emergencyReason;

  const ServiceState({
    this.status = 'IDLE',
    this.isOverlayActive = false,
    this.currentLoop = 0,
    this.totalLoops = 0,
    this.activeTargetIndex = 0,
    this.errorMessage,
    this.emergencyReason,
  });

  bool get isRunning => status == 'RUNNING';
  bool get isPaused => status == 'PAUSED';

  ServiceState copyWith({
    String? status,
    bool? isOverlayActive,
    int? currentLoop,
    int? totalLoops,
    int? activeTargetIndex,
    String? errorMessage,
    String? emergencyReason,
  }) {
    return ServiceState(
      status: status ?? this.status,
      isOverlayActive: isOverlayActive ?? this.isOverlayActive,
      currentLoop: currentLoop ?? this.currentLoop,
      totalLoops: totalLoops ?? this.totalLoops,
      activeTargetIndex: activeTargetIndex ?? this.activeTargetIndex,
      errorMessage: errorMessage,
      emergencyReason: emergencyReason,
    );
  }

  @override
  List<Object?> get props => [
        status,
        isOverlayActive,
        currentLoop,
        totalLoops,
        activeTargetIndex,
        errorMessage,
        emergencyReason,
      ];
}
