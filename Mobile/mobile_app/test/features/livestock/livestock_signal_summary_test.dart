import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_models.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/widgets/livestock_signal_summary.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

LivestockSignal _signal() {
  return LivestockSignal.fromJson({
    'livestockId': 14,
    'livestockCode': 'HKT14',
    'revision': 2,
    'health': {
      'status': 'CRITICAL',
      'activeAlertTypes': ['TEMPERATURE_ABNORMAL'],
      'metrics': {
        'rumenTemperature': {
          'value': 39.4,
          'unit': 'CELSIUS',
          'status': 'CRITICAL',
          'freshness': 'FRESH',
        },
        'rumenMotility': {
          'value': 2.1,
          'unit': 'TIMES_PER_MINUTE',
          'status': 'NORMAL',
          'freshness': 'FRESH',
        },
      },
    },
    'ai': {'status': 'OBSERVE', 'score': 0.4},
    'fence': {'status': 'BREACH'},
    'device': {'status': 'OFFLINE'},
    'alerts': {'activeCount': 3, 'unreadCount': 1},
  });
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: LivestockSignalSummary(signal: _signal())),
    ),
  );
  await tester.pump();
}

LivestockSignal _presenceSignal() {
  return LivestockSignal.fromJson({
    'livestockId': 14,
    'livestockCode': 'HKT14',
    'revision': 2,
    'presence': {
      'status': 'RETURN_HOME',
      'activeAlertTypes': ['RETURN_HOME'],
    },
  });
}

void main() {
  testWidgets('renders priority badges, +N, and rumen metrics', (tester) async {
    await _pump(tester);

    expect(find.byKey(const Key('livestock-signal-health')), findsOneWidget);
    expect(find.byKey(const Key('livestock-signal-fence')), findsOneWidget);
    expect(find.byKey(const Key('livestock-signal-device')), findsNothing);
    expect(find.byKey(const Key('livestock-signal-ai')), findsNothing);
    expect(find.byKey(const Key('livestock-signal-more')), findsOneWidget);
    expect(
      find.byKey(const Key('livestock-signal-rumen-temp')),
      findsOneWidget,
    );
    expect(find.textContaining('39.4°C'), findsOneWidget);
    expect(find.textContaining('2.1'), findsOneWidget);
  });

  testWidgets('renders return home as a separate presence badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: LivestockSignalSummary(signal: _presenceSignal())),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('livestock-signal-presence')), findsOneWidget);
    expect(find.byKey(const Key('livestock-signal-health')), findsNothing);
    expect(find.text('Return home'), findsOneWidget);
  });
}
