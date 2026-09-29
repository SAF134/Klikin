class ChannelConstants {
  static const String controllerChannel = 'com.klikin.app/controller';
  static const String eventsChannel = 'com.klikin.app/events';

  // Method names
  static const String methodCheckPermissions = 'checkPermissions';
  static const String methodRequestOverlayPermission = 'requestOverlayPermission';
  static const String methodRequestAccessibilityPermission = 'requestAccessibilityPermission';
  static const String methodStartOverlay = 'startOverlay';
  static const String methodStopOverlay = 'stopOverlay';
  static const String methodSyncTargets = 'syncTargets';
  static const String methodUpdateLoopConfig = 'updateLoopConfig';
  static const String methodStartExecution = 'startExecution';
  static const String methodPauseExecution = 'pauseExecution';
  static const String methodGetServiceStatus = 'getServiceStatus';

  // Event types
  static const String eventStateChanged = 'STATE_CHANGED';
  static const String eventTargetCoordinatesChanged = 'TARGET_COORDINATES_CHANGED';
  static const String eventExecutionProgress = 'EXECUTION_PROGRESS';
  static const String eventEmergencyStop = 'EMERGENCY_STOP';
}
