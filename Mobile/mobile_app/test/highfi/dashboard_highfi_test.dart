import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_stat_tile.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';

void main() {
  testWidgets('dashboard highfi blocks are visible', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('twin-farm-header')), findsOneWidget);
    expect(find.byKey(const Key('twin-stat-livestock')), findsOneWidget);
    expect(find.byKey(const Key('twin-scene-fever')), findsOneWidget);
    expect(find.byKey(const Key('twin-scene-epidemic')), findsOneWidget);
  });

  testWidgets('renders reusable high-fidelity components on dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byType(HighfiCard), findsWidgets);
    expect(find.byType(HighfiStatTile), findsWidgets);
    expect(find.byType(HighfiStatusChip), findsWidgets);
  });

  testWidgets('HighfiStatTile supports trend text and tap feedback', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HighfiStatTile(
            title: '在围率',
            value: '95.2%',
            caption: '今日牧场概览',
            trend: '+1.8%',
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('+1.8%'), findsOneWidget);

    await tester.tap(find.byType(HighfiStatTile));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('HighfiStatusChip can be created from ViewState presets', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HighfiStatusChip.fromViewState(
            viewState: ViewState.offline,
          ),
        ),
      ),
    );

    expect(find.text('离线'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
  });
}
