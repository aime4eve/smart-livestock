import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/alert_card.dart';

RanchAlertData _alert({bool read = false, String status = 'ACTIVE'}) {
  return RanchAlertData(
    id: '1',
    type: 'FENCE_BREACH',
    severity: 'CRITICAL',
    status: status,
    message: 'Test alert message',
    livestockId: '10',
    fenceId: '3',
    occurredAt: '2026-06-11T08:30:00Z',
    read: read,
  );
}

void main() {
  group('AlertCard', () {
    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AlertCard(alert: _alert())),
      ));
      expect(find.text('Test alert message'), findsOneWidget);
    });

    testWidgets('shows dismiss button when showDismiss is true and status is ACTIVE',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AlertCard(
            alert: _alert(status: 'ACTIVE'),
            showDismiss: true,
            onDismiss: () {},
          ),
        ),
      ));
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('does not show dismiss when status is not ACTIVE', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AlertCard(
            alert: _alert(status: 'DISMISSED'),
            showDismiss: true,
          ),
        ),
      ));
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AlertCard(alert: _alert(), onTap: () => tapped = true),
        ),
      ));
      await tester.tap(find.byKey(const Key('alert-card-1')));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('shows status badge for AUTO_RESOLVED', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AlertCard(alert: _alert(status: 'AUTO_RESOLVED'))),
      ));
      expect(find.text('已自动解除'), findsOneWidget);
    });
  });
}
