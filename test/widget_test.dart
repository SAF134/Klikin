import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klikin/core/constants/channel_constants.dart';
import 'package:klikin/domain/entities/click_profile.dart';
import 'package:klikin/domain/repositories/i_profile_repository.dart';
import 'package:klikin/main.dart';
import 'package:klikin/services/platform_bridge_service.dart';

class FakeProfileRepository implements IProfileRepository {
  final List<ClickProfile> _profiles = [];

  @override
  Future<void> deleteProfile(String id) async {
    _profiles.removeWhere((p) => p.id == id);
  }

  @override
  Future<ClickProfile?> getProfileById(String id) async {
    try {
      return _profiles.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ClickProfile>> getProfiles() async {
    return _profiles;
  }

  @override
  Future<void> saveProfile(ClickProfile profile) async {
    _profiles.add(profile);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel(ChannelConstants.controllerChannel),
      (MethodCall methodCall) async {
        if (methodCall.method == ChannelConstants.methodCheckPermissions) {
          return {
            'hasOverlayPermission': true,
            'hasAccessibilityPermission': true,
          };
        }
        return true;
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

  testWidgets('KlikinApp renders DashboardScreen smoke test', (WidgetTester tester) async {
    final fakeRepo = FakeProfileRepository();
    final bridgeService = PlatformBridgeService();

    await tester.pumpWidget(KlikinApp(
      bridgeService: bridgeService,
      profileRepository: fakeRepo,
    ));

    await tester.pumpAndSettle();

    expect(find.text('Klikin'), findsOneWidget);
    expect(find.text('MODE OPERASI'), findsOneWidget);
    expect(find.text('Single-Point'), findsOneWidget);
    expect(find.text('Multi-Point'), findsOneWidget);
  });
}
