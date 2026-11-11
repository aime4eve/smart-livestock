import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/alert_detail_sheet.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// NIX-286 widget tests for the estrus confirm/reject actions inside the
// legacy (ranch page) alert detail sheet. The sheet refreshes its detail via
// GET /alerts/{id} on open, so the MockClient must answer both the detail
// fetch and the estrus-feedback POST.

class _FakeSessionController extends SessionController {
  @override
  AppSession build() => const AppSession.authenticated(
        role: UserRole.owner,
        accessToken: 'test-token',
        userId: 1,
        userName: 'Test User',
        phone: '13800138000',
        tenantId: 1,
        username: 'testuser',
        activeFarmId: '7',
      );
}

AlertItem _alert({String type = 'ESTRUS', String stage = 'active'}) {
  return AlertItem(
    id: '101',
    title: 'SL-7 发情检测告警',
    subtitle: '',
    priority: 'P1',
    type: type,
    stage: stage,
    livestockCode: 'SL-7',
  );
}

/// Detail payload the sheet's open-time GET resolves to (type/status kept
/// consistent with the tapped alert so the actions stay visible).
Map<String, dynamic> _detailJson(AlertItem alert) {
  return {
    'id': alert.id,
    'message': alert.title,
    'type': alert.type,
    'status': alert.stage.toUpperCase(),
    'severity': alert.severity,
    'source': alert.source,
    'livestockId': alert.livestockCode,
    'read': alert.read,
  };
}

http.Client _mockClient({
  required AlertItem detailAlert,
  Map<String, dynamic>? feedbackResponse,
  void Function(Uri url, Map<String, dynamic> body)? onFeedbackPost,
}) {
  return MockClient((req) async {
    if (req.method == 'POST' && req.url.path.endsWith('/estrus-feedback')) {
      onFeedbackPost?.call(
        req.url,
        jsonDecode(req.body) as Map<String, dynamic>,
      );
      return http.Response(
        jsonEncode(
          feedbackResponse ??
              {
                'code': 'OK',
                'data': {'alertId': '101', 'verdict': 'CONFIRMED'},
              },
        ),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    if (req.method == 'GET' && req.url.path.endsWith('/alerts/101')) {
      return http.Response(
        jsonEncode({'code': 'OK', 'data': _detailJson(detailAlert)}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    return http.Response(jsonEncode({'code': 'NOT_FOUND'}), 404);
  });
}

/// Pumps the sheet under the given mock HTTP client. [interact] runs inside
/// the `http.runWithClient` zone — any tap that triggers an API call must
/// stay inside it, or the call bypasses the MockClient.
Future<void> _pumpSheet(
  WidgetTester tester,
  AlertItem alert, {
  required http.Client Function() clientFactory,
  Future<void> Function(WidgetTester tester)? interact,
}) async {
  await http.runWithClient(() async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(() => _FakeSessionController()),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AlertDetailSheet(alert: alert, role: UserRole.owner),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (interact != null) {
      await interact(tester);
      await tester.pumpAndSettle();
    }
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

  testWidgets('active ESTRUS alert shows confirm/reject actions', (tester) async {
    await _pumpSheet(
      tester,
      _alert(),
      clientFactory: () => _mockClient(detailAlert: _alert()),
    );
    expect(find.text('确认发情'), findsOneWidget);
    expect(find.text('不是发情'), findsOneWidget);
  });

  testWidgets('non-ESTRUS alert shows no confirm/reject actions', (
    tester,
  ) async {
    final fever = _alert(type: 'TEMPERATURE_ABNORMAL');
    await _pumpSheet(
      tester,
      fever,
      clientFactory: () => _mockClient(detailAlert: fever),
    );
    expect(find.text('确认发情'), findsNothing);
    expect(find.text('不是发情'), findsNothing);
  });

  testWidgets(
    'confirm flow posts to the estrus-feedback endpoint and shows success',
    (tester) async {
      final capturedPosts = <Uri>[];
      final capturedBodies = <Map<String, dynamic>>[];
      await _pumpSheet(
        tester,
        _alert(),
        clientFactory: () => _mockClient(
          detailAlert: _alert(),
          feedbackResponse: {
            'code': 'OK',
            'data': {
              'alertId': '101',
              'verdict': 'CONFIRMED',
              'physiologyEventId': 55,
              'labelId': 9,
              'idempotent': false,
            },
          },
          onFeedbackPost: (url, body) {
            capturedPosts.add(url);
            capturedBodies.add(body);
          },
        ),
        interact: (tester) async {
          await tester.tap(find.text('确认发情'));
          await tester.pumpAndSettle();
          expect(find.text('确认发情？'), findsOneWidget);
          await tester.tap(find.text('确认'));
          await tester.pumpAndSettle();
        },
      );

      expect(capturedPosts, hasLength(1));
      expect(
        capturedPosts.single.path,
        endsWith('/farms/7/alerts/101/estrus-feedback'),
      );
      expect(capturedBodies.single, {'confirmed': true});
      expect(find.text('已确认发情'), findsOneWidget);
      // Buttons hide after the accepted verdict (local submitted marker).
      expect(find.text('确认发情'), findsNothing);
      expect(find.text('不是发情'), findsNothing);
    },
  );
}
