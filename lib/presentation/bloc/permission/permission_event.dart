import 'package:equatable/equatable.dart';

abstract class PermissionEvent extends Equatable {
  const PermissionEvent();

  @override
  List<Object?> get props => [];
}

class CheckPermissionsEvent extends PermissionEvent {
  const CheckPermissionsEvent();
}

class RequestOverlayPermissionEvent extends PermissionEvent {
  const RequestOverlayPermissionEvent();
}

class RequestAccessibilityPermissionEvent extends PermissionEvent {
  const RequestAccessibilityPermissionEvent();
}
