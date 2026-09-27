import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klikin/core/constants/channel_constants.dart';
import 'package:klikin/services/platform_bridge_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlatformBridgeService bridgeService;
  final List<MethodCall> log = <MethodCall>[];

  setUp(() {
    log.clear();
    bridgeService = PlatformBridgeService();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel(ChannelConstants.controllerChannel),
      (MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case ChannelConstants.methodCheckPermissions:
            return <String, bool>{
              'hasOverlayPermission': true,
              'hasAccessibilityPermission': true,
            };
          case ChannelConstants.methodRequestOverlayPermission:
          case ChannelConstants.methodRequestAccessibilityPermission:
          case ChannelConstants.methodStartOverlay:
          case ChannelConstants.methodStopOverlay:
          case ChannelConstants.methodSyncTargets:
          case ChannelConstants.methodUpdateLoopConfig:
          case ChannelConstants.methodStartExecution:
          case ChannelConstants.methodPauseExecution:
            return true;
          case ChannelConstants.methodGetServiceStatus:
            return 'RUNNING';
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel(ChannelConstants.controllerChannel),
      null,
    );
  });

  test('checkPermissions returns granted permissions accurately', () async {
    final status = await bridgeService.checkPermissions();
    expect(status.hasOverlayPermission, isTrue);
    expect(status.hasAccessibilityPermission, isTrue);
    expect(status.isAllGranted, isTrue);
    expect(log.single.method, ChannelConstants.methodCheckPermissions);
  });

  test('startOverlay invokes channel with profile data', () async {
    final payload = {
      'profileId': 'test_1',
      'targets': [
        {'x': 100, 'y': 200, 'pressDurationMs': 50, 'delayAfterMs': 300}
      ]
    };
    final success = await bridgeService.startOverlay(payload);
    expect(success, isTrue);
    expect(log.single.method, ChannelConstants.methodStartOverlay);
    expect(log.single.arguments, payload);
  });

  test('getServiceStatus returns RUNNING', () async {
    final status = await bridgeService.getServiceStatus();
    expect(status, 'RUNNING');
    expect(log.single.method, ChannelConstants.methodGetServiceStatus);
  });
}
