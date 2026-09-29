import 'package:equatable/equatable.dart';
import 'package:klikin/domain/entities/click_profile.dart';
import 'package:klikin/services/platform_bridge_service.dart';

abstract class ServiceEvent extends Equatable {
  const ServiceEvent();

  @override
  List<Object?> get props => [];
}

class StartOverlayEvent extends ServiceEvent {
  final ClickProfile profile;

  const StartOverlayEvent(this.profile);

  @override
  List<Object?> get props => [profile];
}

class StopOverlayEvent extends ServiceEvent {
  const StopOverlayEvent();
}

class NativeEventReceived extends ServiceEvent {
  final NativeEvent event;

  const NativeEventReceived(this.event);

  @override
  List<Object?> get props => [event];
}
