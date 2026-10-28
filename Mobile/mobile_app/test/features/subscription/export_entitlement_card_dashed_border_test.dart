import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/widgets/export_entitlement_card.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// NIX-324 fidelity D3: the export-entitlement card must carry a dashed
/// info-blue border (prototype §5). Flutter has no dashed-border primitive,
/// so the fix mounted a CustomPainter walking the rounded rect — a solid
/// Border.all would regress to exactly one path draw with no stroke dashes.
class _CountingCanvas implements Canvas {
  int paths = 0;
  Paint? lastPaint;

  @override
  void drawPath(Path path, Paint paint) {
    paths++;
    lastPaint = paint;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets('export card paints a dashed stroke, not a solid border',
      (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ExportEntitlementCard(
          exportWindow: ExportWindow(
            terminatedAt: now.subtract(const Duration(days: 10)),
            windowEndsAt: now.add(const Duration(days: 20)),
            daysLeft: 20,
          ),
        ),
      ),
    ));

    final finder = find.byKey(const Key('export-entitlement-card'));
    expect(finder, findsOneWidget);
    final painter = tester.widget<CustomPaint>(finder).painter;
    expect(painter, isNotNull);

    final canvas = _CountingCanvas();
    painter!.paint(canvas, const Size(300, 120));

    // Rounded-rect perimeter ≈ 800px at 9px per dash cycle ⇒ ~89 segments;
    // a solid border is a single drawPath.
    expect(canvas.paths, greaterThan(20),
        reason: 'dashed border must emit many short path segments');
    // Paint.color round-trips through float32; compare the quantized
    // 8-bit channels or low-bit drift fails an identical-looking color.
    expect(canvas.lastPaint!.color.toARGB32(), 0xFF4A7F9D);
    expect(canvas.lastPaint!.style, PaintingStyle.stroke);
    expect(canvas.lastPaint!.strokeWidth, 1);
  });
}
