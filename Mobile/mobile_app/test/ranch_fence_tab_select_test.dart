import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/ranch_fence_tab.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

RanchFenceData _fence(String id, String name) => RanchFenceData(
      id: id,
      name: name,
      active: true,
      type: 'POLYGON',
      colorValue: 0xFF4C9A5F,
      points: const [
        LatLng(28.0, 112.0),
        LatLng(28.01, 112.0),
        LatLng(28.01, 112.01),
      ],
      areaHectares: 1,
      livestockCount: 2,
      version: 1,
    );

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: const [Locale('en'), Locale('zh')],
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('tapping a fence card reports selection', (tester) async {
    String? selectedId;
    await tester.pumpWidget(_wrap(SingleChildScrollView(
      child: RanchFenceTab(
        fences: [_fence('f1', 'Zone A'), _fence('f2', 'Zone B')],
        alerts: const [],
        noGpsCount: 0,
        outsideFenceCount: 0,
        totalLivestock: 5,
        fenceUnread: 0,
        fenceStatusMap: const {},
        livestockMarkers: const [],
        selectedFenceId: null,
        onFenceSelected: (id) => selectedId = id,
      ),
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Zone A'));
    await tester.pump();
    expect(selectedId, 'f1');

    // Rebuild with the parent-applied selection (RanchPage owns the state),
    // then tap the selected list card to collapse.
    await tester.pumpWidget(_wrap(SingleChildScrollView(
      child: RanchFenceTab(
        fences: [_fence('f1', 'Zone A'), _fence('f2', 'Zone B')],
        alerts: const [],
        noGpsCount: 0,
        outsideFenceCount: 0,
        totalLivestock: 5,
        fenceUnread: 0,
        fenceStatusMap: const {},
        livestockMarkers: const [],
        selectedFenceId: 'f1',
        onFenceSelected: (id) => selectedId = id,
      ),
    )));
    await tester.pump();
    await tester.tap(find.text('Zone A').last);
    await tester.pump();
    expect(selectedId, '');
  });
}
