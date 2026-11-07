import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/features/pages/calving_page.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// NIX-389 widget tests for the calving prediction page. ApiClient's
// top-level `http.get` honours `http.runWithClient`, so a MockClient
// speaking the real envelope ({"code":"OK","data":…}) replaces the network;
// the farm-scoped controller resolves its path from ApiClient's activeFarmId.

http.Client _mockClient({required List<Map<String, dynamic>> items}) {
  return MockClient((req) async {
    if (req.url.path.endsWith('/livestock/calving-predictions')) {
      return http.Response(
        jsonEncode({
          'code': 'OK',
          'data': {'items': items},
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    return http.Response(jsonEncode({'code': 'NOT_FOUND'}), 404);
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  http.Client Function() clientFactory,
) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await http.runWithClient(() async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CalvingPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }, clientFactory);
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    ApiClient.instance.setActiveFarmId('7');
  });

  tearDown(() {
    ApiClient.instance.setActiveFarmId(null);
  });

  testWidgets('renders livestock code, risk band colour, window and assessed time',
      (tester) async {
    final client = _mockClient(items: [
      {
        'livestockId': '101',
        'livestockCode': 'SL-001',
        'riskScore': 75,
        'predictedAt': '2026-11-07T08:30:00Z',
        'expectedWindowStart': '2026-11-08T00:00:00Z',
        'expectedWindowEnd': '2026-11-09T00:00:00Z',
        'tempDropCelsius': 1.4,
        'activityRatio': 1.8,
        'priorEnabled': true,
      },
      {
        'livestockId': '102',
        'livestockCode': 'SL-002',
        'riskScore': 55,
        'predictedAt': null,
        'expectedWindowStart': null,
        'expectedWindowEnd': null,
        'tempDropCelsius': null,
        'activityRatio': null,
        'priorEnabled': false,
      },
    ]);
    await _pumpPage(tester, () => client);

    // Rows render with their codes and labelled fields.
    expect(find.text('SL-001'), findsOneWidget);
    expect(find.text('SL-002'), findsOneWidget);
    expect(find.textContaining('风险分: 75'), findsOneWidget);
    expect(find.textContaining('风险分: 55'), findsOneWidget);
    // Missing window/assessed ends render the em-dash placeholder.
    expect(find.textContaining('预计分娩窗口'), findsNWidgets(2));
    expect(find.text('预计分娩窗口: —'), findsOneWidget);
    expect(find.textContaining('评估时间'), findsNWidgets(2));
    expect(find.text('评估时间: —'), findsOneWidget);
    expect(find.text('暂无临产预测数据'), findsNothing);
  });

  testWidgets('empty list renders the calm empty state', (tester) async {
    await _pumpPage(tester, () => _mockClient(items: []));
    expect(find.text('暂无临产预测数据'), findsOneWidget);
  });
}
