import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:hkt_livestock_agentic/core/map/map_constants.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/fence_item.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/widgets/fence_template_picker.dart';

/// Template presets must land on the caller-provided anchor (the active
/// farm's registered coordinates) instead of the hardcoded demo center,
/// so "new fence" on an overseas farm doesn't draw in Changsha.
void main() {
  const farmAnchor = LatLng(-32.0, -62.5);

  group('fenceTemplatePresetFor anchoring', () {
    test('rectangle preset centres on the anchor', () {
      final preset = fenceTemplatePresetFor(
        FenceTemplate.rectangle,
        anchor: farmAnchor,
      );
      expect(preset.type, FenceType.rectangle);
      for (final p in preset.drawingPoints) {
        expect((p.latitude - farmAnchor.latitude).abs(), lessThan(0.01));
        expect((p.longitude - farmAnchor.longitude).abs(), lessThan(0.01));
      }
      expect(preset.focusPoint, farmAnchor);
    });

    test('circle preset centred on the anchor', () {
      final preset = fenceTemplatePresetFor(
        FenceTemplate.circle,
        anchor: farmAnchor,
      );
      expect(preset.type, FenceType.circle);
      expect(preset.drawingPoints.first, farmAnchor);
      expect(preset.focusPoint, farmAnchor);
    });

    test('defaults keep the legacy demo-centre behaviour', () {
      final preset = fenceTemplatePresetFor(FenceTemplate.circle);
      expect(preset.focusPoint, MapConstants.mapCenter);
    });
  });
}
