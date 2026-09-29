import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klikin/presentation/bloc/permission/permission_event.dart';
import 'package:klikin/presentation/bloc/permission/permission_state.dart';
import 'package:klikin/services/platform_bridge_service.dart';

class PermissionBloc extends Bloc<PermissionEvent, PermissionState> {
  final PlatformBridgeService _bridgeService;

  PermissionBloc({required PlatformBridgeService bridgeService})
      : _bridgeService = bridgeService,
        super(const PermissionState(isLoading: true)) {
    on<CheckPermissionsEvent>(_onCheckPermissions);
    on<RequestOverlayPermissionEvent>(_onRequestOverlay);
    on<RequestAccessibilityPermissionEvent>(_onRequestAccessibility);
    on<RequestBatteryOptimizationEvent>(_onRequestBatteryOptimization);
  }

  Future<void> _onCheckPermissions(
    CheckPermissionsEvent event,
    Emitter<PermissionState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final status = await _bridgeService.checkPermissions();
    emit(state.copyWith(
      hasOverlayPermission: status.hasOverlayPermission,
      hasAccessibilityPermission: status.hasAccessibilityPermission,
      hasBatteryOptimizationIgnored: status.hasBatteryOptimizationIgnored,
      isLoading: false,
    ));
  }

  Future<void> _onRequestOverlay(
    RequestOverlayPermissionEvent event,
    Emitter<PermissionState> emit,
  ) async {
    await _bridgeService.requestOverlayPermission();
  }

  Future<void> _onRequestAccessibility(
    RequestAccessibilityPermissionEvent event,
    Emitter<PermissionState> emit,
  ) async {
    await _bridgeService.requestAccessibilityPermission();
  }

  Future<void> _onRequestBatteryOptimization(
    RequestBatteryOptimizationEvent event,
    Emitter<PermissionState> emit,
  ) async {
    await _bridgeService.requestBatteryOptimization();
  }
}
