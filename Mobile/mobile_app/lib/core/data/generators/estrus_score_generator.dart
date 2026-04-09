import 'dart:math';

import 'package:smart_livestock_demo/core/models/twin_models.dart';

class EstrusScoreGenerator {
  EstrusScoreGenerator({this.seed = 42});

  final int seed;
  final Map<String, List<EstrusTrendPoint>> _cache = {};

  List<EstrusTrendPoint> generate({
    required String livestockId,
    required bool inEstrus,
    required int cycleDay,
    required DateTime start,
    required DateTime end,
  }) {
    return _cache.putIfAbsent(livestockId, () => _doGenerate(
          livestockId: livestockId,
          inEstrus: inEstrus,
          cycleDay: cycleDay,
          start: start,
          end: end,
        ));
  }

  List<EstrusTrendPoint> _doGenerate({
    required String livestockId,
    required bool inEstrus,
    required int cycleDay,
    required DateTime start,
    required DateTime end,
  }) {
    final rng = Random(seed + livestockId.hashCode);
    final points = <EstrusTrendPoint>[];

    var t = start;
    var day = cycleDay;
    while (t.isBefore(end)) {
      double score;
      if (!inEstrus || day <= 16 || day == 21) {
        score = 10.0 + rng.nextDouble() * 20.0;
      } else if (day == 17 || day == 18) {
        score = 40.0 + rng.nextDouble() * 20.0;
      } else {
        score = 75.0 + rng.nextDouble() * 25.0;
      }

      score += (rng.nextDouble() - 0.5) * 10.0;
      score = score.clamp(0.0, 100.0);

      points.add(EstrusTrendPoint(
        score: double.parse(score.toStringAsFixed(1)),
        timestamp: t,
      ));

      t = t.add(const Duration(days: 1));
      day = (day % 21) + 1;
    }

    return points;
  }
}
