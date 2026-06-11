import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/features/ranch/domain/ranch_models.dart';
import 'package:smart_livestock_demo/features/ranch/presentation/widgets/auto_resolved_section.dart';

List<RanchAlertData> _alerts() => [
      RanchAlertData(
        id: '1',
        type: 'FENCE_BREACH',
        severity: 'CRITICAL',
        status: 'AUTO_RESOLVED',
        message: 'Auto-resolved alert 1',
        resolvedAt: '2026-06-11T08:30:00Z',
      ),
      RanchAlertData(
        id: '2',
        type: 'TEMPERATURE_ABNORMAL',
        severity: 'WARNING',
        status: 'AUTO_RESOLVED',
        message: 'Auto-resolved alert 2',
        resolvedAt: '2026-06-11T09:00:00Z',
      ),
    ];

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

void main() {
  group('AutoResolvedSection', () {
    testWidgets('shows collapsed by default with count', (tester) async {
      await tester.pumpWidget(_wrap(AutoResolvedSection(alerts: _alerts())));
      expect(find.text('已自动解除 (2)'), findsOneWidget);
      expect(find.text('Auto-resolved alert 1'), findsNothing);
    });

    testWidgets('expands on tap to show items', (tester) async {
      await tester.pumpWidget(_wrap(AutoResolvedSection(alerts: _alerts())));
      await tester.tap(find.byKey(const Key('auto-resolved-toggle')));
      await tester.pumpAndSettle();
      expect(find.text('Auto-resolved alert 1'), findsOneWidget);
      expect(find.text('Auto-resolved alert 2'), findsOneWidget);
    });

    testWidgets('renders nothing when alerts empty', (tester) async {
      await tester.pumpWidget(_wrap(const AutoResolvedSection(alerts: [])));
      expect(find.text('已自动解除'), findsNothing);
    });
  });
}
