import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alert_workbench.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alerts_repository.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/alert_workbench_detail_sheet.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/alert_workbench_view.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

WorkbenchItem _item({
  String id = 'fence-1',
  String bucket = 'immediate',
  String asset = 'fence',
  bool unread = true,
  String reasonType = 'FENCE_BREACH',
  String reasonAlertId = '101',
}) {
  return WorkbenchItem(
    id: id,
    bucket: bucket,
    asset: WorkbenchAsset(
      kind: asset,
      id: '3',
      name: asset == 'fence' ? 'North fence' : 'SL-7',
      subtitle: '',
    ),
    title: 'SL-7 breached North fence',
    subtitle: '',
    severity: 'CRITICAL',
    unread: unread,
    occurredAt: DateTime.parse('2026-09-25T01:00:00Z'),
    resolvedAt: null,
    resolvedType: null,
    reasons: [
      WorkbenchReason(
        alertId: reasonAlertId,
        type: reasonType,
        severity: 'CRITICAL',
        message: 'SL-7 breached the fence',
        occurredAt: null,
        read: false,
      ),
    ],
    ai: null,
    actions: const ['VIEW_FENCE', 'MARK_READ', 'DISMISS'],
    targetRoute: '/alerts?asset=fence',
  );
}

AlertWorkbenchData _data() {
  return AlertWorkbenchData(
    summary: const WorkbenchSummary(
      buckets: [
        WorkbenchBucket(key: 'immediate', total: 1, unread: 1),
        WorkbenchBucket(key: 'field', total: 2, unread: 1),
        WorkbenchBucket(key: 'observe', total: 3, unread: 0),
        WorkbenchBucket(key: 'resolved', total: 4, unread: 0),
      ],
      assets: [
        WorkbenchAssetCount(key: 'livestock', total: 1, unread: 1),
        WorkbenchAssetCount(key: 'herd', total: 0, unread: 0),
        WorkbenchAssetCount(key: 'fence', total: 1, unread: 1),
        WorkbenchAssetCount(key: 'device', total: 1, unread: 0),
      ],
    ),
    items: [_item()],
    page: 1,
    pageSize: 50,
    total: 1,
  );
}

void main() {
  testWidgets('renders four buckets, unread state, and asset card', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AlertWorkbenchView(
            data: _data(),
            selectedBucket: 'all',
            selectedAsset: const {'all'},
            onBucket: (_) {},
            onAsset: (_) {},
            onItem: (_) => opened = true,
            onLoadMore: () {},
            onRanking: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Immediate'), findsWidgets);
    expect(find.text('Field check'), findsOneWidget);
    expect(find.text('Observe'), findsOneWidget);
    expect(find.text('Handled today'), findsOneWidget);
    expect(find.text('SL-7 breached North fence'), findsOneWidget);
    expect(find.text('Evidence 1'), findsOneWidget);

    await tester.tap(find.text('SL-7 breached North fence'));
    expect(opened, isTrue);
  });

  test('parses workbench payload and reconciles unread total', () {
    final payload = {
      'summary': {
        'buckets': [
          {'key': 'immediate', 'total': 5, 'unread': 3},
          {'key': 'field', 'total': 7, 'unread': 2},
          {'key': 'observe', 'total': 5, 'unread': 0},
          {'key': 'resolved', 'total': 12, 'unread': 0},
        ],
        'assets': [
          {'key': 'fence', 'total': 2, 'unread': 1},
        ],
      },
      'items': [
        {
          'id': 'fence-01',
          'bucket': 'immediate',
          'asset': {'kind': 'fence', 'id': '3', 'name': 'North'},
          'title': '3 breached',
          'severity': 'CRITICAL',
          'unread': true,
          'reasons': [
            {
              'alertId': 101,
              'type': 'FENCE_BREACH',
              'severity': 'CRITICAL',
              'message': 'SL-07 breached',
              'read': false,
            },
          ],
          'ai': {'band': 'alarm', 'findingCode': 'temp_spike', 'score': 0.86},
          'actions': ['VIEW_FENCE'],
        },
      ],
      'page': 1,
      'pageSize': 50,
      'total': 1,
    };

    final data = AlertWorkbenchJson.fromMap(payload);
    expect(data.summary.immediate, 5);
    expect(data.summary.unreadTotal, 5);
    expect(data.items.single.reasons.single.alertId, '101');
    expect(data.items.single.ai?.band, 'alarm');
  });

  // ── NIX-286: estrus confirm/reject actions in the detail sheet ──

  Future<void> pumpDetailSheet(
    WidgetTester tester,
    WorkbenchItem item, {
    Future<AlertFeedbackResult> Function(String alertId,
            {required bool confirmed})?
        onEstrusFeedback,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AlertWorkbenchDetailSheet(
            item: item,
            role: UserRole.owner,
            onMarkRead: (_) async {},
            onDismiss: (_) async {},
            onNavigate: (_) {},
            onTrajectory: (_) {},
            onEstrusFeedback: onEstrusFeedback,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'ESTRUS item shows confirm/reject actions wired to the underlying alertId',
    (tester) async {
      final submissions = <(String alertId, bool confirmed)>[];
      await pumpDetailSheet(
        tester,
        _item(id: 'estrus-1', asset: 'livestock', reasonType: 'ESTRUS'),
        onEstrusFeedback: (alertId, {required confirmed}) async {
          submissions.add((alertId, confirmed));
          return AlertFeedbackResult(
            alertId: alertId,
            verdict: 'CONFIRMED',
          );
        },
      );

      expect(find.text('确认发情'), findsOneWidget);
      expect(find.text('不是发情'), findsOneWidget);

      // Confirm flow reaches the callback with the ESTRUS reason's alertId.
      await tester.tap(find.text('确认发情'));
      await tester.pumpAndSettle();
      expect(find.text('确认发情？'), findsOneWidget);
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();

      expect(submissions, hasLength(1));
      expect(submissions.single.$1, '101');
      expect(submissions.single.$2, isTrue);
      expect(find.text('已确认发情'), findsOneWidget);
    },
  );

  testWidgets('non-ESTRUS item shows no estrus confirm/reject actions', (
    tester,
  ) async {
    await pumpDetailSheet(tester, _item());
    expect(find.text('确认发情'), findsNothing);
    expect(find.text('不是发情'), findsNothing);
  });
}
