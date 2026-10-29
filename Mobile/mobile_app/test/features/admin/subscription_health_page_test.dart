import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/admin/presentation/subscription_health_page.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// NIX-324 fidelity D4/D5/D6 for the admin overview page. ApiClient's
/// top-level `http.get` honours `http.runWithClient`, so a MockClient
/// speaking the real envelope ({"code":"OK","data":…}) replaces the
/// network without sockets — a real HttpServer cannot complete inside the
/// fake-async widget-test zone (its IO callbacks bind to the fake zone).
/// D4 legend footer (four dots + total note), D5 eight filter chips +
/// tenant search, D6 localised zh pill labels + health/keyword/size params.
void main() {
  final capturedQueries = <String>[];
  final capturedPuts = <({String path, Map<String, dynamic>? body})>[];

  setUp(() {
    capturedQueries.clear();
    capturedPuts.clear();
    FlutterSecureStorage.setMockInitialValues({});
  });

  http.Client mockClient() => MockClient((req) async {
        if (req.method == 'PUT') {
          capturedPuts.add((
            path: req.url.path,
            body: jsonDecode(req.body) as Map<String, dynamic>?,
          ));
          return http.Response(
            jsonEncode({
              'code': 'OK',
              'data': {'id': 33},
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        capturedQueries.add(req.url.query);
        final items = [
          {
            'tenantId': 2,
            'subscriptionId': 22,
            'tenantName': '南非-市场',
            'tier': 'PREMIUM',
            'healthStatus': 'EXPIRED',
            'daysToExpiry': null,
            'sameDayGroup': false,
            'exportWindow': {'daysLeft': 19},
          },
          {
            'tenantId': 3,
            'subscriptionId': 33,
            'tenantName': 'Demo Ranch',
            'tier': 'PREMIUM',
            'healthStatus': 'RENEWAL_FAILED',
            'daysToExpiry': null,
            'sameDayGroup': false,
          },
          {
            'tenantId': 4,
            'subscriptionId': 44,
            'tenantName': '肯尼亚试点',
            'tier': 'BASIC',
            'healthStatus': 'TRIAL',
            'daysToExpiry': 5,
            'sameDayGroup': true,
          },
          {
            'tenantId': 5,
            'subscriptionId': 55,
            'tenantName': '暂停租户',
            'tier': 'STANDARD',
            'healthStatus': 'SUSPENDED',
            'daysToExpiry': null,
            'sameDayGroup': false,
          },
          {
            'tenantId': 6,
            'subscriptionId': 66,
            'tenantName': '临期租户',
            'tier': 'PREMIUM',
            'healthStatus': 'EXPIRING_SOON',
            'level': 7,
            'daysToExpiry': 7,
            'sameDayGroup': false,
          },
        ];
        return http.Response(
          jsonEncode({
            'code': 'OK',
            'data': {'items': items, 'page': 1, 'pageSize': 100, 'total': 8},
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SubscriptionHealthPage(),
    ));
    await tester.pumpAndSettle();
  }

  /// Runs [body] with the mocked HTTP client bound to the test zone.
  Future<void> withMock(Future<void> Function() body) =>
      http.runWithClient(body, mockClient);

  testWidgets('D5: eight filter chips + search box; backend gets size=100',
      (tester) => withMock(() async {
            await pumpPage(tester);
            for (final f in [
              'all',
              'EXPIRING_SOON',
              'EXPIRED',
              'RENEWAL_FAILED',
              'CANCELLED',
              'SUSPENDED',
              'TRIAL',
              'HEALTHY',
            ]) {
              expect(find.byKey(Key('health-filter-$f')), findsOneWidget,
                  reason: 'filter chip $f missing');
            }
            expect(find.byKey(const Key('health-keyword')), findsOneWidget);
            expect(capturedQueries, isNotEmpty);
            expect(capturedQueries.first, contains('size=100'),
                reason: 'D6 fix: backend param is size, not pageSize');
            expect(capturedQueries.first, contains('health=all'));
          }));

  testWidgets('D4: legend footer four colour dots + total note',
      (tester) => withMock(() async {
            await pumpPage(tester);
            final legendWrap = find.byType(Wrap).first;
            final dotColors = tester
                .widgetList<Container>(find.descendant(
                    of: legendWrap, matching: find.byType(Container)))
                .where((c) =>
                    (c.decoration as BoxDecoration?)?.shape == BoxShape.circle)
                .map((c) => (c.decoration as BoxDecoration).color!.toARGB32())
                .toList();
            expect(dotColors, [0xFF4C9A5F, 0xFFD28A2D, 0xFFC2564B, 0xFF4A7F9D]);
            expect(find.text('健康（>14 天）'), findsOneWidget);
            expect(find.text('临期（14/7/3 分级）'), findsOneWidget);
            expect(find.text('已到期降档'), findsOneWidget);
            expect(find.text('待补缴可复活 / 试点'), findsOneWidget);
            expect(
                tester.widget<Text>(find.byKey(const Key('health-total'))).data,
                contains('共 8 个租户'));
          }));

  testWidgets('D6: zh pill labels per health status',
      (tester) => withMock(() async {
            await pumpPage(tester);
            expect(
                find.descendant(
                    of: find.byKey(const Key('health-row-2')),
                    matching: find.text('已到期')),
                findsOneWidget);
            expect(
                find.descendant(
                    of: find.byKey(const Key('health-row-3')),
                    matching: find.text('待补缴')),
                findsOneWidget);
            expect(
                find.descendant(
                    of: find.byKey(const Key('health-row-4')),
                    matching: find.text('试点中')),
                findsOneWidget);
            // EXPIRED row surfaces the NIX-325 export window countdown.
            expect(find.byKey(const Key('health-export-window')),
                findsOneWidget);
          }));

  testWidgets('chip tap and keyword submit re-query with params',
      (tester) => withMock(() async {
            await pumpPage(tester);
            await tester
                .tap(find.byKey(const Key('health-filter-EXPIRING_SOON')));
            await tester.pumpAndSettle();
            expect(capturedQueries.last, contains('health=EXPIRING_SOON'));

            await tester.enterText(
                find.byKey(const Key('health-keyword')), 'Demo');
            await tester.testTextInput.receiveAction(TextInputAction.done);
            await tester.pumpAndSettle();
            expect(capturedQueries.last, contains('keyword=Demo'));
            expect(capturedQueries.last, contains('health=EXPIRING_SOON'));
          }));

  testWidgets('NIX-334: ops column renders per health status',
      (tester) => withMock(() async {
            await pumpPage(tester);
            expect(find.byKey(const Key('health-action-repay')),
                findsOneWidget); // RENEWAL_FAILED row
            expect(find.byKey(const Key('health-action-restore')),
                findsOneWidget); // SUSPENDED row
            expect(find.byKey(const Key('health-action-convert')),
                findsOneWidget); // TRIAL row
            expect(find.byKey(const Key('health-action-renew')),
                findsOneWidget); // EXPIRED row
            expect(find.byKey(const Key('health-action-disabled')),
                findsOneWidget); // EXPIRING_SOON row
            expect(find.text('协助补缴'), findsOneWidget);
            expect(find.text('恢复服务'), findsOneWidget);
            expect(find.text('转正式引导'), findsOneWidget);
            expect(find.text('跟进续费'), findsOneWidget);
            expect(find.text('发送续费提醒'), findsOneWidget);
          }));

  testWidgets('NIX-334: assist repayment confirm dialog issues PUT ACTIVE '
      'and reloads', (tester) => withMock(() async {
            await pumpPage(tester);
            final queriesBefore = capturedQueries.length;

            await tester.tap(find.byKey(const Key('health-action-repay')));
            await tester.pumpAndSettle();
            expect(find.text('确认协助补缴？'), findsOneWidget);

            await tester.tap(find.widgetWithText(TextButton, '确认'));
            await tester.pumpAndSettle();

            expect(capturedPuts, hasLength(1));
            expect(capturedPuts.single.path,
                '/api/v1/admin/subscriptions/33/status');
            expect(capturedPuts.single.body, {'targetStatus': 'ACTIVE'});
            expect(find.text('操作成功'), findsOneWidget);
            expect(capturedQueries.length, greaterThan(queriesBefore),
                reason: 'the list reloads after a successful write');
          }));

  testWidgets('NIX-334: cancelling the dialog issues no write',
      (tester) => withMock(() async {
            await pumpPage(tester);
            await tester.tap(find.byKey(const Key('health-action-repay')));
            await tester.pumpAndSettle();
            await tester.tap(find.widgetWithText(TextButton, '取消'));
            await tester.pumpAndSettle();
            expect(capturedPuts, isEmpty);
          }));
}
