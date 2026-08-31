import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_device_tile.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

DeviceItem _device(DeviceType type) => DeviceItem(
  id: '7',
  name: 'DEV-007',
  type: type,
  status: DeviceStatus.online,
  boundLivestockCode: '',
);

void main() {
  Future<void> pumpTile(
    WidgetTester tester, {
    required DeviceType type,
    VoidCallback? onViewHealth,
    VoidCallback? onViewTrajectory,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HighfiDeviceTile(
            device: _device(type),
            onViewHealth: onViewHealth,
            onViewTrajectory: onViewTrajectory,
          ),
        ),
      ),
    );
  }

  testWidgets('capsule hides GPS actions and shows health action', (
    tester,
  ) async {
    await pumpTile(tester, type: DeviceType.rumenCapsule, onViewHealth: () {});

    expect(find.byKey(const Key('device-trajectory-7')), findsNothing);
    expect(find.byKey(const Key('device-locate-7')), findsNothing);
    expect(find.byKey(const Key('device-health-7')), findsOneWidget);
    expect(find.text('查看健康数据'), findsOneWidget);
  });

  testWidgets('ear tag shows trajectory action', (tester) async {
    await pumpTile(tester, type: DeviceType.earTag, onViewTrajectory: () {});

    expect(find.byKey(const Key('device-trajectory-7')), findsOneWidget);
    expect(find.byKey(const Key('device-health-7')), findsNothing);
  });

  test('device type GPS capability', () {
    expect(DeviceType.gps.supportsGps, isTrue);
    expect(DeviceType.earTag.supportsGps, isTrue);
    expect(DeviceType.rumenCapsule.supportsGps, isFalse);
  });
}
