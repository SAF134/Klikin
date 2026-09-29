import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klikin/data/models/click_profile_model.dart';
import 'package:klikin/presentation/bloc/service/service_event.dart';
import 'package:klikin/presentation/bloc/service/service_state.dart';
import 'package:klikin/services/platform_bridge_service.dart';

class ServiceBloc extends Bloc<ServiceEvent, ServiceState> {
  final PlatformBridgeService _bridgeService;
  StreamSubscription<NativeEvent>? _subscription;

  ServiceBloc({required PlatformBridgeService bridgeService})
      : _bridgeService = bridgeService,
        super(const ServiceState()) {
    on<StartOverlayEvent>(_onStartOverlay);
    on<StopOverlayEvent>(_onStopOverlay);
    on<NativeEventReceived>(_onNativeEventReceived);

    _subscription = _bridgeService.events.listen((event) {
      add(NativeEventReceived(event));
    });
  }

  Future<void> _onStartOverlay(
    StartOverlayEvent event,
    Emitter<ServiceState> emit,
  ) async {
    final model = ClickProfileModel.fromEntity(event.profile);
    final success = await _bridgeService.startOverlay(model.toMap());
    if (success) {
      emit(state.copyWith(
        isOverlayActive: true,
        status: 'ARMED',
      ));
    } else {
      emit(state.copyWith(
        errorMessage: 'Gagal menjalankan panel kontrol melayang.',
      ));
    }
  }

  Future<void> _onStopOverlay(
    StopOverlayEvent event,
    Emitter<ServiceState> emit,
  ) async {
    await _bridgeService.stopOverlay();
    emit(state.copyWith(
      isOverlayActive: false,
      status: 'IDLE',
    ));
  }

  void _onNativeEventReceived(
    NativeEventReceived event,
    Emitter<ServiceState> emit,
  ) {
    final nativeEvent = event.event;

    if (nativeEvent is StateChangedEvent) {
      final isOverlayNowActive = nativeEvent.state != 'IDLE';
      emit(state.copyWith(
        status: nativeEvent.state,
        isOverlayActive: isOverlayNowActive,
        errorMessage: nativeEvent.state == 'ERROR' ? nativeEvent.message : null,
      ));
    } else if (nativeEvent is ExecutionProgressEvent) {
      emit(state.copyWith(
        currentLoop: nativeEvent.currentLoop,
        totalLoops: nativeEvent.totalLoops,
        activeTargetIndex: nativeEvent.targetIndex,
      ));
    } else if (nativeEvent is EmergencyStopEvent) {
      emit(state.copyWith(
        status: 'PAUSED',
        emergencyReason: nativeEvent.reason,
      ));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
