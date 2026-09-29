import 'package:equatable/equatable.dart';

class PermissionState extends Equatable {
  final bool hasOverlayPermission;
  final bool hasAccessibilityPermission;
  final bool hasBatteryOptimizationIgnored;
  final bool isLoading;

  const PermissionState({
    this.hasOverlayPermission = false,
    this.hasAccessibilityPermission = false,
    this.hasBatteryOptimizationIgnored = true,
    this.isLoading = false,
  });

  bool get isAllGranted => hasOverlayPermission && hasAccessibilityPermission;

  PermissionState copyWith({
    bool? hasOverlayPermission,
    bool? hasAccessibilityPermission,
    bool? hasBatteryOptimizationIgnored,
    bool? isLoading,
  }) {
    return PermissionState(
      hasOverlayPermission: hasOverlayPermission ?? this.hasOverlayPermission,
      hasAccessibilityPermission:
          hasAccessibilityPermission ?? this.hasAccessibilityPermission,
      hasBatteryOptimizationIgnored:
          hasBatteryOptimizationIgnored ?? this.hasBatteryOptimizationIgnored,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        hasOverlayPermission,
        hasAccessibilityPermission,
        hasBatteryOptimizationIgnored,
        isLoading,
      ];
}
