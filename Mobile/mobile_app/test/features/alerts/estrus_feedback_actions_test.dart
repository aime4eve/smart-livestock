import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/features/alerts/data/alerts_api_repository.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alerts_repository.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/estrus_feedback_actions.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// NIX-286 widget tests for the estrus confirm/reject actions widget.
// ApiClient's top-level `http` calls honour `http.runWithClient`, so a
// MockClient speaking the real envelope ({"code":"OK","data":…}) replaces the
// network when the flow is exercised through the real AlertsApiRepository.

Future<void> _pumpActions(
  WidgetTester tester, {
  required Future<AlertFeedbackResult> Function(
    String alertId, {
    required bool confirmed,
  }) onSubmit,
  bool enabled = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: EstrusFeedbackActions(
          alertId: '101',
          onSubmit: onSubmit,
          enabled: enabled,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Taps the confirm trigger and accepts the confirmation dialog.
Future<void> _confirmThroughDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('estrus-confirm-101')));
  await tester.pumpAndSettle();
  // Mistouch protection: the dialog is up before any submission.
  expect(find.text('确认发情？'), findsOneWidget);
  await tester.tap(find.text('确认'));
  await tester.pumpAndSettle();
}

Future<void> _rejectThroughDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('estrus-reject-101')));
  await tester.pumpAndSettle();
  expect(find.text('不是发情？'), findsOneWidget);
  await tester.tap(find.text('确认'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    ApiClient.instance.setActiveFarmId('7');
  });

  tearDown(() {
    ApiClient.instance.setActiveFarmId(null);
  });

  testWidgets('renders confirm and reject buttons for ESTRUS alert', (
    tester,
  ) async {
    await _pumpActions(
      tester,
      onSubmit: (alertId, {required confirmed}) async {
        throw UnimplementedError();
      },
    );
    expect(find.text('确认发情'), findsOneWidget);
    expect(find.text('不是发情'), findsOneWidget);
  });

  testWidgets(
    'confirm flow: dialog → API path/body correct via real repository → '
    'success snackbar → buttons disappear',
    (tester) async {
      final capturedUrls = <Uri>[];
      final capturedBodies = <Map<String, dynamic>>[];
      final client = MockClient((req) async {
        capturedUrls.add(req.url);
        capturedBodies.add(jsonDecode(req.body) as Map<String, dynamic>);
        return http.Response(
          jsonEncode({
            'code': 'OK',
            'data': {
              'alertId': '101',
              'verdict': 'CONFIRMED',
              'physiologyEventId': 55,
              'labelId': 9,
              'idempotent': false,
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      await http.runWithClient(() async {
        await _pumpActions(
          tester,
          onSubmit: (alertId, {required confirmed}) => const AlertsApiRepository()
              .submitEstrusFeedback('7', alertId, confirmed: confirmed),
        );
        await _confirmThroughDialog(tester);
      }, () => client);

      // Endpoint + body contract: POST /farms/{farmId}/alerts/{alertId}/
      // estrus-feedback with {"confirmed": true} (NIX-286 T2).
      expect(capturedUrls, hasLength(1));
      expect(
        capturedUrls.single.path,
        endsWith('/farms/7/alerts/101/estrus-feedback'),
      );
      expect(capturedBodies.single, {'confirmed': true});
      // Success copy (confirmed variant, not reject/duplicate).
      expect(find.text('已确认发情'), findsOneWidget);
      expect(find.text('已标记为不是发情'), findsNothing);
      expect(find.text('已提交过相同结论'), findsNothing);
      // Local submitted marker hides both buttons after success.
      expect(find.byKey(const Key('estrus-confirm-101')), findsNothing);
      expect(find.byKey(const Key('estrus-reject-101')), findsNothing);
    },
  );

  testWidgets(
    'reject flow: dialog → API body {"confirmed": false} → reject snackbar',
    (tester) async {
      final capturedBodies = <Map<String, dynamic>>[];
      final client = MockClient((req) async {
        capturedBodies.add(jsonDecode(req.body) as Map<String, dynamic>);
        return http.Response(
          jsonEncode({
            'code': 'OK',
            'data': {
              'alertId': '101',
              'verdict': 'REJECTED',
              'physiologyEventId': null,
              'labelId': null,
              'idempotent': false,
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      await http.runWithClient(() async {
        await _pumpActions(
          tester,
          onSubmit: (alertId, {required confirmed}) => const AlertsApiRepository()
              .submitEstrusFeedback('7', alertId, confirmed: confirmed),
        );
        await _rejectThroughDialog(tester);
      }, () => client);

      expect(capturedBodies.single, {'confirmed': false});
      expect(find.text('已标记为不是发情'), findsOneWidget);
    },
  );

  testWidgets('server error surfaces the backend message, buttons stay', (
    tester,
  ) async {
    final client = MockClient((req) async {
      return http.Response(
        jsonEncode({'code': 'VALIDATION', 'message': '发情告警不存在'}),
        400,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    await http.runWithClient(() async {
      await _pumpActions(
        tester,
        onSubmit: (alertId, {required confirmed}) => const AlertsApiRepository()
            .submitEstrusFeedback('7', alertId, confirmed: confirmed),
      );
      await _confirmThroughDialog(tester);
    }, () => client);

    // The server-side i18n message is shown verbatim (no raw exception text).
    expect(find.text('发情告警不存在'), findsOneWidget);
    // Failure keeps the buttons for retry.
    expect(find.byKey(const Key('estrus-confirm-101')), findsOneWidget);
    expect(find.byKey(const Key('estrus-reject-101')), findsOneWidget);
  });

  testWidgets('non-API failure shows generic copy without leaking raw error', (
    tester,
  ) async {
    await _pumpActions(
      tester,
      onSubmit: (alertId, {required confirmed}) async {
        throw Exception('boom network stack');
      },
    );
    await _confirmThroughDialog(tester);

    expect(find.textContaining('boom'), findsNothing);
    expect(find.text('反馈提交失败，请稍后重试'), findsOneWidget);
    expect(find.byKey(const Key('estrus-confirm-101')), findsOneWidget);
  });

  testWidgets('idempotent repeat shows the duplicate verdict copy', (
    tester,
  ) async {
    await _pumpActions(
      tester,
      onSubmit: (alertId, {required confirmed}) async {
        return AlertFeedbackResult(
          alertId: alertId,
          verdict: 'CONFIRMED',
          idempotent: true,
        );
      },
    );
    await _confirmThroughDialog(tester);

    expect(find.text('已提交过相同结论'), findsOneWidget);
    expect(find.text('已确认发情'), findsNothing);
  });

  testWidgets('buttons show spinner and ignore taps while submitting', (
    tester,
  ) async {
    final completer = Completer<AlertFeedbackResult>();
    var callCount = 0;
    await _pumpActions(
      tester,
      onSubmit: (alertId, {required confirmed}) {
        callCount++;
        return completer.future;
      },
    );
    await tester.tap(find.byKey(const Key('estrus-confirm-101')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认'));
    await tester.pump();

    // Loading state: spinner replaces the labels and taps are swallowed.
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    await tester.tap(find.byKey(const Key('estrus-reject-101')));
    await tester.pump();
    expect(callCount, 1);

    completer.complete(
      const AlertFeedbackResult(alertId: '101', verdict: 'CONFIRMED'),
    );
    await tester.pumpAndSettle();
    expect(find.text('已确认发情'), findsOneWidget);
  });

  testWidgets('enabled=false buttons never trigger a submission', (
    tester,
  ) async {
    var called = false;
    await _pumpActions(
      tester,
      enabled: false,
      onSubmit: (alertId, {required confirmed}) async {
        called = true;
        return AlertFeedbackResult(alertId: alertId, verdict: 'CONFIRMED');
      },
    );
    await tester.tap(
      find.byKey(const Key('estrus-confirm-101')),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('estrus-reject-101')),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(called, isFalse);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
