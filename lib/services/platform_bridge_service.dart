import 'dart:async';
import 'package:flutter/services.dart';
import 'package:klikin/core/constants/channel_constants.dart';

class PermissionStatusModel {
  final bool hasOverlayPermission;
  final bool hasAccessibilityPermission;

  const PermissionStatusModel({
    required this.hasOverlayPermission,
    required this.hasAccessibilityPermission,
  });

  bool get isAllGranted => hasOverlayPermission && hasAccessibilityPermission;

  factory PermissionStatusModel.fromMap(Map<dynamic, dynamic> map) {
    return PermissionStatusModel(
      hasOverlayPermission: map['hasOverlayPermission'] as bool? ?? false,
      hasAccessibilityPermission:
          map['hasAccessibilityPermission'] as bool? ?? false,
    );
  }
}

abstract class NativeEvent {
  const NativeEvent();
}

class StateChangedEvent extends NativeEvent {
  final String state;
  final String? message;

  const StateChangedEvent({required this.state, this.message});
}

class TargetCoordinatesChangedEvent extends NativeEvent {
  final int index;
  final int x;
  final int y;

  const TargetCoordinatesChangedEvent({
    required this.index,
    required this.x,
    required this.y,
  });
}

class ExecutionProgressEvent extends NativeEvent {
  final int currentLoop;
  final int totalLoops;
  final int targetIndex;

  const ExecutionProgressEvent({
    required this.currentLoop,
    required this.totalLoops,
    required this.targetIndex,
  });
}

class EmergencyStopEvent extends NativeEvent {
  final String reason;

  const EmergencyStopEvent({required this.reason});
}

class UnknownNativeEvent extends NativeEvent {
  final Map<dynamic, dynamic> raw;

  const UnknownNativeEvent(this.raw);
}

class PlatformBridgeService {
  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Stream<NativeEvent>? _eventStream;

  PlatformBridgeService({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel = methodChannel ??
            const MethodChannel(ChannelConstants.controllerChannel),
        _eventChannel =
            eventChannel ?? const EventChannel(ChannelConstants.eventsChannel);

  Stream<NativeEvent> get events {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((dynamic raw) => _parseNativeEvent(raw));
    return _eventStream!;
  }

  NativeEvent _parseNativeEvent(dynamic raw) {
    if (raw is! Map) return UnknownNativeEvent({'data': raw});
    final eventType = raw['eventType'] as String?;

    switch (eventType) {
      case ChannelConstants.eventStateChanged:
        return StateChangedEvent(
          state: raw['state'] as String? ?? 'IDLE',
          message: raw['message'] as String?,
        );
      case ChannelConstants.eventTargetCoordinatesChanged:
        return TargetCoordinatesChangedEvent(
          index: (raw['index'] as num?)?.toInt() ?? 0,
          x: (raw['x'] as num?)?.toInt() ?? 0,
          y: (raw['y'] as num?)?.toInt() ?? 0,
        );
      case ChannelConstants.eventExecutionProgress:
        return ExecutionProgressEvent(
          currentLoop: (raw['currentLoop'] as num?)?.toInt() ?? 0,
          totalLoops: (raw['totalLoops'] as num?)?.toInt() ?? 0,
          targetIndex: (raw['targetIndex'] as num?)?.toInt() ?? 0,
        );
      case ChannelConstants.eventEmergencyStop:
        return EmergencyStopEvent(
          reason: raw['reason'] as String? ?? 'Unknown Reason',
        );
      default:
        return UnknownNativeEvent(raw);
    }
  }

  Future<PermissionStatusModel> checkPermissions() async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        ChannelConstants.methodCheckPermissions,
      );
      if (result != null) {
        return PermissionStatusModel.fromMap(result);
      }
    } on PlatformException {
      // Fallback on error
    }
    return const PermissionStatusModel(
      hasOverlayPermission: false,
      hasAccessibilityPermission: false,
    );
  }

  Future<bool> requestOverlayPermission() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.methodRequestOverlayPermission,
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> requestAccessibilityPermission() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.methodRequestAccessibilityPermission,
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> startOverlay(Map<String, dynamic> profileData) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.methodStartOverlay,
        profileData,
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> stopOverlay() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.methodStopOverlay,
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> syncTargets(List<Map<String, dynamic>> targets) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.methodSyncTargets,
        targets,
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> updateLoopConfig(Map<String, dynamic> loopConfig) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.methodUpdateLoopConfig,
        loopConfig,
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> startExecution() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.methodStartExecution,
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> pauseExecution() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.methodPauseExecution,
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<String> getServiceStatus() async {
    try {
      final result = await _methodChannel.invokeMethod<String>(
        ChannelConstants.methodGetServiceStatus,
      );
      return result ?? 'IDLE';
    } on PlatformException {
      return 'ERROR';
    }
  }
}
