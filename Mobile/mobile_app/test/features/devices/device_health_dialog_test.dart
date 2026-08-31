import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/features/pages/devices_page.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('device dialog uses unwrapped farm API responses', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox.expand(
              child: DeviceHealthDialog(
                device: DeviceItem(
                  id: '153',
                  name: 'TB-89',
                  type: DeviceType.rumenCapsule,
                  status: DeviceStatus.online,
                  boundLivestockCode: 'HKT33',
                ),
                healthLoader: _loadHealth,
                seriesLoader: _loadSeries,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('设备健康分'), findsOneWidget);
    expect(find.text('HEALTHY'), findsOneWidget);
    expect(find.text('72小时温度曲线'), findsOneWidget);
    expect(find.text('24小时蠕动曲线'), findsOneWidget);
    expect(find.text('加载失败'), findsNothing);
  });
}

Future<Map<String, dynamic>> _loadHealth(String deviceId) async {
  expect(deviceId, '153');
  return {
    'deviceId': 153,
    'score': 80,
    'grade': 'HEALTHY',
    'dimensions': {'battery': 100},
  };
}

Future<Map<String, dynamic>> _loadSeries(String deviceId) async {
  expect(deviceId, '153');
  return {
    'deviceId': '153',
    'temperature72h': [
      {'temperature': 30.2, 'timestamp': '2026-08-31T06:00:00Z'},
    ],
    'motility24h': [
      {'frequency': 3.2, 'intensity': 0, 'timestamp': '2026-08-31T06:00:00Z'},
    ],
  };
}
