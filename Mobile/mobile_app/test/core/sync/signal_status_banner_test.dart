import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_status_banner.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_store.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_sync_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Publishes a fixed sync state so the banner can be exercised without the
/// polling/transport machinery.
class _FixedStateController extends SignalSyncController {
  _FixedStateController(this._state);

  final SignalSyncState _state;

  @override
  SignalSyncState build() => _state;
}

const _staleText = '实时信号同步中断，正在自动恢复';
const _retryText = '立即重试';
const _forbiddenText = '当前账号无权获取该牧场的实时信号，实时位置与状态不可用';

Future<void> _pumpBanner(WidgetTester tester, SignalSyncState state) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        signalSyncControllerProvider.overrideWith(
          () => _FixedStateController(state),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SignalSyncStatusBanner()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('a transient outage keeps the recovering text and retry button', (
    tester,
  ) async {
    await _pumpBanner(tester, const SignalSyncState(farmId: '1', stale: true));

    expect(find.text(_staleText), findsOneWidget);
    expect(find.text(_retryText), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
    expect(find.text(_forbiddenText), findsNothing);
  });

  // A permission denial neither recovers on its own nor changes on retry, so
  // "recovering automatically" would be false and the retry button useless.
  testWidgets('a permission denial states it and offers no retry', (
    tester,
  ) async {
    await _pumpBanner(
      tester,
      const SignalSyncState(farmId: '1', stale: true, forbidden: true),
    );

    expect(find.text(_forbiddenText), findsOneWidget);
    expect(find.text(_staleText), findsNothing);
    expect(find.text(_retryText), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('a healthy sync renders nothing', (tester) async {
    await _pumpBanner(tester, const SignalSyncState(farmId: '1'));

    expect(find.byType(Row), findsNothing);
    expect(find.text(_staleText), findsNothing);
    expect(find.text(_forbiddenText), findsNothing);
  });
}
