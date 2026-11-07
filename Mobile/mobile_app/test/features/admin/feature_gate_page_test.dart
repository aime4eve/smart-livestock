import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/admin/feature_gate/presentation/feature_gate_page.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// NIX-389 Task 3: locked-tile policy card on the feature-gate admin page.
/// ApiClient's top-level `http.get/put` honour `http.runWithClient`, so a
/// MockClient speaking the real envelope ({"code":"OK","data":…}) replaces
/// the network — a real HttpServer cannot complete inside the fake-async
/// widget-test zone (same pattern as subscription_health_page_test).
void main() {
  final capturedPuts = <({String path, Map<String, dynamic> body})>[];
  String policy = 'SHOW_LOCKED';
  bool failPut = false;

  setUp(() {
    capturedPuts.clear();
    policy = 'SHOW_LOCKED';
    failPut = false;
    FlutterSecureStorage.setMockInitialValues({});
  });

  http.Client mockClient() => MockClient((req) async {
        if (req.url.path.endsWith('platform/display-settings')) {
          if (req.method == 'PUT') {
            if (failPut) {
              return http.Response(
                jsonEncode({
                  'code': 'VALIDATION_ERROR',
                  'message': '非法策略',
                }),
                400,
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            }
            final body = jsonDecode(req.body) as Map<String, dynamic>;
            capturedPuts.add((path: req.url.path, body: body));
            policy = body['lockedTilePolicy'] as String;
            return http.Response(
              jsonEncode({
                'code': 'OK',
                'data': {'lockedTilePolicy': policy},
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          return http.Response(
            jsonEncode({
              'code': 'OK',
              'data': {'lockedTilePolicy': policy},
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        // Feature gates list backing the tier tabs (empty is fine here).
        return http.Response(
          jsonEncode({'code': 'OK', 'data': {'value': []}}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FeatureGatePage(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// Runs [body] with the mocked HTTP client bound to the test zone.
  Future<void> withMock(Future<void> Function() body) =>
      http.runWithClient(body, mockClient);

  SegmentedButton<String> segments(WidgetTester tester) =>
      tester.widget(find.byKey(const Key('locked-tile-policy-segments')));

  testWidgets('renders the loaded policy as the selected segment',
      (tester) => withMock(() async {
            policy = 'HIDE';
            await pumpPage(tester);
            expect(find.byKey(const Key('locked-tile-policy-card')),
                findsOneWidget);
            expect(find.text('锁定瓷片显示策略'), findsOneWidget);
            expect(find.text('显示锁定瓷片'), findsOneWidget);
            expect(find.text('隐藏锁定瓷片'), findsOneWidget);
            expect(segments(tester).selected, {'HIDE'});
          }));

  testWidgets('switching a segment PUTs the policy and toasts success',
      (tester) => withMock(() async {
            await pumpPage(tester);
            expect(segments(tester).selected, {'SHOW_LOCKED'});

            await tester.tap(find.text('隐藏锁定瓷片'));
            await tester.pumpAndSettle();

            expect(capturedPuts, hasLength(1));
            expect(capturedPuts.single.path,
                '/api/v1/admin/platform/display-settings');
            expect(capturedPuts.single.body, {'lockedTilePolicy': 'HIDE'});
            expect(segments(tester).selected, {'HIDE'});
            expect(find.text('锁定瓷片显示策略已更新'), findsOneWidget);
          }));

  testWidgets('a failed PUT rolls the selection back and toasts the failure',
      (tester) => withMock(() async {
            await pumpPage(tester);
            failPut = true;

            await tester.tap(find.text('隐藏锁定瓷片'));
            await tester.pumpAndSettle();

            expect(capturedPuts, isEmpty,
                reason: 'the rejected PUT must not be captured as saved');
            expect(segments(tester).selected, {'SHOW_LOCKED'},
                reason: 'the selection rolls back to the previous policy');
            expect(find.text('非法策略'), findsOneWidget,
                reason: 'the backend localized message wins the toast');
          }));
}
